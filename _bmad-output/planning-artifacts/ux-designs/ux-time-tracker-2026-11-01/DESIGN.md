---
name: Time Tracker
description: Quiet paper-toned native macOS system; near-achromatic, hairline depth, one muted color set reserved for categories.
status: final
updated: 2026-11-01
sources:
  - imports/duna-reference.md
  - docs/application-design.md
colors:
  surface-canvas: '#F7F7F5'
  surface-card: '#FFFFFF'
  surface-inset: '#EDECE7'
  surface-selected: '#E1DEE6'
  surface-input: '#EEEEEE'
  text-primary: '#1B0624'
  text-secondary: '#766A7C'
  text-tertiary: '#898683'
  text-body: '#444444'
  action-primary: '#160F0C'
  on-action-primary: '#FFFFFF'
  border-ghost: '#898683'
  category-clay: '#B4705A'
  category-ochre: '#B8964A'
  category-moss: '#8A9A6A'
  category-lagoon: '#5F8A88'
  category-slate: '#6F86A0'
  category-plum: '#8D6F8F'
  category-rose: '#B88A8A'
  category-taupe: '#7A7570'
typography:
  timer-display:
    fontFamily: SF Pro
    fontSize: 32px
    fontWeight: '400'
    lineHeight: '1.1'
    letterSpacing: -0.03em
  day-total:
    fontFamily: SF Pro
    fontSize: 28px
    fontWeight: '400'
    lineHeight: '1.1'
    letterSpacing: -0.03em
  title:
    fontFamily: SF Pro
    fontSize: 20px
    fontWeight: '500'
    lineHeight: '1.3'
  palette-input:
    fontFamily: SF Pro
    fontSize: 20px
    fontWeight: '400'
    lineHeight: '1.3'
  body:
    fontFamily: SF Pro
    fontSize: 15px
    fontWeight: '400'
    lineHeight: '1.4'
  body-emphasis:
    fontFamily: SF Pro
    fontSize: 15px
    fontWeight: '500'
    lineHeight: '1.4'
  caption:
    fontFamily: SF Pro
    fontSize: 13px
    fontWeight: '400'
    lineHeight: '1.4'
  micro:
    fontFamily: SF Pro
    fontSize: 12px
    fontWeight: '400'
    lineHeight: '1.2'
rounded:
  input: 8px
  card: 16px
  panel: 20px
  full: 9999px
spacing:
  unit: 4px
  '1': 4px
  '2': 8px
  '3': 12px
  '4': 16px
  '5': 20px
  '6': 24px
  '8': 32px
  '10': 40px
  row-height: 44px
  palette-field-height: 60px
components:
  button-primary:
    backgroundColor: '{colors.action-primary}'
    textColor: '{colors.on-action-primary}'
    typography: '{typography.caption}'
    rounded: '{rounded.full}'
    padding: 8px 16px
  button-ghost:
    backgroundColor: transparent
    textColor: '{colors.text-primary}'
    typography: '{typography.caption}'
    rounded: '{rounded.full}'
    padding: 8px 16px
  card:
    backgroundColor: '{colors.surface-card}'
    rounded: '{rounded.card}'
    padding: '{spacing.4}'
  input-field:
    backgroundColor: '{colors.surface-input}'
    textColor: '{colors.text-primary}'
    typography: '{typography.body}'
    rounded: '{rounded.input}'
    padding: 8px 12px
  badge:
    backgroundColor: '{colors.surface-inset}'
    textColor: '{colors.text-primary}'
    typography: '{typography.micro}'
    rounded: '{rounded.full}'
    padding: 3px 10px
  category-token:
    textColor: '{colors.text-primary}'
    typography: '{typography.body-emphasis}'
    rounded: '{rounded.full}'
    padding: 6px 12px
  palette-panel:
    backgroundColor: '{colors.surface-card}'
    rounded: '{rounded.panel}'
  journal-row:
    backgroundColor: '{colors.surface-card}'
    textColor: '{colors.text-primary}'
    typography: '{typography.body}'
    height: '{spacing.row-height}'
---

## Brand & Style

A quiet, expensive-feeling tool that does not tire with daily use. The posture comes from the Duna reference (docs reconstructed in `imports/duna-reference.md`): a warm paper canvas, near-black ink, pill-shaped controls, almost no depth. Everything web-specific from that reference (hero artwork, navbar, cookie banner, logo bar, marketing stat blocks, GT America) is dropped.

Two anti-goals shape every choice: nothing loud, and nothing with an "AI feel" (gradients, glow, sparkle, glossy translucency, chatty rounded friendliness). When in doubt, remove decoration.

Light theme only for v1. Color tokens are semantic (`surface-*`, `text-*`, `action-*`), not literal (no `linen` in code), so a dark theme can later be added as a second value set without touching components.

Typeface is the system font, SF Pro. It is native to the platform and needs no bundling.

## Colors

Interface is almost achromatic.

- **`{colors.surface-canvas}` (Linen)**: window background. Warm off-white; never pure white as the page.
- **`{colors.surface-card}` (white)**: cards, the palette panel, list containers.
- **`{colors.surface-inset}` (Bone)**: nested panels, badges, running-entry row.
- **`{colors.surface-selected}` (Heather)**: the selected Journal row (a cool tint, so it differs from the warm running row). A running row that is also selected keeps the running fill (`surface-inset`) and shows no extra selection cue; accepted for now. Text on a selected row uses `text-primary` instead of `text-secondary` (3.83:1 on this fill, below AA; no lighter fill reaches 4.5:1 without matching the canvas).
- **`{colors.surface-input}` (Mist)**: fillable areas only.
- **`{colors.text-primary}` (Aubergine Ink)**: all primary text. **`{colors.action-primary}` (Espresso)**: the only filled button color.
- **`{colors.text-secondary}` (Warm Ash)**: meta text (category name in a row, captions). **`{colors.text-tertiary}` (Stone)**: placeholders and decorative marks only; on white it is below AA for small text, so never use it for information the user must read.
- **Category colors** (`category-*`): the only chroma in the app. A fixed set of eight muted tones, equal in saturation and lightness so none shouts on Linen. They are not accents and not brand colors. They appear only as (a) an 8px dot in lists and the menu bar, and (b) the tinted background of the category token.
- **No status colors.** No red, green or blue. Running, error and warning states are carried by tone (`surface-inset`), weight and wording; see `EXPERIENCE.md` State Patterns.

