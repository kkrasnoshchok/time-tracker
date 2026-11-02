---
title: 'Input field, badge and error strip'
type: 'feature'
created: '2026-11-02'
status: 'done'
baseline_commit: '112d7170de5d33528807ecc9cedced610b43c688'
route: 'dispatch'
review_loop_iteration: 0
context:
  - '{project-root}/_bmad-output/planning-artifacts/ux-designs/ux-time-tracker-2026-11-01/DESIGN.md'
  - '{project-root}/_bmad-output/implementation-artifacts/epic-1-context.md'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** `App/Design/` has buttons and a card (Stories 1.2–1.3) but no input field, badge or error strip, so forms and failures would each be hand-built and drift apart.

**Approach:** Add `InputField`, `Badge` and `ErrorStrip` views built only from tokens. Put the input border rule in a pure, tested function. Extend the component gallery with every state. Settle the deferred focus check from Story 1.3 on the way. Story 1.4 of `_bmad-output/planning-artifacts/epics.md`.

## Boundaries & Constraints

**Always:** Input: `surfaceInput` fill, radius `Radius.input` (8), 1px `textTertiary` border, padding 8×12, `body` text; focus turns the border `actionPrimary`, same 1px width. Badge: `surfaceInset` pill, `micro` text, `textPrimary`, padding 3×10. Error strip: one line (`lineLimit(1)`) of `textPrimary` text on `surfaceInset`, leading SF Symbol line icon, optional trailing ghost-style action (label + closure, e.g. «Всё равно»); it has no built-in timer or dismiss, the owner removes it. Input keeps native `TextField` behavior and a hit height of at least 24pt. Swift 6 strict concurrency, `swiftlint` clean. New Swift concepts (`@FocusState`, `@Binding`, `TextFieldStyle` and why a view is used instead) get short English doc comments with TypeScript/React analogies.

**Never:** No shadows, gradients, materials or glow; no red, orange or system accent. No hex literals or ad-hoc font sizes outside tokens. No new colors in `ColorToken`. No edits to `Packages/TimeTrackerCore`. No existing screen restyled. Light theme only.

**Decided by the spec (not in DESIGN.md):** input is a view wrapping `TextField` with its own `@FocusState` (public `TextFieldStyle` cannot restyle a field). Error icon is `exclamationmark.circle`. Error action button reuses `.ghost`. Pure rule: `InputAppearance.borderToken(isFocused:)`.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Input empty | text "", unfocused | placeholder in `textTertiary`, border `textTertiary` | N/A |
| Input filled | text "Design", unfocused | text in `textPrimary`, border `textTertiary` | N/A |
| Input focused | focused | border `actionPrimary`, 1px, no glow | N/A |
| Strip, no action | message only | icon + one line, no button | long text truncates to one line |
| Strip, action | message + «Всё равно» | icon, line, ghost button that calls the closure | N/A |

</frozen-after-approval>

## Code Map

- `App/Design/ColorToken.swift` -- `Color.surfaceInput`, `.surfaceInset`, `.textPrimary`, `.textTertiary`, `.actionPrimary`; `ColorToken` enum for the tested border rule. Reuse, do not change.
- `App/Design/Typography.swift` -- `.typeRole(.body)`, `.typeRole(.micro)`.
- `App/Design/Spacing.swift` -- `Space.x2`, `Space.x3`, `Radius.input`; 3×10 padding has no token, use literals in the Badge only.
- `App/Design/Buttons.swift` -- `.buttonStyle(.ghost)` for the strip action; keyboard-focus ring code under deferred check.
- `App/Design/ComponentGallery.swift` -- add a second `#Preview`; `StateRow` pattern for forced states.
- `AppTests/ButtonAppearanceTests.swift` -- Swift Testing style to follow.
- `_bmad-output/implementation-artifacts/deferred-work.md` -- focus-ring item from Story 1.3.
- `project.yml` -- `App`, `AppTests` globbed; run `xcodegen generate` only.

## Tasks & Acceptance

**Execution:**
- [x] `AppTests/InputAppearanceTests.swift` -- table test: unfocused gives `.textTertiary`, focused gives `.actionPrimary`; run, see FAIL -- red first
- [x] `App/Design/InputAppearance.swift` -- pure `InputAppearance.borderToken(isFocused:)` -> `ColorToken` -- testable focus rule
- [x] `App/Design/InputField.swift` -- `InputField(_ placeholder:text:)` with `@FocusState`, fill, radius 8, border from `InputAppearance` -- quiet input
- [x] `App/Design/Badge.swift` -- `Badge(_ text:)` -- neutral pill
- [x] `App/Design/ErrorStrip.swift` -- `ErrorStrip(_ message:action:)` with optional `(label, handler)` -- calm one-line failure
- [x] `App/Design/ComponentGallery.swift` -- `#Preview("Input, badge and error strip")`: input empty, filled, focused (forced via a wrapper), badge, strip with and without action -- visual check
- [ ] `deferred-work.md` and `Buttons.swift` -- tab to a `.primary` button in a running app with Full Keyboard Access; if the ring is missing or doubled, apply the fix noted in the deferred item and record the result in Implementation Notes -- settle the 1.3 doubt

