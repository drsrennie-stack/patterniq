# PatternIQ, Steps 1 through 10

Prepared for review. Step 11 (implementation) has not started and will not start until this package is approved.

Date: August 10, 2026
Author: Dr. Sharilyn Rennie

---

## What this package is

Section 34 of the PatternIQ master instructions requires ten deliverables before any substantial application code is written. This package contains all ten. Nothing here assumes a feature is buildable until the data behind it has been checked, and several features in the master spec are explicitly deferred because the data does not exist in a form that can be legally and reliably automated today.

The governing constraint applied throughout:

> A market gets an Opportunity Score only when the evidence behind it clears a stated floor. When it does not, PatternIQ says so instead of showing a number.

## Contents

| File | Step | What it covers |
|---|---|---|
| `docs/01-technical-architecture.md` | 1 | Stack, layer model, bitemporal data core, connector contract, deployment |
| `docs/02-data-source-matrix.md` | 2 | Full source matrix, one row per metric, with licensing and limitations |
| `data/data-source-matrix.csv` | 2 | Same matrix in machine-readable form |
| `docs/03-automatable-now.md` | 3 | Tier A / B / C classification and the legal gate for each source |
| `docs/04-mvp-database-schema.md` | 4 | Schema design rationale, entity model, point-in-time query pattern |
| `sql/schema.sql` | 4 | Executable Postgres DDL for the MVP schema |
| `docs/05-opportunity-score-v1.md` | 5 | Opportunity Score defined mathematically, with publication gates |
| `docs/06-confidence-score-v1.md` | 6 | Confidence Score defined mathematically, component by component |
| `docs/07-pattern-detection-framework.md` | 7 | Declarative pattern spec, three worked patterns, false-positive controls |
| `docs/08-backtesting-methodology.md` | 8 | Point-in-time replay, labels, walk-forward design, validation gates |
| `docs/09-component-architecture.md` | 9 | Screen inventory, component tree, shared primitives, state model |
| `wireframes/patterniq-wireframes.html` | 9 | Interactive wireframes for all ten screens |
| `docs/10-implementation-plan.md` | 10 | Seventeen milestones with acceptance tests and four hard gates |
| `docs/compliance-notes.md` | n/a | WCAG 2.2 accessibility record for the wireframe deliverable |
| `docs/open-questions.md` | n/a | Decisions that need you before Step 11 starts |

Read `docs/open-questions.md` last. Nothing in it blocks review, but four items block the build.

## Decisions already taken, from your answers

1. **Stack.** Postgres with TimescaleDB, Python ingestion and modeling, Next.js front end.
2. **Data budget.** Free and public sources for Phase 1. The paid path is documented with prices, and the exact analysis that stays impossible without it is named.
3. **Scope.** Single investor, private tool. The schema still carries a `user_id` on every user-owned table so multi-user is a migration and not a rewrite.

## The three findings that should shape your reading

**1. The metrics the spec wants most are the ones with the weakest free footing.**
Distressed inventory, foreclosure filings, sale-to-list ratio, and days on market are central to flip analysis. Public-domain federal data provides none of them. Days on market, price reductions, active inventory, and new listings are available free from Realtor.com and Redfin, but those are private companies publishing research files under general site terms that do not clearly authorize storage in a private database. Foreclosure data has no free national source at all. Section 3 sets out exactly what this means and what to do about it.

**2. Renovation cost cannot be localized for free.**
BLS producer price indexes for lumber, plywood, millwork, and steel are national only. There is no free equivalent of the RSMeans city cost index. In Opportunity Score v1 the renovation pillar therefore uses county construction wages from QCEW and permit volume as a contractor-capacity proxy, and the national materials trend is applied as a level shift that affects every market equally. It contributes almost nothing to ranking one market against another, and the spec should stop pretending otherwise until a local cost source is bought.

**3. Confidence ships before Opportunity.**
Milestone ordering in Step 10 puts the Confidence Score in production one milestone earlier than the Opportunity Score. This is deliberate. If the confidence machinery is not already running and visible, the first attractive Opportunity Score to appear on screen will be believed.

## What was verified rather than asserted

| Claim | How it was checked | Result |
|---|---|---|
| The schema is valid PostgreSQL | `sql/schema.sql` applied to a live PostgreSQL 16 instance, unmodified except for skipping the TimescaleDB hypertable call | Applies clean. 43 tables, views, and functions created. |
| The point-in-time core actually works | `sql/verify-bitemporal.sql` loads a first release and a revision of the same period, then queries both ways | `metric_current` returns the revision. `metric_as_of('2024-06-15')` returns the pre-revision value. `metric_as_of` before first retrieval returns zero rows. A duplicate vintage is rejected by unique constraint. |
| The wireframes meet WCAG 2.2 AA | axe-core via Playwright against Chromium, all ten screens scanned individually in both themes, twenty scans, with `wcag2a`, `wcag2aa`, `wcag21a`, `wcag21aa`, `wcag22aa` | 0 violations. Four contrast failures were found during the audit and fixed rather than documented as limitations. Full record in `docs/compliance-notes.md`. |
| Data source facts | Every source in Step 2 verified against the live publisher in August 2026. Anything not confirmable from the publisher's own page is marked unverified rather than assumed. | Three sources carry unresolved licensing. They are named, and the resolution path is a milestone. |

The audit script is included as `a11y-check.mjs` and can be re-run against any revision.

## How to review this

The fastest useful path is:

1. `docs/03-automatable-now.md`, to see what the data actually supports.
2. `docs/05-opportunity-score-v1.md` and `docs/06-confidence-score-v1.md`, to check the math and the publication gates.
3. `wireframes/patterniq-wireframes.html` in a browser, to see how evidence and uncertainty are surfaced.
4. `docs/10-implementation-plan.md`, to agree the sequence and the gates.

Mark anything you disagree with and it gets revised before Step 11.
