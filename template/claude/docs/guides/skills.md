# Which skill for which task

The full list. The main rows are also in `.claude/rules/skills-and-plugins.md`, which loads every session. Read this file when no main row fits the task.

Plugins listed in `.claude/settings.json` (Superpowers, Ponytail, Caveman, mattpocock-skills, ux-ui-agent-skills, unslop-ui): Claude Code offers to install them when the project opens. The Caveman skills and the design skills (`impeccable`, `ui-ux-pro-max`, `design-taste-frontend`) must be installed by hand. See `setup.md`.

## Planning and building

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
| Question about how the code works or how parts connect (needs a graph, see `graphify.md`) | `graphify` |
| Throwaway prototype to test an idea or a UI | `mattpocock-skills:prototype` |
| Stress-test a plan with hard questions | `mattpocock-skills:grilling` |
| Research a topic from trusted sources into a Markdown file | `mattpocock-skills:research` |
| Project words, glossary, decision records | `mattpocock-skills:domain-modeling` |
| Design module boundaries, make code easier to test | `mattpocock-skills:codebase-design` |

## Bugs and checking

| Task | Skill |
|---|---|
| A bug, test failure, or unexpected behavior: find the cause before fixing | `superpowers:systematic-debugging` |
| Before saying work is done, fixed, or passing | `superpowers:verification-before-completion` |
| Work is done and tests pass: decide how to merge | `superpowers:finishing-a-development-branch` |

## Code review

| Task | Skill |
|---|---|
| Ask for a review after a task or before merging | `superpowers:requesting-code-review` |
| Respond to review feedback | `superpowers:receiving-code-review` |
| Review a change: logic, safety, load, tests, needless lines | `ponytail:ponytail-review` |
| Short review, one line per finding | `caveman-review` |
| Audit the whole repo: bugs, security, bloat | `ponytail:ponytail-audit` |
| List every `shortcut:` comment (technical debt) | `ponytail:ponytail-debt` |

## Frontend and UI/UX

| Task | Skill |
|---|---|
| Design, redesign, critique, audit, or polish any UI | `impeccable` |
| UI/UX choices: style, color, fonts, layout, accessibility, charts | `ui-ux-pro-max` |
| Websites and landing pages that must not look generic or AI-made | `design-taste-frontend` |
| Remove AI-looking copy and visual clutter from a UI (user runs it; needs `pstack`) | `/unslop-ui` |
| Harsh design review of a finished screen, after checks pass | agent `ux-ui-agent-skills:design-critic` |

## Writing and communication

| Task | Skill |
|---|---|
| Short, direct replies with all technical facts kept | `caveman` |
| Write a commit message (only when the user asks to commit) | `caveman-commit` |
| Shrink a long memory or instruction file | `caveman-compress` |
| Create or edit a skill | `superpowers:writing-skills` |
| Write or edit `CLAUDE.md` or rule files | `mattpocock-skills:writing-for-agents` |
| Write a pull request description | `mattpocock-skills:pr` |

## Help and reference

| Task | Skill |
|---|---|
| How to find and use skills | `superpowers:using-superpowers` |
| A Superpowers session went wrong: find out why | `superpowers:diagnosing-superpowers` |
| Quick reference for Ponytail or Caveman | `ponytail:ponytail-help`, `caveman-help` |

The Caveman Cloud skills (`caveman-setup`, `caveman-stats`, `caveman-discover`, `caveman-learn`, `caveman-manage`, `caveman-optimize`, `caveman-evidence-review`, `caveman-explore`, `cavecrew`) and `ponytail:ponytail-gain` are for measuring and cutting AI cost. Use them only when the user asks.
