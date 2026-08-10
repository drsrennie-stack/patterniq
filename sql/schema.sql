-- PatternIQ MVP schema
-- PostgreSQL 16 with TimescaleDB
-- Step 4 deliverable. Reviewed, not yet applied.
--
-- Conventions
--   snake_case everywhere
--   surrogate bigint identity keys, natural keys carried as unique constraints
--   timestamptz for every instant, date for every calendar boundary
--   no ON UPDATE CASCADE anywhere; identifiers are stable by design
--   every user-owned table carries user_id even though Phase 1 has one user

BEGIN;

CREATE EXTENSION IF NOT EXISTS timescaledb;
CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS citext;

CREATE SCHEMA IF NOT EXISTS core;
CREATE SCHEMA IF NOT EXISTS ingest;
CREATE SCHEMA IF NOT EXISTS analytics;
CREATE SCHEMA IF NOT EXISTS app;

-- =====================================================================
-- ENUMS
-- =====================================================================

CREATE TYPE core.geo_level AS ENUM (
    'nation','region','division','state','cbsa','cbsa_division',
    'county','place','zcta','tract'
);

CREATE TYPE core.license_class AS ENUM (
    'PUBLIC_DOMAIN',          -- federal work, unrestricted
    'PERMISSIVE_ATTRIBUTION', -- permitted with a required disclaimer
    'LICENSED',               -- paid, terms per contract
    'MANUAL',                 -- hand curated from public statute or filings
    'DERIVED',                -- computed; inherits the strictest parent class
    'UNVERIFIED'              -- terms not confirmed; export blocked
);

CREATE TYPE core.cadence AS ENUM (
    'weekly','monthly','quarterly','annual','irregular','static'
);

CREATE TYPE core.polarity AS ENUM (
    'higher_is_better',   -- for flip opportunity, after orientation
    'lower_is_better',
    'context_only'        -- never enters a score directly
);

CREATE TYPE core.quality_flag AS ENUM (
    'ok','outlier_review','stale','suppressed','source_conflict',
    'imputed_geography','provisional'
);

CREATE TYPE core.claim_type AS ENUM ('fact','inference','pattern','prediction');

CREATE TYPE core.validation_status AS ENUM (
    'unvalidated','in_validation','validated','retired'
);

-- =====================================================================
-- CORE: geography
-- =====================================================================

CREATE TABLE core.geography (
    geo_id           bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    geo_key          text        NOT NULL,          -- 'county:06067', 'cbsa:40900', 'zcta:95618'
    geo_level        core.geo_level NOT NULL,
    name             text        NOT NULL,
    state_fips       char(2),
    county_fips      char(5),
    cbsa_code        char(5),
    zcta5            char(5),
    tract_geoid      char(11),
    vintage_year     smallint    NOT NULL,          -- boundary vintage; CBSA delineations change
    parent_geo_id    bigint      REFERENCES core.geography(geo_id),
    population       integer,                        -- latest PEP, denormalized for peer set banding
    housing_units    integer,
    land_area_sqmi   numeric(12,4),
    is_active        boolean     NOT NULL DEFAULT true,
    UNIQUE (geo_key, vintage_year)
);

CREATE INDEX ON core.geography (geo_level, state_fips);
CREATE INDEX ON core.geography (cbsa_code) WHERE cbsa_code IS NOT NULL;

-- Allocation weights for moving between geography levels.
-- Sourced from the HUD USPS crosswalk (ZIP based) and Census relationship files.
CREATE TABLE core.geography_crosswalk (
    from_geo_id      bigint      NOT NULL REFERENCES core.geography(geo_id),
    to_geo_id        bigint      NOT NULL REFERENCES core.geography(geo_id),
    weight_basis     text        NOT NULL,          -- 'residential_address_share','housing_units','population'
    weight           numeric(10,8) NOT NULL CHECK (weight > 0 AND weight <= 1),
    source_dataset_id bigint     NOT NULL,
    effective_from   date        NOT NULL,
    effective_to     date,
    PRIMARY KEY (from_geo_id, to_geo_id, weight_basis, effective_from)
);

-- =====================================================================
-- CORE: sources, datasets, licensing
-- =====================================================================

