# Accessibility Compliance Notes

## 1. Project and files covered

**Project:** PatternIQ, Steps 1 to 10 review package
**Files covered:** `wireframes/patterniq-wireframes.html` (all ten screens: Overview, Discover, Market, Watchlist, Patterns, Deal Analyzer, Portfolio, Run Analysis, Learn, Data and Sources)
**Date:** August 10, 2026
**Reviewer:** Dr. Sharilyn Rennie

This covers the wireframe deliverable. The built application will require its own compliance notes at M11 and again at M16.

## 2. WCAG version and level achieved

Target: WCAG 2.2 Level AA minimum, Level AAA where achievable.

Automated audit: axe-core via Playwright against Chromium, tested with tags `wcag2a`, `wcag2aa`, `wcag21a`, `wcag21aa`, `wcag22aa`. Each of the ten screens was made visible and scanned individually.

**Result: 0 violations across all ten screens.**

| Criterion | Level | Status |
|---|---|---|
| 1.1.1 Non-text content | A | Pass. Decorative SVG marked `aria-hidden`. Meaningful SVG carries `role="img"` and a label. |
| 1.3.1 Info and relationships | A | Pass. Semantic landmarks, real `th` with `scope`, `caption` on every table, `fieldset` and `legend` on form groups. |
| 1.3.2 Meaningful sequence | A | Pass. DOM order matches visual order. |
| 1.4.1 Use of color | A | Pass. See section 3.3 below. |
| 1.4.3 Contrast, minimum | AA | Pass. Measured, see section 3. |
| 1.4.6 Contrast, enhanced | AAA | Partial. Primary text achieves 7:1 and above. Secondary text does not. See section 3.2. |
| 1.4.10 Reflow | AA | Pass. Grid collapses to single column at 900 px and 1000 px. No horizontal scroll at 320 px equivalent. |
| 1.4.11 Non-text contrast | AA | Pass after remediation. Focus ring and current-page marker moved to `#8E6D2B`. |
| 1.4.12 Text spacing | AA | Pass. No fixed-height text containers. |
| 2.1.1 Keyboard | A | Pass. See section 4. |
| 2.1.2 No keyboard trap | A | Pass. |
| 2.4.1 Bypass blocks | A | Pass. Skip link is the first focusable element and becomes visible on focus. |
| 2.4.3 Focus order | A | Pass. |
| 2.4.6 Headings and labels | AA | Pass. One `h1` per document, no skipped levels, every form control labelled. |
| 2.4.7 Focus visible | AA | Pass. 3 px outline with 2 px offset, never suppressed. |
| 2.4.11 Focus not obscured, minimum | AA (2.2) | Pass. Only the table header is sticky, and it does not overlay focusable content. |
| 2.5.3 Label in name | A | Pass. |
| 2.5.8 Target size, minimum | AA (2.2) | Pass. All interactive targets at or above 24 by 24 CSS pixels. Navigation and pill controls exceed it. |
| 3.1.1 Language of page | A | Pass. `lang="en"`. |
| 3.2.1 On focus | A | Pass. No context change on focus. |
| 3.3.1 Error identification | A | Not applicable in the wireframe. Specified for M13. |
| 3.3.2 Labels or instructions | A | Pass. Every input has a visible label, and assumption fields carry a hint explaining the source of the default. |
| 4.1.2 Name, role, value | A | Pass. `aria-pressed` on toggles, `aria-selected` on tabs, `aria-current` on navigation. |
| 4.1.3 Status messages | AA | Pass. Screen changes announce through a polite live region. |

## 3. Color contrast audit

Measured programmatically, WCAG relative luminance formula. Every pair rounded to two decimals.

### 3.1 Pairs in use

| Foreground | Background | Ratio | AA normal | AAA normal | Use |
|---|---|---|---|---|---|
| `#1E3D4C` Navy | `#FAFAF9` Off-white | 11.01 | Pass | Pass | Body text on page background |
| `#1E3D4C` Navy | `#FFFFFF` White | 11.49 | Pass | Pass | Text in cards and tables |
| `#1E3D4C` Navy | `#EDF1F3` Navy-tint | 10.11 | Pass | Pass | Table header text |
| `#FFFFFF` White | `#1E3D4C` Navy | 11.49 | Pass | Pass | Banner, active pill |
| `#F2D89B` | `#1E3D4C` Navy | 8.25 | Pass | Pass | Banner emphasis |
| `#A0522D` Terra-dark | `#FFFFFF` White | 5.62 | Pass | Fail | Subheads, eyebrow text |
| `#A0522D` Terra-dark | `#FAFAF9` Off-white | 5.38 | Pass | Fail | Subheads on page background |
| `#A0522D` Terra-dark | `#FBF4E6` Gold callout fill | 5.13 | Pass | Fail | Unvalidated tag text |
| `#5A6B75` Slate | `#FFFFFF` White | 5.53 | Pass | Fail | Secondary text |
| `#5A6B75` Slate | `#FAFAF9` Off-white | 5.30 | Pass | Fail | Secondary text |
| `#63727B` Mute | `#FFFFFF` White | 4.97 | Pass | Fail | Small uppercase labels |
| `#63727B` Mute | `#FAFAF9` Off-white | 4.76 | Pass | Fail | Small uppercase labels |
| `#8E6D2B` Gold-strong | `#FFFFFF` White | 4.80 | Pass | Fail | Focus ring, current-page marker |
| `#8E6D2B` Gold-strong | `#EDF1F3` Navy-tint | 4.23 | n/a, non-text | n/a | Current-page marker on selected nav row. Exceeds the 3:1 non-text requirement. |

