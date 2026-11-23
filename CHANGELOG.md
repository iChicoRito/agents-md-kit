# Changelog

All notable changes to agents-md-kit. Versions follow [semantic versioning](https://semver.org): `MAJOR.MINOR.PATCH`.

## How to release (for maintainers)

1. Update `VERSION`, `kit_version` in `install.sh` and `$kitVersion` in `install.ps1` to the new number. The tests fail if they differ.
2. Add a section below.
3. Commit, push, wait for the tests to pass.
4. Tag and publish: `gh release create vX.Y.Z --title vX.Y.Z --notes-file <notes>`.

## 1.0.0 - 2026-11-23

First release.

- Three versions: `claude` (Claude Code), `agents` (Codex and other agents), `both`.
- Installers for Bash (`install.sh`) and PowerShell (`install.ps1`), with arrow-key menus, a progress bar and a summary tree.
- Never overwrites files. An existing `.gitignore` is merged.
- `PROMPT.md`: a prompt that makes your AI fill the placeholders from your code.
- `--update`: adds missing kit files and saves newer kit versions as `*.kit-new`.
- `--version`: installs a released version.
- `.agents-md-kit` file records the kit version and variant of each project.
- Line-limit hook for `CLAUDE.md` and `AGENTS.md` (200 lines). Skipped quietly without Node.js.
- Automatic tests on Ubuntu, macOS and Windows.
- MIT license.
