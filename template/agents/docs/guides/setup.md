# Setup

Run the project locally.

1. [STEP 1]
2. [STEP 2]

## AI agent skills

This project uses global skills. They are not copied into the repo. Install them with `npx skills add` (needs Node.js). Pick your agent as the target when asked:

The kit installer can install or update the primary skills (Superpowers, Ponytail, Caveman) for you. It asks first (default No). To skip the question: `--skills yes|no`.

```bash
npx skills add obra/superpowers                         # brainstorming, writing-plans, systematic-debugging and more
npx skills add DietrichGebert/ponytail                  # ponytail, ponytail-review, ponytail-audit and more
npx skills add JuliusBrussee/caveman                    # caveman, caveman-commit, caveman-review and more
npx skills add mattpocock/skills                        # prototype, grilling, research and more
npx skills add pbakaus/impeccable                       # impeccable
npx skills add nextlevelbuilder/ui-ux-pro-max-skill     # ui-ux-pro-max
npx skills add Leonxlnx/taste-skill                     # design-taste-frontend (pick it from the list)
```

## Graphify (optional): a knowledge graph of the code

Graphify turns the codebase into a graph the AI can query. It then asks the graph instead of reading many files, which saves tokens on big projects. The rule `graphify.md` tells the AI how to use it, and does nothing until a graph exists. The kit installer offers both steps below and asks first (default No). This is the manual way.

```bash
uv tool install graphifyy        # or: pip install graphifyy   (the package name has two y)
graphify install                 # adds the graphify skill to your agent
```

- Build the graph once: `graphify update .` reads your code and needs no AI, so it costs no tokens. To add docs, papers or images, run `/graphify .` in Claude Code, or install the skill for another agent with `graphify install --platform <name>` (for example `codex`).
- Keep it current: run `graphify update .` after code changes, or `graphify hook install` to do it after every commit.
- Open `graphify-out/graph-view.html` in a browser for an interactive map of the code, like Obsidian's graph view. The kit installer builds it after the graph, and it keeps its own name: graphify owns `graph.html` and rewrites it on each update, so the kit view lives beside it and survives. Rebuild it any time with `agents-md-kit --graph-view` (PowerShell: `agents-md-kit -GraphView`).
- `graphify-out/` holds the graph, a report and an HTML view. Commit it to share the graph with your team, or add it to `.gitignore` to keep it local.
