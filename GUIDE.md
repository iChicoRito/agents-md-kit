# agents-md-kit guide

What every file does, and how to use the kit on a new or existing project.

## The idea

AI agents need instructions about your project. If everything is in one huge file, the agent reads all of it every time. That is slow and costly.

This kit uses a small "front page" that the agent always reads, plus separate files that it opens only when a task needs them. The project can grow big, and the agent still reads very little every session.

## Pick your version

The installer asks which agents you use and installs one of three versions:

| Version | Use it when | What is different |
|---|---|---|
| `claude` | You only use Claude Code | No `AGENTS.md`, no `.agents/`. Everything lives in `CLAUDE.md` and `.claude/`. |
| `agents` | You only use Codex or other agents | No `CLAUDE.md`, no `.claude/`. `AGENTS.md` is the main file, rules live in `.agents/rules/`. No line-limit hook and no plugin settings (those are Claude Code features). Skills are installed with `npx skills add`. |
| `both` | You use Claude Code and Codex together | `CLAUDE.md` is the main file. `AGENTS.md` points Codex to it. Both `.claude/` and `.agents/`. |

Not sure? Pick `both`. It works for every agent.

The file list below describes the `both` version. The other two versions have a subset of these files, as the table says.

## What each file does

### Files at the top of the project

**`CLAUDE.md`: the main instructions**
The most important file. It tells the AI what the project is, how the folders are laid out, which commands to run, and where to find more information. Claude Code reads it at the start of every session. It is a list of links, not a full manual. It must stay under 200 lines.

**`AGENTS.md`: a signpost for other AI tools**
Codex and some other AI tools look for `AGENTS.md`, not `CLAUDE.md`. This file only says "read `CLAUDE.md` and follow it". Every AI follows the same instructions, and you keep only one file up to date. Do not put project details here.

**`PROMPT.md`: the fill-in prompt**
Added for existing projects. For new projects the installer asks (default: no). A ready prompt for your version. Tell your AI `Read PROMPT.md and do what it says.` and it fills the `[PLACEHOLDERS]` from your code. Delete it when you are done, or keep it to run again after big changes. Agents do not load it on their own.

**`.gitignore`: files git leaves out**
It keeps two personal files out of git:
- `.claude/settings.local.json`: your own Claude settings
- `CLAUDE.local.md`: your own private notes for Claude

These stay on your computer and are never shared.

### The `.claude/` folder: AI settings and rules

**`.claude/settings.json`: Claude Code settings**
It does three things:
1. Stops Claude from adding its name to your commits.
2. Lists six plugins: Superpowers, Ponytail, Caveman, mattpocock-skills, ux-ui-agent-skills and unslop-ui. Anyone who opens the project in Claude Code is offered an install.
3. Turns on the line checker below.

**`.claude/hooks/check-claude-md.js`: the line checker**
A small program that runs after Claude edits a file. If `CLAUDE.md` or `AGENTS.md` goes over 200 lines, it warns Claude to move details elsewhere. It needs Node.js.

**`.claude/rules/`: how the AI must work**
Six short rule files. Claude Code reads all of them every session. `CLAUDE.md` lists them for other agents.

| File | What it tells the AI |
|---|---|
| `plan-before-bigger-tasks.md` | For anything bigger than a small fix: understand the goal, write a short plan, then build. |
| `keep-it-simple.md` | Do only what was asked. Make the smallest change that works. Do not touch unrelated code. |
| `skills-and-plugins.md` | Which skill to use for which job (debugging, reviews, design and more), and where skills come from. |
| `git.md` | Never commit unless you ask. No AI names in commit messages. |
| `check-work.md` | Check the work before finishing. Say clearly what was not checked. |
| `plain-language.md` | Use simple words and short explanations. |

**`.claude/skills/`: project skills for Claude Code only**
It starts empty, with only a `.gitkeep` (an empty file that makes git keep the folder). Claude Code loads skills here automatically. Other agents do not see them. Use it for a skill only Claude needs.

### The `.agents/` folder: project skills for every agent

**`.agents/skills/`: skills made for this project**
It starts empty. Its only file is `.gitkeep`, an empty file that makes git keep the folder. The skills you use (Superpowers, design skills and more) are installed on your computer, not here. Put a skill here only if it is specific to this project, for example "how to deploy this app". Each skill gets its own folder with a `SKILL.md`.

