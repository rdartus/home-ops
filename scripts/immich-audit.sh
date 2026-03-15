#!/usr/bin/env bash
# =============================================================================
# immich-audit.sh — Fichiers NAS non encore importés dans Immich
# =============================================================================
#
# Compare les fichiers physiques du NAS (upload/ + library/) avec la base
# Immich pour identifier ceux qui sont SUR LE DISQUE MAIS ABSENTS DE LA BASE
# (= à ré-uploader).
# Mode par défaut: permissif sur le suffixe +N avant extension (ex: +1).
# Mode strict avec --exact.
#
# Prérequis :
#   - ssh    (accès au NAS)
#   - comm, sort (coreutils, présents par défaut)
#   - psql   (paquet postgresql-client) — sauf si kubectl dispo (kubectl exec fallback)
#
# Connexion DB auto-détectée :
#   1. IP MetalLB du service cnpg-cluster-rw-lb si le NAS est joignable
#   2. Sinon : kubectl exec sur le pod primaire CNPG (aucun port-forward)
#   Les credentials sont auto-lus depuis le secret k8s immich-db-secret.
#
# Utilisation :
#   ./scripts/immich-audit.sh [options]
#
# Options :
#   --db-user       Utilisateur PostgreSQL  (auto depuis secret k8s)
#   --db-password   Mot de passe            (auto depuis secret k8s)
#   --db-host       Hôte PostgreSQL         (auto-détecté)
#   --ssh-user      Utilisateur SSH NAS     (défaut : jeank)
#   --output        Rapport texte           (défaut : immich-audit.txt)
#   --exact         Comparaison stricte (noms exacts)
#   --show-missing  Affiche aussi les assets en base mais absents du disque
#   -h, --help      Aide
#
# Sorties générées :
#   immich-audit.txt          — rapport lisible
#   immich-audit-reupload.txt — un chemin NAS absolu par ligne (pour immich-cli)
#   immich-audit-disk.txt     — liste brute des fichiers disque
#   immich-audit-db.txt       — liste brute des fichiers base
#   immich-audit-disk-normalized.txt — liste disque normalisée (debug)
#   immich-audit-db-normalized.txt   — liste base normalisée (debug)
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
DB_USER="mich"
DB_PASSWORD=""

SSH_USER="jeank"
OUTPUT="immich-audit.txt"
COMPARE_EXACT=false
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
    --db-host)       DB_HOST="$2";      shift 2 ;;
    --db-password)   DB_PASSWORD="$2"; shift 2 ;;
    --ssh-user)      SSH_USER="$2";    shift 2 ;;
    --output)        OUTPUT="$2";      shift 2 ;;
    --exact)         COMPARE_EXACT=true; shift ;;
    --show-missing)  SHOW_MISSING=true;  shift ;;
    -h|--help)       usage; exit 0 ;;
    *) echo "Option inconnue : $1" >&2; echo "Utilisez -h pour l'aide." >&2; exit 1 ;;
  esac
done

# try to auto-fetch username and password from kubernetes secret if nothing provided
if [[ -z "$DB_PASSWORD" ]] && command -v kubectl &>/dev/null; then
  secret_json=$(kubectl get secret immich-db-secret -n default \
                  -o jsonpath='{.data}' 2>/dev/null || true)
  if [[ -n "$secret_json" ]]; then
    secret_pw=$(echo "$secret_json" | python3 -c \
      "import sys,json,base64; d=json.load(sys.stdin); print(base64.b64decode(d['password']).decode())" 2>/dev/null || true)
    secret_user=$(echo "$secret_json" | python3 -c \
      "import sys,json,base64; d=json.load(sys.stdin); print(base64.b64decode(d['username']).decode())" 2>/dev/null || true)
    [[ -n "$secret_pw" ]]   && DB_PASSWORD="$secret_pw"
    [[ -n "$secret_user" ]] && DB_USER="$secret_user"
  fi
fi

if [[ -z "$DB_PASSWORD" ]]; then
  echo "ERREUR : --db-password est requis (ou configurer le secret k8s)." >&2
  echo "Utilisez -h pour l'aide." >&2
  exit 1
