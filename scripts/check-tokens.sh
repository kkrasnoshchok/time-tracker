#!/usr/bin/env bash
# Token guard: fails if migrated App/ files bypass the design tokens
# (hex literals, system accent / .red / .blue / .orange, ad-hoc font sizes).
# Usage: scripts/check-tokens.sh [--paths <list-file>] [--root <dir>]
# Exit codes: 0 clean, 1 violations found, 2 usage or missing path.
#
# TS analogy: an ESLint `no-restricted-syntax` rule run in CI. The list file
# (scripts/token-guard-paths.txt) is the rule's `files` glob; each epic adds
# the files it migrated, so progress is enforced rather than remembered.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
LIST="$SCRIPT_DIR/token-guard-paths.txt"

while [ $# -gt 0 ]; do
  case "$1" in
    --paths|--root)
      if [ $# -lt 2 ]; then
        echo "check-tokens: $1 needs a value" >&2
        echo "usage: check-tokens.sh [--paths <file>] [--root <dir>]" >&2
        exit 2
      fi
      if [ "$1" = "--paths" ]; then LIST="$2"; else ROOT="$2"; fi
      shift 2 ;;
    *) echo "usage: check-tokens.sh [--paths <file>] [--root <dir>]" >&2; exit 2 ;;
  esac
done

[ -f "$LIST" ] || { echo "check-tokens: list file not found: $LIST" >&2; exit 2; }
[ -d "$ROOT" ] || { echo "check-tokens: root not found: $ROOT" >&2; exit 2; }
LIST="$(cd "$(dirname "$LIST")" && pwd)/$(basename "$LIST")"
cd "$ROOT"

# Forbidden patterns (extended regex). `rgb.red` and `size: size` must not match:
# an implicit `.red` needs a non-identifier character before the dot.
NOT_ID='(^|[^A-Za-z0-9_])'
END_ID='([^A-Za-z0-9_]|$)'
PATTERNS=(
  -e '#[0-9A-Fa-f]{6}'
  -e "${NOT_ID}\\.(red|blue|orange)${END_ID}"
  -e "Color\\.(red|blue|orange)${END_ID}"
  -e 'Color\.accentColor'
  -e '\.font\(\.system\(size:[[:space:]]*[0-9]'
)

# Read the list: strip comments and blank lines, collect entries.
ENTRIES=()
while IFS= read -r line || [ -n "$line" ]; do
  line="${line%%#*}"
  line="$(printf '%s' "$line" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
  [ -n "$line" ] && ENTRIES+=("$line")
done < "$LIST"

# A missing listed path is an error, checked before scanning anything.
MISSING=0
for entry in ${ENTRIES[@]+"${ENTRIES[@]}"}; do
  if [ ! -e "$entry" ]; then
    echo "check-tokens: listed path does not exist: $entry" >&2
    MISSING=1
  fi
done
[ "$MISSING" -eq 0 ] || exit 2

FOUND=0
for entry in ${ENTRIES[@]+"${ENTRIES[@]}"}; do
  while IFS= read -r file; do
    # The token layer is the one place literals are allowed.
    case "$(basename "$file")" in ColorToken.swift|Typography.swift) continue ;; esac
    hits="$(grep -nE "${PATTERNS[@]}" "$file" || true)"
    if [ -n "$hits" ]; then
      FOUND=1
      printf '%s\n' "$hits" | sed -E "s|^([0-9]+):[[:space:]]*|$file:\\1: |"
    fi
  done < <(find "$entry" -type f -name '*.swift' | LC_ALL=C sort)
done

exit "$FOUND"
