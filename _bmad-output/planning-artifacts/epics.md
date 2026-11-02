---
status: final
stepsCompleted: [1, 2, 3, 4]
inputDocuments:
  - _bmad-output/specs/spec-design-system/SPEC.md
  - _bmad-output/specs/spec-design-system/category-color-mapping.md
  - _bmad-output/planning-artifacts/ux-designs/ux-time-tracker-2026-11-01/DESIGN.md
  - _bmad-output/planning-artifacts/ux-designs/ux-time-tracker-2026-11-01/EXPERIENCE.md
---

# time-tracker - Epic Breakdown

## Overview

This document provides the complete epic and story breakdown for the Time Tracker design system stage, decomposing the requirements from the design-system SPEC (canonical contract, no separate PRD or Architecture document exists for this stage), its companions (category color mapping) and the UX design contract (DESIGN.md + EXPERIENCE.md) into implementable stories. Scope is `App/` only; `Packages/TimeTrackerCore` is not modified.

## Requirements Inventory

### Functional Requirements

FR1 (CAP-1): App code draws every surface from a shared semantic token layer (colors, type, spacing, radii, hairline ring) and a small set of base components: primary and ghost button, card, input field, badge, category dot, category token. Token values equal `DESIGN.md` frontmatter. Outside the token layer, `App/` has no hex literals, no system accent/`.red`/`.blue` colors and no ad-hoc font sizes (checked by grep). A preview or screenshot shows each component in its states.

FR2 (CAP-2): Any stored category `colorHex` is displayed as one of the eight category tones, with no change to stored data. Unit tests (seen failing first) cover `category-color-mapping.md`: all eight Core default hexes map to their distinct tones, an arbitrary hex maps to the nearest tone, an invalid hex maps to taupe. Existing categories show only tone colors after launch with no data written.

FR3 (CAP-3): The user picks a category's color from the eight tones in the Categories tab; free color input is gone. `ColorPicker` and `randomColor()` no longer exist in `CategoriesView`. A row offers eight swatches and selecting one saves that tone. A category added there takes the first unused tone, cycling after eight. Verified by tests of the choice rule and by running the app.

FR4 (CAP-4): The Palette panel follows `DESIGN.md` and the Palette rows of `EXPERIENCE.md`. Screenshot matches the Palette panel spec (opaque white panel, radius 20, 60px field, tinted category token, 40px suggestion rows, three type levels 20/15/12, no icons in rows); Esc/Enter/focus-loss behavior and typed-line grammar unchanged.

FR5 (CAP-5): The Journal shows days, rows and totals in the design language. Screenshot matches `journal-row` (44px, dot + gray category name, tabular duration) and day header with `day-total` and «в фокусе»; the running entry sits on `surface-inset` with `body-emphasis` duration. List width stays stable on selection.

FR6 (CAP-6): The menu bar item and popover show the running category and elapsed time in the design language. Item shows category and elapsed time as plain text, no color or animation; popover shows «Таймер не запущен» with the Palette hotkey hint when idle; no extra translucent background.

FR7 (CAP-7): Entry detail, add-entry sheet, Categories chrome, Settings and error messages use the same tokens and components. Errors render as one `text-primary` line on a `surface-inset` strip with a line icon (no `.red`, which `CategoriesView` uses today); each remaining screen passes the FR1 grep check and has at most one primary button.

FR8 (CAP-8): An entry that lasted 8 hours or more carries the note «долго». Tests with an injected clock (seen failing first): 7h59m shows no note, 8h00m shows «долго», for both running and finished entries. The note is a gray `caption` beside the duration in the Journal row and the popover, disappears once an edit brings the duration under 8h, and uses no color, alarm or notification.

### NonFunctional Requirements

NFR1: `Packages/TimeTrackerCore` is not modified, including its tests. Core still creates categories with the old bright hexes, so the color change is render-time mapping, never a data rewrite (stored `colorHex` is never rewritten).

