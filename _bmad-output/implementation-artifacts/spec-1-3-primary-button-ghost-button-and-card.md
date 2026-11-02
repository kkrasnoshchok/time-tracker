---
title: 'Primary button, ghost button and card'
type: 'feature'
created: '2026-11-02'
status: 'done'
baseline_commit: 'c99a87f8b4635967b555a5c2555db98a62022fa4'
route: 'dispatch'
review_loop_iteration: 0
context:
  - '{project-root}/_bmad-output/planning-artifacts/ux-designs/ux-time-tracker-2026-11-01/DESIGN.md'
  - '{project-root}/_bmad-output/implementation-artifacts/epic-1-context.md'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** `App/` has tokens (Story 1.2) but no shared button or card, so each screen would hand-build actions and groups and drift apart.

**Approach:** Add `PrimaryButtonStyle`, `GhostButtonStyle` and a `card()` container in `App/Design/`, built only from tokens. Put the state rules (normal, pressed, disabled, focused) in a pure, tested function. Add a `#Preview` component gallery showing every state. Story 1.3 of `_bmad-output/planning-artifacts/epics.md`.

## Boundaries & Constraints

**Always:** Primary: `actionPrimary` fill, `onActionPrimary` `caption` text, pill, padding 8×16. Ghost: transparent, 1px `borderGhost` outline, `textPrimary` `caption` text, pill, padding 8×16. Card: `surfaceCard`, radius 16, standard hairline ring, padding 16. Styles apply to any `Button`, so `Button` keeps its native keyboard and accessibility behavior; hit target at least 24pt tall. Swift 6 strict concurrency, `swiftlint` clean. New Swift concepts (`ButtonStyle`, `#Preview`, `@Environment(\.isEnabled)`) get short English doc comments with a TypeScript/React analogy (styled component, Storybook).

**Never:** No shadows, gradients, materials or glow; focus is a crisp ring, not a blur. No hex literals, system accent, `.red`/`.blue` or ad-hoc font sizes outside tokens. No new colors in `ColorToken`. No edits to `Packages/TimeTrackerCore`. No existing screen restyled (migration belongs to later stories). Light theme only.

**Decided by the spec (not in DESIGN.md):** pressed is the fill/outline at 0.8 opacity, disabled is 0.4 opacity with no other change, focused is a 2px `actionPrimary` ring offset 2px outside the pill. Disabled wins over pressed; focus shows only when enabled.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Normal | enabled, not pressed, not focused | opacity 1, no focus ring | N/A |
| Pressed | enabled, pressed | opacity 0.8, no focus ring | N/A |
| Disabled | disabled, pressed or not | opacity 0.4; pressed has no effect | N/A |
| Focused | enabled, focused | opacity 1 (0.8 if also pressed), focus ring on | N/A |
| Disabled + focused | disabled, focused | opacity 0.4, no focus ring | N/A |

</frozen-after-approval>

## Code Map

- `App/Design/ColorToken.swift` -- `Color.actionPrimary`, `.onActionPrimary`, `.borderGhost`, `.textPrimary`, `.surfaceCard` aliases; reuse, do not change.
- `App/Design/Typography.swift` -- `.typeRole(.caption)` for button labels.
- `App/Design/Spacing.swift` -- `Space.x2`, `Space.x4`, `Radius.card`, `Radius.pill`.
- `App/Design/HairlineRing.swift` -- `.hairlineRing(RoundedRectangle(...))` for the card.
- `AppTests/DesignTokenTests.swift` -- Swift Testing style to follow.
- `project.yml` -- `App` and `AppTests` are globbed; run `xcodegen generate` only.
- `.swiftlint.yml` -- line length 120.

## Tasks & Acceptance

**Execution:**
- [x] `AppTests/ButtonAppearanceTests.swift` -- table tests for the I/O matrix; run, see FAIL (missing symbols) -- red first
- [x] `App/Design/ButtonAppearance.swift` -- pure `ButtonAppearance.resolve(isEnabled:isPressed:isFocused:)` returning `opacity` and `showsFocusRing` -- testable state rules
- [x] `App/Design/Buttons.swift` -- `PrimaryButtonStyle`, `GhostButtonStyle` (`ButtonStyle`), `.primary`/`.ghost` static members; focus ring drawn from `@Environment(\.isFocused)`, enabled from `\.isEnabled` -- reusable pills
- [x] `App/Design/Card.swift` -- `View.card()` modifier -- white 16-radius container with hairline ring
- [x] `App/Design/ComponentGallery.swift` -- `#Preview("Buttons and card")` on `surfaceCanvas`: each style in normal, pressed (via a fixed-state preview wrapper), disabled, focused; a card holding both -- visual check, Storybook analogue

