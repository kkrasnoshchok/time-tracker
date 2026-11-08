---
title: 'Token guard script'
type: 'feature'
created: '2026-11-02'
status: 'done'
baseline_commit: '0e551b8e4388dd88422c47b0a10efa5499c4658b'
route: 'dispatch'
review_loop_iteration: 0
context:
  - '{project-root}/_bmad-output/implementation-artifacts/epic-1-context.md'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** The rule "outside the token layer `App/` has no hex literals, system accent/`.red`/`.blue`, or ad-hoc font sizes" is only remembered, so a later view can quietly bypass the tokens.

**Approach:** Add `scripts/check-tokens.sh`, which scans a list of migrated paths and prints `file:line` for each hit, exiting non-zero. The list starts with the already migrated files and each later epic extends it. Story 1.6 of `_bmad-output/planning-artifacts/epics.md`.

## Boundaries & Constraints

**Always:** Bash 3.2-compatible (macOS default), `set -euo pipefail`, no dependencies beyond `grep`. Forbidden: hex literal `#` + 6 hex digits, implicit or `Color.`-qualified `.red`, `.blue`, `.orange`, `Color.accentColor`, `.font(.system(size:` followed by a digit. The list lives in `scripts/token-guard-paths.txt`: one path per line (file or directory, relative to the repo root), `#` comments and blank lines ignored, initial content `App/Design`. The token layer (`ColorToken.swift`, `Typography.swift`) is always skipped even inside a listed directory. Output is `path:line: matched text`, a missing listed path is an error (exit 2), a violation is exit 1, clean is exit 0. Optional arguments: `--paths <file>` and `--root <dir>` so tests can run on fixtures. The list is documented in `CLAUDE.md` Commands (Russian, like the rest of the file). Short comments explain shell concepts via TypeScript/React analogies (lint rule as CI check).

**Never:** No edits to `App/` Swift files, `Packages/`, `project.yml` or swiftlint config. Do not list unmigrated files (`Journal`, `Palette`, `MenuBar`, `Settings`, `Support/CategoryTone.swift`) — they still hold violations that later epics fix. No `sleep` or network in tests. No git hooks or CI wiring.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Clean tree | real list (`App/Design`) | no output, exit 0 | N/A |
| Hex literal | `Color(hex: "#B4705A")` on line 3 | `…/Bad.swift:3: …`, exit 1 | N/A |
| Named colors | `.red`, `Color.blue`, `.orange` | each line reported, exit 1 | N/A |
| Accent | `Color.accentColor` | reported, exit 1 | N/A |
| Font size | `.font(.system(size: 22))` | reported, exit 1 | N/A |
| Property access | `rgb.red`, `size: size` | not reported | N/A |
| Token layer | hex in `ColorToken.swift` in a listed dir | skipped, exit 0 | N/A |
| Missing path | list names a nonexistent path | message on stderr, exit 2 | exit 2 |
| Comments | `#` line and blank lines in list | ignored | N/A |

</frozen-after-approval>

## Code Map

- `scripts/coverage.sh` -- style reference for existing scripts (header comment, usage line, `set -euo pipefail`).
- `App/Design/ColorToken.swift`, `App/Design/Typography.swift` -- the only `App/Design` files with literals; the always-skipped token layer.
- `App/Design/*` (other files) -- already clean, so the initial list entry `App/Design` exits 0.
- `App/Journal`, `App/Palette`, `App/MenuBar`, `App/Settings`, `App/Journal/CategoriesView.swift` -- hold `.red`, `.orange`, `Color.accentColor`, `.system(size: 22)`; stay off the list.
- `CLAUDE.md` -- add the script to the `## Команды` block and one line about the list file.

## Tasks & Acceptance

**Execution:**
- [x] `scripts/test-check-tokens.sh` and `scripts/fixtures/token-guard/{clean,bad-hex,bad-named,bad-accent,bad-font}/Sample.swift` plus a `ColorToken.swift` fixture -- run the matrix against `--root`/`--paths` and assert exit codes and `file:line` output; run it with no `check-tokens.sh` and see FAIL -- red first
- [x] `scripts/check-tokens.sh` -- implement scan, token-layer skip, exit codes -- the guard
- [x] `scripts/token-guard-paths.txt` -- header comment plus `App/Design` -- migrated list
- [x] `CLAUDE.md` -- add `scripts/check-tokens.sh` and `scripts/test-check-tokens.sh` to Commands; say each later epic adds its files to `scripts/token-guard-paths.txt` -- discoverability

**Acceptance Criteria:**
- Given the test script before `check-tokens.sh` exists, when run, then it fails; after implementation it passes covering every matrix row.
- Given the clean repo, when `scripts/check-tokens.sh` runs, then exit 0 with no output.
- Given a temporary violating line added to a file under `App/Design`, when it runs, then it prints that `file:line` and exits 1; removing the line restores exit 0.
- Given `git diff -- App Packages project.yml`, then it is empty.

## Implementation Notes

## Spec Change Log

## Review Triage Log