NFR2: Tokens and components live in `App/`; views hold no business logic. The hex→tone mapping and the 8-hour check are small pure functions in `App/` with unit tests that were seen failing first (a deliberate departure from the CLAUDE.md "logic in Core" rule, on the author's instruction).

NFR3: "Now" comes from `TimeProvider`, never `Date()`; time stays UTC. Tests use no `sleep` and no real time.

NFR4: Tokens are semantic (`surface-*`, `text-*`, `action-*`), light theme only. No Liquid Glass or materials inside our surfaces, no gradients, shadows, glow, or red/green/blue anywhere.

NFR5: Font weights 400 and 500 only; negative tracking only on `timer-display` and `day-total`; tabular figures for any ticking or summed time.

NFR6: Accessibility floor holds: keyboard reachability, VoiceOver names for token and timer, text styles that scale (Dynamic Type), hit targets ≥ 24pt (Journal rows ≥ 44pt), Reduce Motion removes panel transitions, Increase Contrast keeps hairline rings visible.

NFR7: Swift 6 strict concurrency; TDD (red first); new Swift concepts are explained after each task through TypeScript/React analogies.

NFR8: Rollout order: tokens and mapping first (FR1, FR2), then Palette (FR4), Journal (FR5), menu bar (FR6), the rest (FR7). FR3 follows the surface it lives on (Categories), FR8 follows the surfaces it lives on (Journal row and popover).

### Additional Requirements

- No starter template; brownfield SwiftUI app. New files in `App/` need `xcodegen generate` (the `.xcodeproj` is generated, not committed); `swiftlint` must stay clean.
- Hex→tone mapping rules (`category-color-mapping.md`): exact match first (case-insensitive `#RRGGBB`); otherwise nearest tone by Oklab distance, ties to the earlier tone in the order clay, ochre, moss, lagoon, slate, plum, rose, taupe; invalid or empty hex → taupe.
- Core default hexes (`PaletteViewModel.categoryColors`) map: `#0A84FF`→slate, `#30D158`→moss, `#FF9F0A`→clay, `#FF453A`→rose, `#BF5AF2`→plum, `#64D2FF`→lagoon, `#FFD60A`→ochre, `#AC8E68`→taupe; all eight stay distinct.
- New-category tone choice in Categories tab: first tone in the order above not used by any category; if all eight used, cycle by `count % 8`. The stored value is the tone's own hex, which maps to itself. Two categories may share a tone; the category name always sits beside the dot.
- «долго» is evaluated per entry from its duration (running: `now − start`); entries spanning midnight use their full duration; threshold 8h inclusive.
- Open (not in scope, decide later): moving mapping and «долго» into Core; whether Palette in-place category creation uses the "first unused" rule.
- Non-goals: dark theme; any change to Core, data model, palette grammar or hotkeys; a stop hotkey or "stop now" in Entry detail; rewriting stored colorHex; custom window chrome, replacing the menu bar item, restyling system dialogs.

### UX Design Requirements

UX-DR1: Color tokens in `App/`: surface-canvas #F7F7F5, surface-card #FFFFFF, surface-inset #EDECE7, surface-input #EEEEEE, text-primary #1B0624, text-secondary #766A7C, text-tertiary #898683 (placeholders/decorative only), text-body #444444, action-primary #160F0C, on-action-primary #FFFFFF, border-ghost #898683, and category-clay #B4705A, ochre #B8964A, moss #8A9A6A, lagoon #5F8A88, slate #6F86A0, plum #8D6F8F, rose #B88A8A, taupe #7A7570.

UX-DR2: Typography tokens (SF Pro, weights 400/500): timer-display 32/400 tracking -0.03em; day-total 28/400 tracking -0.03em; title 20/500; palette-input 20/400; body 15/400; body-emphasis 15/500; caption 13/400; micro 12/400; line heights per DESIGN.md. Mapped to scalable text styles; tabular figures helper for time.

UX-DR3: Spacing and radius tokens: 4px grid scale 4, 8, 12, 16, 20, 24, 32, 40; row-height 44; palette-field-height 60; window content padding 20; card gap 24; radii input 8, card 16, panel 20, full pill (nothing below 8 except palette suggestion rows at 10).

UX-DR4: Hairline ring: 1px, black at 5% opacity, drawn inset; Palette panel 10%; raised opacity under Increase Contrast. No drop shadows in content.

UX-DR5: Button primary: Espresso fill, white `caption` text, pill, padding 8×16; the only filled button, at most one per surface.

UX-DR6: Button ghost: transparent, 1px `border-ghost` outline, `text-primary`, `caption`, pill, padding 8×16.

UX-DR7: Card: white, radius 16, hairline ring, padding 16; separated by space, not borders.

UX-DR8: Input field: Mist fill, radius 8, 1px border `text-tertiary`, padding 8×12, `body`; focus shifts border to `action-primary`, no glow.

UX-DR9: Badge: Bone (`surface-inset`) pill, `micro` text, padding 3×10, neutral information only.

UX-DR10: Category dot: 8px circle in the category color, never larger, never a row fill.

UX-DR11: Category token: pill, category color mixed at 22% over `surface-card`, `body-emphasis` `text-primary` text, padding 6×12, no dot; VoiceOver announces the category name.

UX-DR12: Palette panel: opaque white, radius 20, 1px ring at 10%, no material. Order: input field row (60px, line-icon magnifier left, category token, typed text, muted `#tag`), running row on `surface-canvas`, suggestions.

UX-DR13: Palette suggestion rows: 40px, radius 10, name `body`, category name `text-secondary` on the right, shortcut hint `micro`; selected row `surface-inset`; no icons; hover does not move selection.

UX-DR14: Palette uses exactly three type levels (20/15/12). Behavior unchanged: opens focused, closes on Esc/Enter/focus loss, ↑/↓/Tab/Enter, Backspace at start of name removes the token, typed-line grammar `category title #tag -20m`. Reduce Motion removes panel transitions.

UX-DR15: Palette running row: read-only current title, category, elapsed time; no-match first word offers category creation in place (token appears on confirm).

UX-DR16: Journal row: 44px; time of day `caption` `text-secondary`; name `body`; category dot plus category name `text-secondary` right of the name; duration right-aligned, tabular figures; click selects; no icons.

UX-DR17: Journal day header: day name `body-emphasis` with date `caption` below; day total in `day-total` right-aligned with label «в фокусе».

UX-DR18: Journal running entry: row on `surface-inset`, duration in `body-emphasis`, updates every 30 seconds; list width stays stable on selection; split view list + detail kept.

UX-DR19: Journal empty or empty-filter state: one short sentence in `text-secondary`, no illustration.

UX-DR20: Menu bar item: category and elapsed time as plain text, no color, no animation; popover idle state «Таймер не запущен» with the Palette hotkey hint; no extra translucent background; popover running state uses `timer-display`.

UX-DR21: VoiceOver: running timer announces category and elapsed time; category token and dot always accompanied by the category name; color never the only carrier.

UX-DR22: Error strip: one line `text-primary` on `surface-inset` with a line icon, stays until dismissed or cause fixed; no red; microcopy Russian, plain, e.g. «Не удалось сохранить запись. Попробуйте ещё раз.»

UX-DR23: Categories tab: eight tone swatches per row (selected state visible without color alone), no `ColorPicker`, no `randomColor()`, chrome uses tokens, hit targets ≥ 24pt.

UX-DR24: Entry detail, Add-entry sheet, Settings: tokens and base components only, at most one primary button per surface, `.red`/`.blue`/default accent removed, Tab order follows reading order.

UX-DR25: «долго» note: gray `caption` (`text-secondary`) next to the duration in the Journal row and popover; no color, alarm or notification; informational only.

UX-DR26: Grep guardrail: outside the token layer, `App/` contains no hex literals, no system accent / `.red` / `.blue` and no ad-hoc font sizes; a check script or documented command enforces it.

UX-DR27: Component gallery (SwiftUI previews) shows every base component in its states for visual verification.

UX-DR28: Banned everywhere: gradients, bounce or spring animation, sound, Dock badge counts, nagging notifications; motion only functional, short, linear-feeling.

### FR Coverage Map

FR1: Epic 1 - Semantic tokens, base components, preview gallery, grep guard
FR2: Epic 1 - Render-time hex→tone mapping applied to existing category dots
FR3: Epic 5 - Eight swatches, first-unused-tone rule, `ColorPicker`/`randomColor()` removed
FR4: Epic 2 - Palette panel, token, rows in the design language
FR5: Epic 3 - Journal rows, day header, running entry, stable list width
FR6: Epic 4 - Menu bar item and popover
FR7: Epic 5 - Entry detail, add sheet, Categories chrome, Settings, error strip everywhere
FR8: Epic 3 + Epic 4 - 8-hour rule (Journal row), «долго» in popover

## Epic List

### Epic 1: Quiet category colors and the design foundation
Every existing category shows in one of eight muted tones with no data written, and `App/` gains the shared token layer and base components that later epics reuse.
**FRs covered:** FR1, FR2

### Epic 2: Palette in the new style
The Palette becomes an opaque paper panel with a tinted category token, 60px field and 40px rows; behavior and typed-line grammar are unchanged.
**FRs covered:** FR4

### Epic 3: Journal in the new style and the «долго» note
The Journal reads in one calm glance: day header with total «в фокусе», 44px rows, running entry on `surface-inset`; an entry of 8 hours or more carries a gray «долго» until its end time is fixed.
**FRs covered:** FR5, FR8 (rule and Journal row)

### Epic 4: Menu bar and popover in the new style
The menu bar item shows category and elapsed time as plain text; the popover shows «Таймер не запущен» with the hotkey hint when idle, and «долго» beside a long running timer.
**FRs covered:** FR6, FR8 (popover)

### Epic 5: Categories, entry editing, settings and errors
Category color is chosen from eight swatches; Entry detail, add sheet, Categories, Settings and all error messages use the same tokens, and no blue, red or default accent remains in the app.
**FRs covered:** FR3, FR7

Dependencies: Epics 2, 3, 4 and 5 each depend on Epic 1 and on no other epic's output, with one accepted exception: Story 4.3 reuses the «долго» rule created in Story 3.3 (Epic 3 before Epic 4 follows the mandated rollout order; Stories 4.1 and 4.2 do not need it).

## Epic 1: Quiet category colors and the design foundation

Every existing category shows in one of eight muted tones with no data written, and `App/` gains the shared token layer and base components that later epics reuse.

### Story 1.1: Category tone mapping with an App test target

As the author,
I want every stored category color shown as one of eight tones,
So that old bright colors never appear and no data has to change.

*Covers: FR2, NFR1, NFR2, NFR7. Includes adding a Swift Testing target for `App/` logic to `project.yml` (none exists today; Core tests live in the package).*

**Acceptance Criteria:**

**Given** `project.yml` has no test target for `App/`
**When** a `TimeTrackerTests` target is added and `xcodegen generate` is run
**Then** `xcodebuild test -scheme TimeTracker -destination 'platform=macOS'` runs it
**And** a first mapping test is seen failing before any implementation exists

**Given** the eight Core default hexes `#0A84FF #30D158 #FF9F0A #FF453A #BF5AF2 #64D2FF #FFD60A #AC8E68`
**When** each is mapped (also in lowercase)
**Then** they give slate, moss, clay, rose, plum, lagoon, ochre, taupe respectively, all distinct

**Given** a valid `#RRGGBB` hex not in the table
**When** it is mapped
**Then** the nearest tone by Oklab distance is returned
**And** an exact tie goes to the earlier tone in the order clay, ochre, moss, lagoon, slate, plum, rose, taupe

**Given** an empty string, a short hex, or non-hex text
**When** it is mapped
**Then** taupe is returned and nothing throws

**Given** the implementation is done
**When** `git diff` is checked
**Then** `Packages/TimeTrackerCore` has no changes (including its tests)
**And** the mapping is a pure function in `App/` with no `Date()` and no SwiftUI import
**And** the new Swift concepts (`enum` with associated raw values, value types, Swift Testing `@Test`) are explained through TypeScript/React analogies

### Story 1.2: Semantic design tokens

As the author,
I want colors, type, spacing, radii and the hairline ring defined once,
So that every screen draws from the same values.

*Covers: FR1, UX-DR1, UX-DR2, UX-DR3, UX-DR4, NFR4, NFR5, NFR6.*

**Acceptance Criteria:**

**Given** `DESIGN.md` frontmatter
**When** the token layer in `App/` is read in tests
**Then** every color (surface-*, text-*, action-*, border-ghost, eight category tones) equals the DESIGN.md hex
**And** a test seen failing first compares the token hexes to that table

**Given** the typography roles timer-display, day-total, title, palette-input, body, body-emphasis, caption, micro
**When** they are applied
**Then** sizes and weights match DESIGN.md (weights only 400 or 500)
**And** negative tracking exists only on timer-display and day-total
**And** each role is a scalable text style (Dynamic Type) and a tabular-figures modifier exists for ticking and summed time

**Given** the spacing and radius scales
**When** a view needs padding or a corner
**Then** it uses named tokens (4…40 scale, row-height 44, palette-field-height 60, radii 8/16/20/pill)

**Given** the hairline ring modifier
**When** applied to a shape
**Then** it draws 1px black at 5% inset, 10% for the Palette variant, and a higher opacity when Increase Contrast is on
**And** there are no shadows, gradients or materials in the token layer
**And** the Swift concepts used (`extension Color`, `static let`, `ViewModifier`, `@Environment`) are explained via TypeScript/React analogies (design tokens file, HOC/wrapper component, context)

### Story 1.3: Primary button, ghost button and card

As the author,
I want pill buttons and a hairline card,
So that actions and groups look the same on every screen.

*Covers: FR1, UX-DR5, UX-DR6, UX-DR7, UX-DR27.*

**Acceptance Criteria:**

**Given** the primary button style
**When** rendered in a preview
**Then** it has Espresso fill, white `caption` text, pill shape, padding 8×16
**And** it shows normal, pressed, disabled and keyboard-focus states with no glow

**Given** the ghost button style
**When** rendered
**Then** it is transparent with a 1px `border-ghost` outline, `text-primary` `caption` text, pill, padding 8×16, with the same four states

**Given** the card container
**When** rendered over `surface-canvas`
**Then** it is white, radius 16, hairline ring, padding 16, with no shadow
**And** a component gallery preview (SwiftUI `#Preview`) shows all three components in their states
**And** the Swift concepts (`ButtonStyle`, `#Preview`) are explained via TypeScript/React analogies (styled component, Storybook)

### Story 1.4: Input field, badge and error strip

As the author,
I want a quiet input field, a neutral badge and a one-line error strip,
So that forms and failures look calm and consistent.

*Covers: FR1, FR7 (component), UX-DR8, UX-DR9, UX-DR22, UX-DR27.*

**Acceptance Criteria:**

**Given** the input field style
**When** rendered
**Then** it has Mist fill, radius 8, 1px `text-tertiary` border, padding 8×12, `body` text
**And** on focus the border becomes `action-primary` with no glow

**Given** the badge
**When** rendered
**Then** it is a `surface-inset` pill with `micro` text, padding 3×10

**Given** the error strip given a message
**When** rendered
**Then** it shows one line of `text-primary` text on `surface-inset` with a line icon, in no red or orange
**And** it stays until its owner dismisses it or the cause is fixed, and offers an optional ghost action button (e.g. «Всё равно»)

**Given** the gallery previews
**When** opened
**Then** input (empty, filled, focused), badge and error strip (with and without action) are shown
**And** the Swift concepts (`TextFieldStyle`, `@FocusState`) are explained via TypeScript/React analogies

### Story 1.5: Category dot and token; tones on existing dots

As the author,
I want category dots and the category token drawn in the eight tones,
So that existing categories show quiet tones everywhere right away.

*Covers: FR2, FR1, UX-DR10, UX-DR11, UX-DR21.*

**Acceptance Criteria:**

**Given** a stored `colorHex`
**When** the category dot is drawn
**Then** it is an 8px circle in the mapped tone color (Story 1.1)
**And** the dots in `JournalEntriesView`, `RunningTimerView` and `PaletteView` use it instead of `Color(hex:)` with 9–10px circles

**Given** the app is launched with categories created by Core with bright hexes
**When** Journal, Palette and popover are opened
**Then** only the eight tone colors appear and no `colorHex` was written to the store

**Given** the category token
**When** rendered with a category
**Then** it is a pill with the category color mixed 22% over `surface-card`, `body-emphasis` `text-primary` text, padding 6×12, and no dot
**And** its VoiceOver label is the category name, and the dot is hidden from VoiceOver because the name always sits beside it
**And** gallery previews show the token and dot for all eight tones
**And** the Swift concepts (`some View`, computed properties on a value type) are explained via TypeScript/React analogies

### Story 1.6: Token guard script

As the author,
I want a command that fails when a view bypasses the tokens,
So that the "no stray colors or fonts" rule is checked, not remembered.

*Covers: FR1, UX-DR26.*

**Acceptance Criteria:**

**Given** a script in `scripts/` that scans a list of migrated paths
**When** a file in that list contains a hex literal, `.red`, `.blue`, `Color.accentColor`, `.orange`, or a numeric `.font(.system(size:` outside the token layer
**Then** the script prints `file:line` for each hit and exits non-zero
**And** a test (or fixture run) seen failing first proves a violating file is caught

**Given** the migrated-paths list starts with the files already migrated
**When** the script runs on the clean tree
**Then** it exits zero
**And** each later epic adds its files to the list, and the list is documented in `CLAUDE.md` Commands
**And** the Swift/shell concepts are explained briefly via TypeScript/React analogies (lint rule as CI check)

## Epic 2: Palette in the new style

The Palette becomes an opaque paper panel with a tinted category token, 60px field and 40px rows; behavior and typed-line grammar are unchanged.

### Story 2.1: Opaque paper panel and 60px field

As the author,
I want the Palette on a white paper panel with a clean input row,
So that it feels like the rest of the design and not like default glass.

*Covers: FR4, UX-DR12, UX-DR14 (type levels), NFR4.*

**Acceptance Criteria:**

**Given** the Palette is opened
**When** it is rendered
**Then** the panel is opaque white with radius 20 and a 1px ring at 10%
**And** `.regularMaterial`, the drop shadow and the 16pt corner are gone

**Given** the input row
**When** it is rendered
**Then** it is 60px tall with a line-icon magnifier at the left, text in `palette-input` (20/400), and the placeholder in `text-tertiary`
**And** the old `timer` icon and 22pt font are gone

**Given** the keyboard flows (open focused, Esc closes, Enter submits, Tab accepts)
**When** they are exercised in the running app
**Then** they behave exactly as before, and `PalettePanel` focus and close-on-focus-loss are unchanged
**And** `Packages/TimeTrackerCore` is untouched
**And** the Swift concepts (`NSHostingView`, view modifiers order) are explained via TypeScript/React analogies

### Story 2.2: Category token in the typed line

As the author,
I want the category name to turn into a tinted token as I type,
So that I see at a glance which category the line resolves to.

*Covers: FR4, UX-DR11, UX-DR14, UX-DR21, NFR2. Riskiest story of the epic: Core's `PaletteViewModel` exposes only `input` and `items`, so the resolution of the first word is done in `App/`; if Core's parser already exposes it publicly it is reused, otherwise a pure case-insensitive name match is used and covered by tests seen failing first.*

**Acceptance Criteria:**

**Given** the typed first word equals an existing category name
**When** the line is rendered
**Then** the category token (tinted, `body-emphasis`) appears before the typed text
**And** the rest of the line (title, `#tag`, `-20m`) stays editable text, with `#tag` muted

**Given** the token is shown and the cursor is at the start of the remaining text
**When** Backspace is pressed
**Then** the token is removed and its text returns to the line
**And** `viewModel.input` is the same string it would be without the token (grammar `category title #tag -20m` unchanged)

**Given** the first word matches no category
**When** the line is rendered
**Then** no token appears and the Core prompt «Создать категорию» flow works as before

**Given** the resolution logic
**When** unit tests run
**Then** they cover match, no match, case difference, empty line and unicode names, seen failing first
**And** VoiceOver announces the token with the category name
**And** the Swift concepts (`@Bindable`, `@FocusState`, `onKeyPress`) are explained via TypeScript/React analogies (controlled input, refs)

### Story 2.3: Running row, suggestion rows and prompts

As the author,
I want the running row, suggestions and prompts in the design language,
So that the whole Palette reads as one quiet surface.

*Covers: FR4, UX-DR13, UX-DR14, UX-DR15, UX-DR22, UX-DR28.*

**Acceptance Criteria:**

**Given** a timer is running
**When** the Palette is open
**Then** a read-only running row on `surface-canvas` shows title, category dot plus name and elapsed time in tabular figures, using `body` and `micro` only

**Given** suggestions are present
**When** they are rendered
**Then** each row is 40px tall with radius 10, name in `body`, category or hint in `text-secondary` or `micro` at the right, and no icon
**And** the selected row (↑/↓) is on `surface-inset`, and mouse hover does not move the selection
**And** the whole Palette uses exactly three type levels: 20, 15 and 12

**Given** a prompt (create category, overlap, error)
**When** it is shown
**Then** it uses the error-strip look (`text-primary` on `surface-inset`, line icon), with no red and no orange, and keeps its existing wording and keys (⏎, Esc)

**Given** the Palette shows or hides
**When** Reduce Motion is on
**Then** no appear or dismiss transition plays
**And** no gradient, bounce or spring is used
**And** the Swift concepts (`@ViewBuilder`, `@Environment(\.accessibilityReduceMotion)`) are explained via TypeScript/React analogies

### Story 2.4: Palette verification and guard

As the author,
I want the Palette checked against the spec and added to the guard,
So that it cannot drift back.

*Covers: FR4, FR1, UX-DR26, NFR6.*

**Acceptance Criteria:**

**Given** the running app
**When** the Palette is opened in idle, typing, running and prompt states
**Then** screenshots are taken and match the Palette panel spec (opaque white, radius 20, 60px field, tinted token, 40px rows, 20/15/12)

**Given** `App/Palette/*` is added to the token guard list
**When** the guard runs
**Then** it exits zero
**And** Esc, Enter and focus-loss behavior and the typed-line grammar are re-verified by hand with the result noted in the story

## Epic 3: Journal in the new style and the «долго» note

The Journal reads in one calm glance: day header with total «в фокусе», 44px rows, running entry on `surface-inset`; an entry of 8 hours or more carries a gray «долго» until its end time is fixed.

### Story 3.1: Journal rows

As the author,
I want each entry as a calm 44px row,
So that I can scan the day without noise.

*Covers: FR5, UX-DR16, UX-DR18, UX-DR19, UX-DR10. Per DESIGN.md the row no longer carries tags or the start–end range; tags remain in Entry detail and in search.*

**Acceptance Criteria:**

**Given** a finished entry
**When** its row is rendered
**Then** it is 44px tall with time of day (`caption`, `text-secondary`), name (`body`), then the category dot plus the category name in `text-secondary`, and the duration right-aligned in tabular figures
**And** the row has no icon

**Given** the running entry
**When** the list is shown
**Then** its row is on `surface-inset` with the duration in `body-emphasis` instead of «идёт» in the accent color
**And** it updates every 30 seconds as today (via the injected clock, no `Date()`)

**Given** no entries or a filter that matches nothing
**When** the list is empty
**Then** one short sentence in `text-secondary` is shown with no illustration
**And** row hit target is at least 44pt and selection by click and arrow keys still works
**And** the Swift concepts (`List` selection, `Section`, `.tag`) are explained via TypeScript/React analogies

### Story 3.2: Day header with total

As the author,
I want each day to show its name, date and total «в фокусе»,
So that I see how much time the day held.

*Covers: FR5, UX-DR17.*

**Acceptance Criteria:**

**Given** a day group
**When** the header is rendered
**Then** the day name is `body-emphasis` («Сегодня», «Вчера», or weekday) with the date below in `caption`
**And** the total is in `day-total` (28/400, tracking -0.03em, tabular figures) right-aligned with the label «в фокусе»

**Given** a day with entries that include the running one
**When** the clock advances
**Then** the total agrees with the sum of the row durations
**And** the header uses no `.secondary` system styles, only tokens
**And** the Swift concepts (`DayGroup`, formatting with `Text(_:format:)`) are explained via TypeScript/React analogies

### Story 3.3: «долго» rule and note

As the author,
I want an entry of 8 hours or more marked «долго»,
So that a forgotten timer is noticed and fixed.

*Covers: FR8, UX-DR25, NFR2, NFR3. The pure rule is created here and reused by Story 4.3.*

**Acceptance Criteria:**

**Given** the rule as a pure function of `start`, `end` and an injected `now` from `TimeProvider`
**When** unit tests run (seen failing first)
**Then** 7h59m gives no note and 8h00m gives «долго», for finished entries (`end − start`) and running ones (`now − start`)
**And** an entry spanning midnight uses its full duration
**And** no `Date()` and no `sleep` appear in the code or tests

**Given** a Journal row whose entry is 8 hours or more
**When** it is rendered
**Then** a gray `caption` «долго» sits beside the duration, with no color, icon, alarm or notification

**Given** the author edits the end time so the duration is under 8 hours
**When** the change is saved
**Then** the row's duration and the day total update and «долго» disappears
**And** VoiceOver reads the note together with the duration
**And** the Swift concepts (pure functions, protocol-injected clock, Swift Testing `#expect`) are explained via TypeScript/React analogies (dependency injection, fake timers)

### Story 3.4: Stable list width and Journal guard

As the author,
I want the list width to stay put when I select a row,
So that the Journal does not jump.

*Covers: FR5, FR1, UX-DR18, UX-DR26, NFR6.*

**Acceptance Criteria:**

**Given** the Journal split view
**When** a row is selected and deselected repeatedly, and the detail pane appears
**Then** the list width does not change

**Given** the Journal in the running app
**When** screenshots are taken for populated, running-entry, long-entry and empty states
**Then** they match `journal-row` and the day header spec

**Given** `App/Journal/JournalEntriesView.swift` is added to the guard list
**When** the guard runs
**Then** it exits zero
**And** the Swift concepts (`HSplitView` sizing, `frame` min/ideal/max) are explained via TypeScript/React analogies (flex-basis, min/max-width)

## Epic 4: Menu bar and popover in the new style

The menu bar item shows category and elapsed time as plain text; the popover shows «Таймер не запущен» with the hotkey hint when idle, and «долго» beside a long running timer.

### Story 4.1: Menu bar item as plain text

As the author,
I want the menu bar item to show only category and time,
So that it stays quiet next to the system icons.

*Covers: FR6, UX-DR20, UX-DR21, UX-DR28.*

**Acceptance Criteria:**

**Given** a timer is running
**When** the menu bar item is rendered
**Then** it shows the category name and elapsed time as plain text with tabular figures, no color and no animation

**Given** no timer is running
**When** the item is rendered
**Then** it shows the existing idle form with no color

**Given** VoiceOver is on
**When** the item is focused
**Then** it announces category and elapsed time
**And** the Swift concepts (`MenuBarExtra` label, `AppModel` observation) are explained via TypeScript/React analogies

### Story 4.2: Popover in the design language

As the author,
I want the popover to use the tokens and say clearly when nothing runs,
So that it matches the other surfaces.

*Covers: FR6, FR7 (popover errors), UX-DR20, UX-DR22, UX-DR5, UX-DR6.*

**Acceptance Criteria:**

**Given** no timer is running
**When** the popover opens
**Then** it shows «Таймер не запущен» and a hint with the Palette hotkey (from `HotkeyService.shortcutDescription`), on `surface-canvas` with no extra translucent background

**Given** a timer is running
**When** the popover opens
**Then** it shows the category dot and name, elapsed time in `timer-display` (32/400, tabular), the title in `body`, notes in the input field style, and «Остановить» as the only primary button
**And** the other buttons are ghost

**Given** `model.errorMessage` is set
**When** the popover renders
**Then** it uses the error strip, not `.red` text
**And** `RunningTimerView` and `MenuBarContent` use no system fonts such as `.headline` or `.title3` rounded
**And** the Swift concepts (`@State` init, `onChange`) are explained via TypeScript/React analogies

### Story 4.3: «долго» in the popover and menu bar guard

As the author,
I want the popover to mark a very long running timer,
So that I notice a forgotten timer when I open it.

*Covers: FR8, FR1, UX-DR25, UX-DR26.*

**Acceptance Criteria:**

**Given** the running entry has lasted 7h59m
**When** the popover shows it (injected clock)
**Then** no note appears

**Given** the running entry has lasted 8h00m or more
**When** the popover shows it
**Then** a gray `caption` «долго» sits beside the elapsed time, using the rule from Story 3.3, with no color, alarm or notification

**Given** `App/MenuBar/*` and the menu bar label are added to the guard list
**When** the guard runs
**Then** it exits zero
**And** the Swift concepts reused from Story 3.3 are only cross-referenced, not re-explained

## Epic 5: Categories, entry editing, settings and errors

Category color is chosen from eight swatches; Entry detail, add sheet, Categories, Settings and all error messages use the same tokens, and no blue, red or default accent remains in the app.

### Story 5.1: Tone swatches in the Categories tab

As the author,
I want to pick a category color from eight tones,
So that colors stay in the design set.

*Covers: FR3, NFR2, UX-DR23. Tone-choice rule from `category-color-mapping.md`.*

**Acceptance Criteria:**

**Given** the tone-choice rule as a pure function of the categories' mapped tones
**When** unit tests run (seen failing first)
**Then** with no categories the first tone is clay, with clay used the next free one in order clay, ochre, moss, lagoon, slate, plum, rose, taupe is returned, and with all eight used the result is `count % 8`
**And** the value to store is the tone's own hex, which maps to itself

**Given** the Categories tab
**When** a category row is shown
**Then** it offers eight swatches, the current tone marked by more than color alone (ring or check), each at least 24pt and keyboard reachable with a name for VoiceOver
**And** selecting one saves that tone via the existing `setColor`

**Given** a new category is added in the tab
**When** it is saved
**Then** it takes the first unused tone
**And** `ColorPicker` and `randomColor()` no longer exist in `CategoriesView` (checked by grep)
**And** the Swift concepts (`Binding`, `ForEach` over `CaseIterable`) are explained via TypeScript/React analogies

### Story 5.2: Entry detail and add-entry sheet

As the author,
I want the edit form and the add sheet in the design language,
So that fixing a forgotten timer feels like the rest of the app.

*Covers: FR7, UX-DR24, UX-DR22, UX-DR5, UX-DR6, UX-DR8.*

**Acceptance Criteria:**

**Given** Entry detail and the add-entry sheet
**When** they are rendered
**Then** fields use the input-field style, groups sit on cards over `surface-canvas`, and text uses only token type roles
**And** each has at most one primary button (the sheet's confirm); the others are ghost
**And** Tab order follows reading order and every control is keyboard reachable

**Given** a save or overlap problem
**When** it occurs in `EntryFormFields` / `ProblemBanner`
**Then** the error strip shows the Core message, with «Всё равно» as a ghost action for overlap, and no `.red`

**Given** the end time of a long entry is edited and saved
**When** the Journal is shown
**Then** the row and the day total update (flow 3 of `EXPERIENCE.md`)
**And** `App/Journal/EntryDetailView.swift`, `AddEntrySheet.swift`, `EntryFormFields.swift` are added to the guard list and pass
**And** the Swift concepts (`Form`/`formStyle`, sheets, `Binding` of a draft struct) are explained via TypeScript/React analogies

### Story 5.3: Categories chrome, Settings and remaining errors

As the author,
I want Categories and Settings on the same tokens,
So that no screen looks like default SwiftUI.

*Covers: FR7, UX-DR22, UX-DR24, UX-DR26.*

**Acceptance Criteria:**

**Given** the Categories tab, its add row and its error
**When** rendered
**Then** they use tokens and base components, the problem line is the error strip (no `.red`), and at most one primary button is on screen

**Given** the Settings window (hotkeys, export)
**When** rendered
**Then** it uses canvas, cards, ghost and primary buttons from the base set, the export error is the error strip, and no default accent remains

**Given** `CategoriesView.swift` and `SettingsView.swift` are added to the guard list
**When** the guard runs
**Then** they pass
**And** the hotkey recorder control keeps its system look and is not restyled (non-goal: system dialogs)
**And** the Swift concepts (`Settings` scene, `LabeledContent`) are explained via TypeScript/React analogies

### Story 5.4: Whole-app guard and success check

As the author,
I want the guard to cover all of `App/` and a final visual pass,
So that I know the design system is really applied.

*Covers: FR1, FR7, all success signals.*

**Acceptance Criteria:**

**Given** the guard now scans all of `App/` outside the token layer
**When** it runs
**Then** it exits zero: no hex literals, no system accent, `.red`, `.blue` or `.orange`, and no ad-hoc font sizes

**Given** the running app
**When** each screen is opened (Palette, Journal, Entry detail, Add sheet, Categories, Settings, menu bar item, popover)
**Then** only neutral paper tones and the eight category tones are visible
**And** screenshots are recorded in the story

**Given** an entry of 13 hours from the previous day
**When** the Journal is opened and its end time is fixed
**Then** «долго» is shown and then disappears, and the day total updates
**And** `swiftlint` passes and `swift test --package-path Packages/TimeTrackerCore` and the App tests are green
**And** open questions (moving mapping and rule into Core; first-unused tone for Palette-created categories) are listed as follow-ups, not done here
