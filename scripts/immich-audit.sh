#!/usr/bin/env bash
# =============================================================================
# immich-audit.sh — Comparaison fichiers disque vs base de données Immich
# =============================================================================
#
# Prérequis :
#   - psql   (paquet postgresql-client)
#   - ssh    (accès à 192.168.1.16:22022)
#   - jq     (optionnel, pour la sortie JSON)
#
# Avant de lancer, ouvrir un port-forward dans un autre terminal :
#   kubectl port-forward service/cnpg-cluster-rw 5432:5432 -n database
#
# Récupérer le mot de passe :
#   kubectl get secret immich-db-secret -n default \
#     -o jsonpath='{.data.password}' | base64 -d
#
# Utilisation :
#   ./scripts/immich-audit.sh --db-password <MDP> [options]
#
# Options :
#   --db-user       Utilisateur PostgreSQL         (défaut : immich)
#   --db-password   Mot de passe PostgreSQL         (requis)
#   --ssh-user      Utilisateur SSH du serveur NAS  (défaut : jeank)
#   --output        Fichier de sortie texte          (défaut : immich-audit.txt)
#   --show-orphaned Affiche les fichiers orphelins sur disque
#   --show-missing  Affiche les assets manquants sur disque
#   -h, --help      Affiche cette aide
# =============================================================================

set -euo pipefail
LC_ALL=C  # tri cohérent pour comm

# ── Valeurs par défaut ─────────────────────────────────────────────────────────
DISK_HOST="192.168.1.16"
DISK_PORT=22022
DISK_BASE="/srv/dev-disk-by-uuid-46081b96-7d1c-451e-88ba-ab6d8e467c3c/Photo"

DB_HOST="localhost"
DB_PORT=5432
DB_NAME="immich"
DB_USER="immich"
DB_PASSWORD=""

SSH_USER="jeank"
OUTPUT="immich-audit.txt"
SHOW_ORPHANED=false
SHOW_MISSING=false

# Racine container → correspond à DISK_BASE sur le disque physique
CONTAINER_ROOT="/usr/src/app/upload"

# ── Aide ───────────────────────────────────────────────────────────────────────
usage() {
  sed -n '/#$/d; /^# ====/,/^# ====/p; /^# ===/q' "$0" | sed 's/^# \?//'
  grep -E '^\s+--' "$0" | head -20 || true
}

# ── Parsing des arguments ──────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case $1 in
    --db-user)       DB_USER="$2";     shift 2 ;;
    --db-password)   DB_PASSWORD="$2"; shift 2 ;;
    --ssh-user)      SSH_USER="$2";    shift 2 ;;
    --output)        OUTPUT="$2";      shift 2 ;;
    --show-orphaned) SHOW_ORPHANED=true; shift ;;
    --show-missing)  SHOW_MISSING=true;  shift ;;
    -h|--help)       usage; exit 0 ;;
    *) echo "Option inconnue : $1" >&2; echo "Utilisez -h pour l'aide." >&2; exit 1 ;;
  esac
done

if [[ -z "$DB_PASSWORD" ]]; then
  echo "ERREUR : --db-password est requis." >&2
  echo "Utilisez -h pour l'aide." >&2
  exit 1
fi

# ── Vérification des dépendances ───────────────────────────────────────────────
for cmd in psql ssh comm sort; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "ERREUR : '$cmd' est introuvable dans le PATH." >&2
    [[ "$cmd" == "psql" ]] && echo "  → apt install postgresql-client" >&2
    exit 1
  fi
done

JQ_AVAILABLE=false
command -v jq &>/dev/null && JQ_AVAILABLE=true

# ── Répertoire temporaire (nettoyé à la sortie) ────────────────────────────────
TMPDIR_WORK=$(mktemp -d)
trap 'rm -rf "$TMPDIR_WORK"' EXIT

DISK_FILE="$TMPDIR_WORK/disk.txt"
DB_FILE="$TMPDIR_WORK/db.txt"
MISSING_FILE="$TMPDIR_WORK/missing.txt"   # dans DB, absent disque
ORPHANED_FILE="$TMPDIR_WORK/orphaned.txt" # sur disque, absent DB

