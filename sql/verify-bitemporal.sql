-- Verification fixture for the point-in-time core.
-- Run against a database with sql/schema.sql applied.
-- Expected results are stated inline. This ran clean against PostgreSQL 16
-- on August 10, 2026 (TimescaleDB hypertable call skipped in the harness;
-- the DDL is otherwise unmodified).

INSERT INTO core.geography (geo_key,geo_level,name,state_fips,county_fips,vintage_year,population)
VALUES ('county:06067','county','Placeholder County A','06','06067',2023,1585000);

INSERT INTO core.source (source_key,display_name,publisher,is_government)
VALUES ('fhfa','FHFA','FHFA',true);

INSERT INTO core.source_dataset
  (source_id,dataset_key,display_name,access_url,access_method,license_class,
   native_geo_levels,expected_cadence,publication_lag_days,reliability_grade)
VALUES (1,'fhfa_hpi_annual_county','FHFA HPI county','https://example.invalid',
        'file_download','PUBLIC_DOMAIN',ARRAY['county']::core.geo_level[],'quarterly',60,'A');

INSERT INTO core.metric_definition
  (metric_key,display_name,domain,unit,polarity,allowed_geo_levels,default_cadence)
VALUES ('hpi_repeat_sale','Repeat-sale HPI','price','index','higher_is_better',
        ARRAY['county']::core.geo_level[],'quarterly');

INSERT INTO core.metric_source_binding (metric_id,source_dataset_id,geo_level,preference_rank,source_field)
VALUES (1,1,'county',1,'index_nsa');

INSERT INTO ingest.ingest_run (source_dataset_id,connector_version) VALUES (1,'0.1.0');
INSERT INTO ingest.raw_artifact
  (ingest_run_id,source_dataset_id,request_url,content_sha256,content_bytes,storage_uri,retrieved_at)
VALUES (1,1,'https://example.invalid/a.csv',repeat('a',64),100,'file:///tmp/a.csv','2024-05-01');

-- A first release on 2024-05-01, then a revision of the SAME period on 2024-08-01.
INSERT INTO core.metric_observation
 (metric_id,geo_id,source_dataset_id,period_start,period_end,value,
  value_native_geo_level,vintage_seq,retrieved_at,raw_artifact_id,sample_size)
VALUES
 (1,1,1,'2024-01-01','2024-03-31',312.40,'county',1,'2024-05-01',1,842),
 (1,1,1,'2024-01-01','2024-03-31',309.75,'county',2,'2024-08-01',1,915);

-- Expect 309.75, vintage 2. Current best knowledge.
SELECT metric_key, value, vintage_seq FROM core.metric_current;

-- Expect 312.40, vintage 1. The revision had not happened yet.
SELECT metric_key, value, vintage_seq FROM core.metric_as_of('2024-06-15');

-- Expect 0 rows. Nothing had been retrieved yet.
SELECT count(*) AS rows FROM core.metric_as_of('2024-04-01');

-- Expect a unique constraint violation. Vintages cannot be overwritten.
INSERT INTO core.metric_observation
 (metric_id,geo_id,source_dataset_id,period_start,period_end,value,
  value_native_geo_level,vintage_seq,retrieved_at)
VALUES (1,1,1,'2024-01-01','2024-03-31',999,'county',2,'2024-08-01');
