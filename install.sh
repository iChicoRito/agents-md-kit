#!/usr/bin/env bash
# agents-md-kit installer: copy the AI agent template into a project folder.
# Usage:
#   bash install.sh [target folder]                       (from a clone)
#   curl -fsSL https://raw.githubusercontent.com/iChicoRito/agents-md-kit/main/install.sh | bash
#   curl -fsSL .../install.sh | bash -s -- "path/to/project"
# Never overwrites: files that already exist are skipped and listed.
# Exception: an existing .gitignore is kept and only missing lines are added.
set -euo pipefail

archive="https://github.com/iChicoRito/agents-md-kit/archive/refs/heads/main.tar.gz"
target="${1:-$PWD}"
[ -d "$target" ] || { echo "Target folder not found: $target" >&2; exit 1; }
target="$(cd "$target" && pwd)"

# Use the template next to this script; if run through a pipe, download it.
script_dir=""
if [ -n "${BASH_SOURCE[0]:-}" ] && [ -f "${BASH_SOURCE[0]}" ]; then
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi
if [ -n "$script_dir" ] && [ -d "$script_dir/template" ]; then
  template="$script_dir/template"
else
  tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
  echo "Downloading template..."
  curl -fsSL "$archive" | tar -xz -C "$tmp"
  template="$(find "$tmp" -mindepth 2 -maxdepth 2 -type d -name template | head -1)"
  [ -d "$template" ] || { echo "Download failed: template folder not found" >&2; exit 1; }
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
echo "Next: fill the [PLACEHOLDERS] in CLAUDE.md and docs/. Skills setup: docs/guides/setup.md"
