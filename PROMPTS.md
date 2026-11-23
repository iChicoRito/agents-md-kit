# Fill-in prompts

After you install the kit in an **existing project**, copy the prompt for your version and paste it into your AI agent. The agent reads your code and fills the `[PLACEHOLDERS]` for you.

Not sure which version you installed?

- You have `CLAUDE.md` and **no** `AGENTS.md`: use [Claude Code only](#claude-code-only-claude).
- You have `AGENTS.md` and **no** `CLAUDE.md`: use [Codex or other agents](#codex-or-other-agents-agents).
- You have both files: use [Both](#both-both).

Tips:

- Use a strong model and plan mode if your agent has one. The agent reads a lot of code.
- Review what it wrote before you commit. Agents trust these files later, so wrong facts cause wrong work.
- Run the prompt again after big changes to the project. It updates the files.

## Claude Code only (`claude`)

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
9. Do not change any code. Do not commit.

When you finish, give me a short report: what you filled, what you merged, and every TODO left for me.
```

## Codex or other agents (`agents`)

```text
This project uses agents-md-kit (agents version). Fill in the kit's placeholders by reading the real codebase.

Files to fill:
- AGENTS.md: project description, folder structure, commands (dev, test, build, lint), setup notes.
- docs/architecture/overview.md and docs/architecture/data-flow.md
- docs/api/README.md and docs/api/openapi.yaml (only real endpoints)
- docs/database/schema.md
- docs/guides/setup.md, docs/guides/testing.md, docs/guides/deploy.md (keep the "AI agent skills" section in setup.md)
- docs/glossary.md

Rules:
1. First read AGENTS.md and every file in .agents/rules/, and follow them.
2. Read the code, config files (package.json, pyproject.toml, Dockerfile, CI files and similar) and any existing docs or README first. Do not guess.
3. Only write facts you found in the project. If something is unknown, write "TODO: <what is missing>". If a part does not exist (for example no database or no API), write "Not used in this project." in that doc.
4. Keep the existing sections and headings. Replace every [PLACEHOLDER] in the files above.
5. Do not fill docs/architecture/decisions/0000-template.md. It is a blank form. If you find important past decisions, add them as new files (0001-..., 0002-...) and list them in docs/architecture/decisions/README.md.
6. AGENTS.md must stay under 200 lines. It is an index: short facts and links. Put long details in docs/ and link to them. Check the length with wc -l AGENTS.md (nothing checks it automatically).
7. Do not copy rules from .agents/rules/ into AGENTS.md.
8. If the project already had its own instructions (an older AGENTS.md, README sections for developers, or similar), merge the useful parts: short facts into AGENTS.md, long details into docs/. Tell me what you merged.
9. If a folder has its own conventions, suggest a short <folder>/AGENTS.md, but ask me before creating it.
10. Do not change any code. Do not commit.

When you finish, give me a short report: what you filled, what you merged, and every TODO left for me.
```

## Both (`both`)

Paste this into Claude Code or Codex. Either agent can do it.

```text
This project uses agents-md-kit (both version: Claude Code and Codex). Fill in the kit's placeholders by reading the real codebase.

How the kit works here:
- CLAUDE.md is the main instruction file for every agent.
- AGENTS.md is only a pointer that tells Codex to read CLAUDE.md. Keep it that way.

Files to fill:
- CLAUDE.md: project description, folder structure, commands (dev, test, build, lint), setup notes.
- docs/architecture/overview.md and docs/architecture/data-flow.md
- docs/api/README.md and docs/api/openapi.yaml (only real endpoints)
- docs/database/schema.md
- docs/guides/setup.md, docs/guides/testing.md, docs/guides/deploy.md (keep the "AI agent skills" section in setup.md)
- docs/glossary.md

Rules:
1. First read CLAUDE.md and every file in .claude/rules/, and follow them.
2. Read the code, config files (package.json, pyproject.toml, Dockerfile, CI files and similar) and any existing docs or README first. Do not guess.
3. Only write facts you found in the project. If something is unknown, write "TODO: <what is missing>". If a part does not exist (for example no database or no API), write "Not used in this project." in that doc.
4. Keep the existing sections and headings. Replace every [PLACEHOLDER] in the files above.
5. Do not fill docs/architecture/decisions/0000-template.md. It is a blank form. If you find important past decisions, add them as new files (0001-..., 0002-...) and list them in docs/architecture/decisions/README.md.
6. CLAUDE.md must stay under 200 lines. It is an index: short facts and links. Put long details in docs/ and link to them.
7. Do not copy rules from .claude/rules/ into CLAUDE.md.
8. If the project already had its own instructions (an older CLAUDE.md, an older AGENTS.md with real content, CLAUDE.local.md, README sections for developers, or similar), merge the useful parts: short facts into CLAUDE.md, long details into docs/. Then make AGENTS.md the short pointer to CLAUDE.md again. Tell me what you merged.
9. If a folder has its own conventions, suggest a short <folder>/CLAUDE.md plus a <folder>/AGENTS.md that points to it, but ask me before creating them.
10. Do not change any code. Do not commit.

When you finish, give me a short report: what you filled, what you merged, and every TODO left for me.
```

## Starting a brand-new project?

There is little code to read yet. Fill the placeholders as you build, or ask your agent after the first features exist:

```text
Read the code we have so far and fill the [PLACEHOLDERS] in the main instruction file (CLAUDE.md or AGENTS.md) and docs/. Only write facts you find. Mark the rest "TODO". Keep the main file under 200 lines. Do not fill docs/architecture/decisions/0000-template.md.
```