**Acceptance Criteria:**
- Given the appearance tests, when run before the implementation, then they fail to compile; after it, `xcodebuild test -scheme TimeTracker -destination 'platform=macOS'` passes with the 1.1 and 1.2 tests included.
- Given `git diff -- Packages`, then it is empty; given a grep for `shadow|gradient|Material|#[0-9A-Fa-f]{6}` in the four new `App/Design` files, then nothing matches.
- Given the gallery preview, when opened in Xcode, then both buttons and the card render in all states per the Always rules, with no glow.

## Implementation Notes

## Spec Change Log

## Review Triage Log

| Finding | Verdict | Route | Evidence |
|---|---|---|---|
| System focus ring not disabled, so a second ring may show beside the custom one (blind) | medium | patch | Custom `Button` styles on macOS still get the system focus effect; the spec asks for one crisp ring. Fix: `.focusEffectDisabled()`. |
| `@Environment(\.isFocused)` may not report keyboard focus inside a `ButtonStyle` (blind, edge) | maybe-false | defer | Would be medium if true (ring never shows). Settle by opening the app with Full Keyboard Access and tabbing to a `.buttonStyle(.primary)` button. |
| Opacity fades the label too, spec says "fill/outline" (edge) | low | rejected | Spec wording is ambiguous; a whole-control fade is the natural reading and keeps disabled "no other change" consistent. |
| Focus ring (negative padding) clipped by clipping ancestors (edge) | low | rejected | No caller clips today; fix needs layout design. |
| Long or localized label wraps, no `lineLimit` (edge) | low | rejected | No caller yet; guard adds complexity. |
| Disabled button may still look interactive (edge) | false | rejected | `Button` honors `.disabled`, and opacity 0.4 is applied from `\.isEnabled`. |
| 0.4/0.8/24/line widths are literals (blind, edge) | low | rejected | Values come from the spec; tests intentionally repeat them. |
| `Radius.pill` unused, `Capsule` used (edge) | false | rejected | `Capsule` is the same fully rounded shape; no divergence. |
| Disabled contrast too low (blind) | low | rejected | 0.4 is the spec's choice for disabled; disabled text need not meet contrast. |
| No dark or large Dynamic Type previews (blind) | false | rejected | Dark theme is excluded by the spec; type scales via `typeRole`. |
| Gallery has no `#if DEBUG`, `StateRow` repetitive (blind) | low | rejected | `#Preview` is stripped from release builds; repetition is cosmetic. |
| Rendering of `card()`/kinds untested (blind) | low | rejected | Verification-gap layer judged it visual; spec checks it in the gallery. |
| Card not flexible, "white" in dark mode (blind) | false | rejected | Spec fixes padding and radius; dark theme excluded. |
| Redundant `Sendable`, unlabeled test tuple, accessibility traits, hover (blind) | low | rejected | Cosmetic; no named harm. |

## Design Notes

`ButtonStyle` receives `configuration.isPressed` but not focus or enabled; those come from the environment inside a small wrapper `View`, since a style struct cannot hold `@Environment` reads for `makeBody` directly. The gallery cannot press a button, so a wrapper applies the same `ButtonAppearance` with a forced state.

```swift
let a = ButtonAppearance.resolve(isEnabled: true, isPressed: true, isFocused: true)
// a.opacity == 0.8, a.showsFocusRing == true
```

## Verification

**Commands:**
- `xcodegen generate && xcodebuild test -scheme TimeTracker -destination 'platform=macOS'` -- expected: `** TEST SUCCEEDED **`
- `swiftlint` -- expected: no violations
- `swift test --package-path Packages/TimeTrackerCore` -- expected: 187 tests pass

**Manual checks:**
- Open `ComponentGallery.swift` canvas: eight button states and the card match the Always rules; Tab (Full Keyboard Access) shows the focus ring.
