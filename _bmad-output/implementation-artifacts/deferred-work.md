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
