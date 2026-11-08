---
title: 'Category dot and token tones on existing dots'
type: 'feature'
created: '2026-11-02'
status: 'done'
baseline_commit: 'df60d343dc1983a56386acf325c43de456ef22cc'
route: 'dispatch'
review_loop_iteration: 0
context:
  - '{project-root}/_bmad-output/planning-artifacts/ux-designs/ux-time-tracker-2026-11-01/DESIGN.md'
  - '{project-root}/_bmad-output/implementation-artifacts/epic-1-context.md'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** Journal, popover and Palette still draw category dots with `Color(hex:)` from the stored bright hex at 9–10px, so the eight quiet tones (Story 1.1) are not visible anywhere, and there is no category token component.

**Approach:** Add `CategoryDot` (8px circle in the mapped tone) and `CategoryToken` (tinted pill), switch the three existing dots to `CategoryDot`, and show both for all eight tones in the gallery. The 22% tint is a pure, tested function. Story 1.5 of `_bmad-output/planning-artifacts/epics.md`.

## Boundaries & Constraints

**Always:** Dot: 8×8 circle filled with `ColorToken.category(CategoryTone(storedHex:)).color`, hidden from VoiceOver (`accessibilityHidden(true)`). Token: `Capsule` filled with the tone mixed 22% over `ColorToken.surfaceCard`, text is the category name in `typeRole(.bodyEmphasis)` and `textPrimary`, padding 6 vertical × 12 horizontal (`Space.x3` horizontal), no dot, VoiceOver label is the category name. Stored `colorHex` is read only, never written. Each call site keeps its current spacing and text; only the dot view changes. Swift 6 strict concurrency, `swiftlint` clean. New Swift concepts (`some View`, computed properties on a value type) get short English doc comments with TypeScript/React analogies.

**Never:** No edits to `Packages/TimeTrackerCore`, to `CategoryTone` mapping rules, or to existing token values. No new `ColorToken` cases. No hex literals outside tokens, no shadows, gradients, materials or glow. Do not restyle the rest of the three screens (fonts, `.secondary`, spacing stay). `CategoriesView` color picker (`Color(hex:)` at line 108) is untouched (Epic 5). No place uses `CategoryToken` yet (Epic 2 does).

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Core bright hex | `#0A84FF` | dot in slate `#6F86A0`, 8px | N/A |
| No category | `entry.category == nil` | dot in taupe (empty hex maps to taupe) | N/A |
| Invalid hex | `"zzz"` | taupe dot | N/A |
| Tint | clay `#B4705A` over `#FFFFFF` at 22% | `#EFE0DB` | N/A |
| Tint bounds | fraction 0 / 1 | card white / the tone itself | N/A |

</frozen-after-approval>

## Code Map

- `App/Support/CategoryTone.swift` -- `CategoryTone(storedHex:)`, `.hex`. Reuse; add pure tint function here or beside it, no SwiftUI import in the math.
- `App/Design/ColorToken.swift` -- `ColorToken.category(_:)`, `.color`, `.surfaceCard`. Reuse, do not change.
- `App/Design/Badge.swift`, `Card.swift` -- pill/modifier style to follow.
- `App/Design/Spacing.swift` -- `Space.x3` (12). 6×12 vertical literal commented like Badge.
- `App/Journal/JournalEntriesView.swift:144` -- `EntryRow` dot (9px) → `CategoryDot`.
- `App/MenuBar/RunningTimerView.swift:18-20` -- popover dot (10px) → `CategoryDot`.
- `App/Palette/PaletteView.swift:62` -- running-row dot (9px) → `CategoryDot`.
- `App/Design/ComponentGallery.swift` -- add `#Preview("Category dot and token")` with all eight tones.
- `AppTests/CategoryToneTests.swift` -- Swift Testing style; add tint tests in a new `CategoryTintTests.swift`.
- `project.yml` -- globbed; run `xcodegen generate` only.

## Tasks & Acceptance