# ── Helper psql ────────────────────────────────────────────────────────────────
export PGPASSWORD="$DB_PASSWORD"
psql_q() {
  psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -t -A --no-psqlrc "$@"
}

# ── 1. Fichiers sur le disque ──────────────────────────────────────────────────
echo "[disque] Listage via SSH ${SSH_USER}@${DISK_HOST}:${DISK_PORT} …"

ssh -p "$DISK_PORT" \
    -o StrictHostKeyChecking=accept-new \
    -o BatchMode=yes \
    "${SSH_USER}@${DISK_HOST}" \
    "find '$DISK_BASE/upload' '$DISK_BASE/library' -type f 2>/dev/null || true" \
  | LC_ALL=C sed "s|^${DISK_BASE}/||" \
  | LC_ALL=C sort \
  > "$DISK_FILE"

DISK_COUNT=$(wc -l < "$DISK_FILE")
echo "[disque] ${DISK_COUNT} fichiers trouvés dans upload/ et library/"

# Compte aussi les autres sous-dossiers (thumbs, encoded-video…) pour info
echo "[disque] Répartition par sous-dossier :"
ssh -p "$DISK_PORT" \
    -o StrictHostKeyChecking=accept-new \
    -o BatchMode=yes \
    "${SSH_USER}@${DISK_HOST}" \
    "find '$DISK_BASE' -mindepth 1 -maxdepth 1 -type d -exec sh -c \
       'echo \"\$(find \"\$1\" -type f | wc -l) \$(basename \"\$1\")\"' _ {} \;" \
  | sort -rn \
  | while read -r count dir; do
      printf "    %-22s %8d fichiers\n" "${dir}/" "$count"
    done

# ── 2. Chemins depuis la base de données ──────────────────────────────────────
echo ""
echo "[base]  Connexion à ${DB_HOST}:${DB_PORT}/${DB_NAME} …"

if ! psql_q -c "SELECT 1" &>/dev/null; then
  echo "ERREUR : impossible de se connecter à PostgreSQL." >&2
  echo "  → kubectl port-forward service/cnpg-cluster-rw 5432:5432 -n database" >&2
  exit 1
fi

DB_ASSET_TOTAL=$(psql_q -c "SELECT COUNT(*) FROM assets")
DB_USER_TOTAL=$(psql_q -c "SELECT COUNT(*) FROM users WHERE \"deletedAt\" IS NULL")
echo "[base]  ${DB_ASSET_TOTAL} assets, ${DB_USER_TOTAL} utilisateurs"