fi

# Fichier de sortie avec les chemins NAS absolus (pour immich-cli)
UPLOAD_LIST="${OUTPUT%.txt}-reupload.txt"
DISK_EXPORT="${OUTPUT%.txt}-disk.txt"
DB_EXPORT="${OUTPUT%.txt}-db.txt"
DISK_NORMALIZED_EXPORT="${OUTPUT%.txt}-disk-normalized.txt"
DB_NORMALIZED_EXPORT="${OUTPUT%.txt}-db-normalized.txt"

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
# NOTE: le trap principal est posé plus bas (après la détection de connectivité).

DISK_FILE="$TMPDIR_WORK/disk.txt"
DB_FILE="$TMPDIR_WORK/db.txt"
DISK_NORMALIZED_FILE="$TMPDIR_WORK/disk-normalized.txt"
DB_NORMALIZED_FILE="$TMPDIR_WORK/db-normalized.txt"
DISK_PAIRED_FILE="$TMPDIR_WORK/disk-paired.txt"
DB_PAIRED_FILE="$TMPDIR_WORK/db-paired.txt"
MISSING_FILE="$TMPDIR_WORK/missing.txt"   # dans DB, absent disque
ORPHANED_FILE="$TMPDIR_WORK/orphaned.txt" # sur disque, absent DB

normalize_compare_list() {
  sed -E 's/\+[0-9]+(\.[^./]+)$/\1/' "$1"
}

# ── Helper psql ────────────────────────────────────────────────────────────────
CNPG_POD=""
USE_KUBECTL_EXEC=false

trap 'rm -rf "$TMPDIR_WORK"' EXIT

# Auto-detect connectivity: direct LB IP si joignable, sinon kubectl exec
if [[ "$DB_HOST" == "localhost" ]] && command -v kubectl &>/dev/null; then
  svcip=$(kubectl get svc cnpg-cluster-rw-lb -n database \
            -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || true)
  if [[ -n "$svcip" ]]; then
    if ping -c1 -W1 "$svcip" &>/dev/null 2>&1; then
      DB_HOST="$svcip"
      echo "[base]  IP LB détectée et joignable : ${DB_HOST}"
    else
      echo "[base]  IP LB ${svcip} injoignable (WSL/réseau isolé) — kubectl exec fallback"
      USE_KUBECTL_EXEC=true
      CNPG_POD=$(kubectl get pods -n database \
        -l cnpg.io/instanceRole=primary \
        -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)
      if [[ -z "$CNPG_POD" ]]; then
        echo "ERREUR : impossible de trouver le pod primaire CNPG." >&2; exit 1
      fi
      echo "[base]  Pod primaire : ${CNPG_POD}"
    fi
  fi
fi

export PGPASSWORD="$DB_PASSWORD"
# Via LB : TLS chiffré (pas de vérification CA pour usage LAN).
# Via kubectl exec : connexion locale 127.0.0.1 dans le pod, SSL désactivé.
if $USE_KUBECTL_EXEC; then
  export PGSSLMODE="disable"
  psql_q() {
    kubectl exec -n database "$CNPG_POD" -c postgres -q -- \
      env PGPASSWORD="$DB_PASSWORD" PGSSLMODE=disable \
      psql -h 127.0.0.1 -U "$DB_USER" -d "$DB_NAME" -t -A --no-psqlrc "$@"
  }
else
  export PGSSLMODE="require"
  psql_q() {
    psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -t -A --no-psqlrc "$@"
  }
fi

# ── 1. Fichiers sur le disque ──────────────────────────────────────────────────
echo "[disque] Listage via SSH ${SSH_USER}@${DISK_HOST}:${DISK_PORT} …"

ssh -p "$DISK_PORT" \
    -o StrictHostKeyChecking=accept-new \
    -o BatchMode=yes \
    "${SSH_USER}@${DISK_HOST}" \
  "find '$DISK_BASE/upload' '$DISK_BASE/library' -type f ! -name '.immich' 2>/dev/null || true" \
  | LC_ALL=C sed "s|^${DISK_BASE}/||" \
  | LC_ALL=C sort \
  > "$DISK_FILE"

