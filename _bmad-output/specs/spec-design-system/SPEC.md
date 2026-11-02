---
id: SPEC-design-system
companions:
  - ../../planning-artifacts/ux-designs/ux-time-tracker-2026-11-01/DESIGN.md
  - ../../planning-artifacts/ux-designs/ux-time-tracker-2026-11-01/EXPERIENCE.md
  - category-color-mapping.md
sources: []
---

> **Canonical contract.** This SPEC and the files in `companions:` are the complete, preservation-validated contract for what to build, test, and validate. Source documents listed in frontmatter are for traceability — consult them only if you need narrative rationale or prose color this contract intentionally omits.

# Time Tracker design system

## Why

A vision to realize: the app works but looks like default SwiftUI with system blue/red and a free color picker. The author (sole user) has a finished visual identity (`DESIGN.md`: quiet paper tones, pills, hairline depth, eight muted category tones) and behavior spine (`EXPERIENCE.md`) and wants them built into the macOS app once, as reusable tokens and components, so later screens are not restyled twice.

## Capabilities

- **CAP-1**
  - **intent:** App code draws every surface from a shared semantic token layer (colors, type, spacing, radii, hairline ring) and a small set of base components: primary and ghost button, card, input field, badge, category dot, category token.
  - **success:** Token values equal `DESIGN.md` frontmatter. Outside the token layer, `App/` has no hex literals, no system accent/`.red`/`.blue` colors and no ad-hoc font sizes (checked by grep). A preview or screenshot shows each component in its states.

- **CAP-2**
  - **intent:** Any stored category `colorHex` is displayed as one of the eight category tones, with no change to stored data.
  - **success:** Unit tests (seen failing first) cover the mapping in `category-color-mapping.md`: all eight Core default hexes map to their distinct tones, an arbitrary hex maps to the nearest tone, an invalid hex maps to taupe. Existing categories show only tone colors after launch with no data written.

- **CAP-3**
  - **intent:** The user picks a category's color from the eight tones in the Categories tab; free color input is gone.
  - **success:** `ColorPicker` and `randomColor()` no longer exist in `CategoriesView`. A row offers eight swatches and selecting one saves that tone. A category added there takes the first unused tone, cycling after eight. Verified by tests of the choice rule and by running the app.

- **CAP-4**
  - **intent:** The Palette panel follows `DESIGN.md` and the Palette rows of `EXPERIENCE.md`.
  - **success:** Screenshot matches the Palette panel spec (opaque white panel, radius 20, 60px field, tinted category token, 40px suggestion rows, three type levels 20/15/12, no icons in rows); Esc/Enter/focus-loss behavior and typed-line grammar unchanged.

- **CAP-5**
  - **intent:** The Journal shows days, rows and totals in the design language.
  - **success:** Screenshot matches `journal-row` (44px, dot + gray category name, tabular duration) and day header with `day-total` and «в фокусе»; the running entry sits on `surface-inset` with `body-emphasis` duration. List width stays stable on selection.

- **CAP-6**
  - **intent:** The menu bar item and popover show the running category and elapsed time in the design language.
  - **success:** Item shows category and elapsed time as plain text, no color or animation; popover shows «Таймер не запущен» with the Palette hotkey hint when idle; no extra translucent background.

- **CAP-7**
  - **intent:** Entry detail, add-entry sheet, Categories chrome, Settings and error messages use the same tokens and components.
  - **success:** Errors render as one `text-primary` line on a `surface-inset` strip with a line icon (no `.red`, which `CategoriesView` uses today); each remaining screen passes the CAP-1 grep check and has at most one primary button.

- **CAP-8**
  - **intent:** An entry that lasted 8 hours or more carries the note «долго», so a forgotten timer is noticed.
  - **success:** Tests with an injected clock (seen failing first): 7h59m shows no note, 8h00m shows «долго», for both running and finished entries. The note is a gray `caption` beside the duration in the Journal row and the popover, disappears once an edit brings the duration under 8h, and uses no color, alarm or notification.

## Constraints

- Rollout order is Palette (CAP-4), Journal (CAP-5), menu bar (CAP-6), the rest (CAP-7); CAP-1 and CAP-2 come first because the rest depends on them, CAP-3 and CAP-8 follow the surface they live on.
- `Packages/TimeTrackerCore` is not modified, including its tests. It still creates categories with the old bright hexes, so the color change is render-time mapping, never a data rewrite.
- Tokens and components live in `App/`; views hold no business logic. The hex→tone mapping and the 8-hour check are small pure functions in `App/` with unit tests that were seen failing first.
- "Now" comes from `TimeProvider`, never `Date()`; time stays UTC.
- Tokens are semantic (`surface-*`, `text-*`, `action-*`), light theme only. No Liquid Glass or materials inside our surfaces, no gradients, shadows, glow, or red/green/blue anywhere.
- Weights 400 and 500 only; negative tracking only on `timer-display` and `day-total`; tabular figures for any ticking or summed time.
- Accessibility floor of `EXPERIENCE.md` holds: keyboard reachability, VoiceOver names for token and timer, text styles that scale, hit targets ≥ 24pt (rows ≥ 44pt), Reduce Motion removes panel transitions.
- Swift 6 strict concurrency; new Swift concepts are explained after each task through TypeScript/React analogies.

## Non-goals

- Dark theme.
- Any change to Core, data model, palette grammar or hotkeys.
- A hotkey or command to stop the timer, and a "stop now" action in Entry detail (product gaps tracked in `EXPERIENCE.md`).
- Rewriting stored `colorHex` values in the database.
- Custom window chrome, replacing the menu bar item, or restyling system dialogs.

## Success signal

Every screen of the running app shows only neutral paper tones plus the eight category tones; no blue, red, system picker or default accent remains. A 13-hour forgotten entry from yesterday is visibly marked «долго», and fixing its end time in the Journal removes the mark.

## Assumptions

- The mapping and 8-hour check live in `App/` because Core is off-limits; this departs from the CLAUDE.md rule that logic lives in Core, on the author's instruction.
- «долго» is evaluated per entry from its duration (running: `now − start`); entries spanning midnight use their full duration.
- 8 swatches in the Categories tab are enough; two categories sharing a tone beyond eight is acceptable.

## Open Questions

- After this stage, may the mapping and the «долго» rule move into Core, to match the CLAUDE.md rule and let CSV export or other consumers reuse them?
- Should the Palette's in-place category creation also take a tone from the same "first unused" rule? Today Core assigns the bright hex and CAP-2 hides it, but two categories can then render in one tone while others are free.
