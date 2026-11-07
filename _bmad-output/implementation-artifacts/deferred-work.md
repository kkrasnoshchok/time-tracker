- source_spec: `_bmad-output/implementation-artifacts/spec-window-fixes-and-journal-hotkey.md`
  summary: Add an App test target to cover the KeyCombo <-> KeyboardShortcuts.Shortcut mapping and the rollback of a rejected hotkey.
  evidence: The duplicate rule is tested in Core only; the glue in SettingsView/HotkeyService has no tests, so dropping the rollback line would pass all 187 tests.

## Deferred from: code review of spec-1-1-category-tone-mapping-with-an-app-test-target (2026-11-01)

- source_spec: `_bmad-output/implementation-artifacts/spec-1-1-category-tone-mapping-with-an-app-test-target.md`
  summary: Hex literals in `App/Support/CategoryTone.swift` (`CategoryTone.hex`, `coreDefaults`) sit outside the token layer.
  evidence: Acknowledged in the spec; Story 1.2 moves the tone hexes into tokens, and the Story 1.6 guard script must migrate or allow-list `coreDefaults`.
- source_spec: `_bmad-output/implementation-artifacts/spec-1-1-category-tone-mapping-with-an-app-test-target.md`
  summary: Add `xcodebuild test -scheme TimeTracker -destination 'platform=macOS'` to the CLAUDE.md "Команды" section.
  evidence: CLAUDE.md lists only `swift test --package-path Packages/TimeTrackerCore`; the App tests run only through the Xcode scheme. Deferred because the fix edits an agent-context file.

## Deferred from: code review of spec-1-2-semantic-design-tokens (2026-11-02)

- source_spec: `_bmad-output/implementation-artifacts/spec-1-2-semantic-design-tokens.md`
  summary: Unverified (possibly medium): `@ScaledMetric` in `TypeRoleModifier` may not scale on macOS, so the "every role scales with Dynamic Type" rule could silently fail.
  evidence: No test or manual check shows `scale` changing with `dynamicTypeSize` on macOS 26; settle it by checking that in a preview or a small test.

- source_spec: `_bmad-output/implementation-artifacts/spec-1-3-primary-button-ghost-button-and-card.md`
  summary: Check that the custom keyboard-focus ring on `.primary`/`.ghost` buttons really shows, and that the system focus ring does not appear beside it.
  evidence: `@Environment(\.isFocused)` may not report focus inside a `ButtonStyle`, and `.focusEffectDisabled()` sits inside the style, so it may not remove the system ring. Unverified (maybe-false, medium if true). Settle by tabbing to a styled button with Full Keyboard Access on; if there are two rings or none, move `.focusEffectDisabled()` to the call site or read focus via `@FocusState`.

## Deferred from: code review of spec-1-4-input-field-badge-and-error-strip (2026-11-02)

- source_spec: `_bmad-output/implementation-artifacts/spec-1-4-input-field-badge-and-error-strip.md`
  summary: Unverified (possibly medium): the `InputField` placeholder may not render in `textTertiary` on macOS, because it is styled through `TextField`'s `prompt`.
  evidence: Not seen in a running field. Settle by placing an `InputField` in a running view and checking the empty-state color.
- source_spec: `_bmad-output/implementation-artifacts/spec-1-4-input-field-badge-and-error-strip.md`
  summary: Unverified (possibly medium): the parent `onTapGesture` in `InputField` may disturb caret placement, drag selection or double-click.
  evidence: Settle by clicking and selecting text in a running field; if broken, move the tap to a background layer.
- source_spec: `_bmad-output/implementation-artifacts/spec-1-4-input-field-badge-and-error-strip.md`
  summary: Tabbing to a real `InputField` (border becomes `actionPrimary`) is not checked, and no screen hosts one yet.
  evidence: The AC is manual; check it together with the open Story 1.3 focus-ring item, at the first story that puts an `InputField` on a screen.

## Deferred from: code review of spec-1-5-category-dot-and-token-tones-on-existing-dots (2026-11-02)

- source_spec: `_bmad-output/implementation-artifacts/spec-1-5-category-dot-and-token-tones-on-existing-dots.md`
  summary: Pin `CategoryToken`'s 22% fraction and `surfaceCard` base with a test when the first screen uses the token.
  evidence: Only the gallery renders it today; changing `tintFraction` or the base would keep all tests green.
