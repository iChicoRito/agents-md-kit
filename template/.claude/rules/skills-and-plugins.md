# Skills and plugins

- Use a skill or plugin only when it directly helps the current task. Do not load one just because it is available.
- For general work, use the primary skills: Superpowers, Ponytail, and Caveman.
- For frontend or UI/UX work, use the design skills below. Install others only if they fit the task.
- Skills are installed globally, not copied into this repo. `.claude/skills/` holds only skills made for this project.
- `superpowers:*`, `ponytail:*` and Caveman come from plugins listed in `.claude/settings.json`. Claude Code offers to install them when the project opens.
- `impeccable`, `ui-ux-pro-max`, `design-taste-frontend` and `unslop-ui` must be installed by hand. See `docs/guides/setup.md`.
- Agents that do not load skills automatically (e.g. Codex): find the skill's `SKILL.md` in `~/.claude/skills/` or `~/.claude/plugins/` and follow it.

## Which skill for which task

### Planning and building

| Task | Skill |
|---|---|
| New feature, new behavior, or any creative work: explore the idea first | `superpowers:brainstorming` |
| Turn a spec or idea into a step-by-step plan | `superpowers:writing-plans` |
| Carry out a written plan yourself | `superpowers:executing-plans` |
| Carry out a plan with independent tasks, using subagents | `superpowers:subagent-driven-development` |
| Two or more independent tasks at once | `superpowers:dispatching-parallel-agents` |
| Feature work that needs an isolated branch | `superpowers:using-git-worktrees` |
| Write tests before the code (features and bug fixes) | `superpowers:test-driven-development` |
| Any coding task: smallest change that fully solves it | `ponytail:ponytail` |

### Bugs and checking

| Task | Skill |
|---|---|
| A bug, test failure, or unexpected behavior: find the cause before fixing | `superpowers:systematic-debugging` |
| Before saying work is done, fixed, or passing | `superpowers:verification-before-completion` |
| Work is done and tests pass: decide how to merge | `superpowers:finishing-a-development-branch` |

### Code review

| Task | Skill |
|---|---|
| Ask for a review after a task or before merging | `superpowers:requesting-code-review` |
| Respond to review feedback | `superpowers:receiving-code-review` |
| Review a change: logic, safety, load, tests, needless lines | `ponytail:ponytail-review` |
| Short review, one line per finding | `caveman-review` |
| Audit the whole repo: bugs, security, bloat | `ponytail:ponytail-audit` |
| List every `shortcut:` comment (technical debt) | `ponytail:ponytail-debt` |

### Frontend and UI/UX

| Task | Skill |
|---|---|
| Design, redesign, critique, audit, or polish any UI | `impeccable` |
| UI/UX choices: style, color, fonts, layout, accessibility, charts | `ui-ux-pro-max` |
| Websites and landing pages that must not look generic or AI-made | `design-taste-frontend` |
| Remove AI-looking copy and visual clutter from a UI (plugin `unslop-ui`, not enabled; needs `pstack`) | `unslop-ui` |

### Writing and communication

| Task | Skill |
|---|---|
| Short, direct replies with all technical facts kept | `caveman` |
| Write a commit message (only when the user asks to commit) | `caveman-commit` |
| Shrink a long memory or instruction file | `caveman-compress` |
| Create or edit a skill | `superpowers:writing-skills` |

### Help and reference

| Task | Skill |
|---|---|
| How to find and use skills | `superpowers:using-superpowers` |
| A Superpowers session went wrong: find out why | `superpowers:diagnosing-superpowers` |
| Quick reference for Ponytail or Caveman | `ponytail:ponytail-help`, `caveman-help` |

The Caveman Cloud skills (`caveman-setup`, `caveman-stats`, `caveman-discover`, `caveman-learn`, `caveman-manage`, `caveman-optimize`, `caveman-evidence-review`, `caveman-explore`, `cavecrew`) and `ponytail:ponytail-gain` are for measuring and cutting AI cost. Use them only when the user asks.
