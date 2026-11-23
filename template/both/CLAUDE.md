# Project

[PROJECT DESCRIPTION].

This is the main instruction file for all AI agents. Claude Code loads it automatically. Codex and other agents reach it through `AGENTS.md`.

# Rules

Follow every file in `.claude/rules/`. Claude Code loads them automatically. Other agents: read them at the start of each task:

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
.claude/rules/     # Rules all agents follow (one topic per file)
.claude/skills/    # Project-only skills for Claude Code only
.agents/skills/    # Project-only skills, shared by all agents
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
| Rules (how to work) | `.claude/rules/<topic>.md`, listed above |
| Skills (reusable workflows) | Global; which to use: `.claude/rules/skills-and-plugins.md`. Project-only skills: `.agents/skills/<name>/` (all agents) or `.claude/skills/<name>/` (Claude only) |
| Notes for one folder only | `<folder>/CLAUDE.md`, plus `<folder>/AGENTS.md` pointing to it |
| Architecture, API, database, guides, decisions | `docs/`, listed in `docs/README.md` |
| Claude Code hooks and settings | `.claude/settings.json` |
| Pointer for Codex and other agents | `AGENTS.md` (do not put content there) |

# Keeping this file small

- Hard limit: 200 lines for `AGENTS.md` and `CLAUDE.md`. Claude Code checks this after every edit (`.claude/hooks/check-claude-md.js`).
- Before adding a line, ask: does every agent need this in every session? If not, put it in the table's other locations.
- New rule: add a file to `.claude/rules/` and list it under Rules.
- New folder with its own conventions: add a `CLAUDE.md` inside that folder, and an `AGENTS.md` pointing to it.
- Link to details instead of copying them.
- Delete lines that are outdated or no longer true.