- source_spec: `_bmad-output/implementation-artifacts/spec-1-5-category-dot-and-token-tones-on-existing-dots.md`
  summary: Gallery preview and the three screens (Journal, popover, Palette) were not looked at on screen.
  evidence: Only build, tests and greps ran; check eight dots and tokens in the canvas and the running app.

## Deferred from: code review of spec-1-6-token-guard-script (2026-11-02)

- source_spec: `_bmad-output/implementation-artifacts/spec-1-6-token-guard-script.md`
  summary: Widen the token guard patterns to other system colors (`.green`, `.gray`, ...), implicit `.accentColor`, `Font.system(size:)` outside `.font(`, and non-literal sizes.
  evidence: The guard only matches the spec's exact list, so `.tint(.accentColor)` or `.foregroundStyle(.green)` in a migrated file passes; decide when a later epic migrates such code.
  also not matched (found in code review): `Color(red:green:blue:)`, `0x` integer literals, 3-digit and 8-digit hex shorthand beyond the 6-digit prefix, `NSColor.red`/`UIColor.red` (the `.red` rule needs a non-identifier char before the dot), `.systemBlue`-style colors, and `.font(.system(` split across lines or with extra spaces.

- source_spec: `_bmad-output/implementation-artifacts/spec-1-6-token-guard-script.md`
  summary: CLAUDE.md does not say when to run `scripts/check-tokens.sh` (before finishing a UI task) or what the exit codes mean.
  evidence: Nothing runs the guard automatically (hooks and CI are out of scope), so only a rule in CLAUDE.md makes it a habit; the fix edits an agent-context file, so it needs a deliberate decision.

## Resolved in epic 1 retrospective (2026-11-02)

- Guard patterns widened (system colors, `.accentColor`, `Color(red:)`, `0x`, 3-digit hex, `.systemBlue`, `.system(size:` any value or line-split); fixtures `bad-named-more`, `bad-literals`, `bad-font-more`, `clean-lookalikes` seen failing first. `App/Support/CategoryTone.swift` stays unlisted on purpose (documented in `scripts/token-guard-paths.txt`).
- `CategoryToken` 22% fraction and `surfaceCard` base pinned by `CategoryTokenTests` in `AppTests/CategoryTintTests.swift`.
- Six manual checks (Dynamic Type, focus ring, placeholder, tap gesture, tab focus, dots on screens) moved into acceptance criteria of Stories 2.1, 3.1 and 4.2 in epics.md (A4). CLAUDE.md rules (A2) and the commit-subject rule (A5) were added.

## Deferred from: code review of spec-2-1-opaque-paper-panel-and-60px-field (2026-11-02)

- `PaletteController.show()` / `PalettePanel.resignKey()`: the palette may close right after opening if the panel resigns key during activation (hotkey race). Unverified, medium if real. Settle by opening it with the hotkey from several apps in Story 2.4.
- `PaletteView` fixed-light card in system dark mode: caret, selection and `Divider()` follow the system appearance, so the caret may be white on white. Unverified, medium if real. Settle by checking the field in system dark mode (Story 2.4).
- Story 2.1 manual checks not done: keyboard flows, visual result, `typeRole` Dynamic Type scaling, eight-tone dots, `prompt:` styling under `.plain`. The spec hands them to the author and Story 2.4.

## Deferred from: build of spec-2-2-category-token-in-the-typed-line (2026-11-02)

- source_spec: `_bmad-output/implementation-artifacts/spec-2-2-category-token-in-the-typed-line.md`
  summary: Partly settled (author saw token, tag styling and Backspace work in the running Palette); still unchecked: the `#tag` muting layer behind the transparent-text `TextField` may drift on long lines and the caret may be wrong after Backspace dissolves the token.
  evidence: Not seen in the running Palette (hotkey cannot be sent here). Settle by typing a long line with `#tags` and pressing Backspace at the start of the text, in Story 2.4; if it fails, replace the layered field with an `NSTextField` wrapper.
- source_spec: `_bmad-output/implementation-artifacts/spec-2-2-category-token-in-the-typed-line.md`
  summary: Leading whitespace before the category name gives no token although `PaletteParser` accepts it.
  evidence: `CategoryResolver.split` anchors at the string start; low, trim in Story 2.4 if it shows up.

## Deferred from: code review of spec-2-2-category-token-in-the-typed-line (2026-11-02)

