- source_spec: `_bmad-output/implementation-artifacts/spec-window-fixes-and-journal-hotkey.md`
  summary: Add an App test target to cover the KeyCombo <-> KeyboardShortcuts.Shortcut mapping and the rollback of a rejected hotkey.
  evidence: The duplicate rule is tested in Core only; the glue in SettingsView/HotkeyService has no tests, so dropping the rollback line would pass all 187 tests.
