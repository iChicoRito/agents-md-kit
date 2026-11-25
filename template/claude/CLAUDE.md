# Project

[PROJECT DESCRIPTION].

This is the main instruction file. Claude Code loads it automatically.

# Rules

Follow every file in `.claude/rules/`. Claude Code loads them automatically:

- `.claude/rules/plan-before-bigger-tasks.md`
- `.claude/rules/keep-it-simple.md`
- `.claude/rules/skills-and-plugins.md`
- `.claude/rules/git.md`
- `.claude/rules/check-work.md`
- `.claude/rules/plain-language.md`
- `.claude/rules/graphify.md`

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
.claude/rules/     # Rules Claude follows (one topic per file)
.claude/skills/    # Project-only skills
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

This file is an index, not a manual. Keep only what Claude needs in every session.

| Content | Location |
|---|---|
| Project summary, structure, main commands | This file |
| Rules (how to work) | `.claude/rules/<topic>.md`, listed above |
| Skills (reusable workflows) | Global; which to use: `.claude/rules/skills-and-plugins.md`. Project-only skills: `.claude/skills/<name>/SKILL.md` |
| Notes for one folder only | `<folder>/CLAUDE.md` (loaded when Claude works there) |
| Architecture, API, database, guides, decisions | `docs/`, listed in `docs/README.md` |
| Claude Code hooks and settings | `.claude/settings.json` |

# Keeping this file small

- Hard limit: 200 lines. Claude Code checks this after every edit (`.claude/hooks/check-claude-md.js`).
- Before adding a line, ask: does Claude need this in every session? If not, put it in the table's other locations.
- New rule: add a file to `.claude/rules/` and list it under Rules.
- New folder with its own conventions: add a `CLAUDE.md` inside that folder.
- Link to details instead of copying them.
- Delete lines that are outdated or no longer true.