CREATE TABLE core.source (
    source_id        bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    source_key       text        NOT NULL UNIQUE,   -- 'fhfa','bls','realtor_com'
    display_name     text        NOT NULL,
    publisher        text        NOT NULL,
    homepage_url     text,
    is_government    boolean     NOT NULL
);

CREATE TABLE core.source_dataset (
    source_dataset_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    source_id         bigint    NOT NULL REFERENCES core.source(source_id),
    dataset_key       text      NOT NULL UNIQUE,    -- 'fhfa_hpi_annual_zip5'
    display_name      text      NOT NULL,
    access_url        text      NOT NULL,
    access_method     text      NOT NULL,           -- 'rest_api','file_download','arcgis_rest','manual'
    requires_auth     boolean   NOT NULL DEFAULT false,
    license_class     core.license_class NOT NULL,
    required_disclaimer text,
    native_geo_levels core.geo_level[] NOT NULL,
    expected_cadence  core.cadence NOT NULL,
    publication_lag_days smallint NOT NULL DEFAULT 0,
    history_start     date,
    reliability_grade char(1)   CHECK (reliability_grade IN ('A','B','C','D')),
    known_limitations text,
    is_enabled        boolean   NOT NULL DEFAULT true
);

-- The audit trail for licence questions. A dataset is promoted out of
-- UNVERIFIED only by inserting the actual permission text here.
CREATE TABLE core.license_terms (
    license_terms_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    source_dataset_id bigint   NOT NULL REFERENCES core.source_dataset(source_dataset_id),
    terms_url        text,
    terms_text       text      NOT NULL,
    permits_storage  boolean,
    permits_derived_display boolean,
    permits_redistribution  boolean,
    requires_attribution    boolean,
    obtained_via     text      NOT NULL,            -- 'published_terms','email_confirmation','contract'
    obtained_at      date      NOT NULL,
    reviewed_by      text      NOT NULL,
    notes            text
);

-- =====================================================================
-- INGEST: raw landing and run manifest
-- =====================================================================

CREATE TABLE ingest.ingest_run (
    ingest_run_id    bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    source_dataset_id bigint   NOT NULL REFERENCES core.source_dataset(source_dataset_id),
    started_at       timestamptz NOT NULL DEFAULT now(),
    finished_at      timestamptz,
    status           text      NOT NULL DEFAULT 'running',  -- running|succeeded|failed|quarantined
    records_parsed   integer,
    records_written  integer,
    error_detail     text,
    connector_version text     NOT NULL
);

CREATE TABLE ingest.raw_artifact (
    raw_artifact_id  bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ingest_run_id    bigint   NOT NULL REFERENCES ingest.ingest_run(ingest_run_id),
    source_dataset_id bigint  NOT NULL REFERENCES core.source_dataset(source_dataset_id),
    request_url      text     NOT NULL,
    request_params   jsonb,
    response_status  smallint,
    content_sha256   char(64) NOT NULL,
    content_bytes    bigint   NOT NULL,
    storage_uri      text     NOT NULL,             -- file:// or s3://
    retrieved_at     timestamptz NOT NULL,
    source_published_at timestamptz,                -- from the source's own release metadata
    UNIQUE (source_dataset_id, content_sha256)      -- re-fetching identical content is a no-op
);

CREATE TABLE ingest.quarantine (
    quarantine_id    bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ingest_run_id    bigint   NOT NULL REFERENCES ingest.ingest_run(ingest_run_id),
    check_name       text     NOT NULL,
    check_group      text     NOT NULL,             -- structural|range|continuity|cross_source
    severity         text     NOT NULL,             -- block|flag
    detail           jsonb    NOT NULL,
    created_at       timestamptz NOT NULL DEFAULT now(),
    resolved_at      timestamptz,
    resolution_note  text
);

-- =====================================================================
-- CORE: metric registry and the bitemporal observation store
-- =====================================================================