**Execution:**
- [x] `AppTests/CategoryTintTests.swift` -- table test: clay at 22% over white gives `#EFE0DB`, fraction 0 gives `#FFFFFF`, fraction 1 gives the tone hex; run, see FAIL -- red first
- [x] `App/Support/CategoryTone.swift` -- pure `tintedHex(over:fraction:)` (sRGB channel mix, rounded) -- testable 22% rule
- [x] `App/Design/CategoryDot.swift` -- `CategoryDot(storedHex:)` 8px circle, hidden from VoiceOver -- one dot for all screens
- [x] `App/Design/CategoryToken.swift` -- `CategoryToken(name:storedHex:)` tinted pill with name label -- token for Epic 2
- [x] `App/Journal/JournalEntriesView.swift`, `App/MenuBar/RunningTimerView.swift`, `App/Palette/PaletteView.swift` -- replace the three circles with `CategoryDot` -- tones on existing dots
- [x] `App/Design/ComponentGallery.swift` -- preview with dot and token for all eight tones -- visual check

**Acceptance Criteria:**
- Given the tint tests, when run before the implementation, then they fail to compile; after it, `xcodebuild test -scheme TimeTracker -destination 'platform=macOS'` passes with the 1.1–1.4 tests included.
- Given `git diff -- Packages`, then it is empty; given a grep for `Circle().fill(Color(hex` in `App/Journal`, `App/MenuBar`, `App/Palette`, then nothing matches; given a grep for `shadow|gradient|Material|#[0-9A-Fa-f]{6}|\.red|\.orange|\.blue` in the new `App/Design` files, then nothing matches.
- Given the app launched with Core-created categories, when Journal, popover and Palette show a category, then only the eight tone colors appear and no stored `colorHex` changed.
- Given the gallery preview, when opened, then all eight dots (8px) and tokens (22% tint, no dot) render.

## Implementation Notes

- Tint tests failed to compile first (`value of type 'CategoryTone' has no member 'tintedHex'`), then passed with 1.1-1.4 tests (21 tests); swiftlint 0 violations; Core 187 tests pass; `git diff -- Packages` empty; forbidden-pattern greps empty.
- `tintedHex` clamps the fraction to 0...1 and returns the tone itself for an invalid base (spec silent).
- NOT VERIFIED: gallery preview and running app not looked at on screen.

## Spec Change Log

## Review Triage Log

| Finding | Verdict | Route | Evidence |
|---|---|---|---|
| `tintedHex` clamp, invalid base, lowercase base, non-white base untested (edge, gap) | low | patch | Cases added to `CategoryTintTests`; run passes. |
| Tests infer `.clay` in tuple array (blind) | low | patch | Made explicit `CategoryTone.clay`. |
| `CategoryDot` mapping wiring unpinned (gap) | low | rejected | One-line composition of two tested pieces; a pure helper adds API. |
| `CategoryToken` 0.22 and base unpinned (gap) | low | defer | Gallery only; pin at first real consumer (Epic 2). |
| NaN fraction traps, invalid base returns full tone (edge) | false | rejected | Only caller passes constant 0.22 and a token hex; unreachable. |
| Dark mode, fixed white base (blind, edge) | false | rejected | Light theme only by design. |
| Empty/long name in token, redundant `accessibilityLabel`, per-render recompute, hex round-trip, rounding at 238.5 (blind, edge) | low | rejected | Owner-controlled input, spec-mandated label, tests pass; fixes add complexity. |
| Dot shrinks 9-10px to 8px, uncategorised now taupe (blind) | false | rejected | Required by spec and Story 1.1. |
| `explain-change` not run (blind) | false | rejected | Process step, done after the commit by user request. |

## Design Notes

A `View` is a struct whose `body` is a computed property returning `some View` (React: a function component returning "some JSX"; `some` hides the concrete type like an inferred return type).

```swift
CategoryDot(storedHex: "#0A84FF") // slate 8px circle
CategoryToken(name: "Work", storedHex: "#FF9F0A") // clay tint pill
```

## Verification

**Commands:**
- `xcodegen generate && xcodebuild test -scheme TimeTracker -destination 'platform=macOS'` -- expected: `** TEST SUCCEEDED **`
- `swiftlint` -- expected: no violations
- `swift test --package-path Packages/TimeTrackerCore` -- expected: 187 tests pass

**Manual checks:**
- Gallery canvas shows eight dots and tokens. Run the app: Journal, popover and Palette dots are muted tones.
