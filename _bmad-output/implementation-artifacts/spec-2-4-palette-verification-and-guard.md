---
title: 'Palette verification and guard'
type: 'chore'
created: '2026-11-02'
status: 'done'
route: 'oneshot'
review_loop_iteration: 0
context:
  - '{project-root}/_bmad-output/implementation-artifacts/epic-2-context.md'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** Story 2.4 of `_bmad-output/planning-artifacts/epics.md` closes Epic 2: the restyled Palette must be added to the token guard so it cannot drift back, and its states and behavior must be verified against the Palette panel spec. Several checks were deferred to this story from 2.1 and 2.2 (hotkey race on open, caret in system dark mode, stale `TextSelection`, VoiceOver of the token field, `#tag` layer drift, leading whitespace).

**Approach:** Add `App/Palette` to `scripts/token-guard-paths.txt` and prove the guard exits 0 (plus `scripts/test-check-tokens.sh`, `swiftlint`, App tests and build). The in-app checks need the global hotkey, screenshots of the idle, typing, running and prompt states, VoiceOver and system dark mode; an agent cannot send the hotkey or hear VoiceOver, so they are written as a manual checklist in the Implementation Notes and handed to the author, who records each result there. Nothing is ticked that was not seen. Code fixes are made only for a failure the author reports; `Packages/TimeTrackerCore` is not modified.

</frozen-after-approval>

## Implementation Notes

- Changed: `scripts/token-guard-paths.txt` gains `App/Palette`. No Swift code changed; Core untouched.
- Seen: `scripts/check-tokens.sh` exit 0 with `App/Palette` listed; `scripts/test-check-tokens.sh` ALL TESTS PASSED; `swiftlint` 0 violations in 75 files; `xcodebuild test` 62 App tests in 11 suites passed; Core `swift test` 187 tests passed.
- Review layers skipped: no code diff (one list line), so Blind Hunter has nothing to read.
- Not done by the agent: every in-app check below. The agent cannot send the global hotkey, take screenshots of the Palette, hear VoiceOver or switch system appearance, so none is ticked.

### Manual checklist for the author (record the result next to each item)

States and look (screenshots of each, against the panel spec: opaque white, radius 20, 60px field, tinted token, 40px rows, text 20/15/12):
- [ ] Idle (empty field, running row if a timer runs)
- [ ] Typing (suggestions, ↑/↓ highlight, hover does not move it)
- [ ] Typing with a category token and `#tag`
- [ ] Running state
- [ ] Prompt state (create category, overlap, error: error-strip look, no red/orange)

Behavior re-verification:
- [ ] Esc closes; Enter submits and closes; clicking outside (focus loss) closes
- [ ] Grammar `category title #tag -20m` still parses and starts the entry as before

Deferred items settled here:
- [ ] Opening with the hotkey from several apps: the panel does not close right after opening (2.1)
- [ ] System dark mode: caret, selection and divider are visible in the fixed-light card (2.1)
- [ ] Long line with several `#tags`: muting layer does not drift (2.2); if it does, fallback is an `NSTextField` wrapper
- [ ] Backspace at the start of the text after: Tab completion, typing the space, clearing, submit: caret is right, no crash (2.2)
- [ ] VoiceOver in token mode: token category is announced, U+200B not spoken (2.2)
- [ ] Leading whitespace before the category name gives no token (2.2, low): trim only if it shows up
- [ ] 2.1 leftovers: `typeRole` text follows system text size; eight-tone dots with names; placeholder is `text-tertiary`; click and select text in the field behave normally; Tab focus ring
