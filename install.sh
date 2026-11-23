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
# Environment: NO_COLOR=1 turns colors off. AGENTS_MD_KIT_UI=plain uses typed answers instead of arrow-key menus.
# Never overwrites: files that already exist are skipped and listed.
# Exception: an existing .gitignore is kept and only missing lines are added.
set -euo pipefail

archive="https://github.com/iChicoRito/agents-md-kit/archive/refs/heads/main.tar.gz"
repo="https://github.com/iChicoRito/agents-md-kit"

# ---------- output style ----------
# ansi: a real terminal that understands cursor codes (needed for menus).
# Colors only on such a terminal, and off with NO_COLOR. Unicode symbols only in a UTF-8 locale.
ansi=""; [ -t 1 ] && [ "${TERM:-}" != dumb ] && ansi=1
if [ -n "$ansi" ] && [ -z "${NO_COLOR:-}" ]; then
  B=$'\033[1m'; D=$'\033[2m'; G=$'\033[32m'; Y=$'\033[33m'; RD=$'\033[31m'; A=$'\033[38;5;173m'; N=$'\033[0m'
else
  B=""; D=""; G=""; Y=""; RD=""; A=""; N=""
fi
case "${LC_ALL:-${LC_CTYPE:-${LANG:-}}}" in
  *UTF-8*|*utf8*|*UTF8*|*utf-8*) utf=1 ;;
  *) utf=""; [ "$(locale charmap 2>/dev/null || true)" = UTF-8 ] && utf=1 ;;
esac
if [ -n "$utf" ]; then
  DOT="●"; PTR="❯"; ELB="└"; STAR="✻"; SEP="·"; UP="↑"; DN="↓"
  TL="╭"; TR="╮"; BL="╰"; BR="╯"; H="─"; V="│"
else
  DOT="*"; PTR=">"; ELB="'-"; STAR="*"; SEP="-"; UP="up"; DN="down"
  TL="+"; TR="+"; BL="+"; BR="+"; H="-"; V="|"
fi

say()  { printf '%s\n' "$*"; }
fail() { printf '\n  %s%s Error:%s %s\n\n' "$RD$B" "$DOT" "$N" "$*" >&2; exit 1; }
# done_line "<label>" "<value>" ["<note>"]: one finished step, like Claude Code's tool lines
done_line() { printf '  %s%s%s %-9s %s%s%s%s\n' "$G" "$DOT" "$N" "$1" "$B" "$2" "$N" "${3:+ $D$SEP $3$N}"; }
rule() { local s="" i; for ((i = 0; i < $1; i++)); do s+="$H"; done; printf '%s' "$s"; }

# ---------- help ----------
usage() {
  cat <<EOF

  ${A}${STAR}${N} ${B}agents-md-kit${N} ${D}installer${N}

  ${B}Usage${N}  install.sh [options] [target folder]

    --for claude          Claude Code only        CLAUDE.md + .claude/
    --for agents          Codex / other agents    AGENTS.md + .agents/
    --for both            Claude Code and Codex   all of the above (default)

    --project new         new or empty project (fill the files as you build)
    --project existing    project that already has code

    --prompt yes|no       add PROMPT.md, the prompt that makes your AI fill
                          the placeholders (existing: always added; new: default no)

  ${D}Options you leave out are asked. Target folder: current folder if not given.${N}

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
# Arrow-key menus need an ANSI terminal and a keyboard that can switch to key-by-key mode;
# otherwise answers are typed.
menus=""; old_stty=""
if [ -n "$can_ask" ] && [ -n "$ansi" ] && [ "${AGENTS_MD_KIT_UI:-}" != plain ] \
  && old_stty="$(stty -g <&3 2>/dev/null)" && [ -n "$old_stty" ]; then
  menus=1
fi

cleanup() {
  if [ -n "$menus" ]; then printf '\033[?25h'; stty "$old_stty" 2>/dev/null <&3 || true; fi
  [ -n "${tmp:-}" ] && rm -rf "$tmp"; return 0
}
trap cleanup EXIT
trap 'exit 130' INT

# choose "<question>" <default 1-based> "label|hint"...
# Shows a menu, sets $answer to the chosen number, then collapses it to one line.
choose() {
  local question="$1" sel="$2"; shift 2
  local opts=("$@") n=$# i key rest lab hint
  if [ -z "$menus" ]; then
    say ""; say "  ${B}$question${N}"; say ""
    for ((i = 0; i < n; i++)); do
      lab="${opts[i]%%|*}"; hint="${opts[i]#*|}"
      printf '    %s%d%s  %-24s %s%s%s\n' "$A" $((i + 1)) "$N" "$lab" "$D" "$hint" "$N"
    done
    say ""
    ask "Choose [1-$n, Enter = $sel]:" "$sel" $(seq 1 "$n")
    return
  fi
  draw() {
    for ((i = 0; i < n; i++)); do
      lab="${opts[i]%%|*}"; hint="${opts[i]#*|}"
      if [ $((i + 1)) -eq "$sel" ]; then
        printf '\033[2K  %s%s %d. %-24s%s %s%s%s\n' "$A" "$PTR" $((i + 1)) "$lab" "$N" "$D" "$hint" "$N"
      else
        printf '\033[2K    %d. %-24s %s%s%s\n' $((i + 1)) "$lab" "$D" "$hint" "$N"
      fi
    done
    printf '\033[2K\n\033[2K  %s%s/%s move %s Enter select %s 1-%d pick %s Ctrl+C quit%s\n' \
      "$D" "$UP" "$DN" "$SEP" "$SEP" "$n" "$SEP" "$N"
  }
  printf '\033[?25l'
  say ""; say "  ${B}$question${N}"; say ""
  draw
  # Key-by-key input without echo. One dd read gets a whole key, arrow sequences included
  # (bash's read -n1 splits and loses them in Git Bash on Windows).
  stty -echo -icanon min 1 time 0 <&3
  while :; do
    key="$(dd bs=8 count=1 2>/dev/null <&3)" || break
    case "$key" in
      $'\033[A'|$'\033OA'|k) [ "$sel" -gt 1 ] && sel=$((sel - 1)) ;;
      $'\033[B'|$'\033OB'|j) [ "$sel" -lt "$n" ] && sel=$((sel + 1)) ;;
      [1-9]) if [ "$key" -le "$n" ]; then sel="$key"; break; fi ;;
      ''|$'\r') break ;;   # Enter ($(...) drops the newline)
    esac
    printf '\033[%dA' $((n + 2)); draw
  done
  stty "$old_stty" <&3
  # Erase question + menu (blank, question, blank, n options, blank, hint) and keep one answer line.
  printf '\033[%dA\033[J' $((n + 5))
  printf '\033[?25h'
  answer="$sel"
}

