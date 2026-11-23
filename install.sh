#!/usr/bin/env bash
# agents-md-kit installer: copy the AI agent template into a project folder.
# Usage:
#   bash install.sh [--for claude|agents|both] [target folder]      (from a clone)
#   curl -fsSL https://raw.githubusercontent.com/iChicoRito/agents-md-kit/main/install.sh | bash
#   curl -fsSL .../install.sh | bash -s -- --for claude "path/to/project"
# --for claude: Claude Code only (CLAUDE.md, .claude/)
# --for agents: Codex and other agents only (AGENTS.md, .agents/)
# --for both:   both (default when no choice is given and nobody can be asked)
# Never overwrites: files that already exist are skipped and listed.
# Exception: an existing .gitignore is kept and only missing lines are added.
set -euo pipefail

archive="https://github.com/iChicoRito/agents-md-kit/archive/refs/heads/main.tar.gz"

# ---------- output style (colors only on a real terminal, off with NO_COLOR) ----------
if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
  B=$'\033[1m'; D=$'\033[2m'; G=$'\033[32m'; Y=$'\033[33m'; C=$'\033[36m'; RD=$'\033[31m'; N=$'\033[0m'
else
  B=""; D=""; G=""; Y=""; C=""; RD=""; N=""
fi
say()  { printf '%s\n' "$*"; }
step() { printf '  %s>%s %s\n' "$C" "$N" "$*"; }
fail() { printf '\n  %sError:%s %s\n\n' "$RD$B" "$N" "$*" >&2; exit 1; }

usage() {
  cat <<EOF

  ${B}agents-md-kit${N} installer

  Usage: install.sh [--for claude|agents|both] [target folder]

    --for claude   Claude Code only        CLAUDE.md + .claude/
    --for agents   Codex / other agents    AGENTS.md + .agents/
    --for both     Claude Code and Codex   all of the above (default)

  No --for: you are asked. Target folder: current folder if not given.

EOF
}

# ---------- arguments ----------
choice=""; target="$PWD"
while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    --for) [ $# -ge 2 ] || fail "--for needs a value: claude, agents or both"; choice="$2"; shift 2 ;;
    --for=*) choice="${1#--for=}"; shift ;;
    -*) fail "Unknown option: $1 (see --help)" ;;
    *) target="$1"; shift ;;
  esac
done
[ -d "$target" ] || fail "Target folder not found: $target"
target="$(cd "$target" && pwd)"

# ---------- header ----------
say ""
say "  ${B}agents-md-kit${N}  ${D}AI agent setup for your project${N}"
say "  ${D}--------------------------------------------------${N}"

# ---------- choose version ----------
if [ -z "$choice" ]; then
  if { exec 3</dev/tty; } 2>/dev/null; then
    say ""
    say "  ${B}Which AI agents will you use in this project?${N}"
    say ""
    say "    ${C}1${N}  Claude Code only         ${D}CLAUDE.md + .claude/${N}"
    say "    ${C}2${N}  Codex / other agents     ${D}AGENTS.md + .agents/${N}"
    say "    ${C}3${N}  Both ${G}(recommended)${N}       ${D}CLAUDE.md + AGENTS.md + both folders${N}"
    say ""
    tries=0
    while [ -z "$choice" ]; do
      printf '  Choose [1-3, Enter = 3]: '
      answer=""; read -r answer <&3 || { answer=""; tries=3; }
      case "$answer" in
        1) choice=claude ;; 2) choice=agents ;; 3|"") choice=both ;;
        *) tries=$((tries + 1))
           if [ $tries -ge 3 ]; then choice=both; say "  ${Y}No valid choice, using: both${N}"
           else say "  ${Y}Please type 1, 2 or 3.${N}"; fi ;;
      esac
    done
    exec 3<&-
  else
    choice=both
  fi
fi
case "$choice" in claude|agents|both) ;; *) fail "Unknown --for value: $choice (use claude, agents or both)" ;; esac

case "$choice" in
  claude) label="Claude Code only" ;; agents) label="Codex / other agents" ;; both) label="Claude Code + Codex" ;;
esac
say ""
step "Version:  ${B}$choice${N} ${D}($label)${N}"
step "Target:   $target"

# ---------- find or download the template ----------
script_dir=""
if [ -n "${BASH_SOURCE[0]:-}" ] && [ -f "${BASH_SOURCE[0]}" ]; then
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi
if [ -n "$script_dir" ] && [ -d "$script_dir/template/$choice" ]; then
  template="$script_dir/template/$choice"
