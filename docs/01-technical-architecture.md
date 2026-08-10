# Step 1. Technical Architecture

## 1.1 The single decision everything else follows from

PatternIQ has to answer a question most analytics products never ask:

> What would this investor have known on March 14, 2023?

Section 14 of the master spec makes point-in-time reconstruction a requirement, and Section 31 requires an auditable decision journal. Those two requirements together rule out the ordinary design where a table holds the current value of each metric and gets overwritten on refresh. Housing data revises constantly. FHFA revises repeat-sale indexes as new pairs arrive. BLS benchmarks local area unemployment annually. Zillow and Realtor.com restate recent months. A system that overwrites cannot backtest, and a system that cannot backtest cannot tell you whether its patterns work.

So the core of PatternIQ is a **bitemporal metric store**. Every observation records both the period it describes and the moment we learned it. Nothing is ever updated in place. Revisions are new rows.

Everything else in this architecture exists to feed, guard, or read that store.

## 1.2 Stack

| Layer | Choice | Why |
|---|---|---|
| Database | PostgreSQL 16 with TimescaleDB | Hypertables on the observation table give time partitioning and compression without leaving SQL. Postgres gives strong constraints, which matter more here than throughput. |
| Object storage | Local filesystem in dev, S3-compatible in production (Cloudflare R2 or Backblaze B2) | Raw source artifacts are stored byte for byte, never parsed in place. |
| Ingestion and modeling | Python 3.12, `httpx`, `pandas`, `polars` for the wide files, `pyarrow` | Every source in the matrix is a REST call or a file download. |
| Orchestration | Dagster | Asset-based orchestration matches the layer model directly. Each dataset is an asset with declared dependencies, freshness policies, and per-asset checks. Prefect is an acceptable substitute. |
| Transformations | dbt-core against Postgres | Keeps L2 to L3 logic in version-controlled SQL with tests and lineage. |
| Validation | Pandera for record-level contracts, dbt tests for relational contracts, custom vintage-comparison checks | See Section 1.6. |
| Modeling | scikit-learn, statsmodels, `mapie` for conformal prediction intervals | Interval estimates are a spec requirement, not an add-on. |
| API | FastAPI, Pydantic v2 | Typed contracts shared with the front end via generated OpenAPI. |
| Front end | Next.js 15 (App Router), TypeScript, TanStack Query, TanStack Table, visx or Observable Plot for charts | High-density tables and financial-style charts are the core UI need. |
| Auth | Single-tenant session auth in Phase 1, structured for Auth.js later | Scope answer was single investor. |
| Deployment | Docker Compose on a single VPS, roughly 4 vCPU and 8 GB RAM | Entire Tier A dataset for all US counties and CBSAs is well under 50 GB. |

Charting note: visx and Observable Plot are both chosen for the ability to render many series with toggling and shared axes. Recharts is not adequate for the density Section 25 asks for.

## 1.3 Layer model

Data moves through six numbered layers. Each layer has one job and can only read from the layer below it.

```
L0  RAW LANDING        Exact bytes as fetched. Immutable. Content-hashed.
                       Filesystem or object store, plus a manifest row in Postgres.
                          |
L1  PARSED             Typed records, one table per source dataset. Source's own
                       geography codes and column names preserved. No business logic.
                          |
L2  CANONICAL          metric_observation. Long format, one row per
                       (metric, geography, period, source, vintage). Bitemporal.
                       This is the only table L3 is allowed to read.
                          |
L3  FEATURES           Derived quantities: changes, rolling statistics, peer-relative
                       percentile ranks, volatility. Also point-in-time. Built by dbt.
                          |
L4  ANALYTICS          Opportunity scores, confidence scores, pattern detections,
                       predictions. Every row carries a model_version_id.
                          |
L5  APPLICATION        FastAPI read models, Next.js UI, notifications, weekly report.
```

Two rules make the layering real rather than decorative:

**Rule 1. L3 and above never reference a vendor.** Business logic addresses `metric_key = 'median_days_on_market'`, never `realtor_dot_com.median_dom`. Swapping Realtor.com for a paid MLS feed changes one row in `metric_source_binding` and nothing else. This is the concrete implementation of Section 30's requirement that data providers be replaceable.

