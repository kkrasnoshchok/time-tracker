---
title: 'Tone swatches in the Categories tab'
type: 'feature'
created: '2026-11-07'
status: 'done'
route: 'oneshot'
review_loop_iteration: 0
context:
  - '{project-root}/_bmad-output/implementation-artifacts/epic-5-context.md'
  - '{project-root}/_bmad-output/specs/spec-design-system/category-color-mapping.md'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** Story 5.1 of `_bmad-output/planning-artifacts/epics.md`: the Categories tab lets the author pick any color with a system `ColorPicker` and gives new categories a bright Core hex, so colors leave the eight-tone design set.

**Approach:** Add a pure rule in `App/Support/CategoryTone.swift` that picks the first tone not used by any category (cycling by `count % 8` when all are used) and returns the tone's own hex. In `CategoriesView`, replace `ColorPicker` with a row of eight swatches (current tone marked by a ring, not color alone; at least 24pt; keyboard reachable; VoiceOver names), selecting one calls the existing `journal.setColor`. A new category takes the rule's result; `randomColor()` and `ColorPicker` are removed. The rest of the Categories chrome is Story 5.3 and is not touched.

## I/O & Edge-Case Matrix

| Scenario | State | Expected |
|----------|-------|----------|
| No categories | `[]` | clay |
| Clay used | stored hexes map to clay only | ochre |
| Gap in the middle | clay, ochre, lagoon used | moss (first free in order clay, ochre, moss, lagoon, slate, plum, rose, taupe) |
| Bright Core hex | `#FF9F0A` (maps to clay) | counts as clay used |
| All eight used | 8 categories | tone at index `count % 8` |
| More than eight | 11 categories | index 3 (lagoon) |
| Stored value | any result | `CategoryTone(storedHex: result.hex) == result` |
| Invalid stored hex | `""` | counts as taupe used |

</frozen-after-approval>

## Implementation Notes

- Tests first in `AppTests/CategoryToneTests.swift` (seen FAIL): `CategoryTone.nextFree(usedStoredHexes:)` (name free to change if clearer).
- Swatch picker is its own view (`App/Journal/ToneSwatchPicker.swift`) built on tokens only, added to `scripts/token-guard-paths.txt`. A pure helper for the accessibility name and the selected flag is tested.
- Unverified until the running app (retro B6): swatches are `Button`s that are Tab-reachable inside the `List` row, the ring is visible on the selected swatch, 24pt hit area, VoiceOver reads name plus «выбран». Run the app and record author-reported results here before review.
- Swift concepts to explain after the task: `Binding`, `ForEach` over `CaseIterable`.
- Done: `CategoryTone.nextFree(usedStoredHexes:)`; `ToneSwatch` (names, selected flag, VoiceOver text) and `ToneSwatchPicker` in `App/Journal/ToneSwatchPicker.swift` (24pt hit area, ring plus check on the selected tone, `.plain` buttons, `.help` tooltip); `CategoriesView` uses it, `ColorPicker`, `colorBinding` and `randomColor()` are gone (grep clean); `ToneSwatchPicker.swift` added to the guard list.
- Seen: tests red first (compile: `nextFree`, `ToneSwatch` missing); then App tests succeeded, Core 208 passed, swiftlint 0, `check-tokens.sh` exit 0, `test-check-tokens.sh` passed.
- Running app (B6): the Debug build launches, but this session has no screen control (no assistive access), so the Categories tab was NOT inspected. Owed by the author: [ ] swatches render as eight 24pt circles, selected one has ring and check; [ ] Tab reaches the swatches and Space/Return selects; [ ] clicking a swatch changes the dot color in Journal; [ ] a new category gets the first unused tone; [ ] VoiceOver reads name and «выбран».
- Author-reported 2026-11-07: all five items above checked in the running app, OK (no issues).

## Review Triage Log

- Stale doc comment says `allCases`, code uses `tieBreakOrder` + no test tying the lists: low, real. Patched (comment, `pickerOrderCoversEveryTone`).
- Group label «Цвет категории» has no category name: low, rare; row's text field sits beside it. Rejected.
- No arrow-key navigation / focus ring / radio-group trait: Tab+Space author-checked OK; Epic 5.3 chrome. Rejected.
- Checkmark contrast on ochre/taupe: author saw it on screen, OK. Rejected.
- Literal 24/4/1.5 sizes, narrow window overflow: guard passes, author-checked at normal width. Rejected.
- Hard-coded Russian strings: false, app is Russian-only with no string catalog.
- Tapping the selected swatch rewrites a legacy bright hex to the tone hex: harmless, arguably wanted. Rejected.
- No tests for `CategoryRow.select`/error path: thin glue, covered by manual checks (retro C5). Rejected.
- `nextFree` depends on `journal.categories` contents: that list is the live category set; no archive concept. False.
- All-eight-used repeats a color without hint: required by the AC. False.
- `Color.hexString` now unused in `App/` (tests only), `PaletteViewModel.categoryColors` still used by Core: medium-low, defer (deleted-code cleanup for 5.4).
- Custom colors silently shown as nearest tone: by design (CAP-2 mapping). False.
- Missing blank line before MARK: false, swiftlint 0 violations.
- `nextFree` in `App/` not Core: by design, moving mapping to Core is a listed follow-up. False.