CREATE TABLE core.metric_definition (
    metric_id        bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    metric_key       text     NOT NULL UNIQUE,      -- 'median_days_on_market'
    display_name     text     NOT NULL,
    domain           text     NOT NULL,             -- price|liquidity|supply|distress|economy|hazard|carrying|renovation|transaction
    unit             text     NOT NULL,             -- 'days','usd','ratio','index','count','percent'
    polarity         core.polarity NOT NULL,
    valid_min        numeric,
    valid_max        numeric,
    allowed_geo_levels core.geo_level[] NOT NULL,
    default_cadence  core.cadence NOT NULL,
    is_derived       boolean  NOT NULL DEFAULT false,
    derivation_sql   text,
    education_key    text                            -- joins to app.education_content
);

-- Which dataset supplies a metric at a given geography level, and in what order
-- of preference. Swapping a vendor is an update here and nowhere else.
CREATE TABLE core.metric_source_binding (
    metric_id        bigint   NOT NULL REFERENCES core.metric_definition(metric_id),
    source_dataset_id bigint  NOT NULL REFERENCES core.source_dataset(source_dataset_id),
    geo_level        core.geo_level NOT NULL,
    preference_rank  smallint NOT NULL,             -- 1 = preferred, 2 = backup
    source_field     text     NOT NULL,
    transform_note   text,
    PRIMARY KEY (metric_id, source_dataset_id, geo_level)
);

-- The bitemporal core. Never updated in place. Revisions are new rows.
CREATE TABLE core.metric_observation (
    observation_id   bigint GENERATED ALWAYS AS IDENTITY,
    metric_id        bigint   NOT NULL REFERENCES core.metric_definition(metric_id),
    geo_id           bigint   NOT NULL REFERENCES core.geography(geo_id),
    source_dataset_id bigint  NOT NULL REFERENCES core.source_dataset(source_dataset_id),
    period_start     date     NOT NULL,
    period_end       date     NOT NULL,
    value            numeric,                        -- NULL means reported-as-missing, which is information
    value_native_geo_level core.geo_level NOT NULL,  -- what the SOURCE published, before any rollup
    allocation_weight numeric(10,8),                 -- NULL when native; < 1 when reached via crosswalk
    vintage_seq      integer  NOT NULL,
    retrieved_at     timestamptz NOT NULL,
    source_published_at timestamptz,
    raw_artifact_id  bigint   REFERENCES ingest.raw_artifact(raw_artifact_id),
    quality_flag     core.quality_flag NOT NULL DEFAULT 'ok',
    sample_size      integer,                        -- transaction count, listing count, repeat-sale pairs
    CONSTRAINT period_sane CHECK (period_end >= period_start),
    PRIMARY KEY (observation_id, retrieved_at)
);

SELECT create_hypertable('core.metric_observation','retrieved_at',
                         chunk_time_interval => INTERVAL '90 days',
                         if_not_exists => TRUE);

CREATE UNIQUE INDEX metric_observation_vintage_uq
    ON core.metric_observation (metric_id, geo_id, source_dataset_id,
                                period_start, period_end, vintage_seq, retrieved_at);

CREATE INDEX metric_observation_lookup
    ON core.metric_observation (metric_id, geo_id, period_start DESC, retrieved_at DESC);

-- Current best knowledge: latest vintage from the preferred source.
CREATE VIEW core.metric_current AS
SELECT DISTINCT ON (o.metric_id, o.geo_id, o.period_start, o.period_end)
       o.*, md.metric_key, g.geo_key
FROM core.metric_observation o
JOIN core.metric_definition md ON md.metric_id = o.metric_id
JOIN core.geography g ON g.geo_id = o.geo_id
JOIN core.metric_source_binding b
     ON b.metric_id = o.metric_id
    AND b.source_dataset_id = o.source_dataset_id
    AND b.geo_level = o.value_native_geo_level
ORDER BY o.metric_id, o.geo_id, o.period_start, o.period_end,
         b.preference_rank ASC, o.vintage_seq DESC;

