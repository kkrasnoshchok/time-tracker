---
title: 'Whole-app guard and success check'
type: 'feature'
created: '2026-11-08'
status: 'in-progress'
route: 'oneshot'
review_loop_iteration: 0
context:
  - '{project-root}/_bmad-output/implementation-artifacts/epic-5-context.md'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** Story 5.4 of `_bmad-output/planning-artifacts/epics.md`: the token guard still scans only a hand-kept list of migrated paths, so an unmigrated or new file under `App/` can bring back hex literals, system colors or ad-hoc fonts unnoticed, and the author has no final proof that only paper tones and the eight category tones are visible.

**Approach:** The guard scans all of `App/` outside the token layer (`App/Support/CategoryTone.swift` is the one data exemption: its hexes are stored-data keys). Remaining literals are removed or moved into the token layer (`Color.hexString` leaves `App/`, the starter-category seed uses tone hexes). The final visual pass, the 13-hour «долго» flow and the open B6 checks are listed as owed to the author. Moving the mapping/rule into Core and first-unused tone for Palette-created categories stay follow-ups.

## I/O & Edge-Case Matrix

| Scenario | State | Expected |
|----------|-------|----------|
| Guard on whole `App/` | after cleanup | exit 0 |
| Literal in `CategoryTone.swift` | fixture | not reported (documented exemption) |
| Same literal in another `Support/` file | fixture | reported |

</frozen-after-approval>

## Implementation Notes

- Guard: `scripts/token-guard-paths.txt` is now just `App`. Exemptions are in `check-tokens.sh`: token layer files plus `Support/CategoryTone.swift` (stored-hex mapping keys). Fixtures `data-exempt` and `data-exempt-mixed` seen FAIL first (exit 1 on the exempt file), then `test-check-tokens.sh` ALL TESTS PASSED.
- First whole-`App/` run found 5 hits: `AppEnvironment` seed hexes, `CategoryTone` keys (exempted), `Color+Hex.swift` `.gray` x2. Fixes: `Color(hex:)` moved into `App/Design/ColorToken.swift` (token layer); `Color.hexString` (used only by tests) moved to `AppTests/ColorHexString.swift` and `Color+Hex.swift` deleted (closes the 5.1 deferral); the starter-category seed now stores `CategoryTone.slate/.moss/.clay` hexes (same tones as before: the old bright hexes mapped to them; only affects new installs).
- Seen: `check-tokens.sh` exit 0 on all of `App/`, App tests `** TEST SUCCEEDED **`, Core 208 passed, swiftlint 0 violations.
- NOT done here (no screen control; owed by the author, unverified): [ ] visual pass over Palette, Journal, Entry detail, Add sheet, Categories, Settings, menu bar item, popover: only paper tones and the eight category tones, screenshots recorded in this story; [ ] flow: entry of 13h from the previous day → «долго» shows, fix the end time → it disappears and the day total updates; [ ] open B6 checks from 5.3 and the VoiceOver items in `deferred-work.md`.
- Follow-ups, not done: move the tone mapping and the «долго» rule into Core; first-unused tone for Palette-created categories (`PaletteViewModel.categoryColors` still uses bright hexes); the epic-5 deferrals on native `Picker`/`DatePicker` and double scroll. CLAUDE.md still says the guard covers «мигрированных файлах» (see deferred-work).
- Review not run by the author's rule; review goes to a fresh session.
