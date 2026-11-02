---
title: 'Category token in the typed line'
type: 'feature'
created: '2026-11-02'
status: 'done'
route: 'oneshot'
review_loop_iteration: 0
context:
  - '{project-root}/_bmad-output/implementation-artifacts/epic-2-context.md'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** The Palette input row shows the typed category as plain text, so the author cannot see at a glance which category the line resolves to. Story 2.2 of `_bmad-output/planning-artifacts/epics.md`. Core's `PaletteViewModel` exposes only `input` and `items`, and `PaletteParser` does not expose the matched prefix, so the first-word resolution lives in `App/`.

**Approach:** Add a pure `CategoryResolver` in `App/Palette` (case-insensitive, longest name wins, the name must be followed by whitespace) that splits `input` into the typed prefix, the matched category and the rest. `PaletteView` shows a `CategoryToken` (tone from the category's stored color) before a `TextField` bound to the rest only; `viewModel.input` stays the single source of truth (`prefix + rest`), so the grammar is unchanged. Backspace with the caret at the start of the rest drops the prefix's trailing space, which removes the token and returns its text to the line. `#tag` words are muted by a styled text layer under a clear-text field. The token is announced to VoiceOver as «Категория <name>». Core, running row, suggestion rows and prompts are untouched (Stories 2.3, 2.4). New Swift concepts (`@Bindable`, `@FocusState`, `onKeyPress`, custom `Binding`) are explained afterwards via TypeScript/React analogies (controlled input, refs).

</frozen-after-approval>

## Implementation Notes

- Decision: the token appears only when the category name is followed by whitespace (so typing a full name without a space stays plain text, and Tab completion `Name ` makes the token at once).
- Decision: `#tag` muting uses a layered `Text(AttributedString)` behind a transparent-foreground `TextField`; known limit: if the line scrolls inside the field the layers can drift. To be checked in the running app.
- TDD: `AppTests/CategoryResolverTests.swift` seen failing first (match, no match, case, empty line, unicode, longest name, no trailing space).
- Files: new `App/Palette/CategoryResolver.swift`, `AppTests/CategoryResolverTests.swift`; changed `App/Palette/PaletteView.swift` (token, rest-only field binding, Backspace via `TextField(selection:)`, `mutingTags`). Core untouched.
- Result: build, 37 App tests, `swiftlint` and `scripts/check-tokens.sh` pass. `mutingTags` tests were added after the code, not seen failing first.
- Not verified in the running app (hotkey cannot be sent here): token look, Backspace dissolving the token, caret position after it, `#tag` layer alignment, VoiceOver label.
- Review: no review subagent was launched (no instruction to use subagents); the diff was read by hand.

## Review Triage Log

- low (rejected): a line with leading whitespace before the category name (` Работа x`) gets no token, while the parser still accepts it. Rare, and the fix adds a trimming rule beyond a simple correction.
- low (rejected): `store.categories()` is fetched up to three times per render. The view model already fetches per keystroke; a cache would add state.
- maybe-false (deferred): the `#tag` muting layer can drift from the field when the line scrolls inside the field, and the transparent-text field may show a different caret or selection look. Would be settled by typing a long line with tags in the running Palette.
- maybe-false (deferred): after Backspace removes the token, the caret may not land between name and text. Would be settled by pressing Backspace in the running Palette.

## Post-review fix (author test in the running app)

- Bug: Backspace never removed the token. The text field handles Backspace itself, so `onKeyPress(.delete)` never fired.
- Fix: while a token is shown the field text starts with an invisible anchor (`U+200B`); deleting it dissolves the token (`CategoryResolver.fieldText` / `input(afterEditing:)`, tests seen failing first). `onKeyPress(.delete)` removed. Build, 43 App tests, swiftlint and the token guard pass; the fix itself is not yet seen in the running app.
