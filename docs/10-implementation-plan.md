# Step 10. Implementation Plan

Seventeen milestones. Each is one to two weeks of focused work, each has an acceptance test that either passes or does not, and each leaves the system in a working state.

Four hard gates sit between groups of milestones. A gate is not a review meeting. It is a condition that must be true before the next milestone starts.

---

## Gate structure

| Gate | Position | Condition | Why it exists |
|---|---|---|---|
| **G-A. Data integrity** | After M06 | Point-in-time replay is proven, the validation gate blocks a deliberately corrupted vintage, and every Tier A source round-trips reproducibly | No score may be computed on a store that cannot prove what it knew and when |
| **G-B. Confidence before opportunity** | Between M09 and M10 | The Confidence Score is computed, stored, and rendered with its component breakdown | If the confidence machinery is not already visible, the first attractive Opportunity Score will be believed |
| **G-C. Validation before narrative** | Before M15 ships any pattern history | No pattern claims historical behavior until `pattern_validation` has rows clearing the Step 8 sample gates | This is the difference between analysis and storytelling |
| **G-D. Calibration before probability** | Phase 3 | No probability or interval is displayed until reliability and coverage tests pass | An uncalibrated probability is worse than no probability |

---

## Phase 1. Functional Intelligence MVP

### M00. Repository and infrastructure skeleton
Monorepo, Docker Compose with Postgres and TimescaleDB, Dagster, FastAPI, Next.js. CI running ruff, mypy, pytest, eslint, tsc. Pre-commit hooks. Secrets through environment only.

**Acceptance:** `docker compose up` produces a working stack from a clean checkout. CI fails on a deliberately introduced type error.

### M01. Geography spine
Load the geography dimension for nation, state, CBSA, county, and ZCTA, with vintage years. Load the HUD USPS ZIP crosswalk and OMB CBSA delineations. Implement the aggregation function, and deliberately implement no disaggregation function.

**Acceptance:** every county resolves to exactly one CBSA or to non-metro. Every ZCTA's county allocation weights sum to 1.0 within 0.001. A unit test asserting that a downward allocation attempt raises an exception passes.

### M02. Connector framework and raw landing
Implement the `Connector` protocol, the artifact store with SHA-256 content addressing, the ingest run manifest, and the license class enum with write-time enforcement.

**Acceptance:** the same fetch run twice produces one artifact row, not two. A parse re-run against a stored artifact with no network access produces byte-identical parsed output.

### M03. First three connectors
FRED, Census ACS, BLS LAUS. Chosen because they cover three different access patterns: keyed REST with a series grammar, keyed REST with a geography grammar, and a rate-limited API needing request batching.

**Acceptance:** all three load to L1 for every county in three test states. The BLS connector stays under 500 queries per day while covering 3,143 counties, proven by a recorded run.

### M04. Canonical store and bitemporal loader
Build `metric_definition`, `metric_source_binding`, `metric_observation`. Implement vintage sequencing, `metric_current`, and `metric_as_of`.

**Acceptance:** load a series, load a revised version of the same period, then assert that `metric_as_of` at a date before the revision returns the original value and `metric_current` returns the revision. This is the single most important test in the codebase.

### M05. Validation gate and quarantine
Structural, range, continuity, and cross-source checks. Quarantine table. Confidence penalty wiring.

**Acceptance:** a vintage with an out-of-range value is blocked and quarantined with the failing check named. A vintage with an unusual but physically possible jump is written with an `outlier_review` flag rather than blocked. A missing value stays null and is never imputed, asserted by test.

### M06. Remaining Tier A connectors
FHFA, Census BPS, BLS QCEW, BLS PPI, BEA, FEMA NRI, FEMA OpenFEMA, NOAA Storm Events, HUD FMR and crosswalk, Freddie Mac PMMS, Treasury FIO.

**Acceptance:** national county coverage for every Tier A metric, with a coverage report showing exactly which counties are missing which metrics and why. That report is a deliverable, not a byproduct.

