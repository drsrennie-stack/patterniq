# Accessibility Compliance Notes

## 1. Project and files covered

**Project:** PatternIQ, Steps 1 to 10 review package
**Files covered:** `wireframes/patterniq-wireframes.html`, all ten screens (Overview, Discover, Market, Watchlist, Patterns, Deal Analyzer, Portfolio, Run Analysis, Learn, Data and Sources) in **both themes** (Terminal, default; Research, toggle)
**Date:** August 11, 2026 (revised: single-typeface pass)
**Reviewer:** Dr. Sharilyn Rennie

This covers the wireframe deliverable. The built application requires its own compliance notes at M11 and again at M16.

## 2. WCAG version and level achieved

Target: WCAG 2.2 Level AA minimum, Level AAA where achievable.

Automated audit: axe-core via `@axe-core/playwright` against Chromium, tags `wcag2a`, `wcag2aa`, `wcag21a`, `wcag21aa`, `wcag22aa`. Each of the ten screens was made visible and scanned individually, in each of the two themes. Twenty scans total.

**Result: 0 violations across all ten screens in both themes.**

| Criterion | Level | Status |
|---|---|---|
| 1.1.1 Non-text content | A | Pass. Decorative SVG marked `aria-hidden`. Every meaningful chart carries `role="img"` and a descriptive label naming it as placeholder data. |
| 1.3.1 Info and relationships | A | Pass. Semantic landmarks, real `th` with `scope`, `caption` on every table, `fieldset` and `legend` on form groups. |
| 1.3.2 Meaningful sequence | A | Pass. DOM order matches visual order. |
| 1.4.1 Use of color | A | Pass, and load-bearing in this design. See section 3.4. |
| 1.4.3 Contrast, minimum | AA | Pass in both themes. Measured, see section 3. |
| 1.4.6 Contrast, enhanced | AAA | Terminal theme: pass for primary text, numerals, deltas, and accents. Research theme: partial. See section 3.3. |
| 1.4.10 Reflow | AA | Pass. Grid collapses to single column at 900 px and 1100 px. No horizontal scroll at 320 px equivalent, except the dense ranking table, which scrolls horizontally inside its own container by design rather than breaking the page. |
| 1.4.11 Non-text contrast | AA | Pass. Focus ring, active pill, current-page marker, meter fills, depth bars, and candle bodies all exceed 3:1 against their adjacent surfaces. |
| 1.4.12 Text spacing | AA | Pass. No fixed-height text containers. |
| 2.1.1 Keyboard | A | Pass. See section 4. |
| 2.1.2 No keyboard trap | A | Pass. |
| 2.2.2 Pause, stop, hide | A | Pass. The metrics ticker moves for longer than five seconds, so it carries a visible pause control as the first focusable element in its region, and the animation is removed entirely under `prefers-reduced-motion`. |
| 2.4.1 Bypass blocks | A | Pass. Skip link is the first focusable element and becomes visible on focus. |
| 2.4.3 Focus order | A | Pass. |
| 2.4.6 Headings and labels | AA | Pass. One `h1` per document, no skipped levels, every form control labelled. |
| 2.4.7 Focus visible | AA | Pass. 2 px outline with 2 px offset, never suppressed. |
| 2.4.11 Focus not obscured, minimum | AA (2.2) | Pass. Only table headers are sticky, and they do not overlay focusable content. |
| 2.5.3 Label in name | A | Pass. |
| 2.5.8 Target size, minimum | AA (2.2) | Pass. All interactive targets at or above 24 by 24 CSS pixels. |
| 3.1.1 Language of page | A | Pass. `lang="en"`. |
| 3.2.1 On focus | A | Pass. No context change on focus. |
| 3.3.1 Error identification | A | Not applicable in the wireframe. Specified for M13. |
| 3.3.2 Labels or instructions | A | Pass. Every input has a visible label, and every assumption field carries a hint naming the source of its default. |
| 4.1.2 Name, role, value | A | Pass. `aria-pressed` on toggles and the ticker pause, `aria-selected` on tabs, `aria-current` on navigation. |
| 4.1.3 Status messages | AA | Pass. Screen changes and theme changes announce through a polite live region. |

## 3. Color contrast audit

Measured programmatically using the WCAG relative luminance formula, rounded to two decimals.

### 3.1 Terminal theme (default)

