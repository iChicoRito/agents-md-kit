# Fill-in prompt (agents-md-kit)

This project has the agents-md-kit setup. `CLAUDE.md` and `docs/` still contain `[PLACEHOLDERS]`. This prompt makes your AI fill them by reading your code.

## How to use

Open Claude Code in this project and send **one** of these:

- Short: `Read PROMPT.md and do what it says.`
- Or copy the whole prompt below and paste it.

New project? Run it after your first features exist. Until then most entries stay `TODO`.

Then review what it wrote before you commit. When you are done, delete this file, or keep it to run again after big changes.

## Prompt

```text
This project uses agents-md-kit (Claude Code version). Fill in the kit's placeholders by reading the real codebase.

Files to fill:
- CLAUDE.md: project description, folder structure, commands (dev, test, build, lint), setup notes.
- docs/architecture/overview.md and docs/architecture/data-flow.md
- docs/api/README.md and docs/api/openapi.yaml (only real endpoints)
- docs/database/schema.md
- docs/guides/setup.md, docs/guides/testing.md, docs/guides/deploy.md (keep the "AI agent skills" section in setup.md)
- docs/glossary.md

Rules:
1. Read the code, config files (package.json, pyproject.toml, Dockerfile, CI files and similar) and any existing docs or README first. Do not guess.
2. Only write facts you found in the project. If something is unknown, write "TODO: <what is missing>". If a part does not exist (for example no database or no API), write "Not used in this project." in that doc.
3. Keep the existing sections and headings. Replace every [PLACEHOLDER] in the files above.
4. Do not fill docs/architecture/decisions/0000-template.md. It is a blank form. If you find important past decisions, add them as new files (0001-..., 0002-...) and list them in docs/architecture/decisions/README.md.
5. CLAUDE.md must stay under 200 lines. It is an index: short facts and links. Put long details in docs/ and link to them.
6. Do not copy rules from .claude/rules/ into CLAUDE.md.
7. If the project already had its own instructions (an older CLAUDE.md, CLAUDE.local.md, README sections for developers, or similar), merge the useful parts: short facts into CLAUDE.md, long details into docs/. Tell me what you merged.
8. If a folder has its own conventions, suggest a short <folder>/CLAUDE.md, but ask me before creating it.
9. Do not change any code. Do not commit. Do not edit PROMPT.md.

When you finish, give me a short report: what you filled, what you merged, and every TODO left for me.
```
