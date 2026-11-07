# Epic 5 Context: Categories, entry editing, settings and errors

<!-- Compiled from planning artifacts, epic-4-context.md, the epic 4 retro and category-color-mapping.md. Edit freely. Regenerate with compile-epic-context if planning docs change. -->

## Goal

Category color is chosen from the eight design tones instead of a free color picker. Entry detail, the add-entry sheet, Categories, Settings and every error message move onto the shared tokens and base components, so no blue, red or default accent remains anywhere in the app. Behavior does not change; this is a restyle plus the swatch picker and the first-unused-tone rule.

## Stories

- Story 5.1: Tone swatches in the Categories tab
- Story 5.2: Entry detail and add-entry sheet
- Story 5.3: Categories chrome, Settings and remaining errors
- Story 5.4: Whole-app guard and success check

## Requirements & Constraints

- Eight tones in the order clay, ochre, moss, lagoon, slate, plum, rose, taupe. A new category from the Categories tab takes the first tone not used by any category; with all eight used, tone index `count % 8`. The stored value is the tone's own hex, which maps to itself.
- Two categories may share a tone. Color is never the only carrier of meaning: the name sits beside the dot; the selected swatch is marked by a ring or check.
- Swatches are at least 24pt, keyboard reachable and named for VoiceOver.
- At most one primary button per screen; errors use the error strip, never `.red`; no system fonts or accent. The hotkey recorder keeps its system look.
- TDD with red first; no `Date()` in logic, no `sleep`. Core stays untouched unless a story says otherwise (moving the mapping into Core is a follow-up, not Epic 5).

## Technical Decisions

- Tone logic is a pure function in `App/` (`CategoryTone` in `App/Support`, tokens in `App/Design/ColorToken.swift`); stored `colorHex` is never rewritten, mapping happens at render time.
- Core still creates categories from the Palette with bright hexes (`PaletteViewModel.categoryColors`); first-unused tone for Palette-created categories is an open follow-up listed in 5.4.
- `CategoriesView` lives in `App/Journal/CategoriesView.swift` and uses `journal.addCategory(name:colorHex:)` and `journal.setColor(_:for:)`.
- Guard list `scripts/token-guard-paths.txt`: each story adds the files it migrates; 5.4 widens it to all of `App/`. Run `scripts/check-tokens.sh` at the end of each UI task.
- New `App/` files need `xcodegen generate`. App tests: `xcodebuild test -scheme TimeTracker -destination 'platform=macOS'`.
- Commit subjects name the story (`feat(5-1): …`); preparatory work gets its own `chore(...)` commit. Every story gets its own `spec-n-m-…` file (retro C4).

## UX & Interaction Patterns

- Process lessons: when a story depends on a native control's look or keys, write the assumption as unverified and run the app before review (retro B6). Thin SwiftUI glue is checked by hand; logic goes into tested pure helpers (retro C5).
- Closing 4.x manual/VoiceOver checks (C1-C3) and epic 2/3 leftovers (`mutingTags` helper, B1/B3) should land before 5.2 edits the Journal detail area.

## Cross-Story Dependencies

- 5.1 depends only on Epic 1 tokens. 5.3 builds on 5.1 (Categories chrome). 5.4 requires 5.1-5.3 done.