Category token background: the category color mixed at 22% over `surface-card`, text stays `text-primary`.

Existing categories carry arbitrary hex values; migrating them to this set is a build concern (see `EXPERIENCE.md`).

## Typography

SF Pro throughout. Weights 400 and 500 only.

| Role | Size / weight | Use |
|---|---|---|
| `timer-display` | 32 / 400, tracking -0.03em | Elapsed time of the running entry in the popover |
| `day-total` | 28 / 400, tracking -0.03em | Day total in the Journal |
| `title` | 20 / 500 | Window and section titles |
| `palette-input` | 20 / 400 | Text typed in the palette |
| `body` | 15 / 400 | Rows, suggestions, form text |
| `body-emphasis` | 15 / 500 | Category token, selected item name |
| `caption` | 13 / 400 | Meta, button labels, time of day |
| `micro` | 12 / 400 | Badges, shortcut hints |

Negative tracking appears only on `timer-display` and `day-total`. Body text and everything below 20px keeps default tracking. Numbers in lists and the timer use tabular figures so digits do not jitter when the timer ticks. The palette uses exactly three levels (20 / 15 / 12); the earlier mix of sizes read as inconsistent.

## Layout & Spacing

4px base grid. Use the scale `4, 8, 12, 16, 20, 24, 32, 40`. Row height 44px; palette input field 60px; card padding 16px; window content padding 20px; gap between cards 24px. No fixed page max-width; the Journal window scales, content columns stay readable via a split view (list + detail) as today.

Native window chrome, menu bar and system materials stay system-drawn. This design system governs content drawn inside our windows and panels.

## Elevation & Depth

No drop shadows in content. Depth comes from tone (`surface-canvas` → `surface-card` → `surface-inset`) and a hairline ring: 1px, black at 5% opacity, drawn inset. The palette panel floats over other apps and uses a slightly stronger 1px ring (black at 10%) so its edge survives on any background; this is the only exception, and the OS may still add its own window shadow.

Translucent materials (`.regularMaterial`, Liquid Glass) are not used inside our surfaces. The palette is an opaque paper panel; a translucent panel changes color with whatever is behind it and loses the warm paper tone.

## Shapes

Radii: inputs 8, cards 16, the palette panel 20, controls and tags full pill. Nothing below 8. Pills are non-negotiable for buttons, badges and the category token.

Icons: thin-stroke, geometric line icons (SF Symbols at light or regular weight, outlined variants), never rounded or friendly filled sets. Icons are used sparingly; list rows and palette suggestions carry no icons.

## Components

- **Button, primary** (`button-primary`): Espresso fill, white `caption` text, pill. The only filled button; at most one per surface.
- **Button, ghost** (`button-ghost`): transparent, 1px `border-ghost` outline, `text-primary`, pill. Secondary and dismiss actions.
- **Card** (`card`): white, radius 16, hairline ring, padding 16. Separated from neighbors by space, not borders.
- **Input field** (`input-field`): Mist fill, radius 8, 1px border in `text-tertiary`. Focus shifts the border to `action-primary`; no glow.
- **Badge** (`badge`): Bone pill with `micro` text. Neutral information only.
- **Category dot**: 8px circle in the category color. Never larger than 8px, never a row fill.
- **Category token** (`category-token`): pill with the category-tinted background (see Colors), `body-emphasis` text, no dot. Appears inside the palette input before the typed name.
- **Palette panel** (`palette-panel`): white, radius 20. Order top to bottom: input field row (60px, line-icon magnifier left, category token, typed text, muted `#tag`), the "running" row on `surface-canvas`, then suggestions. Suggestion rows: 40px tall, radius 10, name in `body`, category name in `text-secondary` on the right, shortcut hint in `micro`. Selected row: `surface-inset`. No suggestion icons.
- **Journal row** (`journal-row`): 44px. Time of day (`caption`, `text-secondary`), name (`body`), category dot plus category name (`text-secondary`) right of the name, duration right-aligned in tabular figures. The running entry's row uses `surface-inset` and a `body-emphasis` duration.
- **Day header**: day name (`body-emphasis`) with date below (`caption`), day total in `day-total` on the right with the label "в фокусе".

Composition references (exploration, not final): `.working/font-and-surfaces-sf-vs-inter.html`, `.working/palette-paper-vs-material.html`, `.working/category-palette.html`. This spine wins on conflict.

## Do's and Don'ts

Do
- Use Linen as the canvas and white cards on it.
- Keep Espresso as the only filled button color.
- Keep category color to the dot and the token tint.
- Use pills for every interactive control and tag.
- Build depth from tone and the hairline ring.
- Use tabular figures for any ticking or summed time.

Don't
- Add any blue, green or red accent, or any chroma outside the eight category tones.
- Add shadows, glow, gradients or translucent materials inside our surfaces.
- Use negative tracking on text below 20px.
- Add icons to rows or suggestions.
- Fill a row or a card with a category color.
- Use `text-tertiary` for information the user must read.
