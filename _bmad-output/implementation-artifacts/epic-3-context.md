# Epic 3 Context: Journal in the new style and the «долго» note

<!-- Compiled from planning artifacts, epic-2-context.md, the epic 2 retro and deferred-work.md. Edit freely. -->

## Goal

The Journal reads in one calm glance: a day header with the total «в фокусе», 44px rows, the running entry on `surface-inset`, and a gray «долго» beside the duration of any entry of 8 hours or more until its end time is fixed. Behavior (selection by click and arrows, 30-second running update, detail pane) does not change; this is a restyle plus one small pure rule.

## Stories

- Story 3.1: Journal rows
- Story 3.2: Day header with total
- Story 3.3: «долго» rule and note
- Story 3.4: Stable list width and Journal guard

## Requirements & Constraints

- Row (finished): 44px, no icon. Order: time of day (`caption`, `text-secondary`), name (`body`), category dot + category name (`text-secondary`), duration right-aligned in tabular figures. No tags and no start–end range in the row (they stay in Entry detail and search).
- Row (running): `surface-inset`, duration in `body-emphasis` instead of «идёт» in the accent color; updates every 30 s through the injected clock.
- Empty list or empty filter result: one short sentence in `text-secondary`, no illustration. Hit target ≥ 44pt; click and arrow-key selection keep working.
- Day header: day name in `body-emphasis` («Сегодня», «Вчера», weekday), date below in `caption`; total in `day-total` (28/400, tracking -0.03em, tabular) right-aligned with the label «в фокусе». The total equals the sum of the row durations, including the running one. Tokens only, no `.secondary` system styles.
- «долго»: pure function of `start`, `end`, injected `now` (`TimeProvider`). 7h59m none, 8h00m yes; finished = `end − start`, running = `now − start`; midnight-spanning uses full duration. Rendered as gray `caption`, no color, icon, alarm or notification. Disappears after the end time is edited below 8 h; day total updates. VoiceOver reads the note together with the duration. Story 4.3 reuses the rule, so it must live where the popover can import it.
- Stable width: list width does not change when a row is selected, deselected, or the detail pane appears. A fix already landed in `spec-window-fixes-and-journal-hotkey.md` (done); Story 3.4 verifies it still holds after the restyle. Only change layout code after a regression is seen in the running app.
- Selected row (added after 3.2 by the author): no system blue selection; `surface-inset` fill plus `HairlineRing` at `Radius.row`; the running row is `surface-inset` without a ring, so a selected running row shows both. Lives in Story 3.4 with the width check; hide the `List` native highlight (e.g. `listRowBackground`, `.tint`/`scrollContentBackground` as needed) and check it in the running app (retro A6).
- Dark theme is out of scope for v1 (DESIGN.md: light only); recorded as a future epic.
- Weights 400/500 only, negative tracking only on `day-total` (and `timer-display`). Dynamic Type via `typeRole`; tabular figures modifier for time.
- `Date()` is forbidden in logic and tests; no `sleep`. Time is stored in UTC; "now" comes from `TimeProvider`.
- Logic belongs in `Packages/TimeTrackerCore` where it is pure and shared (the «долго» rule, day totals if not already there); `App/Journal` views only render state.
- Last story adds `App/Journal/JournalEntriesView.swift` to `scripts/token-guard-paths.txt`; `scripts/check-tokens.sh` must exit 0. Per retro A4 the guard is widened first (see below). Run the guard at the end of every UI task.
- Commit subjects name the story: `feat(3-1): …`, `test(3-3): …`.

## Technical Decisions

