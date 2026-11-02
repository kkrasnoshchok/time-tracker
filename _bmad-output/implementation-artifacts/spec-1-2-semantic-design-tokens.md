---
title: 'Semantic design tokens'
type: 'feature'
created: '2026-11-02'
status: 'done'
baseline_commit: 'cff0d1fd186a81733667fbe365264a22177c2e46'
route: 'dispatch'
review_loop_iteration: 0
context:
  - '{project-root}/_bmad-output/planning-artifacts/ux-designs/ux-time-tracker-2026-11-01/DESIGN.md'
  - '{project-root}/_bmad-output/implementation-artifacts/epic-1-context.md'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** `App/` has no shared source for colors, type, spacing, radii or the hairline ring; hex values sit in `CategoryTone`, so each screen would restyle things on its own.

**Approach:** Add a token layer in `App/Design/` whose values equal the `DESIGN.md` frontmatter, test it against a hex/size table written from that file (tests seen failing first), and make `CategoryTone.hex` read the eight category tokens instead of its own literals. Story 1.2 of `_bmad-output/planning-artifacts/epics.md`.

## Boundaries & Constraints

**Always:** Colors are semantic (`surfaceCanvas`, not `linen`). Type weights 400 or 500 only; negative tracking only on `timer-display` and `day-total`; every role scales with Dynamic Type; a tabular-figures modifier exists. Radii 8/16/20/pill, spacing 4…40 plus row-height 44 and palette-field-height 60. Hairline ring: 1px black at 5% inset, 10% for the Palette variant, higher opacity under Increase Contrast. Light theme only. Swift 6 strict concurrency, `swiftlint` clean. New Swift concepts (`extension Color`, `static let`, `ViewModifier`, `@Environment`) get short English doc comments with a TypeScript/React analogy.

**Never:** No shadows, gradients, materials or glow in the token layer. No edits to `Packages/TimeTrackerCore`. No screens or components restyled (Stories 1.3–1.5). No dark theme. No token for the legacy Core bright hexes in `CategoryTone.coreDefaults` (stored-data lookup, not design; Story 1.6 allow-lists it).

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Color table | each `ColorToken` | `hex` equals the `DESIGN.md` value (18 colors) | N/A |
| Type roles | the eight roles | size/weight per `DESIGN.md`, weight 400 or 500, tracking < 0 only for two roles | N/A |
| Ring opacity | variant standard / palette, contrast standard / increased | 0.05 / 0.10; increased is strictly higher for both | N/A |
| Tone parity | each `CategoryTone` | `tone.hex` equals its `category-*` token hex | N/A |

</frozen-after-approval>

## Code Map

- `App/Support/CategoryTone.swift` -- `hex` switch holds the eight tone literals; replace with token lookups. `coreDefaults` stays.
- `App/Support/Color+Hex.swift` -- `Color(hex:)` reuse for token colors. Do not change.
- `AppTests/CategoryToneTests.swift` -- existing 6+ tests must keep passing. Model for Swift Testing style.
- `project.yml` -- `App` and `AppTests` are globbed, so no edit expected; run `xcodegen generate`.
- `DESIGN.md` (ux-designs/ux-time-tracker-2026-11-01) -- source of truth for every value.

## Tasks & Acceptance

**Execution:**
- [x] `AppTests/DesignTokenTests.swift` -- write table tests for colors, typography, spacing/radii, ring opacity, tone parity; run, see FAIL (missing symbols) -- red first
- [x] `App/Design/ColorToken.swift` -- `enum ColorToken: CaseIterable` with `hex` and `color`, plus `extension Color { static let surfaceCanvas … }` -- single place for hexes
- [x] `App/Design/Typography.swift` -- `enum TypeRole` (size, weight, tracking em, line height) and a `ViewModifier` with `@ScaledMetric`, `.typeRole(_)`, `.tabularFigures()` -- scalable text styles
- [x] `App/Design/Spacing.swift` -- `enum Space`/`Radius` named constants -- no magic numbers in views
- [x] `App/Design/HairlineRing.swift` -- `ViewModifier` reading `@Environment(\.colorSchemeContrast)`, pure `opacity(variant:contrast:)`, `.hairlineRing(_:)` on a shape -- ring without shadows
- [x] `App/Support/CategoryTone.swift` -- `hex` returns the matching `ColorToken` hex -- tone hexes leave the file

**Acceptance Criteria:**
- Given the token tests, when run before the implementation, then they fail to compile or assert; after it, `xcodebuild test -scheme TimeTracker -destination 'platform=macOS'` passes with the 1.1 tests included.
- Given `git diff -- Packages`, then it is empty; given a grep for `shadow|gradient|Material` in `App/Design`, then nothing matches.

## Implementation Notes

## Spec Change Log

## Review Triage Log

| Finding | Verdict | Route | Evidence |
|---|---|---|---|
| Increased-contrast ring opacities only checked as "higher" (blind, edge, gap) | medium | patch | Changing 0.30 to 0.06 passes every test; exact cases added. |
| `Color.*` aliases untested (gap) | medium | patch | A copy-paste slip in an alias passes all tests; alias hex test added. |
| Tone parity test is tautological (edge, gap) | low | patch | Compares `hex` to the expression `hex` returns; now uses literals. 1.1 tests still cover the mapping. |
| `@ScaledMetric` may not scale on macOS (blind, edge) | maybe-false | defer | Spec Design Notes choose this design; settle by a manual check that `scale` changes with `dynamicTypeSize` on macOS 26. |
| `lineSpacing` overshoots line height (blind, edge) | low | rejected | Approximation is stated in Design Notes; fix is more than a direct correction. |
| 1pt vs 1px ring width (edge) | false | rejected | DESIGN.md uses CSS-style px as points; no Retina requirement is stated. |
| No dark theme / ring invisible on dark fills (blind, edge) | false | rejected | Spec Never: light theme only. |
| Contrast of `textTertiary` on canvas (blind) | false | rejected | Values are fixed by DESIGN.md; not this story's choice. |
| Tests copy hexes by hand instead of parsing DESIGN.md (blind) | false | rejected | The spec asks for a table written from that file. |
| Spec says 18 colors, code has 19 (edge) | false | rejected | DESIGN.md lists 11 UI + 8 category colors; the spec miscounted, and fixing it edits the spec. |
| `weightValue`/`fontWeight`, `Radius.pill = 9999`, `tabularFigures` untested, shared hex of `textTertiary`/`borderGhost` (blind, edge) | low | rejected | Cosmetic; fixes add complexity without a named harm. |

## Design Notes

Dynamic Type on macOS: `Font.system(size:)` does not scale, so the type modifier holds `@ScaledMetric(relativeTo: .body) var size` and builds the font from it. Line height is applied as `lineSpacing = size × (lineHeight − 1)` (approximation, SwiftUI has no line-height). Tracking = `size × em`.

## Verification

**Commands:**
- `xcodegen generate && xcodebuild test -scheme TimeTracker -destination 'platform=macOS'` -- expected: `** TEST SUCCEEDED **`
- `swiftlint` -- expected: no violations
- `swift test --package-path Packages/TimeTrackerCore` -- expected: 187 tests pass
