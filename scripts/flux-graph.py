#!/usr/bin/env python3
"""
flux-graph.py — Generate a Mermaid dependency graph from Flux Kustomization files.

Usage:
  python3 scripts/flux-graph.py                  # print Mermaid to stdout
  python3 scripts/flux-graph.py --update-readme  # patch the README in-place
  python3 scripts/flux-graph.py --namespace default  # filter to one namespace
  python3 scripts/flux-graph.py --no-archive     # already the default; kept for clarity
"""

import argparse
import re
import sys
from pathlib import Path

try:
    import yaml
except ImportError:
    sys.exit("PyYAML is required: pip install pyyaml")

# ── config ────────────────────────────────────────────────────────────────────

REPO_ROOT = Path(__file__).resolve().parent.parent
KS_GLOB = "kubernetes/**/ks.yaml"
ARCHIVE_PATH = "kubernetes/_archive"

README = REPO_ROOT / "README.md"
# The script rewrites everything between these two markers inside the README.
README_START_MARKER = "```mermaid"
README_END_MARKER = "```"
# Section heading that locates the right mermaid block (there could be several).
README_SECTION = "### Cluster layout"

# ── YAML parsing ──────────────────────────────────────────────────────────────

def load_kustomizations(repo_root: Path, exclude_archive: bool = True) -> list[dict]:
    """Return a list of Kustomization manifests found in ks.yaml files."""
    results = []
    for path in sorted(repo_root.glob(KS_GLOB)):
        if exclude_archive and ARCHIVE_PATH in path.as_posix():
            continue
        try:
            docs = list(yaml.safe_load_all(path.read_text()))
        except yaml.YAMLError as exc:
            print(f"[WARN] Could not parse {path}: {exc}", file=sys.stderr)
            continue

        for doc in docs:
            if not isinstance(doc, dict):
                continue
            api = doc.get("apiVersion", "")
            kind = doc.get("kind", "")
            if kind != "Kustomization" or "kustomize.toolkit.fluxcd.io" not in api:
                continue
            meta = doc.get("metadata", {})
            name = meta.get("name", "")
            namespace = meta.get("namespace", "")
            depends_on = doc.get("spec", {}).get("dependsOn") or []
            if name:
                results.append(
                    {
                        "name": name,
                        "namespace": namespace,
                        "dependsOn": depends_on,
                        "file": path.relative_to(repo_root).as_posix(),
                    }
                )
    return results


# ── graph building ────────────────────────────────────────────────────────────

def node_id(name: str, namespace: str) -> str:
    """Stable, sanitised Mermaid node id."""
    return re.sub(r"[^a-zA-Z0-9_]", "_", f"{namespace}__{name}")


def build_graph(
    kustomizations: list[dict],
    filter_ns: str | None = None,
) -> tuple[dict, list[tuple]]:
    """
    Returns:
      nodes  – {node_id: label_string}
      edges  – [(from_id, to_id, label)]
    Arrows follow the "A depends on B" direction: A --> B.
    """
    nodes: dict[str, str] = {}
    edges: list[tuple] = []

    # Index for quick lookup
    known: dict[tuple, str] = {}  # (name, namespace) -> node_id

    for ks in kustomizations:
        if filter_ns and ks["namespace"] != filter_ns:
            continue
        nid = node_id(ks["name"], ks["namespace"])
        label = f"Kustomization: {ks['name']}"
        nodes[nid] = label
        known[(ks["name"], ks["namespace"])] = nid

    for ks in kustomizations:
        if filter_ns and ks["namespace"] != filter_ns:
            continue
        src_id = node_id(ks["name"], ks["namespace"])
        for dep in ks["dependsOn"]:
            dep_name = dep.get("name", "")
            dep_ns = dep.get("namespace", ks["namespace"])
            dep_id = node_id(dep_name, dep_ns)
            # Add the dependency node even if it lives outside filter_ns
            if dep_id not in nodes:
                nodes[dep_id] = f"Kustomization: {dep_name}"
            edges.append((src_id, dep_id, "dependsOn"))

    return nodes, edges


# ── Mermaid rendering ─────────────────────────────────────────────────────────

def render_mermaid(nodes: dict, edges: list[tuple]) -> str:
    lines = ["graph TD;"]
    for nid, label in sorted(nodes.items()):
        lines.append(f'  {nid}["{label}"]')
    lines.append("")
    for src, dst, rel in sorted(edges):
        arrow_label = "Depends on" if rel == "dependsOn" else rel
        lines.append(f"  {src} -->|\"{arrow_label}\"| {dst}")
    return "\n".join(lines)


# ── README patching ───────────────────────────────────────────────────────────

def update_readme(mermaid_body: str, readme: Path = README) -> None:
    """Replace the mermaid block that follows README_SECTION in the README."""
    text = readme.read_text()

    # Locate the section heading
    section_pos = text.find(README_SECTION)
    if section_pos == -1:
        sys.exit(f"[ERROR] Could not find '{README_SECTION}' in {readme}")

    # Find the first ```mermaid after the section heading
    search_from = section_pos + len(README_SECTION)
    start_pos = text.find(README_START_MARKER, search_from)
    if start_pos == -1:
        sys.exit(f"[ERROR] Could not find {README_START_MARKER!r} after '{README_SECTION}'")

    # Find the closing ```
    end_search_from = start_pos + len(README_START_MARKER)
    end_pos = text.find(README_END_MARKER, end_search_from)
    if end_pos == -1:
        sys.exit("[ERROR] Could not find the closing ``` for the mermaid block")

    new_block = f"{README_START_MARKER}\n{mermaid_body}\n{README_END_MARKER}"
    new_text = text[:start_pos] + new_block + text[end_pos + len(README_END_MARKER):]
    readme.write_text(new_text)
    print(f"[OK] README updated: {readme}", file=sys.stderr)


# ── CLI ───────────────────────────────────────────────────────────────────────

def main() -> None:
    parser = argparse.ArgumentParser(
        description="Generate a Mermaid graph of Flux Kustomization dependencies."
    )
    parser.add_argument(
        "--update-readme",
        action="store_true",
        help="Patch the Cluster layout mermaid block in README.md",
    )
    parser.add_argument(
        "--namespace",
        metavar="NS",
        default=None,
        help="Filter nodes to a single namespace (dependencies outside it are still shown).",
    )
    parser.add_argument(
        "--include-archive",
        action="store_true",
        help="Also include files under kubernetes/_archive/",
    )
    parser.add_argument(
        "--repo",
        metavar="PATH",
        default=str(REPO_ROOT),
        help=f"Path to the repository root (default: {REPO_ROOT})",
    )
    args = parser.parse_args()

    repo_root = Path(args.repo).resolve()
    kustomizations = load_kustomizations(repo_root, exclude_archive=not args.include_archive)

    if not kustomizations:
        sys.exit("[ERROR] No Kustomization manifests found.")

    nodes, edges = build_graph(kustomizations, filter_ns=args.namespace)
    mermaid = render_mermaid(nodes, edges)

    if args.update_readme:
        update_readme(mermaid, readme=repo_root / "README.md")
    else:
        print(f"```mermaid\n{mermaid}\n```")


if __name__ == "__main__":
    main()
