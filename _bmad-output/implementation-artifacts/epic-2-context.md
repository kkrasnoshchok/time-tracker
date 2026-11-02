# Epic 2 Context: Palette in the new style

<!-- Compiled from planning artifacts. Edit freely. Regenerate with compile-epic-context if planning docs change. -->

## Goal

The Palette becomes an opaque paper panel with a tinted category token, a 60px input field and 40px suggestion rows, built from the Epic 1 tokens and base components. Behavior and the typed-line grammar (`category title #tag -20m`) do not change; this is a restyle plus a small `App/`-side resolution of the first word into a token.

## Stories

- Story 2.1: Opaque paper panel and 60px field
- Story 2.2: Category token in the typed line
- Story 2.3: Running row, suggestion rows and prompts
- Story 2.4: Palette verification and guard

## Requirements & Constraints

- Panel: opaque white, radius 20, 1px ring at 10% black (stronger than the usual 5%; raised further under Increase Contrast). No material, no drop shadow in content, no gradient, no bounce or spring.
- Exactly three type levels in the Palette: 20 (`palette-input`, 400), 15 (`body`), 12 (`micro`). Weights 400/500 only. Tabular figures for elapsed time.
- Input row 60px, line-icon magnifier at left, placeholder in `text-tertiary`. Suggestion rows 40px, radius 10, no icons, selected row on `surface-inset`, hover does not move selection.
- Behavior unchanged: opens focused, closes on Esc / Enter / focus loss, ↑/↓/Tab/Enter, Backspace at the start of the name removes the token.
- `Packages/TimeTrackerCore` and its tests are not modified. Core's `PaletteViewModel` exposes `input` and `items`; first-word resolution is done in `App/` (reuse a public Core parser if one exists, else a pure case-insensitive name match with tests seen failing first).
- Accessibility: Dynamic Type via scalable text styles, VoiceOver names the token's category, Reduce Motion removes panel transitions, hit targets ≥ 24pt.
- Prompts (create category, overlap, error) use the error-strip look (`text-primary` on `surface-inset`, line icon, no red/orange), keeping wording and keys.
- Final story adds `App/Palette` to `scripts/token-guard-paths.txt`; `scripts/check-tokens.sh` must exit 0.
- Manual checks carried from Epic 1 (done in 2.1): `typeRole` text changes size with system text size on macOS (if `@ScaledMetric` does not scale, record it and fix the rule); category dots show eight tones with the name beside them; also unverified: focus ring on styled buttons, `InputField` placeholder color, tap gesture caret behavior, Tab focus.

## Technical Decisions

- Tokens and components live in `App/Design` (`ColorToken`, `Typography`/`typeRole`, `Spacing`, `HairlineRing`, `InputField`, `ErrorStrip`, `CategoryDot`, `CategoryToken`). Views hold no business logic; "now" comes from `TimeProvider`, never `Date()`.
- App tests run via `xcodebuild test -scheme TimeTracker -destination 'platform=macOS'`; new `App/` files need `xcodegen generate`.
- Commit subjects name the story: `feat(2-1): …`, `test(2-1): …`.

## UX & Interaction Patterns

- Palette panel order: input field row (magnifier, category token, typed text, muted `#tag`), running row on `surface-canvas`, suggestions.
- No-match first word offers category creation in place; the token appears on confirm.

## Cross-Story Dependencies

- Depends on Epic 1 only.
- 2.2 adds the token to the input row built in 2.1; 2.3 restyles rows and prompts below it; 2.4 verifies all states and adds `App/Palette` to the guard.
