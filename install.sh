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
choice=""; target="$PWD"
while [ $# -gt 0 ]; do
  case "$1" in
    --for) choice="${2:-}"; shift 2 ;;
    --for=*) choice="${1#--for=}"; shift ;;
    *) target="$1"; shift ;;
  esac
done
[ -d "$target" ] || { echo "Target folder not found: $target" >&2; exit 1; }
target="$(cd "$target" && pwd)"

# No choice given: ask on the terminal if there is one, else use "both".
if [ -z "$choice" ]; then
  if { exec 3</dev/tty; } 2>/dev/null; then
    echo "Which AI agents will you use in this project?"
    echo "  1) Claude Code only"
    echo "  2) Codex or other agents only"
    echo "  3) Both (default)"
    printf "Choose 1, 2 or 3: "
    read -r answer <&3 || answer=""
    exec 3<&-
  else
    answer=""
  fi
  case "$answer" in 1) choice=claude ;; 2) choice=agents ;; *) choice=both ;; esac
fi
case "$choice" in claude|agents|both) ;; *) echo "Unknown --for value: $choice (use claude, agents or both)" >&2; exit 1 ;; esac
echo "Installing for: $choice"

# Use the template next to this script; if run through a pipe, download it.
script_dir=""
if [ -n "${BASH_SOURCE[0]:-}" ] && [ -f "${BASH_SOURCE[0]}" ]; then
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi
if [ -n "$script_dir" ] && [ -d "$script_dir/template/$choice" ]; then
  template="$script_dir/template/$choice"
else
  tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
  echo "Downloading template..."
  curl -fsSL "$archive" | tar -xz -C "$tmp"
  template="$(find "$tmp" -mindepth 3 -maxdepth 3 -type d -path "*/template/$choice" | head -1)"
  [ -d "$template" ] || { echo "Download failed: template/$choice not found" >&2; exit 1; }
fi

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

echo "Copied $copied file(s) into $target"
if [ -n "$gi_status" ]; then
  if [ ${#gi_added[@]} -gt 0 ]; then
    echo "Updated existing .gitignore, added: $(IFS=,; echo "${gi_added[*]}" | sed 's/,/, /g')"
  else
    echo "Existing .gitignore already has all template lines"
  fi
fi
if [ ${#skipped[@]} -gt 0 ]; then
  echo "Skipped ${#skipped[@]} existing file(s), merge by hand:"
  printf '  %s\n' "${skipped[@]}"
fi
main="CLAUDE.md"; [ "$choice" = agents ] && main="AGENTS.md"
echo "Next: fill the [PLACEHOLDERS] in $main and docs/. Skills setup: docs/guides/setup.md"
