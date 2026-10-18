#!/usr/bin/env bash
# Runs the TimeTrackerCore tests with coverage and fails if any module folder is below the threshold.
# Usage: scripts/coverage.sh [threshold-percent]   (default 90)
set -euo pipefail

THRESHOLD="${1:-90}"
PACKAGE="$(cd "$(dirname "$0")/.." && pwd)/Packages/TimeTrackerCore"

swift test --package-path "$PACKAGE" --enable-code-coverage > /dev/null
REPORT="$(swift test --package-path "$PACKAGE" --show-codecov-path 2>/dev/null | tail -1)"

python3 - "$REPORT" "$THRESHOLD" <<'PY'
import collections, json, sys

report, threshold = sys.argv[1], float(sys.argv[2])
files = json.load(open(report))["data"][0]["files"]
totals = collections.defaultdict(lambda: [0, 0])
for entry in files:
    marker = "/Sources/TimeTrackerCore/"
    if marker not in entry["filename"]:
        continue
    folder = entry["filename"].split(marker)[1].split("/")[0]
    lines = entry["summary"]["lines"]
    totals[folder][0] += lines["covered"]
    totals[folder][1] += lines["count"]

failed = False
print(f"{'module':10s} {'lines':>11s} {'cover':>7s}")
for folder, (covered, count) in sorted(totals.items()):
    percent = 100.0 * covered / count if count else 100.0
    mark = "" if percent >= threshold else "  <-- below threshold"
    failed |= percent < threshold
    print(f"{folder:10s} {covered:5d}/{count:<5d} {percent:6.1f}%{mark}")
sys.exit(1 if failed else 0)
PY