# ask "<prompt>" <default> <valid answers...>; result in $answer (typed fallback)
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

# ---------- welcome ----------
w=50
say ""
say "  ${A}${TL}$(rule $w)${TR}${N}"
printf '  %s%s%s %s%s%s %sWelcome to agents-md-kit%s%*s%s%s%s\n' "$A" "$V" "$N" "$A" "$STAR" "$N" "$B" "$N" $((w - 27)) "" "$A" "$V" "$N"
printf '  %s%s%s%*s%s%s%s\n' "$A" "$V" "$N" $w "" "$A" "$V" "$N"
printf '  %s%s%s   %sAI agent setup for Claude Code and Codex%s%*s%s%s%s\n' "$A" "$V" "$N" "$D" "$N" $((w - 43)) "" "$A" "$V" "$N"
say "  ${A}${BL}$(rule $w)${BR}${N}"
say ""
show_target="$target"; [ -n "${HOME:-}" ] && case "$target" in "$HOME"*) show_target="~${target#"$HOME"}" ;; esac
say "  ${D}Folder: $show_target${N}"
[ -n "$menus" ] && say "  ${D}Pick with arrow keys. Nothing is overwritten.${N}" || say "  ${D}Nothing is overwritten.${N}"
[ -n "$can_ask" ] && [ -z "$menus" ] || say ""   # typed questions bring their own blank line

if [ -z "$choice" ]; then
  if [ -n "$can_ask" ]; then
    choose "Which AI agents will you use in this project?" 3 \
      "Claude Code only|CLAUDE.md + .claude/" \
      "Codex / other agents|AGENTS.md + .agents/" \
      "Both (recommended)|CLAUDE.md + AGENTS.md + both folders"
    case "$answer" in 1) choice=claude ;; 2) choice=agents ;; *) choice=both ;; esac
  else
    choice=both
  fi
fi
case "$choice" in
  claude) label="Claude Code only" ;; agents) label="Codex / other agents" ;; both) label="Claude Code + Codex" ;;
esac
done_line "Agents" "$choice" "$label"

if [ -z "$project" ]; then
  if [ -n "$can_ask" ]; then
    if [ "$detected" = new ]; then def=1; else def=2; fi
    choose "Is this a new or an existing project?" "$def" \
      "New / empty project|you fill the files as you build$([ $def = 1 ] && echo " $SEP this folder looks empty")" \
      "Existing project|your AI fills them from your code$([ $def = 2 ] && echo " $SEP this folder has files")"
    case "$answer" in 1) project=new ;; *) project=existing ;; esac
  else
    project="$detected"
  fi
fi
done_line "Project" "$project"

prompt_note=""
if [ "$project" = existing ]; then
  [ "$prompt" = no ] && prompt_note="always added for existing projects"
  prompt=yes