> ### GATE A. Data integrity
> Point-in-time replay proven. Corrupted vintage blocked. All Tier A sources reproducible. Coverage report reviewed.

### M07. Tier B connectors and the license decision
Realtor.com and Redfin connectors, both registered as `UNVERIFIED`. Export blocking implemented and tested. The two license emails sent and their answers recorded in `license_terms`.

**Acceptance:** an export attempt on a figure whose lineage includes an unverified source is blocked with a clear message. A `license_terms` row promoting a dataset out of `UNVERIFIED` unblocks it, proven by test.

**These emails should be sent during M00, not M07.** They cost twenty minutes and the answers can take weeks. Everything downstream of the exit liquidity pillar depends on them.

### M08. Feature layer and peer sets
dbt models for every feature in Step 5. Peer set construction with point-in-time population tertiles. Winsorization, percentile ranking, polarity orientation. Robust z as a parallel normalization for later comparison.

**Acceptance:** features computed for all covered counties and CBSAs across the full available history. Percentile ranks within a peer set sum to the expected uniform distribution within tolerance. A point-in-time feature computed at a past date does not change when new data arrives, asserted by test.

### M09. Confidence Score v1
All seven components. Component storage. The supporting and limiting lists generated from the component detail. Bands.

**Acceptance:** every covered market has a confidence score with a full component breakdown. The distribution across markets is sensible: dense metro counties in the 65 to 80 range, thin rural counties below 40, no market above 90. A market with a deliberately deleted source shows the expected coverage drop.

> ### GATE B. Confidence before opportunity
> Confidence computed, stored, and rendered with its breakdown before any opportunity number exists anywhere in the system.

### M10. Opportunity Score v1
Pillar computation with coverage-based renormalization. Composite. All five publication gates. Withholding with reasons. Model version record with `weight_provenance = 'declared_prior'` and `validation_status = 'unvalidated'`.

**Acceptance:** scores computed for markets clearing the gates, withheld with stated reasons for those that do not. The withheld count is large and every reason is specific. Component contributions sum to the composite within floating-point tolerance. Every UI surface carries the unvalidated label.

### M11. Shared UI primitives and the market page
`ScoreBadge`, `ConfidenceMeter`, `ProvenancePopover`, `ExplainButton`, `ClaimTag`, `PillarBreakdown`, `SeriesChart`, `WithheldNotice`, `LicenseBadge`. Then the market page assembled from them.

**Acceptance:** every displayed number reaches its provenance in one interaction. Full keyboard traversal of the market page including the chart. Automated axe scan passes with zero violations. Contrast measured and recorded in `compliance-notes.md`. A withheld market renders its withheld state rather than an empty page.

Primitives first, page second. Building the page first produces primitives shaped by one screen's convenience.

### M12. Discover and Watchlist
Screener with peer set selection and preference filters. Rank table with sorting, column visibility, and sparklines. Withheld markets panel with gate breakdown. Watchlist with change columns and pinned comparison.

**Acceptance:** a filtered ranking of 1,000 rows renders and sorts without perceptible delay. The withheld panel accounts for every evaluated market, so scored plus withheld equals evaluated exactly.

### M13. Deal Analyzer
Deterministic arithmetic only. Conservative, base, and optimistic scenarios. Sensitivity grid. Break-even and maximum advisable purchase. Market context card. Client and server computation with a parity assertion.

**Acceptance:** client and server results match to the cent on 500 randomized input sets, run in CI. Every output traces to inputs with no hidden constants. Full keyboard operation of the form with associated error messages.

### M14. Pattern engine and three patterns
Generic evaluator over the JSONB specification. The three patterns from Step 7. Persistence tracking, invalidation, status transitions. Pattern library UI showing the unvalidated state correctly.

**Acceptance:** a pattern fires on synthetic data constructed to satisfy its conditions and does not fire when any invalidation condition is added. Detection confidence is capped at 40 for every unvalidated pattern, asserted by test. The UI renders "no historical validation yet" and contains no generated historical narrative, asserted by a snapshot test.