**Rule 2. Nothing skips a layer.** No connector writes to L2 directly. No API endpoint reads L1. Violations are caught in CI by a lint rule over the dbt manifest and a static check over the connector package.

## 1.4 The bitemporal core

Each row in `metric_observation` carries five time-related fields:

| Field | Meaning |
|---|---|
| `period_start`, `period_end` | The interval the observation describes. A monthly county DOM figure for June 2026 has period 2026-06-01 to 2026-06-30. |
| `source_published_at` | When the publisher released this value, from the source's own release metadata where available. |
| `retrieved_at` | When PatternIQ fetched it. Always known, always trustworthy. |
| `vintage_seq` | A monotonically increasing integer per (metric, geography, period, source). Vintage 1 is the first release. Vintage 4 is the third revision. |

The knowledge cut used for backtesting is `retrieved_at`, not `source_published_at`, because `retrieved_at` is the only one PatternIQ can guarantee. If PatternIQ was not running on that date, it did not know the value, regardless of when the publisher released it. For historical bootstrapping of vintages that predate the system, see Section 8.7 on the synthetic-vintage problem, which is the single largest methodological weakness in the whole design and is handled by refusing to claim the affected period as a valid backtest window.

Reads take one of two forms:

```sql
-- Current best knowledge
SELECT * FROM metric_current WHERE metric_key = ... AND geo_id = ...;

-- What we knew on a given date
SELECT * FROM metric_as_of('2023-03-14'::date) WHERE metric_key = ... AND geo_id = ...;
```

`metric_as_of(d)` selects, for each (metric, geography, period, source), the highest `vintage_seq` whose `retrieved_at <= d`. That function is the backtesting engine's only entry point to data. Every model, feature, score, and pattern evaluated historically goes through it. There is no second path, which is what prevents look-ahead bias from creeping in through a convenient shortcut.

## 1.5 Connector contract

Every source implements the same protocol. A connector is roughly one hundred lines.

```python
class Connector(Protocol):
    dataset_key: str                  # 'fhfa_hpi_annual_zip5'
    source_key: str                   # 'fhfa'
    license_class: LicenseClass       # PUBLIC_DOMAIN | PERMISSIVE_ATTRIBUTION | UNVERIFIED | LICENSED
    native_geo_levels: list[GeoLevel]
    expected_cadence: Cadence
    publication_lag: timedelta

    def discover(self) -> list[FetchPlan]: ...
    def fetch(self, plan: FetchPlan) -> RawArtifact: ...     # writes L0, returns manifest
    def parse(self, artifact: RawArtifact) -> pa.Table: ...  # writes L1
    def map_to_canonical(self, table: pa.Table) -> list[CanonicalObservation]: ...
```

Four properties fall out of this:

- **Reproducibility.** `fetch` stores the raw bytes with a SHA-256 hash and the full request. Any parse can be re-run against the original artifact without touching the network.
- **License is a first-class field.** `license_class` is checked at write time. An `UNVERIFIED` dataset can be ingested and analyzed but is blocked from any export, share, or public-facing surface until it is promoted. See Step 3.
- **Cadence and lag are declared.** The Confidence Score's freshness component reads `expected_cadence` directly, so a source that goes quiet automatically reduces confidence without anyone writing a special case.
- **Geography is declared.** `native_geo_levels` is enforced. A connector cannot emit ZIP-level observations for a dataset that only publishes counties.

## 1.6 Validation gate

Between L1 and L2 sits a gate. A vintage that fails does not get written, and does not silently replace the previous vintage. It is quarantined with a reason, and the failure lowers that source's contribution to Confidence until it clears.

Checks run in four groups.

**Structural.** Schema match, expected column set, no unexpected nulls in key columns, row count within tolerance of the previous vintage, geography codes resolve against the geography dimension.

**Range.** Values inside declared physical bounds. Unemployment rate between 0 and 100. Median days on market between 1 and 730. Median list price between 10,000 and 50,000,000. Violations are hard failures, not clamps.

