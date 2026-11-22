# agents-md-kit

A small, scalable instruction setup for AI coding agents (Claude Code and Codex). One command adds it to any project.

- `CLAUDE.md` is the main instruction file, kept under 200 lines.
- `AGENTS.md` points Codex and other agents to `CLAUDE.md`, so every agent follows the same rules.
- `.claude/rules/` holds the working rules, one topic per file.
- `docs/` holds architecture, API, database and guides. Agents open these only when a task needs them.
- A hook warns Claude Code when `CLAUDE.md` or `AGENTS.md` goes over 200 lines.

New here? Read the **[guide](GUIDE.md)**: what every file does, and how to use the kit on a new or existing project.

## Install

Open a terminal **in your project folder** and run one command.

**Windows (PowerShell)**

```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/iChicoRito/agents-md-kit/main/install.ps1)))
```

**Mac, Linux, Git Bash**

```bash
curl -fsSL https://raw.githubusercontent.com/iChicoRito/agents-md-kit/main/install.sh | bash
```

To install into another folder, add the path at the end:

```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/iChicoRito/agents-md-kit/main/install.ps1))) "C:\path\to\project"
```

```bash
curl -fsSL https://raw.githubusercontent.com/iChicoRito/agents-md-kit/main/install.sh | bash -s -- "path/to/project"
```

No git needed. The installer downloads the template and copies it in.

**Safe for existing projects**

- It never overwrites a file. Files that already exist are skipped and listed, so you can merge them by hand.
- It keeps an existing `.gitignore` and adds only the missing lines at the end.
- Running it again changes nothing.

## What you get

```text
CLAUDE.md          main instructions (all agents)
AGENTS.md          pointer for Codex and other agents
.gitignore         keeps personal Claude files out of git
.claude/
  rules/           how agents should work
  skills/          skills made only for this project
  hooks/           line-limit check
  settings.json    plugins, hook, no AI author lines on commits
docs/              architecture, API, database, guides, decisions
```

## Requirements

- [Claude Code](https://claude.com/claude-code) and/or Codex.
- Node.js, for the line-limit hook and the design skills.
- Skills: Superpowers, Ponytail and Caveman install as plugins when you open the project in Claude Code. The design skills are installed by hand. See `docs/guides/setup.md` after install.

## After install

1. Fill the `[PLACEHOLDERS]` in `CLAUDE.md` and `docs/`. You can ask Claude:
   > Fill in the [PLACEHOLDERS] in CLAUDE.md by reading the codebase. Keep the sections and stay under 200 lines. Put architecture, API and database details in docs/.
2. In Claude Code, run `/memory` and `/skills` to check what loads.

Using it on an existing project? See [GUIDE.md](GUIDE.md#use-it-on-an-existing-project) for how to merge.

## Optional: short command

Add an `agents-md-kit` command so you can type one word in any project.

PowerShell (run `notepad $PROFILE` and add):

```powershell
function agents-md-kit { & ([scriptblock]::Create((irm https://raw.githubusercontent.com/iChicoRito/agents-md-kit/main/install.ps1))) @args }
```

Bash (add to `~/.bashrc`):

```bash
agents-md-kit() { curl -fsSL https://raw.githubusercontent.com/iChicoRito/agents-md-kit/main/install.sh | bash -s -- "$@"; }
```
