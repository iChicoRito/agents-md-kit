#!/usr/bin/env python3
"""Build an Obsidian-style graph view from a graphify graph.json.

    python graph_view.py                      # graphify-out/graph.json -> graphify-out/graph.html
    python graph_view.py path/to/graph.json -o view.html --title "My project"

The result is one self-contained HTML file: no network, no build step, open it in any browser.
Python 3.8+, standard library only.
"""
import argparse
import html
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
VENDOR = ["d3-dispatch.min.js", "d3-quadtree.min.js", "d3-timer.min.js", "d3-force.min.js"]
NODE_KEYS = ("id", "label", "community", "community_name", "file_type", "source_file", "source_location", "_callable", "_callable_class")
LINK_KEYS = ("source", "target", "relation", "confidence")
SAFE = {"<": "\\u003c", ">": "\\u003e", "&": "\\u0026", " ": "\\u2028", " ": "\\u2029"}


def read(path):
    with open(path, encoding="utf-8") as f:
        return f.read()


def json_safe(text):
    """Make JSON safe inside an HTML <script> element. The \\u escapes are valid inside JSON strings."""
    return "".join(SAFE.get(c, c) for c in text)


def slim(graph, title):
    """Keep only the fields the viewer uses. Large graphs get much smaller."""
    nodes = [{k: n[k] for k in NODE_KEYS if k in n} for n in graph.get("nodes", [])]
    raw_links = graph.get("links", graph.get("edges", []))
    links = [{k: e[k] for k in LINK_KEYS if k in e} for e in raw_links]
    return {"directed": bool(graph.get("directed")), "nodes": nodes, "links": links, "__title": title}


def default_title(graph_path):
    folder = os.path.basename(os.path.dirname(os.path.dirname(os.path.abspath(graph_path))))
    return folder or "Graph"


def build(graph_path, out_path, title=None):
    graph = json.loads(read(graph_path))
    title = title or default_title(graph_path)
    view = slim(graph, title)
    data = json.dumps(view, separators=(",", ":"), ensure_ascii=False)
    vendor = "\n".join(read(os.path.join(HERE, "vendor", name)).strip() for name in VENDOR)
    if "</script" in vendor.lower():
        raise SystemExit("vendor code must not contain </script")
    page = read(os.path.join(HERE, "template.html"))
    for token in ("/*__VENDOR__*/", "/*__DATA__*/", "__TITLE_TEXT__"):
        if token not in page:
            raise SystemExit("template.html is missing " + token)
    # data goes last so a stray token inside it is never replaced
    page = page.replace("__TITLE_TEXT__", html.escape(title))
    page = page.replace("/*__VENDOR__*/", vendor, 1)
    page = page.replace("/*__DATA__*/", json_safe(data), 1)
    os.makedirs(os.path.dirname(os.path.abspath(out_path)), exist_ok=True)
    with open(out_path, "w", encoding="utf-8", newline="\n") as f:
        f.write(page)
    return len(view["nodes"]), len(view["links"])


def main(argv=None):
    ap = argparse.ArgumentParser(description="Build an Obsidian-style graph view from graphify-out/graph.json")
    ap.add_argument("graph", nargs="?", default=os.path.join("graphify-out", "graph.json"), help="path to graph.json")
    ap.add_argument("-o", "--out", help="output file (default: graph.html next to graph.json)")
    ap.add_argument("--title", help="name shown in the top bar (default: the project folder)")
    args = ap.parse_args(argv)
    if not os.path.isfile(args.graph):
        print("No graph found at %s. Build one first: graphify update ." % args.graph, file=sys.stderr)
        return 2
    out = args.out or os.path.join(os.path.dirname(os.path.abspath(args.graph)), "graph.html")
    try:
        n, e = build(args.graph, out, args.title)
    except (OSError, ValueError) as err:
        print("Could not build the graph view: %s" % err, file=sys.stderr)
        return 1
    print("Graph view: %s (%d nodes, %d links)" % (out, n, e))
    return 0


if __name__ == "__main__":
    sys.exit(main())
