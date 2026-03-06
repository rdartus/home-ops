#!/usr/bin/env python3
"""
flux-graph.py — Generate a Mermaid dependency graph from Flux Kustomization files.

Usage:
  python3 scripts/flux-graph.py                  # simple graph (default)
  python3 scripts/flux-graph.py --full           # full graph: subgraphs + all edges
  python3 scripts/flux-graph.py --update-readme  # patch the README in-place
  python3 scripts/flux-graph.py --namespace default  # filter to one namespace
  python3 scripts/flux-graph.py --include-archive    # include _archive/ files

Simple mode (default):
  - Flat graph, no subgraphs.
  - Transitive edges removed: if C->B->A, the direct C->A edge is dropped.
  - Nodes with no dependsOn are linked from a virtual "Flux Controller" root.

Full mode (--full):
  - Nodes grouped in subgraphs per namespace.
  - All declared edges kept (no reduction).
  - No virtual root node.
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

FLUX_CONTROLLER_ID = "flux_controller"
FLUX_CONTROLLER_LABEL = "Flux Controller"


def node_id(name: str, namespace: str) -> str:
    """Stable, sanitised Mermaid node id."""
    return re.sub(r"[^a-zA-Z0-9_]", "_", f"{namespace}__{name}")


def build_graph(
    kustomizations: list[dict],
    filter_ns: str | None = None,
) -> tuple[dict[str, str], list[tuple[str, str]]]:
    """
    Returns:
      nodes – {node_id: label}
      edges – [(prerequisite_id, dependent_id)]  (before transitive reduction)
    Nodes with no declared dependsOn are collected as roots; they will be
    connected to the virtual Flux Controller node by render_mermaid.
    """
    ns_lookup: dict[tuple[str, str], str] = {
        (ks["name"], ks["namespace"]): ks["namespace"]
        for ks in kustomizations
    }

    nodes: dict[str, str] = {}   # node_id -> label
    edges: list[tuple[str, str]] = []
    # Track which nodes have at least one declared dependency
    has_deps: set[str] = set()

    def ensure_node(name: str, namespace: str) -> str:
        nid = node_id(name, namespace)
        if nid not in nodes:
            nodes[nid] = name
        return nid

    for ks in kustomizations:
        if filter_ns and ks["namespace"] != filter_ns:
            continue
        ensure_node(ks["name"], ks["namespace"])

    for ks in kustomizations:
        if filter_ns and ks["namespace"] != filter_ns:
            continue
        dependent_id = ensure_node(ks["name"], ks["namespace"])
        for dep in ks["dependsOn"]:
            dep_name = dep.get("name", "")
            dep_ns = dep.get("namespace") or ks["namespace"]
            if (dep_name, dep_ns) not in ns_lookup:
                dep_ns = next(
                    (ns for (n, ns) in ns_lookup if n == dep_name), dep_ns
                )
            prereq_id = ensure_node(dep_name, dep_ns)
            edges.append((prereq_id, dependent_id))
            has_deps.add(dependent_id)

    return nodes, edges, has_deps


# ── transitive reduction ──────────────────────────────────────────────────────

def transitive_reduction(edges: list[tuple[str, str]]) -> list[tuple[str, str]]:
    """
    Remove redundant edges from a DAG.
    Edge (u, v) is redundant when v is reachable from u via a longer path,
    i.e. through at least one intermediate node.
    """
    # Build adjacency list (full reachability per node, excluding direct edge)
    adj: dict[str, set[str]] = {}
    for u, v in edges:
        adj.setdefault(u, set()).add(v)
        adj.setdefault(v, set())  # ensure every node exists

    def reachable_via_others(u: str, v: str) -> bool:
        """True if v is reachable from u through any successor of u other than v."""
        visited: set[str] = set()
        stack = [w for w in adj.get(u, set()) if w != v]
        while stack:
            node = stack.pop()
            if node == v:
                return True
            if node not in visited:
                visited.add(node)
                stack.extend(adj.get(node, set()))
        return False

    return [(u, v) for u, v in edges if not reachable_via_others(u, v)]


# ── Mermaid rendering ─────────────────────────────────────────────────────────

def render_simple(
    nodes: dict[str, str],
    edges: list[tuple[str, str]],
    has_deps: set[str],
) -> str:
    """
    Simple mode: flat graph, transitive reduction, virtual Flux Controller root.
    """
    reduced = transitive_reduction(edges)
    root_ids = [nid for nid in sorted(nodes) if nid not in has_deps]

    lines = ["graph TD;"]
    lines.append("")
    lines.append(f'  {FLUX_CONTROLLER_ID}["{FLUX_CONTROLLER_LABEL}"]')
    lines.append("")

    for nid, label in sorted(nodes.items(), key=lambda x: x[1]):
        lines.append(f'  {nid}["{label}"]')

    lines.append("")
    for nid in root_ids:
        lines.append(f"  {FLUX_CONTROLLER_ID} --> {nid}")

    lines.append("")
    for prereq, dependent in sorted(reduced):
        lines.append(f"  {prereq} --> {dependent}")

    return "\n".join(lines)


def render_full(
    nodes: dict[str, str],
    edges: list[tuple[str, str]],
    kustomizations: list[dict],
) -> str:
    """
    Full mode: one subgraph per namespace, all declared edges, no reduction.
    """
    # Build namespace mapping from the raw kustomizations list
    ns_map: dict[str, str] = {
        node_id(ks["name"], ks["namespace"]): ks["namespace"]
        for ks in kustomizations
    }
    # For nodes referenced as deps that may live outside filter_ns, fall back
    # to extracting namespace from the node_id pattern "ns__name"
    def ns_from_id(nid: str) -> str:
        if nid in ns_map:
            return ns_map[nid]
        # node_id format: namespace__name (double underscore)
        parts = nid.split("__", 1)
        return parts[0].replace("_", "-") if len(parts) == 2 else "unknown"

    ns_to_nodes: dict[str, list[tuple[str, str]]] = {}
    for nid, label in sorted(nodes.items(), key=lambda x: x[1]):
        ns = ns_from_id(nid)
        ns_to_nodes.setdefault(ns, []).append((nid, label))

    lines = ["graph TD;"]

    for ns in sorted(ns_to_nodes):
        # Prefix with "ns_" to avoid Mermaid reserved keywords (e.g. "default")
        sg_id = "ns_" + re.sub(r"[^a-zA-Z0-9_]", "_", ns)
        lines.append("")
        lines.append(f'  subgraph {sg_id}["{ns}"]')
        for nid, label in ns_to_nodes[ns]:
            lines.append(f'    {nid}["{label}"]')
        lines.append("  end")

    lines.append("")
    for prereq, dependent in sorted(edges):
        lines.append(f"  {prereq} --> {dependent}")

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
        "--full",
        action="store_true",
        help="Full graph: subgraphs per namespace + all edges (no transitive reduction).",
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

    nodes, edges, has_deps = build_graph(kustomizations, filter_ns=args.namespace)

    if args.full:
        mermaid = render_full(nodes, edges, kustomizations)
    else:
        mermaid = render_simple(nodes, edges, has_deps)

    if args.update_readme:
        update_readme(mermaid, readme=repo_root / "README.md")
    else:
        print(f"```mermaid\n{mermaid}\n```")


if __name__ == "__main__":
    main()
