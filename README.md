# agents-md-kit

A small, scalable instruction setup for AI coding agents. One command adds it to any project. Pick the version for the agents you use: Claude Code, Codex (and other agents), or both.

- One main instruction file, kept under 200 lines.
- Working rules, one topic per file.
- `docs/` for architecture, API, database and guides. Agents open these only when a task needs them.

New here? Read the **[guide](GUIDE.md)**: what every file does, and how to use the kit on a new or existing project.

## Pick your version

| Version | For | Main file | Folder |
|---|---|---|---|
| `claude` | Claude Code only | `CLAUDE.md` | `.claude/` |
| `agents` | Codex and other agents only | `AGENTS.md` | `.agents/` |
| `both` | Claude Code and Codex in the same project | `CLAUDE.md`, with `AGENTS.md` pointing to it | `.claude/` and `.agents/` |

The installer asks which one you want. If it cannot ask (for example in a script), it installs `both`.

## Install

Open a terminal **in your project folder** and run one command. It asks which version you want.

**Windows (PowerShell)**

```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/iChicoRito/agents-md-kit/main/install.ps1)))
```

**Mac, Linux, Git Bash**

```bash
curl -fsSL https://raw.githubusercontent.com/iChicoRito/agents-md-kit/main/install.sh | bash
```

**Skip the question** by naming the version (`claude`, `agents` or `both`):

```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/iChicoRito/agents-md-kit/main/install.ps1))) -For claude
```

```bash
curl -fsSL https://raw.githubusercontent.com/iChicoRito/agents-md-kit/main/install.sh | bash -s -- --for claude
```

**Install into another folder** by adding the path at the end:

```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/iChicoRito/agents-md-kit/main/install.ps1))) -For both "C:\path\to\project"
```

```bash
curl -fsSL https://raw.githubusercontent.com/iChicoRito/agents-md-kit/main/install.sh | bash -s -- --for both "path/to/project"
```

No git needed. The installer downloads the template and copies it in.

**Safe for existing projects**

- It never overwrites a file. Files that already exist are skipped and listed, so you can merge them by hand.
- It keeps an existing `.gitignore` and adds only the missing lines at the end.
- Running it again changes nothing.

## What you get

**`claude`: Claude Code only**

```text
CLAUDE.md          main instructions
.gitignore         keeps personal Claude files out of git
.claude/
  rules/           how Claude should work (loaded automatically)
  skills/          skills made only for this project (loaded automatically)
  hooks/           line-limit check
  settings.json    plugins, hook, no AI author lines on commits
docs/              architecture, API, database, guides, decisions
```

**`agents`: Codex and other agents only**

```text
AGENTS.md          main instructions
.agents/
  rules/           how agents should work (AGENTS.md lists them)
  skills/          skills made only for this project
docs/              architecture, API, database, guides, decisions
```

**`both`: Claude Code and Codex**

```text
CLAUDE.md          main instructions (all agents)
AGENTS.md          pointer: tells Codex to read CLAUDE.md
.gitignore         keeps personal Claude files out of git
.claude/
  rules/           how agents should work
  skills/          skills for Claude Code only
  hooks/           line-limit check
  settings.json    plugins, hook, no AI author lines on commits
.agents/
  skills/          skills made only for this project (all agents)
docs/              architecture, API, database, guides, decisions
```

## Requirements

- Claude Code, Codex, or both.
- Node.js, for `npx skills add` (and for the line-limit hook in Claude Code).
- Skills. See `docs/guides/setup.md` after install:
  - `claude` and `both`: six plugins (Superpowers, Ponytail, Caveman, mattpocock-skills, ux-ui-agent-skills, unslop-ui) install when you open the project in Claude Code. The Caveman skills and design skills are installed by hand with `npx skills add`.
  - `agents`: all skills are installed with `npx skills add`.

## After install

1. Fill the `[PLACEHOLDERS]` in the main file (`CLAUDE.md`, or `AGENTS.md` for the `agents` version) and in `docs/`. You can ask your agent:
   > Fill in the [PLACEHOLDERS] in CLAUDE.md by reading the codebase. Keep the sections and stay under 200 lines. Put architecture, API and database details in docs/.
2. In Claude Code, run `/memory` and `/skills` to check what loads.

Using it on an existing project? See [GUIDE.md](GUIDE.md#use-it-on-an-existing-project) for how to merge.

## Optional: short command

Add an `agents-md-kit` command so you can type one word in any project. Options pass through, for example `agents-md-kit --for claude`.

PowerShell (run `notepad $PROFILE` and add):

```powershell
function agents-md-kit { & ([scriptblock]::Create((irm https://raw.githubusercontent.com/iChicoRito/agents-md-kit/main/install.ps1))) @args }
```

Bash (add to `~/.bashrc`):

```bash
agents-md-kit() { curl -fsSL https://raw.githubusercontent.com/iChicoRito/agents-md-kit/main/install.sh | bash -s -- "$@"; }
```

PowerShell uses `-For claude`; Bash uses `--for claude`.
