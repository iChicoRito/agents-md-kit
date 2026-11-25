# Changelog

All notable changes to agents-md-kit. Versions follow [semantic versioning](https://semver.org): `MAJOR.MINOR.PATCH`.

## How to release (for maintainers)

1. Update `VERSION`, `kit_version` in `install.sh` and `$kitVersion` in `install.ps1` to the new number. The tests fail if they differ.
2. Add a section below.
3. Commit, push, wait for the tests to pass.
4. Tag and publish: `gh release create vX.Y.Z --title vX.Y.Z --notes-file <notes>`.

## Unreleased

- New installer question: install or update the primary skills (Superpowers, Ponytail, Caveman) from their official repos. Default No. Skip the question with `--skills yes|no` (PowerShell: `-Skills`).
- Skills install with `npx skills add` from the official repos (`obra/superpowers`, `DietrichGebert/ponytail`, `JuliusBrussee/caveman`), into your user folder. It fetches the latest version, so skills you already have are updated.
- `claude`: Claude Code (`~/.claude/skills`). `agents`: Codex (`~/.agents/skills`). `both`: the same skills in both.
- Needs Node.js. Plugin hooks (such as the automatic caveman and ponytail modes) are not installed this way.
- Installing graphify, building the graph and installing the skills now show a progress bar, like the file copy. The bar counts steps; the running step moves toward its end but only completes when it really finishes.

## 1.6.0 - 2026-11-23

- Faster graph view: smooth (60 fps) with 10,000+ nodes while the layout settles, zooming and dragging. Before, it slowed down above about 1,000 nodes.
- The physics runs in a Web Worker, so the page keeps drawing while it works. If the browser blocks the worker, it runs in the page as before.
- Drawing is batched per group, skips what is off screen, and draws tiny dots as squares.
- Big graphs (over 3,000 nodes) keep settling on screen instead of freezing half done.

## 1.5.1 - 2026-11-23

- `PROMPT.md` now tells the AI to use graphify when a graph exists: query it first, read files after. If graphify is installed but no graph exists, the AI asks before building one.

## 1.5.0 - 2026-11-23

- New graph view: `graphify-out/graph.html` is now an interactive, Obsidian-style map of the code. It is one offline file (no network, no CDN). Dragging a node pulls its neighbors along the links (force simulation). Hover lights up a node and its neighbors, click opens details and connections, `/` searches, the settings panel hides groups and tunes the forces, and there are dark and light themes. The look follows shadcn/ui (zinc).
- `--graph-view` / `-GraphView`: builds the view from `graphify-out/graph.json`, then stops. The installer also builds it right after it builds the graph. graphify rewrites `graph.html` on every update, so run `--graph-view` again afterwards.
- Needs Python 3.8+ (graphify needs Python already). The viewer ships in `tools/graph-view/` with the d3-force modules inlined (ISC license in `tools/graph-view/vendor/`).
- Tests: graph view generator (`tests/test_graph_view.py`) plus installer checks, in both suites.

## 1.4.0 - 2026-11-23

- The installer now asks about graphify at the end, always with No as the default. If `graphify` is missing it offers to install the official package (`graphifyy`, with `uv`, else `pipx`, else `pip --user`). If it is installed, or just got installed, it offers to build the code graph (`graphify update .`, code only, no AI, no tokens). It never installs or builds without a yes, and it skips both when a graph already exists.
- `--graphify yes|no` / `-Graphify yes|no`: answer for scripts. Without the option and without a keyboard, nothing is installed or built, and the install summary prints a tip instead.
- Dry run skips the graphify step.

## 1.3.0 - 2026-11-23

- New rule `graphify.md` (all three versions): when a project has a graphify knowledge graph (`graphify-out/graph.json`), the AI asks the graph first (`graphify query`, `path`, `explain`, `affected`) and opens source files only for the lines the answer points to. It does nothing until a graph exists, and asks you before it builds one.
- `graphify` added to the skills tables, and a "Graphify (optional)" section added to `docs/guides/setup.md` (install, build, keep current).
- Existing projects: `--update` adds `graphify.md` and saves the changed `CLAUDE.md` / `AGENTS.md` as `.kit-new`.

## 1.2.0 - 2026-11-23

- `--check` / `-Check`: lists the `[PLACEHOLDERS]` still left in `CLAUDE.md`, `AGENTS.md` and `docs/`, file by file. Bash exits with code 1 while some are left, so it also works in scripts and CI.
- The install summary now mentions `--check`.
- README: how to read the installer before running it, and how to pin a release.
- `CONTRIBUTING.md` and GitHub issue forms for bug reports and ideas.

## 1.1.0 - 2026-11-23

- `--dry-run` / `-DryRun`: shows what would be added, merged or skipped, and changes nothing.
- `--add-command` / `-AddCommand`: adds the short command `agents-md-kit` to your PowerShell profile, `~/.zshrc` or `~/.bashrc`. Running it again adds nothing.
- Tests: GitHub Actions now uses `actions/checkout@v5`.

## 1.0.1 - 2026-11-23

- The installer no longer adds a `.agents-md-kit` file to projects. The version stays on GitHub (`VERSION`, releases) and in the installer's welcome box. `--update` works out the variant from the `.claude/` and `.agents/` folders. An old `.agents-md-kit` file from 1.0.0 can be deleted.

## 1.0.0 - 2026-11-23

First release.

- Three versions: `claude` (Claude Code), `agents` (Codex and other agents), `both`.
- Installers for Bash (`install.sh`) and PowerShell (`install.ps1`), with arrow-key menus, a progress bar and a summary tree.
- Never overwrites files. An existing `.gitignore` is merged.
- `PROMPT.md`: a prompt that makes your AI fill the placeholders from your code.
- `--update`: adds missing kit files and saves newer kit versions as `*.kit-new`.
- `--version`: installs a released version.
- `.agents-md-kit` file records the kit version and variant of each project (removed in 1.0.1).
- Line-limit hook for `CLAUDE.md` and `AGENTS.md` (200 lines). Skipped quietly without Node.js.
- Automatic tests on Ubuntu, macOS and Windows.
- MIT license.