`.agents/` is a shared folder name that Codex and other agents use. Writing the skill here means you write it once for every agent. This is the default place for a project skill. When you add one, also add a row under "Project skills" in `.claude/rules/skills-and-plugins.md`, so Claude Code knows it exists and when to use it.

### The `docs/` folder: knowledge about your system

The AI does not read these every session. It opens one when a task needs it, so they can grow big without slowing anything down. People can read them too.

| File | What it is for |
|---|---|
| `docs/README.md` | The map. One line per document. Add a line when you add a doc. |
| `docs/architecture/overview.md` | The big picture: the main parts of the system and how they connect. |
| `docs/architecture/data-flow.md` | How a request moves through the system, step by step. |
| `docs/architecture/decisions/README.md` | A list of important decisions the team made. |
| `docs/architecture/decisions/0000-template.md` | A form for a new decision: what you decided and why. Copy it for each new one. This stops the AI from "fixing" things that were done on purpose. |
| `docs/api/README.md` | API rules: login method, error format, versions. |
| `docs/api/openapi.yaml` | The exact list of API endpoints. Tools can read it. It is the official source. Starts empty. |
| `docs/database/schema.md` | Your tables, how they relate, and rules for changing them. |
| `docs/guides/setup.md` | How to run the project locally, and how to install the AI skills. |
| `docs/guides/testing.md` | How to run and write tests. |
| `docs/guides/deploy.md` | How to release the project. |
| `docs/glossary.md` | Words specific to your project and what they mean. |

Most of these start as forms with `[PLACEHOLDERS]` to fill in.

## What the AI reads, and when

| Every session | Only when a task needs it |
|---|---|
| `CLAUDE.md` | Any file in `docs/` |
| The 6 rule files | A skill's full instructions |
| The list of skill names | |

## Use it on a new project

In the steps below, "main file" means `CLAUDE.md` (`claude` and `both` versions) or `AGENTS.md` (`agents` version).

1. **Create your project folder** and open a terminal in it.
2. **Run the install command** (see [README](README.md#install)). Pick your version, then **New project**. Say yes to `PROMPT.md` if you want your AI to fill the files later.
3. **Install the skills.** Open the project in Claude Code and accept the plugin install offer. Then run the four `npx skills add` commands in `docs/guides/setup.md` for the Caveman skills and the design skills.
4. **Fill in the basics** in `CLAUDE.md`: project description, folders, commands. If you have no code yet, fill these in as you build.
5. **Fill in `docs/` as you build.** When you design the database, write `docs/database/schema.md`. When you make a big decision, write a decision file.
6. **Check it loads.** In Claude Code, type `/memory` (instruction files) and `/skills` (skills).

## Use it on an existing project

1. **Open a terminal in the project folder**, run the same install command, pick your version, then **Existing project** (it adds `PROMPT.md`). It is safe:
   - It never overwrites a file you already have.
   - It lists the files it skipped.
   - It keeps your `.gitignore` and adds only the missing lines.
2. **Look at the skipped files.** If your project already had a `CLAUDE.md` or `AGENTS.md`, the kit did not touch it. Merge by hand:
   - Move your existing instructions into the kit's `CLAUDE.md` layout. Keep only short, every-session information.
   - Move long details (architecture, API notes) into the right `docs/` file.
   - Make `AGENTS.md` the short signpost to `CLAUDE.md`.
3. **Let the AI fill in the placeholders.** It can read your code. Tell your agent `Read PROMPT.md and do what it says.` (or copy the prompt from [PROMPTS.md](PROMPTS.md)). The prompt also merges your old instructions and lists every TODO it could not fill.
4. **Fill in `docs/` one area at a time.** For example:
   > Read the API code and fill in docs/api/README.md and docs/api/openapi.yaml.

   > Read the database models and fill in docs/database/schema.md.
5. **Review what the AI wrote.** Fix anything wrong. The AI will trust these files later.
6. **Add folder notes if needed.** If a folder like `backend/` has its own rules, add a small `backend/CLAUDE.md` plus an `AGENTS.md` that points to it.
7. **Install the skills** and **check it loads** (`/memory`, `/skills`), as for a new project.
8. **Commit** when you are happy with it.

## Keep it working as the project grows

`CLAUDE.md` stays short and only points to things:

- Details go in `docs/`, with a line in `docs/README.md`.
- New rules go in `.claude/rules/`, one topic per file, and get listed in `CLAUDE.md`.
- Notes for one folder go in that folder's `CLAUDE.md`.
- Delete lines that are outdated. Old instructions mislead the AI.
- When code changes behavior, update the matching doc in the same change.