cp "$DISK_FILE" "$DISK_EXPORT"
normalize_compare_list "$DISK_FILE" | LC_ALL=C sort > "$DISK_NORMALIZED_FILE"
cp "$DISK_NORMALIZED_FILE" "$DISK_NORMALIZED_EXPORT"
paste "$DISK_FILE" "$DISK_NORMALIZED_FILE" > "$DISK_PAIRED_FILE"

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
  echo "  → vérifier que le service est accessible (port‑forward ou IP LB)" >&2
  echo "    kubectl get svc cnpg-cluster-rw-lb -n database" >&2
  exit 1
fi

DB_ASSET_TOTAL=$(psql_q -c "SELECT COUNT(*) FROM asset")
DB_USER_TOTAL=$(psql_q -c "SELECT COUNT(*) FROM \"user\" WHERE \"deletedAt\" IS NULL")
echo "[base]  ${DB_ASSET_TOTAL} assets, ${DB_USER_TOTAL} utilisateurs"

# Chemins relatifs (strip du préfixe container)
psql_q -c "
  SELECT regexp_replace(\"originalPath\", '^${CONTAINER_ROOT}/', '')
  FROM asset
  ORDER BY 1
" \
  | LC_ALL=C sort \
  > "$DB_FILE"

cp "$DB_FILE" "$DB_EXPORT"
normalize_compare_list "$DB_FILE" | LC_ALL=C sort > "$DB_NORMALIZED_FILE"
cp "$DB_NORMALIZED_FILE" "$DB_NORMALIZED_EXPORT"
paste "$DB_FILE" "$DB_NORMALIZED_FILE" > "$DB_PAIRED_FILE"

# ── 3. Comparaison ─────────────────────────────────────────────────────────────
echo ""
echo "[audit] Comparaison disque ↔ base …"

if $COMPARE_EXACT; then
  echo "[audit] Mode comparaison : exact"
else
  echo "[audit] Mode comparaison : permissif (+N avant extension ignoré)"
fi

if $COMPARE_EXACT; then
  # Lignes uniquement dans DB (manquantes sur disque), comparaison exacte
  comm -13 "$DISK_FILE" "$DB_FILE" > "$MISSING_FILE"
  # Lignes uniquement sur disque (orphelins), comparaison exacte
  comm -23 "$DISK_FILE" "$DB_FILE" > "$ORPHANED_FILE"
else
  # Lignes uniquement dans DB (manquantes sur disque), comparaison permissive +N
  awk -F '\t' 'NR==FNR { seen[$2]=1; next } !($2 in seen) { print $1 }' \
    "$DISK_PAIRED_FILE" "$DB_PAIRED_FILE" > "$MISSING_FILE"
  # Lignes uniquement sur disque (orphelins), comparaison permissive +N
  awk -F '\t' 'NR==FNR { seen[$2]=1; next } !($2 in seen) { print $1 }' \
    "$DB_PAIRED_FILE" "$DISK_PAIRED_FILE" > "$ORPHANED_FILE"
fi

MISSING_COUNT=$(wc -l < "$MISSING_FILE")
ORPHANED_COUNT=$(wc -l < "$ORPHANED_FILE")

# Assets manquants actifs (non soft-deleted)
if [[ "$MISSING_COUNT" -gt 0 ]]; then
  MISSING_ACTIVE=$(psql_q -c "
    SELECT COUNT(*)
    FROM asset
    WHERE \"deletedAt\" IS NULL
      AND regexp_replace(\"originalPath\", '^${CONTAINER_ROOT}/', '') = ANY(
        SELECT unnest(string_to_array(\$\$$(paste -sd',' "$MISSING_FILE")\$\$, ','))
      )
  " 2>/dev/null || echo "N/A")
else
  MISSING_ACTIVE=0
fi

# ── 4. Statistiques par utilisateur ───────────────────────────────────────────
echo ""
echo "[audit] Statistiques par utilisateur …"

USER_STATS=$(psql_q -c "
  SELECT
    u.email,
    u.name,
    COUNT(a.id)                                            AS total,
    COUNT(a.id) FILTER (WHERE a.\"deletedAt\" IS NOT NULL) AS soft_deleted
  FROM \"user\" u
  LEFT JOIN asset a ON a.\"ownerId\" = u.id
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
  printf "  %-42s %d\n" "Fichiers sur disque (upload/ + library/)" "$DISK_COUNT"
  printf "  %-42s %d\n" "Assets importés dans Immich" "$DB_ASSET_TOTAL"
  echo "  ────────────────────────────────────────────────────────"
  printf "  %-42s %d  ★\n" "À RE-UPLOADER (disque, absent de la base)" "$ORPHANED_COUNT"
  printf "  %-42s %d\n" "En base mais absent du disque" "$MISSING_COUNT"
  printf "  %-42s %s\n" "  dont non soft-deleted" "$MISSING_ACTIVE"
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

# ── 6. Fichiers à ré-uploader dans Immich ─────────────────────────────────────

# Génération systématique du fichier de chemins absolus NAS
: > "$UPLOAD_LIST"
if [[ "$ORPHANED_COUNT" -gt 0 ]]; then
  while IFS= read -r relpath; do
    printf '%s/%s\n' "$DISK_BASE" "$relpath"
  done < "$ORPHANED_FILE" > "$UPLOAD_LIST"
fi

{
  echo ""
  echo "FICHIERS À RE-UPLOADER DANS IMMICH (${ORPHANED_COUNT})"
  echo "════════════════════════════════════════════════════════════"
  if [[ "$ORPHANED_COUNT" -gt 0 ]]; then
    echo ""
    echo "  Répartition par dossier :"
    # group by 2nd-level path (ex: library/2023, upload/2024)
    awk -F'/' '{print $1"/"$2}' "$ORPHANED_FILE" \
      | LC_ALL=C sort | uniq -c \
      | LC_ALL=C sort -k2 \
      | while read -r cnt subdir; do
          printf "    %-32s %4d fichiers\n" "${subdir}/" "$cnt"
        done
    echo ""
    echo "  Chemins NAS complets → ${UPLOAD_LIST}"
    echo ""
    echo "  Exemple de re-upload avec l'immich-cli :"
    echo "    while IFS= read -r f; do"
    echo "      immich upload --server http://<HOST> --key <API_KEY> \"\$f\""
    echo "    done < '${UPLOAD_LIST}'"
  else
    echo "  Aucun fichier orphelin — tous les médias sont déjà dans Immich."
  fi
  echo "════════════════════════════════════════════════════════════"
} | tee -a "$OUTPUT"

# ── 7. Assets en base mais absents du disque (optionnel) ───────────────────────
if $SHOW_MISSING && [[ "$MISSING_COUNT" -gt 0 ]]; then
  {
    echo ""
    echo "ASSETS EN BASE MAIS ABSENTS DU DISQUE (${MISSING_COUNT}) :"
    echo "────────────────────────────────────────────────────────"
    psql_q -c "
      SELECT
        u.email,
        a.type,
        a.\"originalFileName\",
        a.\"deletedAt\" IS NOT NULL  AS soft_deleted,
        to_char(a.\"fileCreatedAt\", 'YYYY-MM-DD') AS created,
        COALESCE(af.size, 0)        AS file_size,
        regexp_replace(a.\"originalPath\", '^${CONTAINER_ROOT}/', '') AS rel_path
      FROM asset a
      JOIN \"user\" u ON u.id = a.\"ownerId\"
      LEFT JOIN asset_file af ON af.\"assetId\" = a.id AND af.type = 'original'
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
  } | tee -a "$OUTPUT"
fi

echo ""
echo "Rapport   → ${OUTPUT}"
[[ -s "$UPLOAD_LIST" ]] && echo "Re-upload → ${UPLOAD_LIST}  (${ORPHANED_COUNT} fichiers)"
echo "Disque    → ${DISK_EXPORT}"
echo "Base      → ${DB_EXPORT}"
echo "Disque ≈  → ${DISK_NORMALIZED_EXPORT}"
echo "Base ≈    → ${DB_NORMALIZED_EXPORT}"
