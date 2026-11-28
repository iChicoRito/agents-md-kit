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
#   --update                    project already has the kit: add missing files, and save the
#                               newer kit version of changed files as <file>.kit-new
# Environment: NO_COLOR=1 turns colors off. AGENTS_MD_KIT_UI=plain uses typed answers instead of arrow-key menus.
# Never overwrites: files that already exist are skipped and listed.
# Exception: an existing .gitignore is kept and only missing lines are added.
set -euo pipefail

kit_version="2.1.1"   # keep equal to the VERSION file (the tests check this)
repo="https://github.com/iChicoRito/agents-md-kit"
archive="$repo/archive/refs/heads/main.tar.gz"

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
  DOT="●"; PTR="❯"; ELB="└"; TEE="├"; STAR="✻"; SEP="·"; UP="↑"; DN="↓"
  SPIN=(⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏); FULL="█"; EMPTY="░"
  TL="╭"; TR="╮"; BL="╰"; BR="╯"; H="─"; V="│"
else
  DOT="*"; PTR=">"; ELB="'-"; TEE="|-"; STAR="*"; SEP="-"; UP="up"; DN="down"
  SPIN=('|' '/' '-' '\'); FULL="#"; EMPTY="-"
  TL="+"; TR="+"; BL="+"; BR="+"; H="-"; V="|"
fi

say()  { printf '%s\n' "$*"; }
fail() { printf '\n  %s%s Error:%s %s\n\n' "$RD$B" "$DOT" "$N" "$*" >&2; exit 1; }
# done_line "<label>" "<value>" ["<note>"]: one finished step, like Claude Code's tool lines
done_line() { printf '  %s%s%s %-12s %s%s%s%s\n' "$G" "$DOT" "$N" "$1" "$B" "$2" "$N" "${3:+ $D$SEP $3$N}"; }
files() { if [ "$1" = 1 ]; then echo "1 file"; else echo "$1 files"; fi; }
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

    --update              the project already has the kit: add missing files, and
                          save the newer kit version of changed files as <file>.kit-new

    --version 1.0.0       install that released version instead of the latest
                          (list: $repo/releases)

    --dry-run             show what would be added, merged or skipped; change nothing

    --add-command         add the short command "agents-md-kit" to your shell
                          (~/.zshrc for zsh, otherwise ~/.bashrc), then stop

    --check               list the [PLACEHOLDERS] still left in CLAUDE.md, AGENTS.md
                          and docs/, then stop (exit code 1 when some are left)

    --graphify yes|no     graphify, the code knowledge graph: yes = install it if missing and
                          build the graph without asking, no = skip it (default: ask)

    --skills yes|no       primary skills (Superpowers, Ponytail, Caveman, unslop, official repos):
                          yes = install them, or update those already installed, without
                          asking; no = skip (default: ask)

  ${D}Options you leave out are asked. Target folder: current folder if not given.${N}

EOF
}

# ---------- arguments ----------
choice=""; project=""; prompt=""; update=""; want_version=""; dry=""; add_cmd=""; check=""; gfy_flag=""; skills_flag=""; step_log=""; target="$PWD"
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
    --update) update=1; shift ;;
    --version) need_value "$1" $#; want_version="$2"; shift 2 ;;
    --version=*) want_version="${1#--version=}"; shift ;;
    --dry-run) dry=1; shift ;;
    --add-command) add_cmd=1; shift ;;
    --check) check=1; shift ;;
    --graphify) need_value "$1" $#; gfy_flag="$2"; shift 2 ;;
    --graphify=*) gfy_flag="${1#--graphify=}"; shift ;;
    --skills) need_value "$1" $#; skills_flag="$2"; shift 2 ;;
    --skills=*) skills_flag="${1#--skills=}"; shift ;;
    -*) fail "Unknown option: $1 (see --help)" ;;
    *) target="$1"; shift ;;
  esac
done