-- Point in time. The ONLY entry point the backtester is permitted to use.
CREATE FUNCTION core.metric_as_of(as_of timestamptz)
RETURNS TABLE (
    metric_id bigint, metric_key text, geo_id bigint, geo_key text,
    period_start date, period_end date, value numeric,
    value_native_geo_level core.geo_level, vintage_seq integer,
    retrieved_at timestamptz, quality_flag core.quality_flag, sample_size integer
)
LANGUAGE sql STABLE AS $$
    SELECT DISTINCT ON (o.metric_id, o.geo_id, o.period_start, o.period_end)
           o.metric_id, md.metric_key, o.geo_id, g.geo_key,
           o.period_start, o.period_end, o.value,
           o.value_native_geo_level, o.vintage_seq,
           o.retrieved_at, o.quality_flag, o.sample_size
    FROM core.metric_observation o
    JOIN core.metric_definition md ON md.metric_id = o.metric_id
    JOIN core.geography g ON g.geo_id = o.geo_id
    JOIN core.metric_source_binding b
         ON b.metric_id = o.metric_id
        AND b.source_dataset_id = o.source_dataset_id
        AND b.geo_level = o.value_native_geo_level
    WHERE o.retrieved_at <= as_of
    ORDER BY o.metric_id, o.geo_id, o.period_start, o.period_end,
             b.preference_rank ASC, o.vintage_seq DESC;
$$;

-- Recorded disagreement between sources measuring the same construct.
-- Section 12 of the spec: never silently reconcile.
CREATE TABLE analytics.source_discrepancy (
    discrepancy_id   bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    metric_id        bigint   NOT NULL REFERENCES core.metric_definition(metric_id),
    geo_id           bigint   NOT NULL REFERENCES core.geography(geo_id),
    period_start     date     NOT NULL,
    source_a_dataset_id bigint NOT NULL REFERENCES core.source_dataset(source_dataset_id),
    source_b_dataset_id bigint NOT NULL REFERENCES core.source_dataset(source_dataset_id),
    value_a          numeric  NOT NULL,
    value_b          numeric  NOT NULL,
    normalized_gap   numeric  NOT NULL,             -- gap divided by cross-sectional IQR
    detected_at      timestamptz NOT NULL DEFAULT now()
);

-- =====================================================================
-- ANALYTICS: features
-- =====================================================================

CREATE TABLE analytics.feature_definition (
    feature_id       bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    feature_key      text     NOT NULL UNIQUE,      -- 'dom_yoy_change','price_reduction_share_pctile'
    display_name     text     NOT NULL,
    base_metric_id   bigint   REFERENCES core.metric_definition(metric_id),
    transform        text     NOT NULL,             -- 'yoy_change','pct_rank_peer','robust_z','rolling_std','level'
    lookback_periods smallint,
    polarity         core.polarity NOT NULL,
    peer_set_rule    text,                          -- 'same_level_population_tertile'
    education_key    text
);

CREATE TABLE analytics.feature_value (
    feature_id       bigint   NOT NULL REFERENCES analytics.feature_definition(feature_id),
    geo_id           bigint   NOT NULL REFERENCES core.geography(geo_id),
    period_start     date     NOT NULL,
    as_of            timestamptz NOT NULL,          -- knowledge date this value was computed under
    value            numeric,
    input_coverage   numeric(5,4) NOT NULL,         -- share of required inputs present
    peer_set_size    integer,
    PRIMARY KEY (feature_id, geo_id, period_start, as_of)
);

-- =====================================================================
-- ANALYTICS: model versions, scores
-- =====================================================================

CREATE TABLE analytics.score_model_version (
    model_version_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    model_family     text     NOT NULL,             -- 'opportunity','confidence'
    version_label    text     NOT NULL,             -- 'v1.0.0'
    weights          jsonb    NOT NULL,             -- pillar and component weights
    feature_set      jsonb    NOT NULL,
    gates            jsonb    NOT NULL,             -- publication thresholds
    normalization    text     NOT NULL,
    weight_provenance text    NOT NULL,             -- 'declared_prior' | 'fitted' | 'fitted_constrained'
    validation_status core.validation_status NOT NULL DEFAULT 'unvalidated',
    effective_from   timestamptz NOT NULL DEFAULT now(),
    retired_at       timestamptz,
    notes            text,
    UNIQUE (model_family, version_label)
);