**Acceptance Criteria:**
- Given the input tests, when run before the implementation, then they fail to compile; after it, `xcodebuild test -scheme TimeTracker -destination 'platform=macOS'` passes with the 1.1–1.3 tests included.
- Given `git diff -- Packages`, then it is empty; given a grep for `shadow|gradient|Material|#[0-9A-Fa-f]{6}|\.red|\.orange|\.blue` in the new `App/Design` files, then nothing matches.
- Given the gallery preview, when opened, then input (empty, filled, focused), badge and both strips render per the Always rules, with no glow and no red.
- Given a real `InputField` in a running view, when tabbed to, then its border turns `actionPrimary`.

## Implementation Notes

- Input tests failed to compile first (`cannot find 'InputAppearance'`), then passed with 1.1-1.3 tests; swiftlint 0 violations; Core 187 tests pass; `git diff -- Packages` empty; forbidden-pattern grep empty.
- Added `InputFieldShell` (draws the shell for a forced focus state) so the gallery can show the focused look; `InputField` wraps it with `@FocusState`.
- NOT VERIFIED: the Story 1.3 focus-ring check (tabbing to a `.primary` button with Full Keyboard Access) and the "tab to a real InputField" criterion need a human at the running app; no screen uses `InputField` yet. `Buttons.swift` left unchanged; the deferred item stays open.

## Spec Change Log

## Review Triage Log

| Finding | Verdict | Route | Evidence |
|---|---|---|---|
| Truncated strip message unreadable (edge) | low | patch | One line with `lineLimit(1)`; fix: `.help(message)`. Applied. |
| Action label may be compressed before the message (edge) | low | patch | Fix: `.fixedSize()` on the action button. Applied. |
| Placeholder color via `prompt` `foregroundStyle` may be ignored on macOS (edge, claim) | maybe-false | defer | Medium if true (empty-state spec broken). Settle by viewing a running field. |
| Parent `onTapGesture` may disturb caret placement or selection (blind, edge, claim) | maybe-false | defer | Medium if true. Settle by clicking and double-clicking text in a running field. |
| Focus-to-border wiring and "tab to a real field" not verified (gap, claim) | maybe-false | defer | Spec AC is manual; no screen hosts `InputField` yet. Merged with the open 1.3 focus item. |
| Focus wiring untested in view (gap, edge) | low | rejected | Pure rule tested; view is a one-line pass-through; a view-level test needs new surface. |
| No disabled, error or submit state on `InputField` (blind, edge) | low | rejected | Not in spec, no caller; guards add complexity. |
| `ErrorStrip` not announced to VoiceOver, no grouping (blind, edge) | low | rejected | No caller yet; announcement adds API. Revisit when Epic 3 uses the strip. |
| Empty or long message, double action fire, empty badge (edge) | low | rejected | Owner-controlled inputs, unlikely in everyday use. |
| Magic numbers `24`, `3`, `10` (blind, gap) | low | rejected | From the spec; Badge literal is commented. |
| Empty `TextField` title, placeholder doubles as label (blind, edge) | low | rejected | `accessibilityLabel` is set; no named harm. |
| Tuple action not `Sendable`/struct (blind) | false | rejected | Builds under Swift 6 strict concurrency; views run on the main actor. |
| Strip indistinguishable from Badge, no red (blind) | false | rejected | Deliberate per spec: no status colors. |
| Test coverage thin, `InputHost` `@State var`, localization, previews variants (blind) | low | rejected | Cosmetic; no named harm. |

## Design Notes

`TextField` focus is read with `@FocusState` (React: `onFocus`/`onBlur` state) and passed to the pure rule, so the rule is testable and the view only draws.

```swift
InputAppearance.borderToken(isFocused: true) // .actionPrimary
```

## Verification

**Commands:**
- `xcodegen generate && xcodebuild test -scheme TimeTracker -destination 'platform=macOS'` -- expected: `** TEST SUCCEEDED **`
- `swiftlint` -- expected: no violations
- `swift test --package-path Packages/TimeTrackerCore` -- expected: 187 tests pass

**Manual checks:**
- Gallery canvas: input, badge, strips match the Always rules. Run the app, tab through an input and a styled button with Full Keyboard Access: one crisp focus indication each.