# ---------- --add-command: put the short command in the shell's startup file, then stop ----------
if [ -n "$add_cmd" ]; then
  case "${SHELL:-}" in */zsh) rc="$HOME/.zshrc" ;; *) rc="$HOME/.bashrc" ;; esac
  line='agents-md-kit() { curl -fsSL https://raw.githubusercontent.com/iChicoRito/agents-md-kit/main/install.sh | bash -s -- "$@"; }'
  say ""
  if [ -f "$rc" ] && grep -q '^agents-md-kit()' "$rc"; then
    done_line "Command" "agents-md-kit" "already in $rc"
  else
    [ -n "$dry" ] || printf '\n# agents-md-kit installer (added by --add-command)\n%s\n' "$line" >> "$rc"
    done_line "Command" "agents-md-kit" "$([ -n "$dry" ] && echo "would be added to" || echo "added to") $rc"
  fi
  say "    ${D}Open a new terminal, then type ${N}${B}agents-md-kit${N}${D} in any project folder.${N}"
  say ""
  exit 0
fi
[ -d "$target" ] || fail "Target folder not found: $target"
target="$(cd "$target" && pwd)"

# Where this script lives (empty when it is piped from curl).
script_dir=""
if [ -n "${BASH_SOURCE[0]:-}" ] && [ -f "${BASH_SOURCE[0]}" ]; then
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

# ---------- --check: list placeholders still left in the kit files, then stop ----------
# A placeholder is an uppercase word in brackets, like [PROJECT DESCRIPTION].
# Markdown links ([API](...)) are not placeholders. PROMPT.md and the ADR template
# (docs/architecture/decisions/0000-template.md) are meant to keep theirs, so they are skipped.
if [ -n "$check" ]; then
  scan=()
  for f in CLAUDE.md AGENTS.md; do [ -f "$target/$f" ] && scan+=("$f"); done
  if [ -d "$target/docs" ]; then
    while IFS= read -r -d '' f; do
      rel="${f#"$target"/}"
      [ "$rel" = "docs/architecture/decisions/0000-template.md" ] || scan+=("$rel")
    done < <(find "$target/docs" -type f \( -name '*.md' -o -name '*.yaml' -o -name '*.yml' \) -print0 | sort -z)
  fi
  [ ${#scan[@]} -gt 0 ] || fail "No CLAUDE.md, AGENTS.md or docs/ in $target. Install the kit first."
  total=0; nfiles=0; rows=()
  for rel in "${scan[@]}"; do
    found="$(LC_ALL=C grep -oE '\[[A-Z][A-Z0-9 _,./:-]+\]([^(]|$)' "$target/$rel" | LC_ALL=C sed -E 's/^(\[[^]]*\]).*/\1/' || true)"
    [ -n "$found" ] || continue
    cnt="$(printf '%s\n' "$found" | wc -l | tr -d ' ')"
    list="$(printf '%s\n' "$found" | awk '!seen[$0]++' | paste -sd'|' - | sed 's/|/, /g')"
    [ ${#list} -gt 60 ] && list="${list:0:57}..."
    total=$((total + cnt)); nfiles=$((nfiles + 1))
    rows+=("$(printf '%-34s %3s' "$rel" "$cnt")  ${D}$list${N}")
  done
  say ""
  if [ $total -eq 0 ]; then
    done_line "Check" "no placeholders left" "$(files ${#scan[@]}) checked"
    say ""
    exit 0
  fi
  done_line "Check" "$total placeholders left" "in $(files $nfiles)"
  for ((i = 0; i < ${#rows[@]}; i++)); do
    if [ $i -eq $((${#rows[@]} - 1)) ]; then br="$ELB"; else br="$TEE"; fi
    say "    ${D}${br}${N} ${rows[i]}"
  done
  say ""
  say "  ${D}Fill them in, or tell your AI:${N} ${B}Read PROMPT.md and do what it says.${N}"
  say ""
  exit 1
fi
case "$choice" in ""|claude|agents|both) ;; *) fail "Unknown --for value: $choice (use claude, agents or both)" ;; esac
case "$project" in ""|new|existing) ;; *) fail "Unknown --project value: $project (use new or existing)" ;; esac
case "$prompt" in ""|yes|no) ;; *) fail "Unknown --prompt value: $prompt (use yes or no)" ;; esac
case "$gfy_flag" in ""|yes|no) ;; *) fail "Unknown --graphify value: $gfy_flag (use yes or no)" ;; esac
case "$skills_flag" in ""|yes|no) ;; *) fail "Unknown --skills value: $skills_flag (use yes or no)" ;; esac
# A pinned version downloads that release; "1.0.0" and "v1.0.0" both work.
want_version="${want_version#v}"
if [ -n "$want_version" ]; then
  case "$want_version" in
    *[!0-9.]*|.*|*.|*..*) fail "Unknown --version value: $want_version (use a release number like 1.0.0)" ;;
  esac
  archive="$repo/archive/refs/tags/v$want_version.tar.gz"
