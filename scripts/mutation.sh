#!/usr/bin/env bash
# Mutation testing with Muter (brew install muter-mutation-testing/formulae/muter).
# Muter 16 corrupts two kinds of files, so they are skipped:
#   - files with non-ASCII text (it counts byte offsets), e.g. Cyrillic strings;
#   - files with typed throws followed by a return type, `throws(E) -> T` (it truncates the signature);
#   - files with multi-line string literals (it rewrites their contents).
# Usage: scripts/mutation.sh [report-file]    (default: /tmp/time-tracker-muter.txt)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PACKAGE="$ROOT/Packages/TimeTrackerCore"
REPORT="${1:-/tmp/time-tracker-muter.txt}"

# Muter copies the whole package; a stale .build or old copy makes its baseline run fail.
rm -rf "$PACKAGE/.build" "$PACKAGE/../TimeTrackerCore_mutated" "$PACKAGE/muter_logs"

cd "$PACKAGE"
ARGS=()
while IFS= read -r file; do
    if LC_ALL=C grep -q '[^[:space:] -~]' "$file"; then
        echo "skipping (non-ASCII): $file" >&2
    elif grep -qE 'throws\([A-Za-z]+\)[[:space:]]*->' "$file"; then
        echo "skipping (typed throws with return type): $file" >&2
    elif grep -q '"""' "$file"; then
        echo "skipping (multi-line string): $file" >&2
    else
        ARGS+=(--files-to-mutate "$file")
    fi
done < <(find Sources -name '*.swift' | sort)

muter run --skip-update-check --skip-coverage -f plain -o "$REPORT" "${ARGS[@]}"
rm -rf "$PACKAGE/../TimeTrackerCore_mutated" "$PACKAGE/.build"
echo "Report: $REPORT"
