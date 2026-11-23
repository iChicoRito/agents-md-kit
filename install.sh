#!/usr/bin/env bash
# agents-md-kit installer: copy the AI agent template into a project folder.
# Usage:
#   bash install.sh [options] [target folder]                       (from a clone)
#   curl -fsSL https://raw.githubusercontent.com/iChicoRito/agents-md-kit/main/install.sh | bash
#   curl -fsSL .../install.sh | bash -s -- --for claude --project existing "path/to/project"
# Options (any option not given is asked; with nobody to ask, the default is used):
#   --for claude|agents|both    which agents (default: both)
#   --project new|existing      new/empty or existing project (default: detected from the folder)
#   --prompt yes|no             add PROMPT.md (existing: always yes; new: default no)
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

  Usage: install.sh [options] [target folder]

    --for claude          Claude Code only        CLAUDE.md + .claude/
    --for agents          Codex / other agents    AGENTS.md + .agents/
    --for both            Claude Code and Codex   all of the above (default)

    --project new         new or empty project (fill the files as you build)
    --project existing    project that already has code

    --prompt yes|no       add PROMPT.md, the prompt that makes your AI fill
                          the placeholders (existing: always added; new: default no)

  Options you leave out are asked. Target folder: current folder if not given.

EOF
}

# ---------- arguments ----------
choice=""; project=""; prompt=""; target="$PWD"
need_value() { [ "$2" -ge 2 ] || fail "$1 needs a value (see --help)"; }
while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    --for) need_value "$1" $#; choice="$2"; shift 2 ;;
    --for=*) choice="${1#--for=}"; shift ;;
    --project) need_value "$1" $#; project="$2"; shift 2 ;;
    --project=*) project="${1#--project=}"; shift ;;
    --prompt) need_value "$1" $#; prompt="$2"; shift 2 ;;
    --prompt=*) prompt="${1#--prompt=}"; shift ;;
    -*) fail "Unknown option: $1 (see --help)" ;;
    *) target="$1"; shift ;;
  esac
done
[ -d "$target" ] || fail "Target folder not found: $target"
target="$(cd "$target" && pwd)"
case "$choice" in ""|claude|agents|both) ;; *) fail "Unknown --for value: $choice (use claude, agents or both)" ;; esac
case "$project" in ""|new|existing) ;; *) fail "Unknown --project value: $project (use new or existing)" ;; esac
case "$prompt" in ""|yes|no) ;; *) fail "Unknown --prompt value: $prompt (use yes or no)" ;; esac

# Empty folder (ignoring .git) means a new project.
detected=existing
[ -z "$(ls -A "$target" | grep -vxF '.git')" ] && detected=new

# ---------- questions (only when someone can answer) ----------
can_ask=""
if { exec 3</dev/tty; } 2>/dev/null; then can_ask=1; fi

# ask "<prompt>" <default> <valid answers...>; result in $answer
ask() {
  local text="$1" def="$2"; shift 2
  local tries=0 a v
  while :; do
    printf '  %s ' "$text"; a=""
    read -r a <&3 || { answer="$def"; say ""; return; }
    a="$(echo "$a" | tr '[:upper:]' '[:lower:]' | tr -d '[:space:]')"
    [ -z "$a" ] && { answer="$def"; return; }
    for v in "$@"; do [ "$a" = "$v" ] && { answer="$a"; return; }; done
    tries=$((tries + 1))
    if [ $tries -ge 3 ]; then answer="$def"; say "  ${Y}No valid answer, using the default.${N}"; return; fi
    say "  ${Y}Please type one of: $*${N}"
  done
}

say ""
say "  ${B}agents-md-kit${N}  ${D}AI agent setup for your project${N}"
say "  ${D}--------------------------------------------------${N}"