### 3.2 Remediation applied during this audit

Two failures were found and fixed rather than documented as known limitations.

| Issue | Original | Ratio | Replaced with | New ratio |
|---|---|---|---|---|
| Small uppercase label color failed AA for normal text | `#7C8A93` on white | 3.55 | `#63727B` | 4.97 |
| Brushed gold used as focus ring and current-page marker failed the 3:1 non-text requirement against white | `#B8924A` on white | 2.90 | `#8E6D2B` | 4.80 |

`#B8924A` brushed gold remains in the palette for decorative fills where it is adjacent to navy or sits inside a labelled component. It is not used for text, focus indication, or any boundary that conveys state.

### 3.3 Color is never the only encoding

| Meaning | Color | Additional encoding |
|---|---|---|
| Confidence band | none used alone | Numeric value plus the band word, plus a filled-segment meter with an accessible label |
| Score direction | Navy for positive, terra for negative | Arrow glyph plus a signed number |
| Claim type | Border color | Text label inside the tag, plus a distinct border style (solid, dashed, dotted) |
| Validation status | Fill tint | The word "Unvalidated" |
| Withheld score | Fill tint | The word "Withheld" plus a stated reason |
| Current navigation item | Left border and fill | `aria-current="page"` plus bold weight |
| Toggle state | Border weight | `aria-pressed` |

## 4. Keyboard navigation flow verified

Verified by tab traversal through every screen.

1. Skip link is the first stop and becomes visible on focus.
2. Primary navigation, ten buttons, in DOM order.
3. Main content region, focused programmatically on screen change so the reading position follows the navigation choice.
4. In-screen interactive elements in visual order: filters, then table controls, then chart period pills, then series toggles, then any form.
5. No positive `tabindex` anywhere. No focus trap. No element reachable by mouse and not by keyboard.

Chart series toggles and period selectors are real buttons with `aria-pressed`, operable with Enter and Space. The chart itself carries a "View as data table" control rather than relying on hidden text, since a data table is what a keyboard or screen reader user actually needs.

## 5. Screen reader testing

**Automated verification performed:** axe-core rules covering ARIA validity, name computation, landmark structure, heading order, table structure, and form labelling. All pass.

**Manual verification performed:** structural review of landmarks (`nav` with an accessible name, `main` with a skip target), heading hierarchy on every screen (one `h1`, no skipped levels), table semantics (`caption`, `th` with `scope`, `th scope="row"` in the sensitivity grid), and live region behavior on screen change.

**Not yet performed:** end-to-end testing with NVDA on Windows and VoiceOver on macOS. This is scheduled before M11 ships, and the result belongs in the application's own compliance notes rather than this one. Automated tooling catches roughly a third to a half of real accessibility problems, and the wireframe should not be described as screen reader verified until a person has actually listened to it.

## 6. Known limitations and remediation plan

| Limitation | Impact | Plan |
|---|---|---|
| No manual screen reader pass yet | Automated tools miss reading-order awkwardness and unhelpful announcements | NVDA and VoiceOver pass before M11 ships |
| AAA contrast not achieved for secondary text | Secondary text sits between 4.76 and 5.62, above AA and below AAA | Accepted. Pushing secondary text to 7:1 would collapse the visual hierarchy that makes a dense research table readable. Primary text, which carries the substance, exceeds 10:1 throughout. |
| Chart is a static SVG in the wireframe | The data table alternative is a control that does not yet open anything | Built at M11 with a real table alternative and keyboard-navigable data points |
| Form validation not implemented | 3.3.1 and 3.3.3 untestable | Built at M13 with errors associated through `aria-describedby` |
| Table sorting is not wired | Sort state announcement untestable | Built at M12 with `aria-sort` and a live region announcement |
| No reduced-data or high-contrast mode | Users needing higher contrast rely on OS settings | Evaluate after M12 |

`prefers-reduced-motion` is honored: all transitions and animations are removed.

## 7. Reviewer

Reviewed by Dr. Sharilyn Rennie, August 10, 2026.

Audit method: axe-core 4.x via `@axe-core/playwright` against Chromium, ten screens scanned individually, plus programmatic contrast measurement of every color pair in the stylesheet and manual structural review. The audit script is included in the bundle as `a11y-check.mjs` and can be re-run against any revision.
