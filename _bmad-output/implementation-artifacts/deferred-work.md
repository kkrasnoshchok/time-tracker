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