### M15. Backtest harness
Point-in-time replay driver. ALFRED vintage recovery for eligible series. Synthetic-vintage labeling. FFR label with the two alternate weightings. Walk-forward folds with embargo. Rank IC with Newey-West standard errors. Decile spreads. Four baselines. The nine look-ahead trap tests. Pattern event study with matched controls, clustered bootstrap, and FDR control.

**Acceptance:** all nine trap tests pass. The harness produces a full report on the Opportunity Score and the three patterns. Whatever that report says, it is published to the Data and Sources screen.

> ### GATE C. Validation before narrative
> Patterns claim historical behavior only after clearing the Step 8 sample gates on genuine-vintage evidence.

### M16. Weekly Intelligence Report
Rendered from a stored score run, never recomputed on view. The ten sections from Section 23 of the master spec. Significance ranking with the count of items not shown stated explicitly. One learning topic tied to something actually happening in the investor's markets or portfolio.

**Acceptance:** opening a prior week's report shows that week's numbers, asserted by test. The report contains no claim not traceable to a stored row. Export respects license blocking.

---

## Phase 2. Personal Investment Intelligence

Sequenced after Phase 1 is in daily use, because the requirements for follow-up prompts will change once real projects are being tracked.

| Milestone | Content | Acceptance |
|---|---|---|
| M17 | Projects, line items, planned against actual, project financials | A project can be created, tracked through every status, and closed with full actuals |
| M18 | Guided follow-up prompts triggered by status transitions, each stating why it is being asked | A prompt fires on transition to listed, prefilled, one-click confirmable, and every prompt shows its reason |
| M19 | Portfolio analytics and category variance | Variance by category with sample sizes shown in headlines, and nothing presented as a pattern below 3 projects |
| M20 | Personal pattern engine on the same JSONB evaluator | Sample gates from Step 7.7 enforced by test. Nothing auto-adjusts an underwriting default without recorded approval |
| M21 | Decision journal and Run Analysis | Every score, pattern, and prediction shown at decision time is reproducible from stored rows |

## Phase 3. Predictive Intelligence

Begins only when either enough completed projects exist for personal models, or the market backtest has produced a validated result. Not on a date.

| Milestone | Content | Gate |
|---|---|---|
| M22 | Outcome models on personal project history, conformal intervals | G-D calibration |
| M23 | Prediction versus actual tracking and error attribution | |
| M24 | Personal against market model blending, per Section 22 | The blend is explained numerically every time it is applied |

## Phase 4. National Discovery

ZIP-level analysis where statistically defensible, expanded screening, and advanced comparison. Deliberately last, because Section 4's prohibition on fabricated ZIP precision is easiest to violate under pressure to expand coverage.

---

## Sequencing decisions worth defending

**Confidence before Opportunity.** The most important ordering choice in the plan. Ship the uncertainty machinery first and the score arrives into a system that already knows how to qualify it.

**Primitives before pages.** `ProvenancePopover` and `ConfidenceMeter` are the components that make the product honest. Building them as page-level conveniences produces components shaped by one screen.

**Backtest before the weekly report.** The weekly report is where narrative pressure is highest. It should not exist until the system can say what is validated and what is not.

**Deal Analyzer before any model.** Deterministic arithmetic on the investor's own assumptions is genuinely useful on day one, has no data dependency, and creates no false precision.

**Tier B licensing emails in week one.** Twenty minutes of work whose answer takes weeks and gates an entire pillar.

**Pattern count of three.** Three fully specified and correctly qualified patterns is a better product than fifteen thin ones, and it is a smaller surface to validate.

## What is deliberately not in this plan

Property-level analysis, comps, an AVM, foreclosure and distress screening, ZIP-level scoring outside dense metros, automated weight fitting before the sample gates are met, alerts before the backtest, mobile-specific views, and multi-user infrastructure.

Each is absent for a stated reason, and each has a documented condition that would bring it in.
