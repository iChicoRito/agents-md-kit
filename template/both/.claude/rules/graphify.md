# Graphify

Graphify turns the codebase into a knowledge graph in `graphify-out/`. Asking the graph costs far fewer tokens than reading many files.

- If `graphify-out/graph.json` exists, ask the graph before you open or search files for a question about how the code works or how parts connect.
- Open a source file only for the exact lines the answer points to.

| Question | Command |
|---|---|
| How does X work? What is X connected to? | `graphify query "<question>"` |
| How does A reach B? | `graphify path "A" "B"` |
| What is X? | `graphify explain "X"` |
| What breaks if I change X? | `graphify affected "X"` |

- No match (exit code 4) or no `graphify` command: fall back to normal search.
- After you change code, run `graphify update .` (code only, no AI cost) to keep the graph current.
- No graph yet: use normal search. Ask the user before you build one (`graphify update .`, see `docs/guides/setup.md`).
