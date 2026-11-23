#!/usr/bin/env python3
"""Tests for tools/graph-view/graph_view.py. Run: python tests/test_graph_view.py (exit code 0 = all passed)."""
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
sys.path.insert(0, os.path.join(ROOT, "tools", "graph-view"))
import graph_view  # noqa: E402

FIXTURE = os.path.join(HERE, "fixtures", "graph.json")
failures = []


def check(name, cond, extra=""):
    print(("  ok   " if cond else "  FAIL ") + name + ("  " + extra if extra and not cond else ""))
    if not cond:
        failures.append(name)


def parts(page):
    """The page's <script> blocks: vendor code, graph data, app code."""
    blocks = re.findall(r"<script(?: id=\"graph-data\" type=\"application/json\")?>(.*?)</script>", page, re.S)
    return blocks if len(blocks) == 3 else None


def build(tmp, graph, name="g", title=None):
    src = os.path.join(tmp, name + ".json")
    out = os.path.join(tmp, name + ".html")
    with open(src, "w", encoding="utf-8") as f:
        json.dump(graph, f)
    graph_view.build(src, out, title)
    with open(out, encoding="utf-8") as f:
        return f.read()


def js_ok(code, tmp):
    """True when node accepts the code (or node is not installed, which is not a failure)."""
    node = shutil.which("node")
    if not node:
        return True
    path = os.path.join(tmp, "check.js")
    with open(path, "w", encoding="utf-8") as f:
        f.write(code)
    return subprocess.run([node, "--check", path], capture_output=True).returncode == 0


tmp = tempfile.mkdtemp()
try:
    with open(FIXTURE, encoding="utf-8") as f:
        fixture = json.load(f)

    print("== real graph (graphify output)")
    page = build(tmp, fixture, "fixture", "demo")
    blocks = parts(page)
    check("page has vendor, data and app scripts", blocks is not None)
    data = json.loads(blocks[1])
    check("all nodes are in the page", len(data["nodes"]) == len(fixture["nodes"]))
    check("all links are in the page", len(data["links"]) == len(fixture["links"]))
    check("heavy fields are dropped", all("metadata" not in n and "norm_label" not in n for n in data["nodes"]))
    check("title reaches the page", data["__title"] == "demo" and "<title>demo - Graph view</title>" in page)
    check("no template placeholder is left", not re.search(r"/\*__|__TITLE_TEXT__", page))
    check("page makes no network request", not re.search(r"<script[^>]*src=|<link[^>]*href=|@import|fetch\(", page))
    check("page script is valid JavaScript", js_ok(blocks[0] + "\n" + blocks[2], tmp))

    print("== odd data")
    nasty = {"directed": True, "nodes": [
        {"id": 1, "label": "</script><script>alert(1)</script>"},
        {"id": "b", "label": "line sep & <b>bold</b>", "community": 3},
        {"id": "c", "label": "Plain"}],
        "edges": [{"source": 1, "target": "b", "relation": "calls"}, {"source": "b", "target": "ghost"}, {"source": "c", "target": "c"}]}
    page = build(tmp, nasty, "nasty", "a<b>&\"c")
    blocks = parts(page)
    check("markup in labels cannot close the script", blocks is not None and "</script><script>alert" not in page)
    check("title is escaped", "<title>a&lt;b&gt;&amp;&quot;c - Graph view</title>" in page)
    check("labels survive the round trip", blocks is not None and json.loads(blocks[1])["nodes"][0]["label"] == "</script><script>alert(1)</script>")
    check("'edges' key works as well as 'links'", blocks is not None and len(json.loads(blocks[1])["links"]) == 3)
    check("page script stays valid", blocks is not None and js_ok(blocks[0] + "\n" + blocks[2], tmp))

    print("== empty and broken input")
    page = build(tmp, {}, "empty")
    check("empty graph still builds", parts(page) is not None and json.loads(parts(page)[1])["nodes"] == [])
    bad = os.path.join(tmp, "bad.json")
    with open(bad, "w", encoding="utf-8") as f:
        f.write("{not json")
    check("broken json gives exit code 1", graph_view.main([bad, "-o", os.path.join(tmp, "x.html")]) == 1)
    check("missing file gives exit code 2", graph_view.main([os.path.join(tmp, "nope.json")]) == 2)

    print("== command line")
    proj = os.path.join(tmp, "my-project", "graphify-out")
    os.makedirs(proj)
    shutil.copy(FIXTURE, os.path.join(proj, "graph.json"))
    check("default output is graph.html next to graph.json", graph_view.main([os.path.join(proj, "graph.json")]) == 0 and os.path.isfile(os.path.join(proj, "graph.html")))
    with open(os.path.join(proj, "graph.html"), encoding="utf-8") as f:
        check("title defaults to the project folder", '"__title":"my-project"' in f.read())
finally:
    shutil.rmtree(tmp, ignore_errors=True)

print("")
print("%s" % ("all passed" if not failures else "%d failed" % len(failures)))
sys.exit(1 if failures else 0)
