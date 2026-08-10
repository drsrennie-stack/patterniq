# Step 9. Wireframes and Component Architecture

Interactive wireframes: `wireframes/patterniq-wireframes.html`. Open in a browser. All ten screens, with working navigation.

Every value in the wireframes is a labeled placeholder and a persistent banner says so. Nothing in them describes any real market.

## 9.1 Design principles applied

From Section 25 of the master spec, translated into rules a developer can follow.

| Principle | Rule |
|---|---|
| Professional research platform, not consumer real estate | Tabular-numeral typography, dense tables, no hero imagery, no gradients, no gamification, no badges or streaks |
| High density without clutter | 13 to 14 px base for tabular data, generous whitespace between blocks rather than inside them, one accent color used sparingly |
| Excellent tables | Sticky headers, right-aligned numerics with aligned decimals, inline sparklines, sortable columns, column visibility control, no zebra striping (borders instead) |
| Evidence always visible | Every score carries its confidence at equal weight. Every number has a provenance affordance. No number appears without a path to its source. |
| Uncertainty is not decoration | Confidence is a labeled value with a band and an expandable component breakdown, never a colored dot alone |
| Accessible | WCAG 2.2 AA minimum, AAA contrast where achievable. See `compliance-notes.md`. |

Two additional rules that follow from Section 27 rather than Section 25:

**Claim typing is visual.** Facts, inferences, patterns, and predictions are rendered with distinct, labeled treatments. A fact carries a source affordance. An inference carries the reasoning. A pattern carries its validation status. A prediction carries an interval and a calibration status. The four are never styled alike.

**Absence is rendered.** A withheld score renders as a withheld score with a reason, not as an empty cell or a hidden row. The Discover screen shows the count of withheld markets in the header.

## 9.2 Palette and type

Taken from your existing primary palette, since PatternIQ has no palette of its own yet. Change it and the wireframes change with it, since everything is driven by CSS custom properties in one block.

| Token | Value | Use |
|---|---|---|
| Navy | `#1E3D4C` | Primary text, headers, table borders, completed and confirmed states |
| Navy deep | `#142A36` | Hover on navy, chart primary series |
| Navy tint | `#EDF1F3` | Selected row fill, table header fill |
| Brushed gold | `#B8924A` | Key accents, primary action, unvalidated markers |
| Terra cotta | `#C2734D` | Eyebrow text, secondary series |
| Terra dark | `#A0522D` | Subheads, emphasis, caution states |
| Off white | `#FAFAF9` | Page background |
| White | `#FFFFFF` | Card and table surfaces |
| Slate | `#5A6B75` | Secondary text, axis labels |

Type: Plus Jakarta Sans for display and headings, DM Sans for eyebrow and UI labels, and a tabular-numeral system stack for all numeric cells. No italics anywhere, per your standing rule, so emphasis uses weight and color only.

Non-color encoding is mandatory. Confidence bands carry a text label and a filled-segment meter, never color alone. Directional changes carry an arrow glyph and a sign, never color alone.

## 9.3 Screen inventory

| Screen | Answers | Primary components |
|---|---|---|
| **Overview** | What changed and what should I look at | `ChangeDigest`, `WatchlistStrip`, `PatternFeed`, `PortfolioSummary`, `MissingInfoPrompts` |
| **Discover** | Where are opportunities | `ScreenerFilters`, `MarketRankTable`, `WithheldMarketsPanel`, `PeerSetSelector` |
| **Market** | Why does this market look this way | `MarketHeader`, `ScorePanel`, `PillarBreakdown`, `SeriesChart`, `SeriesToggleList`, `PatternList`, `ProvenanceTable`, `PeerComparison` |
| **Watchlist** | What changed in what I follow | `WatchlistTable`, `ChangeColumnSet`, `PinnedComparison` |
| **Deal Analyzer** | Does this specific deal work | `DealInputForm`, `ScenarioTabs`, `ResultsPanel`, `SensitivityGrid`, `BreakEvenPanel`, `MarketContextCard` |
| **Patterns** | What is the pattern library and does it work | `PatternCatalog`, `PatternDetail`, `ValidationEvidence`, `FailureConditions` |
| **Portfolio** | How am I actually doing | `ProjectTable`, `PlannedVsActual`, `CategoryVariance`, `PersonalPatternList` |
| **Run Analysis** | What does my history tell me | `AnalysisScopePicker`, `FindingsList`, `FindingDetail` |
| **Learn** | What does this metric mean | `MetricIndex`, `ExplainPanel` |
| **Data and Sources** | Where does all this come from and how good is it | `SourceTable`, `LicenseStatusPanel`, `FreshnessMonitor`, `KnownGapsPanel`, `BacktestResults` |

Settings is a standard preferences form and is not wireframed.

## 9.4 Shared primitives

These carry the product's integrity requirements. Building them first is the reason Milestone M11 is sequenced where it is.