fi
show_version="${want_version:-$kit_version}"

# Empty folder (ignoring .git) means a new project.
detected=existing
[ -z "$(find "$target" -mindepth 1 -maxdepth 1 ! -name .git -print -quit)" ] && detected=new
# Update mode: guess the installed version from the folders, and keep PROMPT.md as it was.
installed=3
[ -d "$target/.claude" ] && [ ! -d "$target/.agents" ] && installed=1
[ ! -d "$target/.claude" ] && [ -d "$target/.agents" ] && installed=2
if [ -n "$update" ]; then
  project=existing
  if [ -z "$prompt" ]; then if [ -e "$target/PROMPT.md" ]; then prompt=yes; else prompt=no; fi; fi
fi

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
  [ -n "$ansi" ] && printf '\033[?25h'
  if [ -n "$menus" ]; then stty "$old_stty" 2>/dev/null <&3 || true; fi
  [ -n "${tmp:-}" ] && rm -rf "$tmp"
  [ -n "$step_log" ] && rm -f "$step_log"
  return 0
}
trap cleanup EXIT
trap 'printf "\n\n  %s%s%s Cancelled. Files already copied stay; run again to finish.\n\n" "$Y" "$DOT" "$N"; exit 130' INT

# barfmt <progress in thousandths of a step> <total steps>: sets $barout to the colored bar and percent.
barfmt() {
  local w=28 t=$(( $2 > 0 ? $2 : 1 )) fill pct on="" off="" i
  fill=$(( $1 * w / (t * 1000) )); pct=$(( $1 * 100 / (t * 1000) ))
  for ((i = 0; i < w; i++)); do if [ $i -lt $fill ]; then on+="$FULL"; else off+="$EMPTY"; fi; done
  barout="$A$on$N$D$off$N $(printf '%3d%%' "$pct")"
}

# progress <done> <total>: one redrawn line "Installing [bar] 52% 13/25" (nothing without ANSI).
# The short pause per file only makes the bar visible; the copy itself takes a blink.
progress() {
  [ -n "$ansi" ] || return 0
  barfmt $(( $1 * 1000 )) "$2"
  printf '\r  %s%s%s Installing  %s  %s%d/%d%s' "$A" "${SPIN[$1 % ${#SPIN[@]}]}" "$N" "$barout" "$D" "$1" "$2" "$N"
  sleep 0.015
}

# spin "<text>" <pid>: animated line until the process ends (plain line without ANSI).
# When $bar_total is set (steps in the current group, $bar_done finished) it also shows the progress bar.
# The running step creeps toward its end but never reaches it: we cannot know how long it takes.
bar_done=0; bar_total=0
spin() {
  if [ -z "$ansi" ]; then printf '  %s %s...\n' "$DOT" "$1"; return; fi
  local i=0 part=""
  printf '\033[?25l'
  while kill -0 "$2" 2>/dev/null; do
    part=""
    if [ "$bar_total" -gt 0 ]; then
      barfmt $(( bar_done * 1000 + 1000 - 100000 / (100 + i) )) "$bar_total"
      part=" $barout  $D$bar_done/$bar_total$N"
    fi
    printf '\r\033[2K  %s%s%s %s%s %s(%ds)%s' "$A" "${SPIN[i % ${#SPIN[@]}]}" "$N" "$1" "$part" "$D" $((i / 10)) "$N"
    i=$((i + 1)); sleep 0.1
  done
  printf '\r\033[2K\033[?25h'
}

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

# ---------- the kit's own files: this checkout, or a download of main / the pinned release ----------
kit_root=""; kit_src=""
fetch_kit() {
  [ -n "$kit_root" ] && return 0
  if [ -z "$want_version" ] && [ -n "$script_dir" ] && [ -d "$script_dir/template" ]; then
    kit_root="$script_dir"; kit_src=local; return 0
  fi
  tmp="$(mktemp -d)"
  ( curl -fsSL "$archive" 2>/dev/null | tar -xz -C "$tmp" 2>/dev/null ) & local dl=$!   # errors: own message below
  spin "Downloading template from GitHub" "$dl"
  if ! wait "$dl"; then
    [ -n "$want_version" ] && fail "Version $want_version not found. See $repo/releases"
    fail "Could not download the template. Check your internet connection."
  fi
  kit_root="$(find "$tmp" -mindepth 1 -maxdepth 1 -type d | head -1)"
  [ -d "$kit_root/template" ] || fail "Download incomplete: template/ not found"
  kit_src=downloaded
}

