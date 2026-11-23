# Skills and plugins

- Use a skill only when it directly helps the task. Do not load one just because it is available.
- Shared skills and plugins are installed globally, not copied into this repo. Install steps: `docs/guides/setup.md`.
- Project skills: `.agents/skills/<name>/SKILL.md` for every agent (default; list it under "Project skills"), or `.claude/skills/<name>/SKILL.md` for Claude Code only (loaded automatically).
- Agents that do not load skills automatically (e.g. Codex): find the skill's `SKILL.md` in `~/.agents/skills/`, `~/.claude/skills/` or `~/.claude/plugins/` and follow it.
- No row below fits? Read the full table: `docs/guides/skills.md`.

## Project skills

Skills in `.agents/skills/`. None yet. Add a row for each new one. (Skills in `.claude/skills/` need no row.)

| Task | Skill file |
|---|---|

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
| Question about how the code works or how parts connect (needs a graph, see `graphify.md`) | `graphify` |
| Review a change | `ponytail:ponytail-review` |
| Design, redesign, or polish any UI | `impeccable` |
| UI choices: style, color, fonts, layout | `ui-ux-pro-max` |
| Commit message (only when the user asks to commit) | `caveman-commit` |
| Write or edit instruction or rule files | `mattpocock-skills:writing-for-agents` |

Cost and token skills (Caveman Cloud, `ponytail:ponytail-gain`): only when the user asks.
