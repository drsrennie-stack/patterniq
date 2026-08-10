# Step 4. MVP Database Schema

Executable DDL is in `sql/schema.sql`. This document explains the decisions the DDL encodes.

## 4.1 Four schemas, four responsibilities

| Schema | Holds | Written by |
|---|---|---|
| `core` | Geography, sources, licensing, metric registry, the bitemporal observation store | Ingestion only |
| `ingest` | Run manifests, raw artifact index, quarantine | Ingestion only |
| `analytics` | Features, model versions, scores, patterns, predictions | dbt and the scoring jobs |
| `app` | User, preferences, watchlists, deals, projects, decision journal, education, alerts, reports | The API |

Read direction is one way. `app` reads from `analytics`, `analytics` reads from `core`, `core` reads from `ingest`. Nothing reads upward.

## 4.2 The observation table is the whole design

```sql
core.metric_observation (
    metric_id, geo_id, source_dataset_id,
    period_start, period_end,
    value, value_native_geo_level, allocation_weight,
    vintage_seq, retrieved_at, source_published_at,
    raw_artifact_id, quality_flag, sample_size
)
```

Seven things are worth defending individually.

**Long format, not wide.** One row per metric per geography per period per source per vintage. A wide table with a column per metric would need a migration every time a source is added, would waste enormous space on sparse coverage, and could not represent the same metric arriving from two sources at once. Long format costs some query verbosity and buys everything else. TimescaleDB compression on older chunks recovers most of the storage difference.

**`source_dataset_id` is part of the grain.** Two sources measuring the same construct both get stored. Neither overwrites the other. `core.metric_current` picks the preferred source through `metric_source_binding.preference_rank`, and `analytics.source_discrepancy` records when they disagree. This is Section 12's "never silently combine conflicting information" implemented as a constraint rather than a policy.

**`vintage_seq` plus `retrieved_at` make revisions first class.** A UNIQUE index on `(metric_id, geo_id, source_dataset_id, period_start, period_end, vintage_seq, retrieved_at)` means a revision cannot overwrite its predecessor. It can only be inserted alongside it.

**`value` is nullable and that is deliberate.** A reported-as-missing observation is different from an observation that was never fetched. The first is data. The second is a gap. Confidence treats them differently, so the schema has to distinguish them.

**`value_native_geo_level` travels with the value.** A county unemployment rate attached to a ZIP through a crosswalk carries `value_native_geo_level = 'county'` and an `allocation_weight` below one. The UI reads this field directly to label the number, and the Confidence Score reads it to apply the geographic precision penalty. This is how Section 4's prohibition on fabricated ZIP precision becomes structurally impossible rather than merely discouraged.

**`sample_size` is carried wherever the source publishes it.** Repeat-sale pair counts from FHFA, listing counts from Realtor.com, transaction counts from Redfin. It feeds the sample adequacy component of Confidence. Where a source does not publish it, the field is null and the component degrades accordingly.

**`raw_artifact_id` closes the provenance loop.** Every number traces to the exact bytes it came from, with a SHA-256 hash and the original request URL. The "View Sources" interaction in Section 12 is a two-join query, not a reconstruction.

## 4.3 Point in time

Two read paths, and only two.

```sql
core.metric_current             -- latest vintage, preferred source. For the live app.
core.metric_as_of(timestamptz)  -- what we knew then. For the backtester.
```

`metric_as_of` filters on `retrieved_at <= as_of` then takes the highest `vintage_seq` per key. The backtest harness has no other way in. There is no configuration flag that lets a model read current data during a historical evaluation, because the function signature makes the knowledge date a required argument rather than an option.

`retrieved_at` rather than `source_published_at` is the filter, because `retrieved_at` is the only one PatternIQ can vouch for. If PatternIQ was not running in 2019, it did not know 2019 values in 2019, whatever the publisher's release calendar says. Step 8 addresses what to do about the resulting bootstrap problem.

