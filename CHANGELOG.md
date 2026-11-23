# Changelog

All notable changes to agents-md-kit. Versions follow [semantic versioning](https://semver.org): `MAJOR.MINOR.PATCH`.

## How to release (for maintainers)

1. Update `VERSION`, `kit_version` in `install.sh` and `$kitVersion` in `install.ps1` to the new number. The tests fail if they differ.
2. Add a section below.
3. Commit, push, wait for the tests to pass.
4. Tag and publish: `gh release create vX.Y.Z --title vX.Y.Z --notes-file <notes>`.

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
