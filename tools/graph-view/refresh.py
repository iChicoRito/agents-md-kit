#!/usr/bin/env python3
"""Refresh the code graph, then rebuild the graph view with this project's template.

    python tools/graph-view/refresh.py              # graphify update . then the view
    python tools/graph-view/refresh.py --no-graph   # only rebuild the view

graphify runs with GRAPHIFY_VIZ_NODE_LIMIT=0, so it does not render its own
graph.html. That leaves exactly one HTML view in the project, and that view is
built from template.html. Nothing left in the pipeline can put the default
design back: not `graphify update .`, not its git hooks, not a full rebuild.

An existing graph.html is removed for the same reason: a second page with the
default look invites opening the wrong one.
"""
import os
import shutil
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
OUT = os.path.join(ROOT, "graphify-out")
GRAPH = os.path.join(OUT, "graph.json")
VIEW = os.path.join(OUT, "graph-view.html")
DEFAULT_HTML = os.path.join(OUT, "graph.html")


def update_graph() -> None:
    exe = shutil.which("graphify")
    if not exe:
        print("graphify not found on PATH; skipping the graph update.", file=sys.stderr)
        return
    env = dict(os.environ, GRAPHIFY_VIZ_NODE_LIMIT="0")
    print("Updating the code graph (graphify, no HTML)...")
    subprocess.run([exe, "update", "."], cwd=ROOT, env=env)


def build_view() -> int:
    gen = os.path.join(HERE, "graph_view.py")
    print("Building the graph view from template.html...")
    return subprocess.run([sys.executable, gen, GRAPH, "-o", VIEW], cwd=ROOT).returncode


def main(argv) -> int:
    if "--help" in argv or "-h" in argv:
        print(__doc__.strip())
        return 0
    if "--no-graph" not in argv:
        update_graph()
    code = build_view()
    if code != 0:
        return code
    if os.path.exists(DEFAULT_HTML):
        os.remove(DEFAULT_HTML)
        print("Removed graphify's graph.html: one view only, always this design.")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