Surfaces: background `#0A0E14`, panel `#111820`, panel 2 `#18212C`, header `#1B2530`.

| Foreground | Background | Ratio | AA | AAA | Use |
|---|---|---|---|---|---|
| `#D6E1EC` Text | Background | 14.59 | Pass | Pass | Primary text and numerals |
| `#D6E1EC` Text | Panel | 13.48 | Pass | Pass | Text in cards and tables |
| `#9BAFC4` Dim | Panel | 7.93 | Pass | Pass | Body copy, table notes |
| `#9BAFC4` Dim | Header | 6.89 | Pass | Fail | Panel header text |
| `#7C90A4` Faint | Panel | 5.43 | Pass | Fail | Small caps labels, metadata |
| `#7C90A4` Faint | Background | 5.88 | Pass | Fail | Axis labels |
| `#3DD68C` Up | Panel | 9.53 | Pass | Pass | Positive deltas, rising candles |
| `#3DD68C` Up | Background | 10.31 | Pass | Pass | Ticker positive values |
| `#FF8080` Down | Panel | 7.36 | Pass | Pass | Negative deltas, falling candles |
| `#FF8080` Down | Background | 7.97 | Pass | Pass | Ticker negative values |
| `#E0A93C` Gold | Panel | 8.43 | Pass | Pass | Accent, unvalidated markers, break-even |
| `#5BC8E8` Cyan | Panel | 9.25 | Pass | Pass | Primary series, meters, depth bars |
| `#A99BF0` Violet | Panel | 7.35 | Pass | Pass | Pattern tags and series |
| `#0A0E14` Ink | `#E0A93C` Gold | 9.13 | Pass | Pass | Text on active pill and skip link |

The terminal theme clears AAA for every element that carries substance: primary text, all numerals, both delta colors, and all four accent colors. Only the small caps metadata labels sit between AA and AAA, which is the correct place for them since they are supporting chrome rather than content.

### 3.2 Research theme (toggle)

Surfaces: background `#FAFAF9`, panel `#FFFFFF`, panel 2 `#F4F6F7`, header `#EDF1F3`.

| Foreground | Background | Ratio | AA | AAA |
|---|---|---|---|---|
| `#1E3D4C` Text | Background | 11.01 | Pass | Pass |
| `#5A6B75` Dim | Panel | 5.53 | Pass | Fail |
| `#5C6A73` Faint | Header | 4.91 | Pass | Fail |
| `#1F7A52` Up | Panel | 5.30 | Pass | Fail |
| `#B03A3A` Down | Panel | 5.98 | Pass | Fail |
| `#856427` Gold | Panel | 4.80 | Pass | Fail |
| `#1E6E86` Cyan | Panel | 5.79 | Pass | Fail |
| `#5B4EA8` Violet | Panel | 6.77 | Pass | Fail |

### 3.3 Remediation applied during this audit

Four failures were found and fixed rather than filed as known limitations.

| Issue | Original | Ratio | Replaced with | New ratio |
|---|---|---|---|---|
| Terminal keyboard-shortcut labels on the selected navigation row | `#7C90A4` on `#1E2A38` | 4.42 | `#9BAFC4` | 6.51 |
| Research small caps labels on panel headers | `#63727B` on `#EDF1F3` | 4.37 | `#5C6A73` | 4.91 |
| Research gold accent on inset surfaces | `#8E6D2B` on `#F4F6F7` | 4.43 | `#856427` | 5.03 |
| Research small caps labels on white (found in the earlier pass) | `#7C8A93` on `#FFFFFF` | 3.55 | `#5C6A73` | 5.58 |

### 3.4 Color is never the only encoding

This matters more in a terminal interface than in most, because red and green carry meaning here rather than decorating it. Roughly one in twelve men has a red-green color vision deficiency, so an up-versus-down encoding carried by hue alone would be unreadable to a meaningful share of any audience.

