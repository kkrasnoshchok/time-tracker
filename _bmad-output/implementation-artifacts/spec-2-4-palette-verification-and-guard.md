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
- Review: all four layers ran on commits `4adb143`..`87509b1` (see Review Findings).
- The agent could not run the in-app checks below (no Accessibility or Screen Recording access: no hotkey, no screenshots, no VoiceOver, no appearance switch). The author ran them; the ticks are author-reported, see Author confirmation.

### Manual checklist (author-reported: ticked on the author's statement, no screenshots or per-item notes)

States and look (screenshots of each, against the panel spec: opaque white, radius 20, 60px field, tinted token, 40px rows, text 20/15/12):
- [x] Idle (empty field, running row if a timer runs)
- [x] Typing (suggestions, ↑/↓ highlight, hover does not move it)
- [x] Typing with a category token and `#tag`
- [x] Running state
- [x] Prompt state (create category, overlap, error: error-strip look, no red/orange)

Behavior re-verification:
- [x] Esc closes; Enter submits and closes; clicking outside (focus loss) closes
- [x] Grammar `category title #tag -20m` still parses and starts the entry as before

Deferred items settled here:
- [x] Opening with the hotkey from several apps: the panel does not close right after opening (2.1)
- [x] System dark mode: caret, selection and divider are visible in the fixed-light card (2.1)
- [x] Long line with several `#tags`: muting layer does not drift (2.2); if it does, fallback is an `NSTextField` wrapper
- [x] Backspace at the start of the text after: Tab completion, typing the space, clearing, submit: caret is right, no crash (2.2)
- [x] VoiceOver in token mode: token category is announced, U+200B not spoken (2.2)
- [x] Leading whitespace before the category name gives no token (2.2, low): trim only if it shows up
- [x] 2.1 leftovers: `typeRole` text follows system text size; eight-tone dots with names; placeholder is `text-tertiary`; click and select text in the field behave normally; Tab focus ring

### Author confirmation

2026-11-04: the author ran every item of the checklist above in the running app and reported in chat that all of them work. No per-item notes or screenshots were attached to the report; the ticks rest on that statement only. No failures, so no code fixes.

### Review Findings

Code review 2026-11-04, commits `4adb143`..`87509b1`, layers: blind-hunter, edge-case-hunter, verification-gap, acceptance-auditor.

- [x] [Review][Decision] (resolved: option a, applied) Manual checks are ticked on one chat statement, and the notes contradict the ticks — AC1 asks for screenshots and AC2 for the result noted in the story; the confirmation records neither per item. Implementation Notes still say "none is ticked" and that review layers were skipped, but all 14 boxes are `[x]` and the layers ran. Options: (a) keep the ticks, mark the section "author-reported, no screenshots or per-item notes", fix the two stale bullets; (b) author adds screenshots or one-line results per item, then (a)'s wording fixes; (c) leave as is. Fix edits the spec, so it needs the author's call. [spec-2-4-palette-verification-and-guard.md:26-27, 31-57]

- [x] [Review][Defer] Guard patterns miss `Color.white`/`.black`, `NSFont`, `Font.custom` and `.system(.title)`-style fonts — deferred: pre-existing guard design, not caused by this change; no such use in `App/Palette` today (grep found none). Settle when a migrated file needs one.

#### Rejected

- low, rejected: spec `status: 'done'` vs sprint `review`, stale `last_updated`. Settled by this review's finalization (both move together); not a code defect.
- false: guard never shown to catch a violation in a directory entry. `test-check-tokens.sh` has fixtures for directory entries (`bad-hex`, `bad-named`, …, seen failing first in 1.6) and for a single file path.
- low, rejected: non-`.swift` or relocated Palette files escape the guard. Same rule as `App/Design`; no such files exist.
- low, rejected: guard is not run automatically (no CI or hook). Known since 1.6 and handled by the CLAUDE.md rule "run before finishing a UI task"; adding CI is out of scope.
- false: commit subject `docs(2-4)` does not tie to the story. It names `2-4`, which is what `git_evidence.py` needs.
- low, rejected: no TypeScript/React explanation, deferred items not linked to deferred-work, no retro follow-up item. No new Swift concepts were added; the retro is `optional` and not part of this story.