| Finding | Verdict | Route | Evidence |
|---|---|---|---|
| `--paths`/`--root` without a value exits 1 via `${2:?}` | medium | patch | Reproduced: `check-tokens.sh --paths` exits 1, same as violations; header promises 2. |
| Fixtures do not pin each named-color / font alternation | medium | patch | `bad-named` has only `.red`, `Color.blue`, `.orange`; dropping other alternations keeps tests green. |
| Guard not wired to any automated run | false | rejected | Spec Never: no git hooks or CI wiring. |
| Narrow pattern set (other named colors, implicit `.accentColor`, `Font.system(size:)`, variable sizes) | low | defer | Spec Always lists the forbidden patterns exactly; widening edits the frozen block. |
| Basename exemption matches anywhere under a listed path | false | rejected | Spec: token layer files are always skipped by name. |
| Empty list passes vacuously | low | rejected | Fix adds a guard; unlikely, loud in review of the list file. |
| grep error / find failure swallowed | low | rejected | Unlikely in practice; fix adds branching. |
| `.red` after `)` or `]` false positive | low | rejected | Fails loudly, fix complicates the regex. |
| Hex-like text in comments/strings, 8-digit hex | low | rejected | Line-based scan by design; no suppression mechanism specified. |
| Path with `|`/`&` breaks sed; overlapping entries print twice | low | rejected | Unlikely repo paths; cosmetic. |
| "No deps beyond grep" but sed/find used | low | rejected | POSIX tools on macOS; intent is no third-party tools. |
| Output prints whole line, not only matched text | false | rejected | Matrix shows `file:line: …`; line text is acceptable. |
| CLAUDE.md comment column alignment | low | rejected | Cosmetic; fix edits agent-context file. |

### Review Findings

Code review 2026-11-02 (Blind Hunter, Edge Case Hunter, Verification Gap, Acceptance Auditor). AC2, AC3 and AC4 checked by hand: clean run exits 0 with no output, a temporary `Color.red` in `App/Design/Badge.swift` prints `file:21` and exits 1, `git diff -- App Packages project.yml` is empty.

- [x] [Review][Patch] Test gaps in `test-check-tokens.sh`: no fixture with a violating file next to `ColorToken.swift` in the same directory (a bug that skips the whole directory would pass, and the real list `App/Design` contains `ColorToken.swift`); no test for an unknown argument (exit 2) or a missing `--paths` file / `--root` dir [scripts/test-check-tokens.sh:53] (medium; blind-hunter+edge-case-hunter)
- [x] [Review][Patch] `last_updated` moved backwards from `11-02-2026 09:20` to `09:11` [_bmad-output/implementation-artifacts/sprint-status.yaml:32] (low; all four layers)
- [x] [Review][Patch] `deferred-work.md` note on widening the patterns omits known bypasses: `Color(red:green:blue:)`, `0x` integer literals, 3-digit and 8-digit hex, `NSColor.red`/`UIColor.red` (the `.red` rule needs a non-identifier char before the dot), `.systemBlue`-style colors, `.font(.system(` split across lines or with extra spaces [_bmad-output/implementation-artifacts/deferred-work.md:47] (low; blind-hunter+edge-case-hunter)
- [x] [Review][Defer] CLAUDE.md says what the script does but not when to run it (before finishing a UI task, exit codes) [CLAUDE.md] — deferred: fix edits an agent-context file

#### Rejected

- Grep error swallowed by `|| true` (low): reproduced, an unreadable file with `Color.red` exits 0 (grep prints a message to stderr); unlikely in a repo checkout, fix adds branching.
- `find` failure inside process substitution is not caught (low): same situation, unlikely, fix adds branching.
- Empty list or zero scanned files exits 0 (low): unlikely, fix adds a guard.
- Non-`.swift` file entry silently skipped (low): every migrated file is Swift, fix adds a branch.
- Filename unescaped in the `sed` replacement (`|`, `&`, `\`) (low): unlikely repo paths.
- Path containing `#` truncated in the list (low): unlikely repo paths.
- Absolute paths, `..`, non-file entries and overlapping entries not validated or de-duplicated (low): unlikely, fix adds guards.
- Basename exemption matches anywhere under a listed path (false): spec says the token layer files are always skipped by name.
- `NSColor.red`, 3-digit hex, multi-line `.font(.system(` bypasses (low): the patterns are in the frozen block, so the fix edits the spec; recorded in the patch above.
- `.red` after `)` or `]` false positive (low): fails loudly, fix complicates the regex.
- "No dependencies beyond `grep`" vs `sed`/`find`/`sort` (false): POSIX tools on macOS, intent is no third-party tools.
- Output is the whole line, not only the matched text (false): the matrix shows `file:line: …`.
- Spec `done` while sprint status says `review` (false): specs 1.2 to 1.5 are the same.
- Implementation Notes empty, no record of the red-first run (low): fix edits the spec.
- AC2/AC3 "depend on the real `App/Design` contents" (false): verified above.

## Design Notes

A lint rule is a `grep` that fails the build (TS: an ESLint `no-restricted-syntax` rule run in CI). The list file is the rule's `files` glob; growing it per epic is how migration progress is enforced.

```bash
scripts/check-tokens.sh                       # real list, exit 0
scripts/check-tokens.sh --root fixtures/x --paths fixtures/x/list.txt
```

## Verification

**Commands:**
- `scripts/test-check-tokens.sh` -- expected: all cases pass
- `scripts/check-tokens.sh` -- expected: no output, exit 0
- `git diff -- App Packages project.yml` -- expected: empty