- Tokens and components come from `App/Design` (`ColorToken`, `typeRole`, `Spacing`, `Radius.row`, `HairlineRing`, `CategoryDot`, `ErrorStrip`). `Space.rowHeight` (44) already exists and is pinned in `DesignTokenTests` (line 63); use it for the Journal row instead of adding a token. Epic 2's `Radius.row` (10) and `Space.suggestionRowHeight` (40) are pinned the same way.
- Palette patterns that Journal may reuse (retro A5, F6): tag muting (`PaletteView.mutingTags(in:)`) and category-name matching (`CategoryResolver`). Journal rows do not show tags, so muting is probably not needed in 3.1; if a story does need it or the matching, stop and decide **before** coding whether to move it into Core's `PaletteParser` (retro Q1) — author decision.
- App tests: `xcodebuild test -scheme TimeTracker -destination 'platform=macOS'`; new `App/` files need `xcodegen generate`. Core tests: `swift test --package-path Packages/TimeTrackerCore`.
- Swift-concept explanations (TypeScript/React analogies) are owed after each story, as listed in its ACs. Also still owed from epic 2: retro A7 (`explain-change` over `83a143b..f648064`).

## Open items carried in (from deferred-work.md and the epic 2 retro)

Journal-relevant and still open:
- **Guard gaps (retro A4, review of 2-4, F7): closed at the start of this epic** (fixtures seen failing first, `scripts/test-check-tokens.sh` green). The guard now also flags `white`/`black`, `NSFont`/`UIFont`, `Font.custom`, `.system(.title)`-style fonts, `.font(.headline)`-style text styles, `.foregroundStyle(.secondary)`-style system styles, `.bold()`, any `.fontWeight` other than `.regular`/`.medium`, and `Color(white:)`/`Color(.sRGB, …)`. `HairlineRing.swift` is exempt only under `Design/`. Two author-approved `.fontWeight(.light)` calls (Palette magnifier, `ErrorStrip` icon) were removed to satisfy the 400/500 rule. Known remaining weaknesses: matches inside comments and strings, and a `.fontWeight(` call split across lines is flagged only on its first line. `ColorToken.swift` and `Typography.swift` are still exempt by file name anywhere. The `clean-lookalikes` fixture lost its `Font.custom` line because it now contradicts the rule.
- **Journal on screen (spec-1-5):** category dots and tokens "were not looked at on screen" in the Journal. Covered by the manual-check AC of Story 3.1 (dots in their tones with the category name beside them, no row filled with a tone).
- **List width (spec-window-fixes-and-journal-hotkey):** that spec is `done`; its width and full-height fix (`HSplitView` with `frame(minWidth:idealWidth:maxWidth:)` in `JournalEntriesView.swift:35-39`) was confirmed by the author at the time. Story 3.4 AC1 re-verifies it after the 3.1–3.3 restyle; do not treat it as an open bug, and run the check in the running app before changing any layout code.
- **App test target for hotkey glue (spec-window-fixes-and-journal-hotkey):** `KeyCombo` ↔ `KeyboardShortcuts.Shortcut` mapping and rollback of a rejected hotkey (including the Journal hotkey) have no App tests. Not part of Epic 3's ACs; keep deferred unless the author pulls it in.
- **Retro A5 / F6:** `PaletteView.mutingTags` placement and `PaletteView.swift` size (267 lines). Journal does not require it unless a story reuses the helper; see Technical Decisions.
- **Retro Q1:** move category-name matching into Core `PaletteParser`? Open; needs the author's decision when Journal needs the resolver.
- **Retro A6:** for stories that depend on text-field or key handling, run the manual check in the running app before code review, not after. Applies to 3.1 (arrow-key selection) and 3.4 (split view width).
- **Retro Q2 (resolved):** an author-reported tick is enough evidence for visual ACs; no screenshots required. Still ask for one line per item when the author reports a manual check. Story 3.4 AC2 mentions screenshots; treat author-reported results as satisfying it.

Not carried (not about the Journal): Dynamic Type/`InputField`/focus-ring items (settled in Epic 2 or moved to Story 4.2), the CLAUDE.md edits (done), the Palette items resolved in the epic 2 retro.

## Cross-Story Dependencies

- Depends on Epic 1 only (tokens and base components), plus the closed guard gaps above.
- 3.1 builds the row; 3.2 adds the day header above it and needs 3.1's row durations for the total agreement check; 3.3 adds the rule and the «долго» note to the row from 3.1 and updates the day total from 3.2; 3.4 fixes list width and adds `JournalEntriesView.swift` to the guard once 3.1–3.3 have migrated it.
- Story 4.3 (Epic 4) reuses the «долго» rule from 3.3, so keep it a public, UI-free function.