elif [ -z "$prompt" ]; then
  if [ -n "$can_ask" ]; then
    if [ -n "$menus" ]; then
      choose "Add PROMPT.md for later?" 2 \
        "Yes|your AI fills the placeholders from your code" \
        "No|copy the prompt from GitHub later"
      case "$answer" in 1) prompt=yes ;; *) prompt=no ;; esac
    else
      say ""
      say "  ${D}PROMPT.md makes your AI fill the placeholders from your code. Useful after your first features exist.${N}"
      ask "Add PROMPT.md for later? [y/N]:" n y n yes no
      case "$answer" in y|yes) prompt=yes ;; *) prompt=no ;; esac
    fi
  else
    prompt=no
  fi
fi
[ -n "$can_ask" ] && exec 3<&-
done_line "PROMPT.md" "$prompt" "$prompt_note"

# ---------- find or download the template ----------
script_dir=""
if [ -n "${BASH_SOURCE[0]:-}" ] && [ -f "${BASH_SOURCE[0]}" ]; then
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi
say ""
if [ -n "$script_dir" ] && [ -d "$script_dir/template/$choice" ]; then
  template="$script_dir/template/$choice"
  done_line "Template" "local copy"
else
  tmp="$(mktemp -d)"
  printf '  %s%s%s Downloading template...' "$A" "$DOT" "$N"
  curl -fsSL "$archive" | tar -xz -C "$tmp" || { printf '\n'; fail "Could not download the template. Check your internet connection."; }
  template="$(find "$tmp" -mindepth 3 -maxdepth 3 -type d -path "*/template/$choice" | head -1)"
  [ -d "$template" ] || { printf '\n'; fail "Download incomplete: template/$choice not found"; }
  if [ -n "$ansi" ]; then printf '\r\033[2K'; else printf '\n'; fi
  done_line "Template" "downloaded" "latest from GitHub"
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

# ---------- result ----------
done_line "Copied" "$copied file(s)"
if [ -n "$gi_status" ]; then
  if [ ${#gi_added[@]} -gt 0 ]; then
    say "    ${D}${ELB}${N} .gitignore kept, ${G}+${#gi_added[@]} line(s)${N}: $(IFS=,; echo "${gi_added[*]}" | sed 's/,/, /g')"
  else
    say "    ${D}${ELB} .gitignore kept, nothing to add${N}"
  fi
fi
if [ ${#skipped[@]} -gt 0 ]; then
  say "    ${D}${ELB}${N} ${Y}${#skipped[@]} file(s) already existed, left untouched. Merge by hand:${N}"
  for s in "${skipped[@]}"; do say "        ${D}$s${N}"; done
fi

main="CLAUDE.md"; [ "$choice" = agents ] && main="AGENTS.md"
case "$choice" in claude) anchor="claude-code-only-claude" ;; agents) anchor="codex-or-other-agents-agents" ;; both) anchor="both-both" ;; esac
prompt_url="$repo/blob/main/PROMPTS.md#$anchor"
prompt_skipped=""; for s in "${skipped[@]+"${skipped[@]}"}"; do [ "$s" = "PROMPT.md" ] && prompt_skipped=1; done

# ---------- next steps ----------
say ""
say "  ${A}${STAR}${N} ${B}Next steps${N}"
say ""
if [ "$prompt" = yes ] && [ -n "$prompt_skipped" ]; then
  say "    ${A}1${N}  Fill the [PLACEHOLDERS] in ${B}$main${N} and ${B}docs/${N}."
  say "       ${Y}Your project already had a PROMPT.md, so the kit's prompt was not added.${N}"
  say "       Copy the prompt from: ${A}$prompt_url${N}"
elif [ "$project" = existing ]; then
  say "    ${A}1${N}  Fill the [PLACEHOLDERS] in ${B}$main${N} and ${B}docs/${N}. Tell your AI:"
  say "       ${A}${PTR}${N} ${B}Read PROMPT.md and do what it says.${N}"
elif [ "$prompt" = yes ]; then
  say "    ${A}1${N}  Fill the [PLACEHOLDERS] in ${B}$main${N} and ${B}docs/${N} as you build."
  say "       After your first features exist, tell your AI:"
  say "       ${A}${PTR}${N} ${B}Read PROMPT.md and do what it says.${N}"
else
  say "    ${A}1${N}  Fill the [PLACEHOLDERS] in ${B}$main${N} and ${B}docs/${N} as you build."
  say "       ${D}Later, to let your AI fill them from your code: $prompt_url${N}"
fi
say "    ${A}2${N}  Install the skills: ${B}docs/guides/setup.md${N}"
if [ "$choice" = agents ]; then
  say "    ${A}3${N}  Start your agent and ask it to read ${B}AGENTS.md${N}"
else
  say "    ${A}3${N}  In Claude Code, run ${B}/memory${N} and ${B}/skills${N} to check what loads"
fi
say ""
say "  ${G}${DOT}${N} ${B}Done.${N} ${D}Guide: $repo/blob/main/GUIDE.md${N}"
say ""
