# Which skill for which task

The full list. The main rows are also in `.agents/rules/skills.md`, which loads every session. Read this file when no main row fits the task.

## Planning and building

| Task | Skill |
|---|---|
| New feature, new behavior, or any creative work: explore the idea first | `brainstorming` |
| Turn a spec or idea into a step-by-step plan | `writing-plans` |
| Carry out a written plan yourself | `executing-plans` |
| Carry out a plan with independent tasks, using subagents | `subagent-driven-development` |
| Two or more independent tasks at once | `dispatching-parallel-agents` |
| Feature work that needs an isolated branch | `using-git-worktrees` |
| Write tests before the code (features and bug fixes) | `test-driven-development` |
| Any coding task: smallest change that fully solves it | `ponytail` |
| Throwaway prototype to test an idea or a UI | `prototype` |
| Stress-test a plan with hard questions | `grilling` |
| Research a topic from trusted sources into a Markdown file | `research` |
| Project words, glossary, decision records | `domain-modeling` |
| Design module boundaries, make code easier to test | `codebase-design` |

## Bugs and checking

| Task | Skill |
|---|---|
| A bug, test failure, or unexpected behavior: find the cause before fixing | `systematic-debugging` |
| Before saying work is done, fixed, or passing | `verification-before-completion` |
| Work is done and tests pass: decide how to merge | `finishing-a-development-branch` |

## Code review

| Task | Skill |
|---|---|
| Ask for a review after a task or before merging | `requesting-code-review` |
| Respond to review feedback | `receiving-code-review` |
| Review a change: logic, safety, load, tests, needless lines | `ponytail-review` |
| Question about how the code works or how parts connect (needs a graph, see `graphify.md`) | `graphify` |
| Short review, one line per finding | `caveman-review` |
| Audit the whole repo: bugs, security, bloat | `ponytail-audit` |
| List every `shortcut:` comment (technical debt) | `ponytail-debt` |

## Frontend and UI/UX

| Task | Skill |
|---|---|
| Design, redesign, critique, audit, or polish any UI | `impeccable` |
| UI/UX choices: style, color, fonts, layout, accessibility, charts | `ui-ux-pro-max` |
| Websites and landing pages that must not look generic or AI-made | `design-taste-frontend` |

## Writing and communication

| Task | Skill |
|---|---|
| Short, direct replies with all technical facts kept | `caveman` |
| Write a commit message (only when the user asks to commit) | `caveman-commit` |
| Shrink a long memory or instruction file | `caveman-compress` |
| Create or edit a skill | `writing-skills` |
| Write or edit `AGENTS.md` or rule files | `writing-for-agents` |
| Write a pull request description | `pr` |

## Help and reference

| Task | Skill |
|---|---|
| How to find and use skills | `using-superpowers` |
| A Superpowers session went wrong: find out why | `diagnosing-superpowers` |
| Quick reference for Ponytail or Caveman | `ponytail-help`, `caveman-help` |

The Caveman Cloud skills (`caveman-setup`, `caveman-stats`, `caveman-discover`, `caveman-learn`, `caveman-manage`, `caveman-optimize`, `caveman-evidence-review`, `caveman-explore`, `cavecrew`) and `ponytail-gain` are for measuring and cutting AI cost. Use them only when the user asks.