else
  tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
  printf '  %s>%s Download: ' "$C" "$N"
  curl -fsSL "$archive" | tar -xz -C "$tmp" || { say "${RD}failed${N}"; fail "Could not download the template. Check your internet connection."; }
  template="$(find "$tmp" -mindepth 3 -maxdepth 3 -type d -path "*/template/$choice" | head -1)"
  [ -d "$template" ] || { say "${RD}failed${N}"; fail "Download incomplete: template/$choice not found"; }
  say "${G}done${N}"
fi

# ---------- copy ----------
copied=0; skipped=(); gi_status=""; gi_added=()
while IFS= read -r -d '' f; do
  rel="${f#"$template"/}"
  dest="$target/$rel"
  if [ "$rel" = ".gitignore" ] && [ -e "$dest" ]; then
    gi_status="checked"
    while IFS= read -r line || [ -n "$line" ]; do
      line="${line%$'\r'}"; line="$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
      case "$line" in ''|'#'*) continue ;; esac
      tr -d '\r' < "$dest" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | grep -qxF -- "$line" || gi_added+=("$line")
    done < "$f"
    if [ ${#gi_added[@]} -gt 0 ]; then
      nl=$'\n'; [ "$(tr -cd '\r' < "$dest" | wc -c)" -gt 0 ] && nl=$'\r\n'
      { [ -s "$dest" ] && [ "$(tail -c1 "$dest")" != "" ] && printf '%s' "$nl"
        printf '%s# Added by agents-md-kit%s' "$nl" "$nl"
        for l in "${gi_added[@]}"; do printf '%s%s' "$l" "$nl"; done; } >> "$dest"
    fi
    continue
  fi
  if [ -e "$dest" ]; then skipped+=("$rel"); continue; fi
  mkdir -p "$(dirname "$dest")"
  cp "$f" "$dest"
  copied=$((copied + 1))
done < <(find "$template" -type f -print0)

# ---------- summary ----------
say ""
say "  ${B}Result${N}"
say "    ${G}+${N} $copied file(s) added"
if [ -n "$gi_status" ]; then
  if [ ${#gi_added[@]} -gt 0 ]; then
    say "    ${G}~${N} .gitignore kept, ${#gi_added[@]} line(s) added: $(IFS=,; echo "${gi_added[*]}" | sed 's/,/, /g')"
  else
    say "    ${D}=${N} .gitignore kept, nothing to add"
  fi
fi
if [ ${#skipped[@]} -gt 0 ]; then
  say "    ${Y}!${N} ${#skipped[@]} file(s) already existed, left untouched. Merge by hand:"
  for s in "${skipped[@]}"; do say "        ${D}$s${N}"; done
fi

main="CLAUDE.md"; [ "$choice" = agents ] && main="AGENTS.md"
say ""
say "  ${B}Next steps${N}"
case "$choice" in claude) anchor="claude-code-only-claude" ;; agents) anchor="codex-or-other-agents-agents" ;; both) anchor="both-both" ;; esac
prompt_url="https://github.com/iChicoRito/agents-md-kit/blob/main/PROMPTS.md#$anchor"
prompt_skipped=""; for s in "${skipped[@]+"${skipped[@]}"}"; do [ "$s" = "PROMPT.md" ] && prompt_skipped=1; done
if [ -n "$prompt_skipped" ]; then
  say "    1. Fill the [PLACEHOLDERS] in ${B}$main${N} and ${B}docs/${N}."
  say "       ${Y}Your project already had a PROMPT.md, so the kit's prompt was not added.${N}"
  say "       Copy the prompt from: ${C}$prompt_url${N}"
else
  say "    1. Fill the [PLACEHOLDERS] in ${B}$main${N} and ${B}docs/${N}. Tell your AI:"
  say "       ${C}Read PROMPT.md and do what it says.${N}"
  say "       ${D}(or copy the prompt from PROMPT.md. Online: $prompt_url)${N}"
fi
say "    2. Install the skills: ${B}docs/guides/setup.md${N}"
if [ "$choice" = agents ]; then
  say "    3. Start your agent and ask it to read ${B}AGENTS.md${N}"
else
  say "    3. In Claude Code, run ${B}/memory${N} and ${B}/skills${N} to check what loads"
fi
say ""
say "  ${G}${B}Done.${N} ${D}Guide: https://github.com/iChicoRito/agents-md-kit/blob/main/GUIDE.md${N}"
say ""
