#!/usr/bin/env bash
# Tests install.sh without a keyboard: every version, new and existing projects, rerun, update.
# Usage: bash tests/test.sh     (exit code 0 = all passed)
set -uo pipefail

kit="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
work="$(mktemp -d)"; trap 'rm -rf "$work"' EXIT
fails=0; n=0
check() { n=$((n + 1)); if eval "$2"; then echo "  ok   $1"; else echo "  FAIL $1"; fails=$((fails + 1)); fi; }
install() { bash "$kit/install.sh" "$@" </dev/null >"$work/last.log" 2>&1; }
# Every template file (except PROMPT.md unless asked) must exist in the project.
has_all() {
  local v="$1" dir="$2" with_prompt="$3" f rel
  while IFS= read -r -d '' f; do
    rel="${f#"$kit/template/$v"/}"
    [ "$rel" = PROMPT.md ] && [ "$with_prompt" = no ] && continue
    [ -e "$dir/$rel" ] || { echo "       missing: $rel"; return 1; }
  done < <(find "$kit/template/$v" -type f -print0)
}
snapshot() { (cd "$1" && find . -type f -exec cksum {} + | sort); }

for v in claude agents both; do
  echo "== $v"
  main=CLAUDE.md; [ $v = agents ] && main=AGENTS.md

  # New, empty project, no PROMPT.md
  d="$work/$v-new"; mkdir -p "$d"
  check "new: installs without error" "install --for $v --project new --prompt no '$d'"
  check "new: every kit file is there" "has_all $v '$d' no"
  check "new: no PROMPT.md" "[ ! -e '$d/PROMPT.md' ]"
  [ $v = claude ] && check "new: no .agents folder" "[ ! -e '$d/.agents' ]"
  [ $v = agents ] && check "new: no .claude folder" "[ ! -e '$d/.claude' ]"

  # Running again changes nothing
  # shellcheck disable=SC2034  # used inside the check string below
  before="$(snapshot "$d")"
  check "rerun: installs without error" "install --for $v --project new --prompt no '$d'"
  check "rerun: no file changed" "[ \"\$(snapshot '$d')\" = \"\$before\" ]"

  # Existing project: own files are kept, .gitignore is merged, PROMPT.md is added
  d="$work/$v-existing"; mkdir -p "$d"
  echo "my own instructions" > "$d/$main"; echo "x" > "$d/app.js"; printf 'node_modules\n' > "$d/.gitignore"
  check "existing: installs without error" "install --for $v '$d'"
  check "existing: own $main untouched" "[ \"\$(cat '$d/$main')\" = 'my own instructions' ]"
  check "existing: own file untouched" "[ \"\$(cat '$d/app.js')\" = x ]"
  check "existing: PROMPT.md added" "[ -e '$d/PROMPT.md' ]"
  check "existing: .gitignore keeps own line" "grep -qx node_modules '$d/.gitignore'"
  check "existing: .gitignore gets kit lines" "grep -qx '\*.kit-new' '$d/.gitignore'"
  check "existing: $main listed as left untouched" "grep -q 'already existed' '$work/last.log'"

  # Update: missing files come back, changed files get a .kit-new, own content stays
  d="$work/$v-update"; mkdir -p "$d"
  install --for $v --project new --prompt no "$d"
  echo "# my notes" >> "$d/$main"; rm "$d/docs/glossary.md"
  check "update: runs without error" "install --update '$d'"
  check "update: detects version $v" "grep -q \"Agents *$v\" '$work/last.log'"
  check "update: deleted file restored" "[ -e '$d/docs/glossary.md' ]"
  check "update: changed file gets .kit-new" "[ -e '$d/$main.kit-new' ]"
  check "update: own edit kept" "grep -qx '# my notes' '$d/$main'"
  check "update: .kit-new is the kit version" "cmp -s '$kit/template/$v/$main' '$d/$main.kit-new'"
  check "update: no PROMPT.md added" "[ ! -e '$d/PROMPT.md' ]"
done

# Bad input is refused
echo "== errors"
check "unknown --for value fails" "! install --for nope '$work'"
check "missing folder fails" "! install --for both '$work/does-not-exist'"

echo ""
echo "$((n - fails))/$n passed"
[ $fails -eq 0 ]