- Stale `TextSelection` when the token appears or disappears without Backspace (Tab completion, typing the space, clear, submit): caret may sit before the anchor or out of range. Unverified, medium if real. Settle by pressing Backspace after each of those in the running Palette (Story 2.4).
- Accessibility of the transparent `TextField` over the drawn `Text`: U+200B in the field value may be spoken by VoiceOver, nothing in the field says a token is active, the token label «Категория …» is not heard-checked. Unverified, medium if real. Settle with VoiceOver on the palette in token mode (Story 2.4).
- `#tag` layer drift on a long line: same item as the Story 2.2 build entry above; still open, `NSTextField` wrapper is the fallback.

## Deferred from: code review of spec-2-4-palette-verification-and-guard (2026-11-04)

- source_spec: `_bmad-output/implementation-artifacts/spec-2-4-palette-verification-and-guard.md`
  summary: Token guard patterns miss `Color.white`/`.black`, `NSFont`, `Font.custom` and `.system(.title)`-style fonts.
  evidence: Pre-existing guard design; `App/Palette` has none of these today (grep found nothing). Add patterns with fixtures seen failing first when a migrated file needs one.

## Resolved in epic 2 retrospective (2026-11-04)

Author-reported on 2026-11-04 (no screenshots or per-item notes; accepted as sufficient evidence):
- Hotkey race: the palette does not close right after opening from several apps (2.1).
- System dark mode: caret, selection and divider are visible in the fixed-light card (2.1).
- 2.1 leftovers: `typeRole` follows system text size, eight-tone dots, placeholder color, click and selection in the field, Tab focus ring.
- `#tag` layer drift on a long line (2.2); stale `TextSelection` after Tab completion, typing the space, clear and submit (2.2); VoiceOver announces the token and does not speak U+200B (2.2); Backspace dissolving the token (fixed in `5881471`).
- Leading whitespace before the category name gives no token (2.2): left as is, trim only if it shows up.

Closed in the review of 3-1 (2026-11-04): the guard now catches `Color.white`/`.black`, `NSFont`, `Font.custom`, `.system(.title)`-style fonts, `.fontWeight(.light)`, qualified `Color.secondary`/`.primary`, `.custom(` and `.weight()` (retro action A4; the author closes A4 in `sprint-status.yaml`). Still not caught: modifier arguments wrapped onto the next line, e.g. `.font(` then `.title)`.

## Deferred from: code review of spec-3-1-journal-rows (2026-11-04)

- Running entry has no VoiceOver cue now that «идёт» is gone (row has no combined accessibility element or label). Decided: do it in Story 3.3 together with «долго».
- No automated check for `EntryRow` running/non-running choice, the «Без названия» fallback or the two empty-state sentences. Extract a pure helper and test it in `AppTests` when 3.3/3.4 touch the row.
- The four manual checks of 3.1 are unticked (retro A6, author-owed).
- Guard still misses modifier arguments wrapped onto the next line (`.font(` / `.title)`); a `$` alternative would flag legitimate wrapped `Typography.*` calls.

## Added after Story 3.2 (2026-11-04), author decisions

- source_spec: `_bmad-output/implementation-artifacts/spec-3-2-day-header-with-total.md`
  summary: Future epic: dark theme. The author saw the Journal looking worse in system dark mode; the app is light-only in v1 (DESIGN.md, epics non-goals).
  evidence: Tokens are semantic, so a dark set can be added later; the fixed-light Palette card and the open dark-mode caret/selection items above belong to the same epic.
- source_spec: `_bmad-output/implementation-artifacts/spec-3-2-day-header-with-total.md`
  summary: Selected Journal row shows the native system blue; moved into Story 3.4 as an AC (surface-inset plus HairlineRing).
  evidence: Author feedback while checking 3-2 in the running app; epic 3 context and `epics.md` updated.

## Deferred from: code review of spec-3-2-day-header-with-total (2026-11-04)

- No automated check that `DayHeader` passes the ticking `model.now` into `liveTotal(at:)` (replacing it with `group.asOf` keeps all Core tests green and freezes the header). Thin view glue; the author's manual check «header total moves with the running row» settles it. Extract a pure helper only if 3.4 touches the header again.
- The three manual checks of 3-2: author-reported done on 2026-11-05 (no screenshots; accepted as in epic 2). Closed.
- Near-midnight edge (accepted, rejected as low): until the next reload the old «today» group keeps growing and the title flips to «Вчера». Revisit if a regroup-on-day-change trigger is added.