if [ -z "$choice" ]; then
  if [ -n "$can_ask" ]; then
    say ""
    say "  ${B}Which AI agents will you use in this project?${N}"
    say ""
    say "    ${C}1${N}  Claude Code only         ${D}CLAUDE.md + .claude/${N}"
    say "    ${C}2${N}  Codex / other agents     ${D}AGENTS.md + .agents/${N}"
    say "    ${C}3${N}  Both ${G}(recommended)${N}       ${D}CLAUDE.md + AGENTS.md + both folders${N}"
    say ""
    ask "Choose [1-3, Enter = 3]:" 3 1 2 3
    case "$answer" in 1) choice=claude ;; 2) choice=agents ;; *) choice=both ;; esac
  else
    choice=both
  fi
fi

if [ -z "$project" ]; then
  if [ -n "$can_ask" ]; then
    if [ "$detected" = new ]; then def=1; note="this folder looks empty"; else def=2; note="this folder already has files"; fi
    say ""
    say "  ${B}Is this a new or an existing project?${N}"
    say ""
    say "    ${C}1${N}  New / empty project      ${D}you fill the files as you build${N}"
    say "    ${C}2${N}  Existing project         ${D}adds PROMPT.md so your AI fills them from your code${N}"
    say ""
    ask "Choose [1-2, Enter = $def, $note]:" "$def" 1 2
    case "$answer" in 1) project=new ;; *) project=existing ;; esac
  else
    project="$detected"
  fi
fi

if [ "$project" = existing ]; then
  [ "$prompt" = no ] && say "  ${Y}Existing project: PROMPT.md is always added.${N}"
  prompt=yes
elif [ -z "$prompt" ]; then
  if [ -n "$can_ask" ]; then
    say ""
    say "  ${D}PROMPT.md makes your AI fill the placeholders from your code. Useful after your first features exist.${N}"
    ask "Add PROMPT.md for later? [y/N]:" n y n yes no
    case "$answer" in y|yes) prompt=yes ;; *) prompt=no ;; esac
  else
    prompt=no
  fi
fi
[ -n "$can_ask" ] && exec 3<&-

case "$choice" in
  claude) label="Claude Code only" ;; agents) label="Codex / other agents" ;; both) label="Claude Code + Codex" ;;
esac
say ""
step "Version:  ${B}$choice${N} ${D}($label)${N}"
step "Project:  ${B}$project${N}"
step "Prompt:   ${B}$prompt${N} ${D}(PROMPT.md)${N}"
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
  [ "$rel" = "PROMPT.md" ] && [ "$prompt" = no ] && continue
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
case "$choice" in claude) anchor="claude-code-only-claude" ;; agents) anchor="codex-or-other-agents-agents" ;; both) anchor="both-both" ;; esac
prompt_url="https://github.com/iChicoRito/agents-md-kit/blob/main/PROMPTS.md#$anchor"
prompt_skipped=""; for s in "${skipped[@]+"${skipped[@]}"}"; do [ "$s" = "PROMPT.md" ] && prompt_skipped=1; done

say ""
say "  ${B}Next steps${N}"
if [ "$prompt" = yes ] && [ -n "$prompt_skipped" ]; then
  say "    1. Fill the [PLACEHOLDERS] in ${B}$main${N} and ${B}docs/${N}."
  say "       ${Y}Your project already had a PROMPT.md, so the kit's prompt was not added.${N}"
  say "       Copy the prompt from: ${C}$prompt_url${N}"
elif [ "$project" = existing ]; then
  say "    1. Fill the [PLACEHOLDERS] in ${B}$main${N} and ${B}docs/${N}. Tell your AI:"
  say "       ${C}Read PROMPT.md and do what it says.${N}"
  say "       ${D}(or copy the prompt from PROMPT.md. Online: $prompt_url)${N}"
elif [ "$prompt" = yes ]; then
  say "    1. Fill the [PLACEHOLDERS] in ${B}$main${N} and ${B}docs/${N} as you build."
  say "       After your first features exist, tell your AI: ${C}Read PROMPT.md and do what it says.${N}"
else
  say "    1. Fill the [PLACEHOLDERS] in ${B}$main${N} and ${B}docs/${N} as you build."
  say "       ${D}Later, to let your AI fill them from your code, copy the prompt: $prompt_url${N}"
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
