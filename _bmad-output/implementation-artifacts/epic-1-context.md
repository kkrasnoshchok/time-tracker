# Epic 1 Context: Quiet category colors and the design foundation

<!-- Compiled from planning artifacts. Edit freely. Regenerate with compile-epic-context if planning docs change. -->

## Goal

Every existing category is shown in one of eight muted tones with no stored data rewritten, and `App/` gains a shared semantic token layer plus small base components that later epics (Palette, Journal, menu bar, Categories/settings) reuse instead of restyling screens twice.

## Stories

- Story 1.1: Category tone mapping with an App test target
- Story 1.2: Semantic design tokens
- Story 1.3: Primary button, ghost button and card
- Story 1.4: Input field, badge and error strip
- Story 1.5: Category dot and token tones on existing dots
- Story 1.6: Token guard script

## Requirements & Constraints

- Stored category `colorHex` is never rewritten. Core still creates categories with the old bright hexes, so the change is render-time mapping only.
- Mapping rules: exact match first (case-insensitive `#RRGGBB`); otherwise nearest tone by Oklab distance, ties to the earlier tone in the order clay, ochre, moss, lagoon, slate, plum, rose, taupe; invalid/empty hex gives taupe.
- The eight Core default hexes must map to eight distinct tones (blue→slate, green→moss, orange→clay, red→rose, purple→plum, cyan→lagoon, yellow→ochre, brown→taupe).
- Outside the token layer, `App/` has no hex literals, no system accent/`.red`/`.blue`, no ad-hoc font sizes (enforced by a guard script).
- Light theme only; no gradients, shadows, glow, materials. Font weights 400/500 only; tabular figures for time.
- Accessibility: names accompany dots/tokens, Dynamic Type text styles, hit targets ≥ 24pt.

## Technical Decisions

- `Packages/TimeTrackerCore` and its tests are not modified. Tokens, components and the mapping live in `App/`, a deliberate departure from "logic in Core". The mapping is a pure function with no `Date()` and no SwiftUI import.
- `App/` has no test target today; add a Swift Testing `TimeTrackerTests` target in `project.yml` (XcodeGen; `.xcodeproj` is generated, not committed), runnable via `xcodebuild test -scheme TimeTracker -destination 'platform=macOS'`.
- TDD: tests are seen failing first. Swift 6 strict concurrency; `swiftlint` stays clean.
- Tone values: clay #B4705A, ochre #B8964A, moss #8A9A6A, lagoon #5F8A88, slate #6F86A0, plum #8D6F8F, rose #B88A8A, taupe #7A7570.

## UX & Interaction Patterns

- Category dot: 8px circle in the tone color, never a row fill. Category token: pill, tone mixed 22% over card white, `body-emphasis` text, padding 6×12, no dot.
- Button/card/input/badge/error-strip specs come from the design contract; at most one primary button per surface.

## Cross-Story Dependencies

- Story 1.5 consumes the mapping from Story 1.1 and tokens from 1.2.
- Stories 1.3–1.5 build on the tokens of 1.2; 1.6 guards the files migrated by the others.
- Epics 2–5 depend on this epic.
