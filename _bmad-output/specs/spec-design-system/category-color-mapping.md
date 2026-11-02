# Category color mapping

Stored `EntryCategory.colorHex` is never rewritten by the migration. App/ maps it to one of eight tones at render time (CAP-2). Core still creates categories with the bright hexes below (`PaletteViewModel.categoryColors`), so the mapping must keep handling them.

| Core default hex | Old hue | Tone | Tone hex |
|---|---|---|---|
| `#0A84FF` | blue | slate | `#6F86A0` |
| `#30D158` | green | moss | `#8A9A6A` |
| `#FF9F0A` | orange | clay | `#B4705A` |
| `#FF453A` | red | rose | `#B88A8A` |
| `#BF5AF2` | purple | plum | `#8D6F8F` |
| `#64D2FF` | cyan | lagoon | `#5F8A88` |
| `#FFD60A` | yellow | ochre | `#B8964A` |
| `#AC8E68` | brown | taupe | `#7A7570` |

The table keeps all eight defaults distinct, so existing categories do not collapse into one color.

Rules:
- Exact match against the table first (case-insensitive, `#RRGGBB`).
- Any other valid hex: nearest tone by Oklab distance; tie goes to the earlier tone in the order clay, ochre, moss, lagoon, slate, plum, rose, taupe.
- Invalid or empty hex: taupe.
- Tone choice for a new category from the Categories tab: first tone in that order not used by any category; if all eight are used, cycle by `count % 8`. The stored value is the tone's own hex, which then maps to itself.
- Two categories may share a tone. Color is never the only carrier of meaning: the category name always sits beside the dot.