| Meaning | Color | Additional encoding |
|---|---|---|
| Positive delta | Up green | Up triangle glyph plus a `+` sign |
| Negative delta | Down red | Down triangle glyph plus a `−` sign |
| Unchanged | Faint | Horizontal bar glyph plus `0.0` |
| Rising candle | Up green | Body is filled |
| Falling candle | Down red | Body is hollow, outline only |
| Confidence band | Cyan meter segments | Numeric score plus the band word, plus an `aria-label` naming both |
| Claim type | Border color | Text label inside the tag, plus a distinct border style (solid, dashed, dotted) |
| Validation status | Gold border | The word "Unvalidated" |
| Withheld score | Faint text | The word "Withheld" plus a stated reason |
| License status | Red border | The word "Unverified" |
| Sensitivity heatmap | Green and red tints | The numeric value in every cell, with a minus sign on losses |
| Current navigation item | Left border and fill | `aria-current="page"` plus bold weight |
| Toggle state | Border color | `aria-pressed` |

Every chart is also legible in grayscale, because series are additionally distinguished by position and, where they overlap, by dash pattern.

## 4. Keyboard navigation flow verified

Verified by tab traversal through every screen in both themes.

1. Skip link, first stop, visible on focus.
2. Theme toggle in the top bar.
3. Ticker pause control, before the ticker content, so a user who wants it stopped reaches the control before the movement.
4. Primary navigation, ten buttons in DOM order.
5. Main content, focused programmatically on screen change so reading position follows the navigation choice.
6. In-screen interactive elements in visual order: filters, table controls, chart period pills, series toggles, then any form.

No positive `tabindex` anywhere. No focus trap. No element reachable by mouse and not by keyboard.

Chart series toggles and period selectors are real buttons with `aria-pressed`, operable with Enter and Space. Each chart carries a "View as data table" control rather than relying on hidden text, because a data table is what a keyboard or screen reader user actually needs from a candlestick chart.

## 5. Screen reader testing

**Automated verification performed:** axe-core rules covering ARIA validity, accessible name computation, landmark structure, heading order, table structure, and form labelling. All pass in both themes across all ten screens.

**Manual verification performed:** structural review of landmarks, heading hierarchy on every screen, table semantics including `th scope="row"` in the sensitivity grid, live region behavior on screen and theme change, and the accessible labels on every chart.

**Not yet performed:** end-to-end testing with NVDA on Windows and VoiceOver on macOS. Scheduled before M11 ships. Automated tooling catches roughly a third to a half of real accessibility problems, so the wireframe should not be described as screen reader verified until a person has listened to it.

## 6. Known limitations and remediation plan

| Limitation | Impact | Plan |
|---|---|---|
| No manual screen reader pass yet | Automated tools miss reading-order awkwardness and unhelpful announcements | NVDA and VoiceOver before M11 ships |
| AAA not achieved for supporting text in either theme, or for any research-theme color | Metadata labels sit between AA and AAA | Accepted. Pushing supporting chrome to 7:1 collapses the visual hierarchy that makes a dense table readable. In the terminal theme, everything carrying substance already exceeds 7:1. |
| Charts are rendered from static placeholder arrays | The data table alternative is a control that does not yet open anything | Built at M11 with a real table alternative and keyboard-navigable data points |
| Form validation not implemented | 3.3.1 and 3.3.3 untestable | Built at M13 with errors associated through `aria-describedby` |
| Table sorting not wired | Sort state announcement untestable | Built at M12 with `aria-sort` and a live region announcement |
| Dense ranking table scrolls horizontally below roughly 1,100 px | Fifteen columns cannot reflow to a phone without becoming useless | Accepted for now. A column visibility control and a card view for narrow screens are specified at M12. |
| Theme preference is not persisted | Toggle resets on reload | Trivial, deferred to M11 with the rest of user preferences |
| Single typeface at small sizes | Plus Jakarta Sans replaced the monospace face throughout at the client's direction. Numeric alignment now depends on OpenType tabular figures rather than fixed advance widths. | Verified: 0 axe violations after the change, in both themes and across all tutorial lessons. If a future browser or fallback lacks `tnum`, dense numeric columns lose decimal alignment. Acceptable and reversible in one CSS block. |

`prefers-reduced-motion` is honored: all transitions are removed and the ticker animation stops entirely.

## 7. Reviewer

Reviewed by Dr. Sharilyn Rennie, August 11, 2026.

Audit method: axe-core 4.x via `@axe-core/playwright` against Chromium. Ten screens scanned individually in each of two themes, twenty scans, plus programmatic contrast measurement of every color pair in both token sets and manual structural review. The audit script is included in the bundle as `a11y-check.mjs` and can be re-run against any revision.