# ---------- welcome ----------
w=50
say ""
say "  ${A}${TL}$(rule $w)${TR}${N}"
vtext="v$show_version"
printf '  %s%s%s %s%s%s %sWelcome to agents-md-kit%s %s%s%s%*s%s%s%s\n' "$A" "$V" "$N" "$A" "$STAR" "$N" "$B" "$N" "$D" "$vtext" "$N" \
  $((w - 28 - ${#vtext})) "" "$A" "$V" "$N"
printf '  %s%s%s%*s%s%s%s\n' "$A" "$V" "$N" $w "" "$A" "$V" "$N"
printf '  %s%s%s   %sAI agent setup for Claude Code and Codex%s%*s%s%s%s\n' "$A" "$V" "$N" "$D" "$N" $((w - 43)) "" "$A" "$V" "$N"
say "  ${A}${BL}$(rule $w)${BR}${N}"
say ""
show_target="$target"; [ -n "${HOME:-}" ] && case "$target" in "$HOME"*) show_target="~${target#"$HOME"}" ;; esac
say "  ${D}Folder: $show_target${N}"
[ -n "$update" ] && say "  ${A}Update mode:${N} ${D}missing files are added; newer kit files are saved as *.kit-new${N}"
[ -n "$dry" ] && say "  ${A}Dry run:${N} ${D}nothing will be changed, you only see what would happen${N}"
[ -n "$menus" ] && say "  ${D}Pick with arrow keys. Nothing is overwritten.${N}" || say "  ${D}Nothing is overwritten.${N}"
[ -n "$can_ask" ] && [ -z "$menus" ] || say ""   # typed questions bring their own blank line

if [ -z "$choice" ]; then
  if [ -n "$can_ask" ]; then
    def=3; [ -n "$update" ] && def=$installed
    choose "Which AI agents will you use in this project?" "$def" \
      "Claude Code only|CLAUDE.md + .claude/" \
      "Codex / other agents|AGENTS.md + .agents/" \
      "Both (recommended)|CLAUDE.md + AGENTS.md + both folders"
    case "$answer" in 1) choice=claude ;; 2) choice=agents ;; *) choice=both ;; esac
  elif [ -n "$update" ]; then
    case "$installed" in 1) choice=claude ;; 2) choice=agents ;; *) choice=both ;; esac
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
if [ -n "$update" ]; then
  prompt_note="kept as it was"
elif [ "$project" = existing ]; then
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
done_line "PROMPT.md" "$prompt" "$prompt_note"

# ---------- find or download the template ----------
say ""
fetch_kit
template="$kit_root/template/$choice"
[ -d "$template" ] || fail "Download incomplete: template/$choice not found"
if [ "$kit_src" = local ]; then done_line "Template" "local copy"
elif [ -n "$want_version" ]; then done_line "Template" "downloaded" "release v$want_version"
else done_line "Template" "downloaded" "latest from GitHub"; fi

# yesno "<question>" "<hint for yes>" "<hint for no>": sets $answer to yes or no (default no)
yesno() {
  if [ -n "$menus" ]; then
    choose "$1" 2 "Yes|$2" "No|$3"
    case "$answer" in 1) answer=yes ;; *) answer=no ;; esac
  else
    say ""; say "  ${D}$2${N}"
    ask "$1 [y/N]:" n y n yes no
    case "$answer" in y|yes) answer=yes ;; *) answer=no ;; esac
  fi
}

# Ask before copying so PROMPT.md reflects the answer.
if [ -z "$dry" ] && [ -z "$gfy_flag" ] && [ -n "$can_ask" ] && [ ! -f "$target/graphify-out/graph.json" ]; then
  yesno "Set up graphify for this project?" \
    "installs graphify if needed and builds the code graph" "install it later: see docs/guides/setup.md"
  gfy_flag="$answer"
fi

