# Project

[PROJECT DESCRIPTION].

This is the main instruction file for AI agents (Codex and others).

# Rules

Follow every file in `.agents/rules/`. Read them at the start of each task:

- `.agents/rules/plan-before-bigger-tasks.md`
- `.agents/rules/keep-it-simple.md`
- `.agents/rules/skills.md`
- `.agents/rules/git.md`
- `.agents/rules/check-work.md`
- `.agents/rules/plain-language.md`
- `.agents/rules/graphify.md`

# Docs

Read the doc a task needs before changing that area. Full map: `docs/README.md`.

- Architecture: `docs/architecture/overview.md`
- Data flow: `docs/architecture/data-flow.md`
- Decisions (ADRs): `docs/architecture/decisions/`. Do not undo a decision without a new ADR.
- API: `docs/api/README.md`, spec `docs/api/openapi.yaml` (source of truth)
- Database: `docs/database/schema.md`
- Guides: `docs/guides/` (setup, testing, deploy)
- Glossary: `docs/glossary.md`

When code changes behavior, update the matching doc in the same change.

# Structure

```text
[FOLDER 1]/        # [FOLDER 1 DESCRIPTION]
[FOLDER 2]/        # [FOLDER 2 DESCRIPTION]
.agents/rules/     # Rules agents follow (one topic per file)
.agents/skills/    # Project-only skills
docs/              # Architecture, API, database, guides
```

# Commands

```bash
# [GROUP 1, e.g. Dev]
[COMMAND]                      # [WHAT IT DOES]
[COMMAND]                      # [WHAT IT DOES]
[COMMAND]                      # [WHAT IT DOES]

# [GROUP 2, e.g. Test]
[COMMAND]                      # [WHAT IT DOES]
[COMMAND]                      # [WHAT IT DOES]
```

# Setup

[SETUP NOTES]

# Where things go

This file is an index, not a manual. Keep only what agents need in every session.

| Content | Location |
|---|---|
| Project summary, structure, main commands | This file |
| Rules (how to work) | `.agents/rules/<topic>.md`, listed above |
| Skills (reusable workflows) | Global; which to use: `.agents/rules/skills.md`. Project-only skills: `.agents/skills/<name>/SKILL.md` |
| Notes for one folder only | `<folder>/AGENTS.md` |
| Architecture, API, database, guides, decisions | `docs/`, listed in `docs/README.md` |

# Keeping this file small

- Hard limit: 200 lines. Nothing checks this automatically. Check with `wc -l AGENTS.md`.
- Before adding a line, ask: does every agent need this in every session? If not, put it in the table's other locations.
- New rule: add a file to `.agents/rules/` and list it under Rules.
- New folder with its own conventions: add an `AGENTS.md` inside that folder.
- Link to details instead of copying them.
- Delete lines that are outdated or no longer true.
