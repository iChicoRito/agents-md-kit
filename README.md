# agents-md-kit

[![test](https://github.com/iChicoRito/agents-md-kit/actions/workflows/test.yml/badge.svg)](https://github.com/iChicoRito/agents-md-kit/actions/workflows/test.yml) [![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

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

The installer asks two questions:

1. **Which agents?** Claude Code, Codex / other agents, or both.
2. **New or existing project?** It suggests the answer from your folder (empty folder = new).
   - **Existing:** it adds `PROMPT.md`, a ready prompt that makes your AI fill the placeholders from your code.
   - **New:** it asks if you want `PROMPT.md` for later (default: no). You fill the files as you build.

If it cannot ask (for example in a script), it uses `both` and detects new or existing from the folder.

## Install

Open a terminal **in your project folder** and run one command. It asks which version you want.

Pick each answer with the arrow keys and Enter (or press its number). Terminals without arrow-key support get numbered questions to type instead.

**Windows (PowerShell)**

```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/iChicoRito/agents-md-kit/main/install.ps1)))
```

**Mac, Linux, Git Bash**

```bash
curl -fsSL https://raw.githubusercontent.com/iChicoRito/agents-md-kit/main/install.sh | bash
```

**Skip the questions** with options: `--for claude|agents|both`, `--project new|existing`, `--prompt yes|no` (PowerShell: `-For`, `-Project`, `-Prompt`):

```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/iChicoRito/agents-md-kit/main/install.ps1))) -For claude -Project existing
```

```bash
curl -fsSL https://raw.githubusercontent.com/iChicoRito/agents-md-kit/main/install.sh | bash -s -- --for claude --project existing
```

**Install into another folder** by adding the path at the end:

```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/iChicoRito/agents-md-kit/main/install.ps1))) -For both "C:\path\to\project"
```

```bash
curl -fsSL https://raw.githubusercontent.com/iChicoRito/agents-md-kit/main/install.sh | bash -s -- --for both "path/to/project"
```

No git needed. The installer downloads the template and copies it in.

See all options: add `--help` (Bash) or `-Help` (PowerShell) to the command.

Prefer typed answers? Set `AGENTS_MD_KIT_UI=plain` before running. `NO_COLOR=1` turns colors off.

**Safe for existing projects**

- It never overwrites a file. Files that already exist are skipped and listed, so you can merge them by hand.
- It keeps an existing `.gitignore` and adds only the missing lines at the end.
- Running it again changes nothing.

**Update a project that already has the kit**

Add `--update` (Bash) or `-Update` (PowerShell) to the install command:

```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/iChicoRito/agents-md-kit/main/install.ps1))) -Update
```

```bash
curl -fsSL https://raw.githubusercontent.com/iChicoRito/agents-md-kit/main/install.sh | bash -s -- --update
```

- Kit files you deleted are added back.
- A kit file that changed (in the kit or by you) is not touched. The newer kit version is saved next to it as `<file>.kit-new`, for example `CLAUDE.md.kit-new`.
- Merge what you want from each `.kit-new` file, then delete it. Or tell your AI: *Merge every \*.kit-new file into the file next to it. Keep my project details. Then delete the .kit-new files.*
- `*.kit-new` is in the kit's `.gitignore`, so these files are not committed by mistake.

**Install a fixed version**

Each install records its kit version in a small `.agents-md-kit` file, and the installer shows the version in its welcome box. To install a released version instead of the latest, add `--version` (Bash) or `-Version` (PowerShell):

```bash
curl -fsSL https://raw.githubusercontent.com/iChicoRito/agents-md-kit/main/install.sh | bash -s -- --version 1.0.0
```

```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/iChicoRito/agents-md-kit/main/install.ps1))) -Version 1.0.0
```

All versions and what changed: [Releases](https://github.com/iChicoRito/agents-md-kit/releases) and [CHANGELOG.md](CHANGELOG.md).

## What you get

**`claude`: Claude Code only**

```text
CLAUDE.md          main instructions
PROMPT.md          prompt that makes your AI fill the placeholders (existing projects, or new if you choose)
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
PROMPT.md          prompt that makes your AI fill the placeholders (existing projects, or new if you choose)
.agents/
  rules/           how agents should work (AGENTS.md lists them)
  skills/          skills made only for this project
docs/              architecture, API, database, guides, decisions
```

**`both`: Claude Code and Codex**

```text
CLAUDE.md          main instructions (all agents)
AGENTS.md          pointer: tells Codex to read CLAUDE.md
PROMPT.md          prompt that makes your AI fill the placeholders (existing projects, or new if you choose)
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
- Node.js, for `npx skills add`. The line-limit hook in Claude Code also uses it, and is skipped quietly without it.
- Skills. See `docs/guides/setup.md` after install:
  - `claude` and `both`: six plugins (Superpowers, Ponytail, Caveman, mattpocock-skills, ux-ui-agent-skills, unslop-ui) install when you open the project in Claude Code. The Caveman skills and design skills are installed by hand with `npx skills add`.
  - `agents`: all skills are installed with `npx skills add`.

## After install

1. Fill the `[PLACEHOLDERS]` in the main file (`CLAUDE.md`, or `AGENTS.md` for the `agents` version) and in `docs/`. For an existing project (or a new one where you chose it), the installer adds `PROMPT.md` with the ready prompt for your version. Tell your AI agent:
   > Read PROMPT.md and do what it says.

   It reads your code and fills everything in. The same prompts are online in [PROMPTS.md](PROMPTS.md):
   - [Claude Code only](PROMPTS.md#claude-code-only-claude)
   - [Codex or other agents](PROMPTS.md#codex-or-other-agents-agents)
   - [Both](PROMPTS.md#both-both)
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

## License

MIT. See [LICENSE](LICENSE). Use it, change it and share it freely.