# ---------- copy ----------
copied=0; same=0; added=(); skipped=(); newer=(); gi_status=""; gi_added=()
todo=()
while IFS= read -r -d '' f; do
  [ "${f#"$template"/}" = "PROMPT.md" ] && [ "$prompt" = no ] && continue
  todo+=("$f")
done < <(find "$template" -type f -print0 | sort -z)
[ -n "$ansi" ] && printf '\033[?25l'
for ((k = 0; k < ${#todo[@]}; k++)); do
  progress "$k" "${#todo[@]}"
  f="${todo[k]}"
  rel="${f#"$template"/}"
  dest="$target/$rel"
  if [ "$rel" = PROMPT.md ] && [ "$gfy_flag" != yes ]; then
    [ -n "${tmp:-}" ] || tmp="$(mktemp -d)"
    sed 's/ If graphify-out\/graph[.]json exists,[^[:cntrl:]]*//' "$f" > "$tmp/PROMPT.md"
    f="$tmp/PROMPT.md"
  fi
  if [ "$rel" = ".gitignore" ] && [ -e "$dest" ]; then
    gi_status="checked"
    while IFS= read -r line || [ -n "$line" ]; do
      line="${line%$'\r'}"; line="$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
      case "$line" in ''|'#'*) continue ;; esac
      tr -d '\r' < "$dest" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | grep -qxF -- "$line" || gi_added+=("$line")
    done < "$f"
    if [ ${#gi_added[@]} -gt 0 ] && [ -z "$dry" ]; then
      nl=$'\n'; [ "$(tr -cd '\r' < "$dest" | wc -c)" -gt 0 ] && nl=$'\r\n'
      { [ -s "$dest" ] && [ "$(tail -c1 "$dest")" != "" ] && printf '%s' "$nl"
        printf '%s# Added by agents-md-kit%s' "$nl" "$nl"
        for l in "${gi_added[@]}"; do printf '%s%s' "$l" "$nl"; done; } >> "$dest"
    fi
    continue
  fi
  if [ -e "$dest" ]; then
    # Same content (line endings ignored): nothing to do. Different: keep yours;
    # in update mode also save the kit's version beside it as .kit-new.
    if [ -f "$dest" ] && [ "$(tr -d '\r' < "$f")" = "$(tr -d '\r' < "$dest")" ]; then same=$((same + 1))
    elif [ -n "$update" ] && [ -f "$dest" ]; then
      [ -n "$dry" ] || cp "$f" "$dest.kit-new"
      newer+=("$rel")
    else skipped+=("$rel"); fi
    continue
  fi
  if [ -z "$dry" ]; then
    mkdir -p "$(dirname "$dest")"
    cp "$f" "$dest"
  fi
  copied=$((copied + 1)); added+=("$rel")
done
progress "${#todo[@]}" "${#todo[@]}"
[ -n "$ansi" ] && printf '\r\033[2K\033[?25h'

# ---------- result: a small tree of what changed ----------
if [ -n "$dry" ]; then
  done_line "Dry run" "nothing was changed" "this is what would happen"
  done_line "Would copy" "$(files "$copied")"
else
  done_line "Copied" "$(files "$copied")"
fi
rows=()   # each row: "<text>" already colored
if [ $copied -gt 0 ]; then
  # Group added files by top-level entry: folders show a count, files show their name.
  while read -r cnt top; do
    if [ "${top%/}" != "$top" ]; then rows+=("${G}+${N} $(printf '%-12s' "$top") ${D}$(files "$cnt")${N}")
    else rows+=("${G}+${N} $top"); fi
  done < <(printf '%s\n' "${added[@]}" | awk -F/ '{ print (NF > 1 ? $1 "/" : $1) }' | sort | uniq -c)
fi
if [ -n "$gi_status" ]; then
  if [ ${#gi_added[@]} -gt 0 ]; then
    rows+=("${G}~${N} .gitignore   ${D}kept, $([ -n "$dry" ] && echo "would add" || echo "added"): $(IFS=,; echo "${gi_added[*]}" | sed 's/,/, /g')${N}")
  else
    rows+=("${D}= .gitignore   kept, nothing to add${N}")
  fi
fi
for s in "${skipped[@]+"${skipped[@]}"}"; do
  rows+=("${Y}!${N} $(printf '%-12s' "$s") ${Y}already existed, left untouched${N}")
done
for s in "${newer[@]+"${newer[@]}"}"; do
  rows+=("${A}${UP}${N} $(printf '%-12s' "$s") ${A}newer kit version $([ -n "$dry" ] && echo "would be saved" || echo "saved") as $s.kit-new${N}")
done
[ "$same" -gt 0 ] && rows+=("${D}= $(files "$same") already up to date${N}")
for ((i = 0; i < ${#rows[@]}; i++)); do
  if [ $i -eq $((${#rows[@]} - 1)) ]; then br="$ELB"; else br="$TEE"; fi
  say "    ${D}${br}${N} ${rows[i]}"
done
[ ${#skipped[@]} -gt 0 ] && say "      ${D}Files marked ! were kept as they are. Merge the kit's version by hand if you want it.${N}"

main="CLAUDE.md"; [ "$choice" = agents ] && main="AGENTS.md"
case "$choice" in claude) anchor="claude-code-only-claude" ;; agents) anchor="codex-or-other-agents-agents" ;; both) anchor="both-both" ;; esac
prompt_url="$repo/blob/main/PROMPTS.md#$anchor"
prompt_skipped=""; for s in "${skipped[@]+"${skipped[@]}"}"; do [ "$s" = "PROMPT.md" ] && prompt_skipped=1; done

# run_step "<text>" <command...>: runs it in the project folder with a spinner; output goes to $step_log
run_step() {
  local text="$1"; shift
  rm -f "$step_log"; step_log="$(mktemp)"
  ( cd "$target" && "$@" ) >"$step_log" 2>&1 & local pid=$!
  spin "$text" "$pid"
  local rc=0; wait "$pid" || rc=$?
  [ "$bar_total" -gt 0 ] && bar_done=$((bar_done + 1))
  return $rc
}

# ---------- graphify (optional): asks first, installs or builds only with a yes ----------
# graphify writes graphify-out/graph.json, its report and its own graph.html. The kit does not
# render, replace or restyle that page: the default one is what you get.
gfy_state=""   # handled: done or declined | skipped: not possible | empty: nobody was asked

graphify_step() {
  local inst=() b nodes
  if [ -f "$target/graphify-out/graph.json" ]; then
    done_line "Graphify" "graph found" "the AI will query graphify-out/ first"; gfy_state=handled; return 0
  fi
  [ -z "$gfy_flag" ] && return 0   # nobody was asked: the next steps mention it
  if [ "$gfy_flag" = no ]; then
    done_line "Graphify" "skipped" "install or build later: see docs/guides/setup.md"; gfy_state=handled; return 0
  fi
  if ! command -v graphify >/dev/null 2>&1; then
    if command -v uv >/dev/null 2>&1; then inst=(uv tool install graphifyy)
    elif command -v pipx >/dev/null 2>&1; then inst=(pipx install graphifyy)
    elif command -v python3 >/dev/null 2>&1; then inst=(python3 -m pip install --user graphifyy)
    elif command -v python >/dev/null 2>&1; then inst=(python -m pip install --user graphifyy); fi
    if [ ${#inst[@]} -eq 0 ]; then
      done_line "Graphify" "not installed" "needs uv, pipx or Python. See docs/guides/setup.md"; gfy_state=skipped; return 0
    fi
    bar_done=0; bar_total=2   # install, then build
    if ! run_step "Installing graphify" "${inst[@]}"; then
      bar_total=0
      done_line "Graphify" "install failed" "see docs/guides/setup.md"
      tail -3 "$step_log" | sed "s/^/        ${D}/; s/\$/${N}/"; gfy_state=skipped; return 0
    fi
    # a new tool may sit in a folder this terminal does not know yet
    if ! command -v graphify >/dev/null 2>&1; then
      for b in "$(uv tool dir --bin 2>/dev/null || true)" "$HOME/.local/bin"; do
        if [ -n "$b" ] && { [ -x "$b/graphify" ] || [ -x "$b/graphify.exe" ]; }; then PATH="$b:$PATH"; break; fi
      done
    fi
    if ! command -v graphify >/dev/null 2>&1; then
      done_line "Graphify" "installed" "open a new terminal, then run: graphify update ."; gfy_state=handled; return 0
    fi
    done_line "Graphify" "installed" "official package: graphifyy"
  else
    done_line "Graphify" "found" "already installed"
  fi
  gfy_state=handled
  [ "$bar_total" -eq 2 ] || { bar_done=0; bar_total=1; }   # graphify was already there: one step
  if run_step "Building the code graph" graphify update .; then
    bar_total=0
    nodes="$(grep -o 'Rebuilt: [^[]*' "$step_log" | tail -1 | sed 's/^Rebuilt: //' || true)"
    done_line "Graph" "built" "${nodes:+$nodes $SEP }graphify-out/"
    say "    ${D}${ELB} open graphify-out/graph.html in a browser: graphify's own view${N}"
    say "    ${D}${ELB} commit graphify-out/ to share it, or add it to .gitignore to keep it local${N}"
  else
    bar_total=0
    done_line "Graph" "build failed" "run graphify update . yourself to see why"
    tail -3 "$step_log" | sed "s/^/        ${D}/; s/\$/${N}/"
  fi
}
if [ -z "$dry" ]; then graphify_step; fi

# ---------- primary skills (optional): Superpowers, Ponytail, Caveman, unslop from their official repos ----------
# Asks first (default No). Claude Code gets the plugins (they bring the automatic modes): installed with
# claude plugin install, or only updated when already installed. Codex gets the plain skills (npx skills add,
# which fetches the latest). A skill that is already in ~/.claude/skills is not installed again as a plugin.
skills_state=""   # handled: done or declined | empty: nobody was asked
# name | plugin id | official repo | a skill the plugin contains (to spot a copy installed the other way)
skill_list=("superpowers|superpowers@superpowers-dev|obra/superpowers|brainstorming" "ponytail|ponytail@ponytail|DietrichGebert/ponytail|ponytail" "caveman|caveman@caveman|JuliusBrussee/caveman|caveman" "unslop|unslop@heydamir|heydamir/unslop|unslop")

skills_step() {
  local ans item name id repo marker rest hook_status installed="" ok=0 ok_claude=0 bad=0 have_claude="" have_npx=""
  [ -z "$skills_flag" ] && [ -z "$can_ask" ] && return 0   # nobody to ask: the next steps mention it
  if [ "$skills_flag" = no ]; then
    done_line "Skills" "skipped" "install later: see docs/guides/setup.md"; skills_state=handled; return 0
  fi
  ans="$skills_flag"
  if [ -z "$ans" ]; then
    yesno "Install or update the primary skills (Superpowers, Ponytail, Caveman, unslop)?" \
      "official repos. For Codex, also adds a Caveman startup hook to this project" "install later: see docs/guides/setup.md"
    ans="$answer"
  fi
  skills_state=handled
  if [ "$ans" != yes ]; then
    done_line "Skills" "skipped" "install later: see docs/guides/setup.md"; return 0
  fi
  [ "$choice" != agents ] && command -v claude >/dev/null 2>&1 && have_claude=1
  [ "$choice" != claude ] && command -v npx >/dev/null 2>&1 && have_npx=1
  [ "$choice" != agents ] && [ -z "$have_claude" ] && done_line "Claude Code" "skipped" "the claude command was not found. See docs/guides/setup.md"
  [ "$choice" != claude ] && [ -z "$have_npx" ] && done_line "Codex" "skipped" "needs Node.js (npx). See docs/guides/setup.md"
  bar_done=0; bar_total=0
  [ -n "$have_claude" ] && bar_total=$((bar_total + ${#skill_list[@]}))
  [ -n "$have_npx" ] && bar_total=$((bar_total + ${#skill_list[@]}))
  if [ -n "$have_claude" ]; then
    installed="$(claude plugin list 2>/dev/null | tr -d '\r' || true)"
    for item in "${skill_list[@]}"; do
      name="${item%%|*}"; rest="${item#*|}"; id="${rest%%|*}"; rest="${rest#*|}"; repo="${rest%%|*}"; marker="${rest#*|}"
      if printf '%s\n' "$installed" | grep -qE "[[:space:]]${id}\$"; then
        claude plugin marketplace update "${id#*@}" >/dev/null 2>&1 || true
        if run_step "Updating $name" claude plugin update "$id" -y; then done_line "$name" "up to date" "Claude Code plugin"; ok=$((ok + 1)); ok_claude=$((ok_claude + 1))
        else done_line "$name" "update failed" "run: claude plugin update $id"; bad=$((bad + 1)); fi
      elif [ -e "$HOME/.claude/skills/$marker" ]; then
        bar_done=$((bar_done + 1))
        done_line "$name" "skipped" "already in ~/.claude/skills (installed as skills, not a plugin)"
      else
        if run_step "Installing $name" claude plugin install "$name" --marketplace "$repo" -y; then done_line "$name" "installed" "Claude Code plugin from $repo"; ok=$((ok + 1)); ok_claude=$((ok_claude + 1))
        else done_line "$name" "install failed" "run: claude plugin install $name --marketplace $repo"; bad=$((bad + 1)); fi
      fi
    done
  fi
  if [ -n "$have_npx" ]; then
    for item in "${skill_list[@]}"; do
      name="${item%%|*}"; rest="${item#*|}"; rest="${rest#*|}"; repo="${rest%%|*}"
      if run_step "Installing $name for Codex" npx --yes skills add "$repo" --skill '*' --agent codex --global -y; then
        done_line "$name" "installed or updated" "Codex skills $SEP $repo"; ok=$((ok + 1))
        if [ "$name" = caveman ] && [ -f "$kit_root/scripts/caveman-hook.cjs" ]; then
          if hook_status="$(node "$kit_root/scripts/caveman-hook.cjs" "$target")"; then
            if [ "$hook_status" = merge ]; then
              done_line "Caveman startup" "merge needed" "add the hook from .codex/hooks.json.kit-new, then trust it in Codex /hooks"
            else
              done_line "Caveman startup" "configured" "review and trust the project hook in Codex /hooks, then start a new session"
            fi
          else
            done_line "Caveman startup" "setup failed" "check Node.js and .codex/hooks.json, then rerun the installer"
          fi
        fi
      else
        done_line "$name" "failed" "run: npx skills add $repo --agent codex"; bad=$((bad + 1))
      fi
    done
  fi
  bar_total=0
  [ "$bad" -gt 0 ] && tail -3 "$step_log" | sed "s/^/        ${D}/; s/\$/${N}/"
  [ "$ok_claude" -gt 0 ] && say "    ${D}${ELB} restart Claude Code to load new or updated plugins${N}"
  return 0
}
if [ -z "$dry" ]; then skills_step; fi

# ---------- next steps ----------
say ""
if [ -n "$dry" ]; then
  say "  ${A}${STAR}${N} ${B}Dry run finished.${N} Nothing was changed."
  say "    Run the same command without ${B}--dry-run${N} to do it for real."
  say ""
  exit 0
fi
say "  ${A}${STAR}${N} ${B}Next steps${N}"
say ""
if [ -n "$update" ]; then
  if [ ${#newer[@]} -gt 0 ]; then
    say "    ${A}1${N}  Merge each ${B}*.kit-new${N} file into the file next to it, then delete the .kit-new. Or tell your AI:"
    say "       ${A}${PTR}${N} ${B}Merge every *.kit-new file into the file next to it. Keep my project details. Then delete the .kit-new files.${N}"
  else
    say "    ${A}1${N}  Nothing to merge. Your kit files match the latest version."
  fi
  say "    ${A}2${N}  New skills or plugins? Check ${B}docs/guides/setup.md${N}"
  say ""
  say "  ${G}${DOT}${N} ${B}Done.${N} ${D}Guide: $repo/blob/main/GUIDE.md${N}"
  say ""
  exit 0
fi
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
if [ -n "$skills_state" ]; then say "    ${A}2${N}  Other skills (design, commit): ${B}docs/guides/setup.md${N}"
else say "    ${A}2${N}  Install the skills: ${B}docs/guides/setup.md${N}"; fi
if [ "$choice" = agents ]; then
  say "    ${A}3${N}  Start your agent and ask it to read ${B}AGENTS.md${N}"
else
  say "    ${A}3${N}  In Claude Code, run ${B}/memory${N} and ${B}/skills${N} to check what loads"
fi
[ -z "$gfy_state" ] && say "    ${D}Optional: build a code graph the AI can query: graphify update .  (see docs/guides/setup.md)${N}"
say "    ${D}See which placeholders are left any time: add${N} ${B}--check${N} ${D}to the install command${N}"
say ""
say "  ${G}${DOT}${N} ${B}Done.${N} ${D}Guide: $repo/blob/main/GUIDE.md${N}"
say ""
