# Contributing

Thanks for helping. Bug reports, ideas and fixes are all welcome.

## Report a bug or suggest an idea

Open an issue: [New issue](https://github.com/iChicoRito/agents-md-kit/issues/new/choose). The bug form asks for:

- your system (Windows, macOS, Linux) and terminal (PowerShell, Git Bash, Terminal, ...);
- the kit version (shown in the installer's welcome box, for example `v1.2.0`);
- the command you ran and what the installer printed.

## Change the kit

```text
install.sh            Bash installer (macOS, Linux, Git Bash)
install.ps1           PowerShell installer (Windows)
template/claude/      files for Claude Code
template/agents/      files for Codex and other agents
template/both/        files for both
tests/test.sh         tests for install.sh
tests/test.ps1        tests for install.ps1
tools/graph-view/     the graph view: template.html (the page), graph_view.py (builds it), vendor/ (d3-force, inlined)
assets/demo.tape      script that records the README GIF
```

Rules:

1. **Keep both installers in step.** A new option or message in `install.sh` needs the same in `install.ps1`.
2. **Keep the templates in step.** A change to a shared file (rules, docs) usually belongs in all three `template/` folders.
3. **`install.ps1` stays plain ASCII.** Windows PowerShell 5.1 misreads UTF-8 files without a BOM. Build symbols from code points, like the existing ones.
4. **Never overwrite a user's file.** That is the kit's main promise.
5. **Add a test** for new behavior in `tests/test.sh` and `tests/test.ps1`.
6. **Write plain English.** Short sentences, simple words.

Run the tests before you open a pull request:

```bash
bash tests/test.sh
```

```powershell
powershell -ExecutionPolicy Bypass -File tests\test.ps1
```

GitHub runs the same tests on Ubuntu, macOS and Windows for every push and pull request.

## Release (maintainers)

See "How to release" in [CHANGELOG.md](CHANGELOG.md). After UI changes, re-record the README GIF: Actions > "demo gif" > Run workflow, then replace `assets/demo.gif` with the result.