## Deferred from: code review of spec-3-3-dolgo-rule-and-note (2026-11-05)

- `.accessibilityElement(children: .ignore)` on the `EntryRow` of `List(selection:)` may drop the selected trait or row actions in VoiceOver (unverified medium). Settle with the author's VoiceOver check: the selected row must be announced as selected. If not, switch to `.combine` plus `.accessibilityAddTraits(isSelected ? .isSelected : [])`, as in `PaletteView.swift:200`.
- No automated check that `EntryRow` feeds `entry.start`, `entry.end`, `now` into `LongEntry.isLong` and the real title, category and duration into `EntryRowText.accessibilityLabel`. Thin private-view glue; the author's manual checks cover it. Extract a pure `EntryRowModel(entry:now:)` only if 3.4 touches the row again.
- The «долго» note widens the trailing group: the category column shifts on long rows, and the title may truncate earlier. Belongs to Story 3.4 (stable list width); recheck there.

## Deferred from: code review of spec-3-4-stable-list-width-and-journal-guard (2026-11-05)

- Arrow keys may not move selection right after a click or while the search field has focus (unverified medium). Settle: click a row and press ↓/↑; then focus the search field and press ↓.
- VoiceOver may not select a Journal row: `onTapGesture` + `.isButton`, `children: .ignore`, no `accessibilityAction` (unverified medium, same open item as the 3-3 deferral). Settle: VO+Space on a row selects it and it is announced as selected.
- Detail pane content may overflow the fixed 400pt width (unverified medium; the cause of the original width change was never confirmed by diagnostics). Settle: check the width with a long title, note and many tags.
- `epic-3-context.md` line 24 and the frozen block of spec 3-4 still say `surface-inset` + `HairlineRing`; shipped is `surface-selected`, no ring. Update on the author's say-so.

## Deferred from: code review of story 4-2 popover-in-the-design-language (2026-11-05)

- `App/MenuBar/MenuBarContent.swift` and `RunningTimerView.swift` are migrated to tokens but not in `scripts/token-guard-paths.txt`, so a return to `.headline`, `.secondary` or `.red` passes `scripts/check-tokens.sh`. Planned for Story 4.3 (epic-4-context); add both files there and run the guard. Raw numbers (70pt notes height, 340pt width, placeholder offsets `Space.x3 + 5`, `Space.x2 + 1`) are not caught by the guard either.
- `DayHeader.title` decides «Сегодня»/«Вчера» with `Calendar.current` (system clock) instead of the `now` it already receives, so it is untestable. Pre-existing, moved unchanged in `764b3ab`. Extract a pure helper taking `now` and a calendar if the header is touched again.

## Deferred from: code review of spec-4-3-long-in-the-popover-and-menu-bar-guard (2026-11-05)

- `RunningTimerView.elapsedRow` wiring (`entry.start` + `model.now` into `PopoverText.longNote`, `isLong: note != nil`, `.accessibilityElement(children: .ignore)`) has no automated test; only the pure helpers are covered. Repo has no SwiftUI view tests. Settle it with the manual check owed in the spec (timer 8h+ via a shifted start in a debug store: gray «долго» on the baseline beside the 32pt timer, fits 340pt, VoiceOver reads time plus «долго»). If a swapped flag or time source ever matters, move the `note`/label decision into one pure function and test that.

## Deferred from: code review of spec-4-1-menu-bar-item-as-plain-text (2026-11-06)

- VoiceOver on the menu bar item is not verified: it should read category and elapsed time (unverified medium, spec 4-1). The visual check passed on 2026-11-07 (plain `Text`, no color, no jitter). The author postponed VoiceOver until before release. Settle: run the app, VO on the menu bar item.
- Static `.accessibilityLabel` on a ticking menu bar label may not be re-read or may go stale (unverified, low to medium). Settle in the same VoiceOver run: wait past a minute, re-focus the item. If stale, add `.accessibilityAddTraits(.updatesFrequently)` or an `accessibilityValue`.

- source_spec: `_bmad-output/implementation-artifacts/spec-5-1-tone-swatches-in-the-categories-tab.md`
  summary: `Color.hexString` in `App/Support/Color+Hex.swift` is now used only by tests after `ColorPicker` was removed; delete it (and its test usage) or keep deliberately.
  evidence: grep shows references only in `AppTests/DesignTokenTests.swift`; candidate for the whole-app cleanup in Story 5.4.