CREATE TABLE analytics.score_run (
    score_run_id     bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    as_of            timestamptz NOT NULL,
    opportunity_model_version_id bigint NOT NULL REFERENCES analytics.score_model_version(model_version_id),
    confidence_model_version_id  bigint NOT NULL REFERENCES analytics.score_model_version(model_version_id),
    geo_levels       core.geo_level[] NOT NULL,
    markets_scored   integer,
    markets_withheld integer,                       -- failed a publication gate
    started_at       timestamptz NOT NULL DEFAULT now(),
    finished_at      timestamptz,
    is_backtest      boolean  NOT NULL DEFAULT false
);

CREATE TABLE analytics.opportunity_score (
    score_run_id     bigint   NOT NULL REFERENCES analytics.score_run(score_run_id),
    geo_id           bigint   NOT NULL REFERENCES core.geography(geo_id),
    period_start     date     NOT NULL,
    score            numeric(5,2),                  -- NULL when withheld by a gate
    withheld_reason  text,
    pillars_available smallint NOT NULL,
    peer_set_key     text     NOT NULL,
    rank_in_peer_set integer,
    PRIMARY KEY (score_run_id, geo_id, period_start)
);

CREATE TABLE analytics.opportunity_component (
    score_run_id     bigint   NOT NULL,
    geo_id           bigint   NOT NULL,
    period_start     date     NOT NULL,
    pillar_key       text     NOT NULL,             -- 'acquisition','exit_liquidity',...
    feature_key      text     NOT NULL DEFAULT '__pillar_rollup__',  -- sentinel, not NULL, so it can key
    raw_value        numeric,
    normalized_value numeric(5,2),
    weight           numeric(6,4) NOT NULL,
    contribution     numeric(6,3) NOT NULL,         -- points added to or subtracted from the composite
    is_available     boolean  NOT NULL,
    unavailable_reason text,
    PRIMARY KEY (score_run_id, geo_id, period_start, pillar_key, feature_key),
    FOREIGN KEY (score_run_id, geo_id, period_start)
        REFERENCES analytics.opportunity_score(score_run_id, geo_id, period_start)
);

CREATE TABLE analytics.confidence_score (
    score_run_id     bigint   NOT NULL REFERENCES analytics.score_run(score_run_id),
    geo_id           bigint   NOT NULL REFERENCES core.geography(geo_id),
    period_start     date     NOT NULL,
    score            numeric(5,2) NOT NULL,
    band             text     NOT NULL,             -- low|limited|moderate|high|very_high
    PRIMARY KEY (score_run_id, geo_id, period_start)
);

CREATE TABLE analytics.confidence_component (
    score_run_id     bigint   NOT NULL,
    geo_id           bigint   NOT NULL,
    period_start     date     NOT NULL,
    component_key    text     NOT NULL,             -- coverage|freshness|agreement|history|sample|precision|stability
    value            numeric(5,2) NOT NULL,
    weight           numeric(6,4) NOT NULL,
    contribution     numeric(6,3) NOT NULL,
    detail           jsonb,                         -- the human-readable reasons list
    PRIMARY KEY (score_run_id, geo_id, period_start, component_key),
    FOREIGN KEY (score_run_id, geo_id, period_start)
        REFERENCES analytics.confidence_score(score_run_id, geo_id, period_start)
);

-- =====================================================================
-- ANALYTICS: patterns
-- =====================================================================

CREATE TABLE analytics.pattern_definition (
    pattern_id       bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    pattern_key      text     NOT NULL,             -- 'increasing_buyer_leverage'
    version_label    text     NOT NULL,
    display_name     text     NOT NULL,
    spec             jsonb    NOT NULL,             -- required signals, thresholds, persistence, invalidation
    eligible_geo_levels core.geo_level[] NOT NULL,
    min_confidence   numeric(5,2) NOT NULL,
    validation_status core.validation_status NOT NULL DEFAULT 'unvalidated',
    interpretation_text text   NOT NULL,
    education_key    text,
    effective_from   timestamptz NOT NULL DEFAULT now(),
    retired_at       timestamptz,
    retirement_reason text,
    UNIQUE (pattern_key, version_label)
);

