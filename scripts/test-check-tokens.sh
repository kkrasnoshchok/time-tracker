#!/usr/bin/env bash
# Tests for scripts/check-tokens.sh against fixtures (no real App/ files involved).
# Usage: scripts/test-check-tokens.sh
# TS analogy: a tiny test runner; each `expect` is an `expect(...).toBe(...)` call.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
GUARD="$HERE/check-tokens.sh"
ROOT="$HERE/fixtures/token-guard"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

FAILED=0
OUT=""
CODE=0

# run <list-content>: writes the list file, runs the guard, fills OUT (stdout+stderr) and CODE.
run() {
  printf '%s\n' "$1" > "$TMP/list.txt"
  CODE=0
  OUT="$("$GUARD" --root "$ROOT" --paths "$TMP/list.txt" 2>&1)" || CODE=$?
}

# expect <name> <expected-code> [expected-substring...]
expect() {
  local name="$1" code="$2" ok=1
  shift 2
  if [ "$CODE" -ne "$code" ]; then ok=0; fi
  local needle
  for needle in "$@"; do
    case "$OUT" in *"$needle"*) ;; *) ok=0 ;; esac
  done
  if [ "$ok" -eq 1 ]; then
    echo "PASS $name"
  else
    echo "FAIL $name (exit $CODE, expected $code)"
    echo "$OUT" | sed 's/^/     | /'
    FAILED=1
  fi
}

if [ ! -x "$GUARD" ]; then
  echo "FAIL check-tokens.sh is missing or not executable: $GUARD"
  exit 1
fi

run "clean";        expect "clean tree"            0
[ -z "$OUT" ] || { echo "FAIL clean tree prints nothing"; FAILED=1; }
run "bad-hex";      expect "hex literal"           1 "bad-hex/Sample.swift:3: "
run "bad-named";    expect "named colors"          1 "bad-named/Sample.swift:3: " "bad-named/Sample.swift:4: " "bad-named/Sample.swift:5: " "bad-named/Sample.swift:6: " "bad-named/Sample.swift:7: " "bad-named/Sample.swift:8: "
run "bad-accent";   expect "accent color"          1 "bad-accent/Sample.swift:3: "
run "bad-font";     expect "ad-hoc font size"      1 "bad-font/Sample.swift:3: " "bad-font/Sample.swift:4: "
run "token-layer";  expect "token layer skipped"   0
run "nonexistent";  expect "missing path"          2 "nonexistent"
run "$(printf '# comment\n\n   \nclean\n# another')"
expect "comments and blanks ignored" 0
run "$(printf 'clean\nbad-hex')"; expect "several paths" 1 "bad-hex/Sample.swift:3: "
run "bad-font/Sample.swift";      expect "single file path" 1 "bad-font/Sample.swift:3: "

# Missing option value is a usage error (exit 2), not "violations found".
for opt in --paths --root; do
  CODE=0
  OUT="$("$GUARD" "$opt" 2>&1)" || CODE=$?
  expect "$opt without value" 2 "usage"
done

if [ "$FAILED" -ne 0 ]; then
  echo "SOME TESTS FAILED"
  exit 1
fi
echo "ALL TESTS PASSED"
