---
title: 'Category tone mapping with an App test target'
type: 'feature'
created: '2026-11-01'
status: 'done'
route: 'oneshot'
review_loop_iteration: 0
context:
  - '{project-root}/_bmad-output/specs/spec-design-system/category-color-mapping.md'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** Core still stores bright `colorHex` values, and `App/` has no test target, so there is nowhere to test App-side logic.

**Approach:** Add a Swift Testing `TimeTrackerTests` target to `project.yml`, then (test first, seen failing) add a pure `CategoryTone` mapping in `App/Support/` that turns any stored hex into one of eight tones: exact match, else nearest by Oklab with ties to the earlier tone, else taupe. `Packages/TimeTrackerCore` stays untouched. Story 1.1 of `_bmad-output/planning-artifacts/epics.md`.

</frozen-after-approval>

## Implementation Notes

- Files: `project.yml` (new `TimeTrackerTests` bundle.unit-test target, `AppTests/` sources, scheme test action), `AppTests/CategoryToneTests.swift`, `App/Support/CategoryTone.swift` (pure, Foundation only, no SwiftUI, no `Date()`).
- Red seen first: before `CategoryTone` existed, `xcodebuild test` ran the new target and failed to compile with "cannot find 'CategoryTone' in scope". After: 6 test functions pass; Core 187 tests still pass; `git diff -- Packages` is empty.
- Decisions: Core default hexes are an explicit table (exact match first, as the mapping contract says); other valid hexes use Oklab nearest with strict `<` over the tie-break order, so ties go to the earlier tone. Tone hexes live in `CategoryTone.hex` for now; Story 1.2 moves them into the token layer.
- Review: independent subagent review layers were not run (no explicit permission to spawn subagents); only self-review. Lint clean for this file.

### Review Findings

Code review of commit `43697ff` (2026-11-01), mode `full`. Layers: Blind Hunter, Edge Case Hunter, Verification Gap Reviewer, Acceptance Auditor. `xcodegen generate` + `xcodebuild test -scheme TimeTracker -destination 'platform=macOS'` was run during triage: `** TEST SUCCEEDED **`, 6 tests in 1 suite.

- [x] [Review][Patch] Tests do not tie `coreDefaults` to Core's real palette — add a test over `PaletteViewModel.categoryColors` (`import TimeTrackerCore`; the test target needs the `TimeTrackerCore` package dependency in `project.yml`) asserting every Core hex maps to its own distinct tone; otherwise a change in Core passes all tests while the "eight defaults stay distinct" rule breaks [App/Support/CategoryTone.swift:25]
- [x] [Review][Patch] Nearest-tone test is weak — only slate, moss and clay are covered, by hexes one step off the tone hex, so any metric passes; add a near-miss per remaining tone and one hex where Oklab and plain RGB distance disagree, and replace the `#FF0000 → .clay` comment ("rose and clay are the closest") with the computed distances [AppTests/CategoryToneTests.swift:30-35]
- [x] [Review][Patch] `best!` force unwrap in `nearest(toDistances:)` — safe today, but rewrite with `if let` / a non-optional seed so no lint rule or later edit can trap [App/Support/CategoryTone.swift:53]
- [x] [Review][Defer] Hex literals live in `App/Support/CategoryTone.swift` (`hex`, `coreDefaults`), outside the future token layer — deferred: acknowledged in this spec; Story 1.2 moves tone hexes into tokens and the Story 1.6 guard script must migrate or allow-list `coreDefaults`
- [x] [Review][Defer] CLAUDE.md "Команды" lists only `swift test` for Core; App tests run only via `xcodebuild test -scheme TimeTracker -destination 'platform=macOS'` — deferred: fix edits CLAUDE.md (agent-context file), needs the author's OK

#### Rejected

- Tone Oklab values recomputed on every `init(storedHex:)` (Blind Hunter, Edge Case Hunter) — low: eight tiny computations per row; `toneHexMapsToItself` already guards against a tone hex failing to parse.
- Whitespace, no-`#` and 8-digit hex fall to taupe (Edge Case Hunter, Blind Hunter, Acceptance Auditor) — low: matches the spec ("valid `#RRGGBB`", else taupe); every writer in the app produces `#RRGGBB` and no path to such values was shown.
- Tie rule tested only through `nearest(toDistances:)` (Acceptance Auditor) — false: `init` has no other selection path, and a real exact tie in Double Oklab distances is not reachable.
- TS/React explanation of new Swift concepts missing (Acceptance Auditor) — low: a chat deliverable, not a repo artifact; cannot be judged from the diff.
- Spec `done` vs sprint `review`, extra artifact files in the diff (Blind Hunter, Acceptance Auditor) — false: `done` is the implementation status of the spec, `review` is the sprint state awaiting this review; epic context and sprint file are the story's expected artifacts.
- Scheme `build` entry lacks the test target (Edge Case Hunter) — false: verified by a real `xcodebuild test`, the target builds and runs.
- Red-first and "runs via scheme" claims unverifiable (Acceptance Auditor) — false for the run: tests execute and pass. The red-first run itself rests on the spec notes only.
- Cyrillic story keys such as `3-3-долго-…` in `sprint-status.yaml` (Blind Hunter) — low: file names with Cyrillic work on macOS; the fix edits planning artifacts.
- `project_key: NOKEY` and `MM-DD-YYYY` timestamps in `sprint-status.yaml` (Blind Hunter) — low: generated by the sprint-planning skill, not part of this story's code.
- `tieBreakOrder` repeats `allCases`, and NaN distances (Blind Hunter) — false: the explicit list is the spec's order, deliberately independent of case declaration order; inputs are finite, NaN is unreachable.
- `CategoryTone` has no callers yet (Verification Gap Reviewer) — false: adoption is Story 1.5.