| Component | Props | Behavior |
|---|---|---|
| `ScoreBadge` | `score`, `band`, `modelVersion`, `validationStatus`, `withheldReason` | Renders a withheld state when `score` is null. Never renders a number without its model version accessible. |
| `ConfidenceMeter` | `score`, `band`, `components[]` | Seven-segment meter with a text label. Expands to the full component breakdown with the supporting and limiting lists from Step 6. |
| `ProvenancePopover` | `metricKey`, `geoId`, `period` | Source, native geography level, observation date, retrieval date, vintage number, license class, sample size, and a link to the raw artifact hash. Attached to every displayed number. |
| `ExplainButton` | `educationKey` | Opens the ten-part explanation from `app.education_content` at the version in force. |
| `ClaimTag` | `type` | One of fact, inference, pattern, prediction. Distinct shape and label for each. |
| `PillarBreakdown` | `components[]` | Diverging bar chart of signed contributions against the peer median, with unavailable pillars listed below, named, with reasons. |
| `SeriesChart` | `series[]`, `period`, `overlays[]` | Multi-series time chart with per-series toggles, period selector (3m, 6m, 1y, 3y, 5y, max), and shaded regions for periods flagged low confidence. Keyboard-navigable data points with an accessible data table alternative. |
| `RankTable` | `rows[]`, `columns[]` | Sticky header, sortable, column visibility, inline sparklines, right-aligned numerics with tabular figures. Every score cell carries its confidence. |
| `PatternCard` | `detection`, `definition`, `validation` | Signals fired against signals required, strength, persistence, invalidation conditions, what to watch next. Renders the "no historical validation yet" state when validation is absent. This is the component that most needs to be built correctly. |
| `EvidenceBlock` | `claims[]` | Ordered list of claims, each with its `ClaimTag`, supporting values, and provenance. The AI interpretation layer renders into this and cannot bypass it. |
| `WithheldNotice` | `reason`, `gate` | Names the gate that failed and what would change it. |
| `LicenseBadge` | `licenseClass` | Visible on any surface whose lineage includes an unverified source. Gates the export control. |

## 9.5 Application structure

```
app/
  (dashboard)/
    page.tsx                      Overview
    discover/page.tsx
    markets/[geoKey]/page.tsx
    watchlist/page.tsx
    deals/page.tsx
    deals/[dealId]/page.tsx
    portfolio/page.tsx
    portfolio/analysis/page.tsx
    patterns/page.tsx
    patterns/[patternKey]/page.tsx
    learn/page.tsx
    learn/[educationKey]/page.tsx
    sources/page.tsx
    weekly/[reportDate]/page.tsx
    settings/page.tsx
components/
  primitives/     ScoreBadge, ConfidenceMeter, ProvenancePopover, ClaimTag, ...
  charts/         SeriesChart, Sparkline, DivergingBar, ReliabilityDiagram
  tables/         RankTable, ProjectTable, SourceTable
  panels/         PillarBreakdown, PatternCard, EvidenceBlock, WithheldNotice
lib/
  api/            generated OpenAPI client
  format/         number, currency, percent, date formatters with tabular alignment
  a11y/           focus management, live region helpers
```

## 9.6 State and data flow

- Server components fetch on the server for the initial render. TanStack Query handles client-side refetch for filter and toggle interaction.
- All market data is read-only in the UI. Nothing recomputes a score client-side. A displayed score is always a stored `score_run` row, so what the investor sees is exactly what the decision journal will record.
- The Deal Analyzer is the one exception. Its arithmetic runs client-side for immediate feedback and is recomputed server-side on save, with both the inputs and the outputs stored in `deal_scenario` for auditability. A mismatch between the two is a build failure, not a rounding tolerance.
- The weekly report is rendered from its stored `sections` JSONB and never recomputed on view. Opening last month's report shows last month's numbers.

## 9.7 Accessibility, built in rather than retrofitted

Full record in `docs/compliance-notes.md`. The load-bearing decisions:

- Semantic landmarks, one h1 per page, no heading level skipped.
- Every chart has a keyboard-reachable data table alternative reached by a visible control, not hidden text.
- Color is never the only encoding. Confidence bands, score directions, pattern statuses, and validation statuses all carry text or shape.
- Focus indicators are visible at 3:1 against adjacent colors and never removed.
- Dynamic regions (filter results, score refresh, alert arrival) announce through `aria-live="polite"`.
- Collapsibles carry `aria-expanded`. Icon-only controls carry accessible names.
- `prefers-reduced-motion` removes all transitions.
- Skip link to main content is the first focusable element.
- Data tables use real `th` with `scope`, and complex tables use `headers` and `id`.
- Deal Analyzer inputs are real form fields with `label for` and `id`, `inputmode="decimal"` on numerics, and errors associated through `aria-describedby`.
