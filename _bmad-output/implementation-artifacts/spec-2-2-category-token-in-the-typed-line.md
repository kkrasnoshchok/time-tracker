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
- Confirmed by the author in the running Palette: Backspace removes the token, tag muting and token look are fine. This settles the two deferred Story 2.2 items about layer drift and caret position (long-line drift was not specifically tried).

### Review Findings

Code review 2026-11-02 (Blind Hunter, Edge Case Hunter, Verification Gap, Acceptance Auditor). The frozen Intent block was not touched.

- [x] [Review][Decision] (resolved: option (a), patched) Two spaces after the category name: Backspace removes one space and the token stays — `CategoryResolver.split("Работа  два")` gives prefix `Работа `, rest ` два`; Backspace yields `Работа два`, which still resolves to a token (two Backspaces needed), and `selection` (an index into `input`) is applied to the anchor-prefixed field text. Options: (a) keep "one Backspace = one space", set the caret only when the new line no longer resolves; (b) dissolve the token by removing the whole whitespace run. [App/Palette/CategoryResolver.swift:15, App/Palette/PaletteView.swift:84]
- [x] [Review][Patch] `#tag` right after the token is never muted — in token mode the muted text starts with U+200B (not whitespace, not `#`), so `Работа #ops` leaves `#ops` plain; `mutingTags` tests never use the anchor. Skip a leading anchor in `mutingTags` and add a test. [App/Palette/PaletteView.swift:123]
- [x] [Review][Patch] Caret after dissolve uses the canonical `split.name.count`, not the typed prefix length (`prefix.count - 1`); a case-insensitive match of a different length (ß/SS) can misplace the caret or run `offsetBy` past `endIndex`. The setter, `dissolved` check and caret offset have no test. Move the offset into a pure `CategoryResolver` function (from `prefix.dropLast().count`) and test it next to `deletingTheAnchorDissolvesTheToken`. [App/Palette/PaletteView.swift:84]
- [x] [Review][Defer] Stale `TextSelection` when the token appears or disappears without Backspace (Tab completion, typing the space, clear, submit) — deferred: maybe-false, medium if real; settle by pressing Backspace after each of those in the running Palette (Story 2.4).
- [x] [Review][Defer] Accessibility of the transparent-field-over-drawn-text layout — deferred: maybe-false, medium if real; U+200B in the field value may be spoken by VoiceOver, no cue in the field that a token is active, token label «Категория …» never heard. Settle with VoiceOver on the palette in token mode (Story 2.4).
- [x] [Review][Defer] `#tag` layer drift on a long line — deferred: maybe-false, medium if real; already recorded in deferred-work.md (settle by typing a long line with tags; `NSTextField` fallback).

#### Rejected

- false: "dissolve guess `text == split.rest` is fragile" — identical paste is a no-op, Cmd+Backspace and select-all+type keep the token with the new rest, which is the intended "any other edit keeps it".
- low: parser/resolver divergence (leading whitespace, multi-space inside a name) and "category logic lives in App/" — an explicit spec decision (parser does not expose the prefix); leading whitespace already in deferred-work; move to Core is a Story 2.4+ design call.
- low: stale `split` captured by the Binding setter — edits arrive one per render on the main actor; no reachable sequence shown.
- low: ZWSP inside `rest` keeps `contains(anchor)` true — only pasted ZWSP; they are stripped anyway.
- low: equal-length case-variant names tie / `best!` — duplicate names ignoring case are not a realistic store state; the unwrap is guarded.
- low: `hex(forCategory:)` may return "" — needs the category deleted between two main-actor reads.
- low: `store.categories()` up to three times per render — already rejected in the spec's triage log.
- low: `mutingTags` tests written after the code — tests exist and pass; not repeatable.
- rejected by rule: stale frozen Approach (`onKeyPress`), 37 vs 43 tests, `done` vs `review` status, triage-log wording — the fix is to edit the spec under review.

Patches applied 2026-11-02: `CategoryResolver.caretOffsetAfterDissolve` (typed prefix length, `nil` while the line still resolves), anchor skipped in `mutingTags`; 4 tests added (tag test seen failing first, caret tests failing to compile first). 47 App tests, swiftlint and token guard pass; not seen in the running Palette.