**Continuity.** Period-over-period change compared against that series' own historical distribution. A change beyond the 99.5th percentile of that market's history flags the vintage for review rather than blocking it, because real markets do move. Flagged observations are written with a `quality_flag` and carry a confidence penalty.

**Cross-source.** Where two sources estimate the same construct, disagreement is measured. FHFA HPI year over year, Zillow ZHVI year over year, and Realtor.com median list price year over year should broadly agree in direction for the same county. Persistent divergence beyond a threshold raises a discrepancy record. Per Section 12, PatternIQ never silently reconciles. It shows both and flags the conflict.

Nothing in this gate substitutes an imputed value for a missing one. Missing stays missing, and missingness flows into Confidence.

## 1.7 Geography

A single `geography` dimension holds every analytical unit, with `geo_level` in (nation, state, cbsa, cbsa_division, county, place, zcta, tract). Boundaries change, so each row carries a `vintage_year` and CBSA definitions are versioned against the OMB delineation used.

Crosswalks live in `geography_crosswalk` with allocation weights. ZIP to county comes from the HUD USPS crosswalk file, which supplies residential address share and is updated quarterly. County to CBSA comes from the OMB delineation files.

Three hard rules:

1. **Never invent precision.** A county-level metric is never presented as a ZIP-level metric. The UI shows the native level on every number. This implements Section 4's prohibition directly.
2. **Aggregation rolls up only.** County to CBSA aggregation is permitted with a declared weighting basis (households, housing units, or transaction count depending on the metric). Disaggregation downward is not implemented anywhere in the codebase.
3. **Crosswalk use costs confidence.** When a metric reaches a geography through an allocation weight rather than natively, the geographic precision component of the Confidence Score is reduced in proportion to the allocation weight.

ZCTA is not ZIP. ZCTAs are Census block aggregations that approximate ZIP delivery areas, PO-box-only ZIPs have no ZCTA, and rural boundaries diverge meaningfully. Anywhere PatternIQ shows a "ZIP" built from Census data, the underlying unit is a ZCTA and the provenance panel says so.

## 1.8 Model and content versioning

Four things are versioned and immutable once used to produce a published number:

- `score_model_version`, holding the pillar weight vector, feature list, normalization method, and gates for a given Opportunity or Confidence version.
- `pattern_definition_version`, holding a pattern's signal specification.
- `prediction_model_version`, holding trained model artifacts and hyperparameters.
- `education_content_version`, so the explanation shown next to a historical score is the explanation that was current then.

Every row in L4 carries the version identifiers used. The decision journal in Section 31 is then a straightforward join rather than a separate logging system.

## 1.9 What runs when

| Job | Cadence | Notes |
|---|---|---|
| Weekly source sweep | Monday 04:00 local | Realtor.com, Redfin, Freddie Mac PMMS, any weekly series |
| Monthly source sweep | Daily check, fires on detection of new release | Zillow on the 16th, BLS LAUS, Census BPS, FHFA monthly |
| Quarterly and annual sweep | Daily check | QCEW, ACS, FHFA annual ZIP and tract, FEMA NRI, HUD FMR |
| Feature rebuild | After any successful L2 write | dbt run, incremental |
| Score run | Weekly, Monday, after feature rebuild | Writes a new `score_run` with a full snapshot |
| Pattern evaluation | Weekly, after score run | |
| Weekly intelligence report | Monday 06:00 local | Reads the score run, never recomputes |
| Backtest suite | Monthly, and on any model version change | |

Everything is idempotent and keyed on content hash, so a re-run costs nothing and never duplicates.

## 1.10 What this architecture deliberately does not have

- **No message queue, no Kafka, no streaming.** The fastest source in the matrix updates weekly. Streaming infrastructure would be pure cost.
- **No microservices.** One Python package, one API, one front end.
- **No vector database or RAG layer in Phase 1.** The AI interpretation layer in Section 28 reads structured score, component, and provenance records and renders them into prose against a fixed template. It does not free-associate over documents. This is the design that makes Section 27's fact / inference / pattern / prediction separation enforceable rather than aspirational.
- **No property-level records in Phase 1.** With free data only, PatternIQ analyzes markets. The Deal Analyzer works on user-entered property assumptions. Parcel-level analysis waits for a paid data decision.