## 4.4 Licensing is enforced in the schema

`core.source_dataset.license_class` is an enum with `UNVERIFIED` as a real value, and `core.license_terms` is the audit table that lets a dataset be promoted out of it. Promotion requires inserting the actual permission text, where it came from, when, and who reviewed it.

The application reads `license_class` on every lineage path before allowing export, sharing, or emailed reports. A number derived from an unverified source can be looked at privately and cannot leave the building without an explicit recorded acknowledgement. This costs perhaps a day of work now and saves a legal archaeology project later.

## 4.5 Model versions are immutable

`analytics.score_model_version` holds the weight vector as JSONB, along with the feature set, the publication gates, the normalization method, and a `weight_provenance` field with values `declared_prior`, `fitted`, or `fitted_constrained`.

Section 6 of the master spec says not to hard-code arbitrary weights permanently. This is the mechanism. v1 weights are a row with `weight_provenance = 'declared_prior'` and `validation_status = 'unvalidated'`, and the UI reads both fields and labels the score accordingly. When backtesting eventually fits weights, that is a new row, not an edit. Every score ever computed remains attributable to the exact weight vector that produced it.

The same pattern applies to `pattern_definition`, `prediction_model_version`, and `education_content`, all of which are versioned with an `effective_from`. A score from March 2026 displays the explanation text that was current in March 2026.

## 4.6 Score components are stored, not recomputed

`analytics.opportunity_component` and `analytics.confidence_component` store every feature's raw value, normalized value, weight, and point contribution for every scored market at every run.

This is more rows than strictly necessary and it is worth it. Section 6 requires every score to show what raised and lowered it, Section 7 requires the same for confidence, and Section 31 requires the decision journal to reproduce what was shown at the time. Recomputing a breakdown from a stored composite is impossible once features have moved on. Storing the breakdown makes the explanation a lookup.

Roughly: 3,200 counties plus 940 CBSAs, times about 30 component rows, times 52 weekly runs, is around 6.5 million rows a year for opportunity components. Trivial for Postgres.

## 4.7 Withholding is a first-class outcome

`analytics.opportunity_score.score` is nullable, and `withheld_reason` sits beside it. A market that fails a publication gate gets a row with a null score and a reason. It is not silently absent, and it does not get a made-up number.

This matters for the failure mode this whole package is designed to prevent. A dashboard that only shows markets with scores looks complete. A dashboard that shows 2,100 scored counties and 1,100 withheld ones, each with a stated reason, tells the truth about the data.

## 4.8 Claim type is stored on every assertion

`core.claim_type` is an enum with values `fact`, `inference`, `pattern`, and `prediction`, and it appears on `decision_journal_entry` and `alert_event`. Section 27 requires these never be blurred. Putting the distinction in the type system means the UI can render each differently without depending on the AI layer to remember to.

## 4.9 Planned versus actual is a column pair, not two tables

`app.project_financial` carries `planned_x` and `actual_x` side by side, and `app.project_line_item` does the same per renovation category. Section 17 wants planned against actual on every dimension, and Section 21 wants error attribution. Column pairs make variance a subtraction rather than a join, and the per-category line items are what make Section 19's personal pattern detection ("your kitchens run 11.8 percent over") a group-by.

## 4.10 Student-privacy analogue: user data stays local

Nothing in `app` is replicated anywhere. `deal.address_line` is user-entered and is never populated from a licensed feed, so no vendor's redistribution terms attach to it. Project financials are the investor's own records. If PatternIQ ever gains a second user, `user_id` is already on every user-owned table and row-level security policies attach without a migration.

## 4.11 What is deliberately absent from the MVP schema

- No parcel or property records table. Free data does not include them. When RentCast or ATTOM is bought, that is a new schema, not a change to this one.
- No listing table. Same reason.
- No comps engine.
- No portfolio-level tax or entity structure modeling.
- No document storage.