# Chemins relatifs (strip du préfixe container)
psql_q -c "
  SELECT regexp_replace(\"originalPath\", '^${CONTAINER_ROOT}/', '')
  FROM assets
  ORDER BY 1
" \
  | LC_ALL=C sort \
  > "$DB_FILE"

# ── 3. Comparaison ─────────────────────────────────────────────────────────────
echo ""
echo "[audit] Comparaison disque ↔ base …"

# Lignes uniquement dans DB (manquantes sur disque)
comm -13 "$DISK_FILE" "$DB_FILE" > "$MISSING_FILE"
# Lignes uniquement sur disque (orphelins)
comm -23 "$DISK_FILE" "$DB_FILE" > "$ORPHANED_FILE"

MISSING_COUNT=$(wc -l < "$MISSING_FILE")
ORPHANED_COUNT=$(wc -l < "$ORPHANED_FILE")

# Assets manquants actifs (non soft-deleted)
MISSING_ACTIVE=$(psql_q -c "
  SELECT COUNT(*)
  FROM assets
  WHERE \"deletedAt\" IS NULL
    AND regexp_replace(\"originalPath\", '^${CONTAINER_ROOT}/', '') = ANY(
      SELECT unnest(string_to_array(\$\$$(paste -sd',' "$MISSING_FILE")\$\$, ','))
    )
" 2>/dev/null || echo "N/A")

# ── 4. Statistiques par utilisateur ───────────────────────────────────────────
echo ""
echo "[audit] Statistiques par utilisateur …"

USER_STATS=$(psql_q -c "
  SELECT
    u.email,
    u.name,
    COUNT(a.id)                                            AS total,
    COUNT(a.id) FILTER (WHERE a.\"deletedAt\" IS NOT NULL) AS soft_deleted
  FROM users u
  LEFT JOIN assets a ON a.\"ownerId\" = u.id
  WHERE u.\"deletedAt\" IS NULL
  GROUP BY u.id, u.email, u.name
  ORDER BY total DESC
" --field-separator='|')

# ── 5. Affichage du rapport ────────────────────────────────────────────────────
SEPARATOR="════════════════════════════════════════════════════════════"

print_report() {
  echo ""
  echo "$SEPARATOR"
  echo "  RÉSUMÉ"
  echo "$SEPARATOR"
  printf "  %-40s %d\n" "Fichiers suivis sur disque" "$DISK_COUNT"
  printf "  %-40s %d\n" "Assets en base" "$DB_ASSET_TOTAL"
  printf "  %-40s %d\n" "Orphelins sur disque (pas en base)" "$ORPHANED_COUNT"
  printf "  %-40s %d\n" "Manquants sur disque (en base)" "$MISSING_COUNT"
  printf "  %-40s %s\n" "  dont actifs (non soft-deleted)" "$MISSING_ACTIVE"
  echo ""
  echo "  PAR UTILISATEUR"
  echo "  ────────────────────────────────────────────────────────"
  printf "  %-35s %6s  %12s\n" "Email" "Total" "Soft-deleted"
  echo "  ────────────────────────────────────────────────────────"
  while IFS='|' read -r email name total soft_del; do
    printf "  %-35s %6s  %12s  (%s)\n" "$email" "$total" "$soft_del" "$name"
  done <<< "$USER_STATS"
  echo "$SEPARATOR"
}

print_report | tee "$OUTPUT"

# ── 6. Détails optionnels ──────────────────────────────────────────────────────
if $SHOW_ORPHANED && [[ "$ORPHANED_COUNT" -gt 0 ]]; then
  echo ""
  echo "FICHIERS ORPHELINS SUR DISQUE (${ORPHANED_COUNT}) :"
  echo "────────────────────────────────────────────────────────"
  cat "$ORPHANED_FILE"
fi | tee -a "$OUTPUT"

if $SHOW_MISSING && [[ "$MISSING_COUNT" -gt 0 ]]; then
  echo ""
  echo "ASSETS EN BASE MAIS ABSENTS DU DISQUE (${MISSING_COUNT}) :"
  echo "────────────────────────────────────────────────────────"

  # Pour chaque chemin manquant, récupérer les détails depuis la base
  psql_q -c "
    SELECT
      u.email,
      a.type,
      a.\"originalFileName\",
      a.\"deletedAt\" IS NOT NULL  AS soft_deleted,
      to_char(a.\"fileCreatedAt\", 'YYYY-MM-DD') AS created,
      a.\"fileSize\",
      regexp_replace(a.\"originalPath\", '^${CONTAINER_ROOT}/', '') AS rel_path
    FROM assets a
    JOIN users u ON u.id = a.\"ownerId\"
    WHERE regexp_replace(a.\"originalPath\", '^${CONTAINER_ROOT}/', '') = ANY(
      SELECT unnest(string_to_array(\$\$$(paste -sd',' "$MISSING_FILE")\$\$, ','))
    )
    ORDER BY u.email, a.\"fileCreatedAt\"
  " --field-separator='|' \
  | while IFS='|' read -r email type filename deleted created size rel_path; do
      del_marker=""
      [[ "$deleted" == "t" ]] && del_marker=" [SUPPRIMÉ]"
      printf "  [%-5s]%s %-30s  %s  %s\n" "$type" "$del_marker" "$filename" "$created" "$email"
    done
fi | tee -a "$OUTPUT"

echo ""
echo "Rapport enregistré dans : ${OUTPUT}"
