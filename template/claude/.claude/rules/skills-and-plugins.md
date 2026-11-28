# Skills and plugins

- Use a skill only when it directly helps the task. Do not load one just because it is available.
- Shared skills and plugins are installed globally, not copied into this repo. Install steps: `docs/guides/setup.md`.
- Project skills: `.claude/skills/<name>/SKILL.md`. Claude Code loads them automatically.
- No row below fits? Read the full table: `docs/guides/skills.md`.

## Main skills

| Task | Skill |
|---|---|
| New feature or creative work: explore the idea first | `superpowers:brainstorming` |
| Turn a spec or idea into a plan | `superpowers:writing-plans` |
| Carry out a written plan | `superpowers:executing-plans` |
| Write tests before the code | `superpowers:test-driven-development` |
| Bug or test failure: find the cause before fixing | `superpowers:systematic-debugging` |
| Before saying work is done or fixed | `superpowers:verification-before-completion` |
| Any coding task: smallest change that fully solves it | `ponytail:ponytail` |
| Review a change | `ponytail:ponytail-review` |
| Question about how the code works or how parts connect (needs a graph, see `graphify.md`) | `graphify` |
| Design, redesign, or polish any UI | `impeccable` |
| UI choices: style, color, fonts, layout | `ui-ux-pro-max` |
| Clean up AI-looking UI (purple gradients, glows, emoji labels, uneven spacing) | `unslop` |
| Commit message (only when the user asks to commit) | `caveman-commit` |
| Write or edit instruction or rule files | `mattpocock-skills:writing-for-agents` |

Cost and token skills (Caveman Cloud, `ponytail:ponytail-gain`): only when the user asks.
