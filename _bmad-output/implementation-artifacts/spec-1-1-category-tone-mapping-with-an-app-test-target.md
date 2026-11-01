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