CREATE TABLE analytics.pattern_detection (
    detection_id     bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    score_run_id     bigint   NOT NULL REFERENCES analytics.score_run(score_run_id),
    pattern_id       bigint   NOT NULL REFERENCES analytics.pattern_definition(pattern_id),
    geo_id           bigint   NOT NULL REFERENCES core.geography(geo_id),
    period_start     date     NOT NULL,
    strength         numeric(5,2) NOT NULL,         -- weighted share of signals firing
    persistence_periods smallint NOT NULL,
    confidence       numeric(5,2) NOT NULL,
    first_detected_at date    NOT NULL,
    status           text     NOT NULL,             -- new|strengthening|stable|weakening|invalidated
    UNIQUE (score_run_id, pattern_id, geo_id, period_start)
);

CREATE TABLE analytics.pattern_signal (
    detection_id     bigint   NOT NULL REFERENCES analytics.pattern_detection(detection_id),
    feature_key      text     NOT NULL,
    required         boolean  NOT NULL,
    fired            boolean  NOT NULL,
    observed_value   numeric,
    threshold_value  numeric,
    threshold_basis  text     NOT NULL,             -- 'own_history_pctile_75','peer_pctile_70','absolute'
    PRIMARY KEY (detection_id, feature_key)
);

-- Populated only by the backtest harness. If empty, the UI must say
-- "no historical validation yet" rather than narrate.
CREATE TABLE analytics.pattern_validation (
    pattern_id       bigint   NOT NULL REFERENCES analytics.pattern_definition(pattern_id),
    horizon_months   smallint NOT NULL,
    outcome_key      text     NOT NULL,
    n_instances      integer  NOT NULL,
    n_markets        integer  NOT NULL,
    n_calendar_years smallint NOT NULL,
    base_rate        numeric(6,4) NOT NULL,
    hit_rate         numeric(6,4) NOT NULL,
    lift             numeric(6,4) NOT NULL,
    ci_low           numeric(6,4) NOT NULL,
    ci_high          numeric(6,4) NOT NULL,
    fdr_adjusted_p   numeric(8,6),
    computed_at      timestamptz NOT NULL DEFAULT now(),
    backtest_run_id  bigint,
    PRIMARY KEY (pattern_id, horizon_months, outcome_key, computed_at)
);

-- =====================================================================
-- ANALYTICS: predictions and calibration
-- =====================================================================

CREATE TABLE analytics.prediction_model_version (
    prediction_model_version_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    target_key       text     NOT NULL,             -- 'net_profit','holding_period_days','p_sells_within_target'
    version_label    text     NOT NULL,
    algorithm        text     NOT NULL,
    hyperparameters  jsonb    NOT NULL,
    training_window  daterange NOT NULL,
    feature_set      jsonb    NOT NULL,
    interval_method  text     NOT NULL,             -- 'conformal','quantile_regression'
    calibration_status core.validation_status NOT NULL DEFAULT 'unvalidated',
    artifact_uri     text,
    created_at       timestamptz NOT NULL DEFAULT now(),
    UNIQUE (target_key, version_label)
);

CREATE TABLE analytics.prediction (
    prediction_id    bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id          bigint   NOT NULL,
    prediction_model_version_id bigint NOT NULL REFERENCES analytics.prediction_model_version(prediction_model_version_id),
    subject_type     text     NOT NULL,             -- 'market','deal','project'
    subject_id       bigint   NOT NULL,
    target_key       text     NOT NULL,
    as_of            timestamptz NOT NULL,
    point_estimate   numeric,
    interval_low     numeric,
    interval_high    numeric,
    interval_level   numeric(4,3),                  -- 0.800 for an 80 percent interval
    confidence       numeric(5,2),
    drivers          jsonb,                         -- ranked contribution list
    created_at       timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE analytics.prediction_outcome (
    prediction_id    bigint   PRIMARY KEY REFERENCES analytics.prediction(prediction_id),
    actual_value     numeric  NOT NULL,
    observed_at      timestamptz NOT NULL,
    error            numeric  NOT NULL,
    interval_covered boolean  NOT NULL,
    attributed_cause text,                          -- 'renovation_underestimate','arv_overestimate',...
    attribution_detail jsonb,
    recorded_at      timestamptz NOT NULL DEFAULT now()
);

-- =====================================================================
-- APP: user, preferences, watchlist
-- =====================================================================

CREATE TABLE app.app_user (
    user_id          bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    email            citext,
    display_name     text     NOT NULL,
    created_at       timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE app.user_preference (
    user_id          bigint   PRIMARY KEY REFERENCES app.app_user(user_id),
    investment_capital numeric,
    max_acquisition_price numeric,
    target_profit    numeric,
    min_roi          numeric(6,4),
    min_annualized_return numeric(6,4),
    max_renovation_budget numeric,
    max_holding_period_days integer,
    risk_tolerance   text,                          -- conservative|balanced|aggressive
    preferred_geo_ids bigint[],
    default_financing jsonb,
    property_types   text[],
    updated_at       timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE app.watchlist (
    watchlist_id     bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id          bigint   NOT NULL REFERENCES app.app_user(user_id),
    name             text     NOT NULL,
    created_at       timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE app.watchlist_item (
    watchlist_id     bigint   NOT NULL REFERENCES app.watchlist(watchlist_id) ON DELETE CASCADE,
    geo_id           bigint   NOT NULL REFERENCES core.geography(geo_id),
    added_at         timestamptz NOT NULL DEFAULT now(),
    note             text,
    PRIMARY KEY (watchlist_id, geo_id)
);

-- =====================================================================
-- APP: deals, projects, actuals
-- =====================================================================

CREATE TABLE app.deal (
    deal_id          bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id          bigint   NOT NULL REFERENCES app.app_user(user_id),
    label            text     NOT NULL,
    geo_id           bigint   REFERENCES core.geography(geo_id),
    address_line     text,                          -- user-entered, never sourced from a licensed feed
    property_type    text,
    bedrooms         smallint,
    bathrooms        numeric(3,1),
    square_feet      integer,
    year_built       smallint,
    created_at       timestamptz NOT NULL DEFAULT now(),
    archived_at      timestamptz
);

CREATE TABLE app.deal_scenario (
    deal_scenario_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    deal_id          bigint   NOT NULL REFERENCES app.deal(deal_id) ON DELETE CASCADE,
    scenario         text     NOT NULL,             -- conservative|base|optimistic
    inputs           jsonb    NOT NULL,             -- full input set, versioned as a whole
    outputs          jsonb    NOT NULL,             -- computed results, stored for auditability
    market_snapshot  jsonb,                         -- opportunity, confidence, patterns at time of analysis
    computed_at      timestamptz NOT NULL DEFAULT now(),
    calculator_version text   NOT NULL,
    UNIQUE (deal_id, scenario, computed_at)
);

CREATE TABLE app.project (
    project_id       bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id          bigint   NOT NULL REFERENCES app.app_user(user_id),
    deal_id          bigint   REFERENCES app.deal(deal_id),
    geo_id           bigint   REFERENCES core.geography(geo_id),
    label            text     NOT NULL,
    status           text     NOT NULL,             -- underwriting|acquired|renovating|listed|pending|sold|abandoned
    acquired_on      date,
    renovation_started_on date,
    listed_on        date,
    contract_on      date,
    sold_on          date,
    created_at       timestamptz NOT NULL DEFAULT now()
);

-- Planned versus actual, one row per line item, with a planned and an actual column.
CREATE TABLE app.project_line_item (
    line_item_id     bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    project_id       bigint   NOT NULL REFERENCES app.project(project_id) ON DELETE CASCADE,
    category         text     NOT NULL,             -- kitchen|bathroom|flooring|roof|hvac|electrical|plumbing|landscaping|paint|structural|permits|other
    subcategory      text,
    planned_amount   numeric,
    actual_amount    numeric,
    planned_days     integer,
    actual_days      integer,
    recorded_at      timestamptz NOT NULL DEFAULT now(),
    note             text
);

CREATE TABLE app.project_financial (
    project_id       bigint   PRIMARY KEY REFERENCES app.project(project_id) ON DELETE CASCADE,
    planned_purchase_price numeric, actual_purchase_price numeric,
    planned_renovation numeric,     actual_renovation numeric,
    planned_holding_days integer,   actual_holding_days integer,
    planned_financing_cost numeric, actual_financing_cost numeric,
    planned_taxes numeric,          actual_taxes numeric,
    planned_insurance numeric,      actual_insurance numeric,
    planned_utilities numeric,      actual_utilities numeric,
    planned_closing_costs numeric,  actual_closing_costs numeric,
    planned_list_price numeric,     actual_list_price numeric,
    planned_sale_price numeric,     actual_sale_price numeric,
    planned_days_on_market integer, actual_days_on_market integer,
    planned_net_profit numeric,     actual_net_profit numeric,
    updated_at       timestamptz NOT NULL DEFAULT now()
);

-- Contextual follow-up prompts. Section 18.
CREATE TABLE app.followup_prompt (
    prompt_id        bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id          bigint   NOT NULL REFERENCES app.app_user(user_id),
    project_id       bigint   REFERENCES app.project(project_id) ON DELETE CASCADE,
    trigger_rule     text     NOT NULL,
    question_text    text     NOT NULL,
    reason_text      text     NOT NULL,             -- every request explains why it is being asked
    field_spec       jsonb    NOT NULL,             -- prefill values, input type, options
    created_at       timestamptz NOT NULL DEFAULT now(),
    answered_at      timestamptz,
    dismissed_at     timestamptz
);

-- =====================================================================
-- APP: decision journal, education, alerts, reports
-- =====================================================================

-- Section 31. Everything needed to judge whether PatternIQ actually worked.
CREATE TABLE app.decision_journal_entry (
    entry_id         bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id          bigint   NOT NULL REFERENCES app.app_user(user_id),
    entry_at         timestamptz NOT NULL DEFAULT now(),
    subject_type     text     NOT NULL,             -- market|deal|project
    subject_id       bigint   NOT NULL,
    score_run_id     bigint   REFERENCES analytics.score_run(score_run_id),
    opportunity_score numeric(5,2),
    confidence_score numeric(5,2),
    detected_pattern_ids bigint[],
    prediction_ids   bigint[],
    claim_type       core.claim_type NOT NULL,
    explanation      text     NOT NULL,
    user_decision    text,                          -- investigated|passed|offered|acquired|no_action
    user_rationale   text,
    outcome_recorded_at timestamptz,
    outcome_summary  jsonb
);

CREATE TABLE app.education_content (
    education_key    text     NOT NULL,
    version_label    text     NOT NULL,
    title            text     NOT NULL,
    definition       text     NOT NULL,
    calculation      text     NOT NULL,
    why_tracked      text     NOT NULL,
    rising_means     text     NOT NULL,
    falling_means    text     NOT NULL,
    interactions     text     NOT NULL,
    common_mistakes  text     NOT NULL,
    worked_example   text     NOT NULL,
    data_source_note text     NOT NULL,
    update_frequency text     NOT NULL,
    effective_from   timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (education_key, version_label)
);

CREATE TABLE app.alert_rule (
    alert_rule_id    bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id          bigint   NOT NULL REFERENCES app.app_user(user_id),
    rule_key         text     NOT NULL,
    subject_type     text     NOT NULL,
    subject_id       bigint,
    spec             jsonb    NOT NULL,             -- threshold, direction, minimum confidence
    min_confidence   numeric(5,2) NOT NULL DEFAULT 60,
    cooldown_days    smallint NOT NULL DEFAULT 14,  -- noise control
    is_enabled       boolean  NOT NULL DEFAULT true
);

CREATE TABLE app.alert_event (
    alert_event_id   bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    alert_rule_id    bigint   NOT NULL REFERENCES app.alert_rule(alert_rule_id) ON DELETE CASCADE,
    score_run_id     bigint   REFERENCES analytics.score_run(score_run_id),
    fired_at         timestamptz NOT NULL DEFAULT now(),
    headline         text     NOT NULL,
    evidence         jsonb    NOT NULL,
    claim_type       core.claim_type NOT NULL,
    acknowledged_at  timestamptz
);

CREATE TABLE app.weekly_report (
    weekly_report_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id          bigint   NOT NULL REFERENCES app.app_user(user_id),
    score_run_id     bigint   NOT NULL REFERENCES analytics.score_run(score_run_id),
    report_date      date     NOT NULL,
    sections         jsonb    NOT NULL,             -- rendered from the score run, never recomputed
    learning_topic_education_key text,
    generated_at     timestamptz NOT NULL DEFAULT now(),
    UNIQUE (user_id, report_date)
);

COMMIT;
