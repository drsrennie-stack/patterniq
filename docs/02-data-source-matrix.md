# Step 2. Data Source Matrix

Every fact in this section was verified against the live source in August 2026. Where a term could not be confirmed from the publisher's own page, it is marked **unverified** rather than assumed. Unverified licensing is treated as a build blocker in Step 3, not as a shrug.

Reliability is rated A through D:

- **A** Federal statistical agency, public domain, stable methodology, documented revisions.
- **B** Federal or quasi-federal, but modeled, suppressed, or infrequently updated.
- **C** Private publisher, methodology documented but changeable, terms unclear.
- **D** Sparse, stale, or requires manual curation.

---

## 2.1 Price level and appreciation

| Metric | Preferred source | Backup | Access | Geo resolution | History | Refresh | Cost | Licensing | Rel. | Known limitations |
|---|---|---|---|---|---|---|---|---|---|---|
| Repeat-sale price index | FHFA House Price Index, all-transactions and purchase-only | Zillow ZHVI | Direct file download, `fhfa.gov/hpi/download/` (quarterly xlsx, `hpi_master.csv`) and `/annual/` for `hpi_at_county.xlsx`, `hpi_at_zip5.xlsx`, `hpi_at_tract.csv` | Nation, division, state, CBSA, county, ZIP3, ZIP5, tract | Expanded national from 1975Q1, purchase-only monthly from 1991-01, county and ZIP files vary by transaction volume | Monthly and quarterly releases, annual for ZIP5 and tract | Free | Public domain, 17 USC 105 | A at state and CBSA, B at county, C at ZIP5 | Index, not a dollar level, must be anchored. County, ZIP, and tract files are labeled developmental and not seasonally adjusted. Thin geographies revise heavily as repeat pairs accumulate. |
| Typical home value level | Zillow ZHVI | Realtor.com median list price | CSV download, `zillow.com/research/data/` | Nation, state, CBSA, county, city, ZIP, neighborhood | From 1996 | Monthly, published the 16th | Free | General Zillow Terms of Use. The aggregate-data clause permits non-personal uses such as market analysis and requires "Data Provided by Zillow Group" attribution on any page showing derived charts. Whether that clause governs the Research CSVs specifically is **unverified**. | C | Smoothed and seasonally adjusted "typical value," not a median sale price. Recent months revise. Zillow warns that download paths change. |
| Median list price | Realtor.com Residential Inventory Core Metrics | Zillow median list price | CSV, `econdata.s3-us-west-2.amazonaws.com/Reports/Core/RDC_Inventory_Core_Metrics_{Geo}_History.csv` | Nation, state, CBSA, county, ZIP | Monthly from roughly 2016-07, ZIP history shorter | Monthly, roughly 1 to 2 week lag | Free | **Unverified.** The realtor.com research page blocked programmatic retrieval of its terms during research. Must be read manually before ingestion. | C | Methodology has changed over time, creating discontinuities. Small counties and ZIPs are suppressed in low-inventory months. |
| Median sale price | Redfin Data Center Housing Market Tracker | Realtor.com, Zillow | TSV/CSV download, `redfin.com/news/data-center/downloads/` | Nation, state, CBSA, county, city, ZIP, neighborhood | From 2012 | Weekly headline, monthly full geography | Free | Redfin general Terms of Use grant a personal, non-transferable license and prohibit automated access without prior written permission. No Data-Center-specific license found. **Unverified and ambiguous.** Redfin publishes `econdata@redfin.com` for research contact. | C | Minimum-sample suppression on small geographies. Recent months revise as closings post. |
| Price per square foot | Redfin Data Center | Zillow | Same as above | CBSA, county, city, ZIP | From 2012 | Monthly | Free | As above | C | Sensitive to mix shift in the transacting stock, not a quality-adjusted measure. |

---

## 2.2 Listing activity and liquidity

This block contains the metrics that matter most to flip exit analysis and that federal sources do not provide at all.

| Metric | Preferred source | Backup | Access | Geo resolution | History | Refresh | Cost | Licensing | Rel. | Known limitations |
|---|---|---|---|---|---|---|---|---|---|---|
| Median days on market | Realtor.com Core Metrics | Redfin Data Center, FRED `MEDDAYONMAR{fips}` | CSV, as 2.1 | Nation, state, CBSA, county, ZIP | From 2016-07 | Monthly | Free | Unverified, as 2.1 | C | Definition is days on Realtor.com, not MLS cumulative DOM. Relistings restart the clock. |
| Active listing count | Realtor.com Core Metrics | Redfin, Zillow inventory | CSV | Nation, state, CBSA, county, ZIP | From 2016-07 | Monthly | Free | Unverified | C | Deduplication rules changed mid-series. |
| New listings | Realtor.com Core Metrics | Redfin | CSV | Nation, state, CBSA, county, ZIP | From 2016-07 | Monthly | Free | Unverified | C | Seasonal, requires year-over-year framing. |
| Share of listings with price reduction | Realtor.com Core Metrics | Redfin price drops file | CSV | Nation, state, CBSA, county, ZIP | From 2016-07 | Monthly | Free | Unverified | C | The single best free proxy for seller capitulation. Central to the acquisition pillar. |
| Pending listings | Realtor.com Core Metrics | Redfin | CSV | Nation, state, CBSA, county | From 2016-07 | Monthly | Free | Unverified | C | Pending definitions vary regionally with contract customs. |
| Sale-to-list ratio | Redfin Data Center | Zillow sale-to-list | TSV | CBSA, county, city, ZIP | From 2012 | Monthly | Free | Unverified, as 2.1 | C | Only meaningful alongside price-reduction share, since a listing cut before contract can close at 100 percent of the reduced list. |
| Homes sold above list, off market in two weeks | Redfin Data Center | none | TSV | CBSA, county, city, ZIP | From 2012 | Monthly | Free | Unverified | C | Strong demand-heat signal, no public-domain substitute. |
| Months of supply | Derived: active listings divided by trailing 3-month average closed sales | none | Computed in L3 | Whatever both inputs share natively | Derived | Monthly | Free | Inherits from inputs | C | Derived metric, inherits the weakest input's confidence. |

**Assessment.** Every metric in this block comes from a private publisher under terms that were not confirmable in research. There is no federal substitute. If the Tier B licensing question resolves badly, the exit-liquidity pillar of the Opportunity Score cannot be computed from free data at all, and the score would need to drop from seven pillars to six with a permanent confidence penalty. This is the largest single risk in the data plan.

---

## 2.3 Supply and construction

| Metric | Preferred source | Backup | Access | Geo resolution | History | Refresh | Cost | Licensing | Rel. | Known limitations |
|---|---|---|---|---|---|---|---|---|---|---|
| Residential building permits, units and value | Census Building Permits Survey | none | Bulk files at `census.gov/construction/bps/`, plus `api.census.gov/data/timeseries/eits/bps` | State, CBSA, county, permit-issuing place | Monthly and annual from 1959 | Monthly, preliminary 12 working days after month end, revised at 17 | Free | Public domain | A at state and CBSA, B at county and place | Permits are not starts. Place-level monthly figures involve imputation for non-reporting jurisdictions and do not revise. |
| Housing units, vacancy status, tenure | Census ACS 5-year, tables B25002, B25003, B25004, DP04 | ACS 1-year for large geographies | `api.census.gov/data/{year}/acs/acs5` | Nation through tract, plus ZCTA | Rolling 5-year windows | Annual, roughly 1 year lag | Free | Public domain. API terms require the disclaimer "This product uses the Census Bureau Data API but is not endorsed or certified by the Census Bureau." API key now required for all queries. | A | 5-year estimates describe an averaged window, not a point in time. Margins of error are large at tract level. |
| National vacancy backdrop | Census Housing Vacancy Survey | none | `census.gov/programs-surveys/cps/about/hvs.html` | Nation, region, limited state | Long | Quarterly | Free | Public domain | B | Too coarse for market analysis. Context only. |
| Housing stock age and condition | Census American Housing Survey | none | Public use files | Nation, roughly 15 rotating metros | Biennial, odd years | Biennial | Free | Public domain | B | Rotating metro panel means most markets are absent in any given cycle. Context only. |

---

## 2.4 Distress and foreclosure

| Metric | Preferred source | Backup | Access | Geo resolution | History | Refresh | Cost | Licensing | Rel. | Known limitations |
|---|---|---|---|---|---|---|---|---|---|---|
| Notice of default, lis pendens, trustee sale, REO | **No free national source exists.** ATTOM Data Solutions is the deepest commercial option; PropertyRadar is the only self-serve tier with API access | County recorder and county court records, jurisdiction by jurisdiction | ATTOM: REST, pricing not published, contact sales. PropertyRadar: API included only on the Business plan at 599 per month, 549 annualized | Parcel, rolls up to any level | Vendor dependent | Vendor dependent | ATTOM unpublished. PropertyRadar 599 per month for API | Negotiated per contract. ATTOM historically restricts caching duration and redistribution. **Unverified.** | C | County-by-county recorder ingestion is technically possible but many recorder sites prohibit bulk automated access in their terms, and judicial-foreclosure states route through fragmented court dockets. |
| HUD, Fannie Mae, Freddie Mac REO listings | hudhomestore.com, homepath.com, homesteps.com | none | Listing websites, no bulk data API | Property | Current listings only | Continuous | Free | Site terms, no bulk feed offered | D | Covers only FHA-insured and GSE-owned inventory. Not a market-level distress measure. |

**Assessment.** Distressed inventory is a named factor in the Opportunity Score in Section 6 of the master spec. It is not available. Step 5 removes it from v1 rather than substituting a proxy, and Step 6 applies a standing coverage penalty to every market's confidence to record its absence.

---

## 2.5 Employment, income, and economic strength

| Metric | Preferred source | Backup | Access | Geo resolution | History | Refresh | Cost | Licensing | Rel. | Known limitations |
|---|---|---|---|---|---|---|---|---|---|---|
| Unemployment rate, labor force, employment | BLS Local Area Unemployment Statistics | FRED mirror | `api.bls.gov/publicAPI/v2/timeseries/data/`, series like `LAUCN281070000000003` | State, CBSA, county, some cities | Generally from the 1990s | Monthly, roughly 1 to 1.5 month lag | Free, key from `data.bls.gov/registrationEngine/` | Public domain. v2 limits: 500 queries per day, 50 series per query, 20 years per query. | A at state and CBSA, B at county | County estimates are model-based small-area estimates, noisy for low-population counties, benchmarked annually. |
| Employment and average weekly wage by industry | BLS Quarterly Census of Employment and Wages | none | Same API, series like `ENU04013105111150`, plus bulk CSV at `bls.gov/cew/downloadable-data-files.htm` | County by NAICS | From 1975 in bulk files | Quarterly, roughly 5 months after quarter end | Free | Public domain | A | Confidentiality suppression on thin county-industry cells, which specifically affects NAICS 23 construction wages in small counties. Long lag. |
| Total nonfarm employment | BLS Current Employment Statistics, state and metro | FRED | Same API | Nation, state, CBSA | Long | Monthly | Free | Public domain | A | No county detail. |
| Personal income, per-capita income | BEA Regional, CAINC tables | ACS B19013 | `apps.bea.gov/api/data/`, key from `apps.bea.gov/api/signup/` | County, CBSA | Varies, many series from 1969 | Annual, roughly 12 to 14 month lag | Free | US government open data. Exact ToS text **unverified**, signup page gated during research. | B | Annual only, long lag, periodic comprehensive revisions. Table code names should be spot-checked against the Swagger UI before building. |
| County and metro GDP | BEA Regional, CAGDP and MGDP tables | none | Same | County, CBSA | From roughly 2001 | Annual, 12 to 14 month lag | Free | As above | B | Too stale for tactical use. Market-tier signal only. |
| Median household income | Census ACS B19013 | BEA per-capita income | Census API | Nation through tract, ZCTA | Rolling 5-year | Annual | Free | Public domain | A | 5-year window smoothing. |
| Population and household estimates | Census Population Estimates Program | ACS B01003 | `api.census.gov/data/{year}/pep/population` | State, county, place, CBSA | Annual intercensal | Annual | Free | Public domain | A | Estimates, revised at each vintage. |

---

## 2.6 Hazard and physical risk

| Metric | Preferred source | Backup | Access | Geo resolution | History | Refresh | Cost | Licensing | Rel. | Known limitations |
|---|---|---|---|---|---|---|---|---|---|---|
| Composite natural hazard risk, expected annual loss by hazard | FEMA National Risk Index | none | Bulk CSV, geodatabase, shapefile at `hazards.fema.gov/nri/data-resources`, plus ArcGIS FeatureServer at `resilience.climate.gov` for query access | County, tract | Static composite, periodic major revisions | Infrequent, check every 12 to 24 months | Free | Public domain | B | A modeled relative-risk composite, not an actuarial loss figure. Weighting of expected annual loss, social vulnerability, and community resilience must be read from the technical documentation before use. |
| Flood zone | FEMA National Flood Hazard Layer | none | ArcGIS REST, `hazards.fema.gov/arcgis/rest/services/public/NFHL/MapServer` | Parcel-level point query | Current effective FIRMs | As panels are revised | Free | Public domain | B | FIRM currency varies widely by county. Some panels are decades old. Point queries are for the Deal Analyzer, not market screening. |
| Disaster declaration history | FEMA OpenFEMA, DisasterDeclarationsSummaries v2 | none | `fema.gov/api/open`, no key required | State, county | From 1953 | Near real time | Free | Public domain | A | Declarations reflect administrative and political process as well as hazard severity. Lagging, noisy proxy. |
| Storm event frequency and damage | NOAA NCEI Storm Events | none | Bulk CSV, `ncei.noaa.gov/stormevents/ftp.jsp` | County | From 1950, thin before the 1990s for non-tornado types | Ongoing | Free | Public domain | B | Reporting completeness improves over time, which creates a spurious upward trend if used naively. |

---

## 2.7 Carrying costs

| Metric | Preferred source | Backup | Access | Geo resolution | History | Refresh | Cost | Licensing | Rel. | Known limitations |
|---|---|---|---|---|---|---|---|---|---|---|
| Effective property tax rate | Derived: Census ACS B25103 median real estate taxes paid divided by B25077 median home value | Lincoln Institute 50-State Property Tax Comparison Study | Census API for the inputs; Lincoln study is an annual PDF at `lincolninst.edu` | County and tract from ACS; roughly 130 cities from Lincoln | ACS rolling 5-year | Annual | Free | Public domain for ACS | B for ACS derivation, D for Lincoln | ACS gives taxes actually paid, not statutory millage. It bakes in homestead exemptions, assessment caps, and non-uniform assessment ratios, and it is survey-reported. For a flipper buying a non-owner-occupied property that will be reassessed at sale, the ACS figure understates the real carrying cost in states with acquisition-value assessment. This is a known and material bias, documented in the metric's education content. |
| Statutory millage, assessment ratio, exemptions | County assessor and treasurer websites | none | Manual | County or municipality | n/a | n/a | Free but labor-intensive | Varies by jurisdiction | D | No standard format across 3,000 counties. Curated manually for watchlist markets only. |
| Homeowners insurance cost | US Treasury Federal Insurance Office homeowners data, 2018 to 2022 | NAIC annual homeowners report, state level | Excel at `home.treasury.gov/system/files/311/Supporting_Underlying_Metrics_and_Disclaimer_for_Analyses_of_US_Homeowners_Insurance_Markets_2018-2022.xlsx` | ZIP, suppressed below 10 insurers or 50 policies | 2018 to 2022 only | One-time release, no confirmed successor | Free | Public domain | D | Already three to four years stale in 2026, in a period when homeowners insurance costs moved sharply. Usable as a relative cross-sectional base layer, not as a current cost estimate. |
| Mortgage rate, 30-year fixed | Freddie Mac PMMS | FRED `MORTGAGE30US` | `freddiemac.com/pmms` weekly Excel; FRED API | National only | From 1971-04 | Weekly, Thursday | Free | Freddie Mac permits use with proper attribution and prohibits alteration of the published document. FRED requires its own disclaimer. | A | National only. Adjustable-rate and points series discontinued in November 2022. |
| Hard money and rehab loan rates | **No public source identified** | none | n/a | n/a | n/a | n/a | n/a | n/a | n/a | The rate most flippers actually pay is not published anywhere. Deal Analyzer takes it as a user input with a documented default. |

---

## 2.8 Renovation economics

| Metric | Preferred source | Backup | Access | Geo resolution | History | Refresh | Cost | Licensing | Rel. | Known limitations |
|---|---|---|---|---|---|---|---|---|---|---|
| Materials cost trend | BLS Producer Price Index commodity series: `WPU081106` and `WPU081108` softwood lumber, `WPU083103` softwood plywood, `WPU082101` millwork, `WPU101703` and related steel products, `WPU1074051` fabricated structural steel | none | BLS API v2 | National only | Long | Monthly | Free | Public domain | A | National only. Contributes no cross-market discrimination. Concrete and gypsum series IDs still need confirmation against the full BLS commodity code list. |
| Local construction labor cost | BLS QCEW, NAICS 23, average weekly wage by county | BLS CES metro construction earnings | BLS API v2 or bulk CSV | County | From 1975 | Quarterly, 5-month lag | Free | Public domain | B | Suppressed in small counties. Measures wages paid, not bid prices. |
| Contractor capacity proxy | Derived: Census BPS permit units per 1,000 housing units, combined with QCEW NAICS 23 employment change | none | Computed in L3 | County, CBSA | Derived | Quarterly | Free | Public domain inputs | C | A proxy for how busy local trades are. Unvalidated until backtesting says otherwise. |
| Local unit cost index | RSMeans, Gordian | none | Commercial license | City | n/a | Annual | Paid, not publicly priced | Proprietary | n/a | The industry standard has no free equivalent. Documented as a known gap. |

---

## 2.9 Transaction costs

| Metric | Preferred source | Backup | Access | Geo resolution | History | Refresh | Cost | Licensing | Rel. | Known limitations |
|---|---|---|---|---|---|---|---|---|---|---|
| State and local transfer tax, recording fees, mortgage recording tax | Manually curated seed table from state statute and county recorder fee schedules | none | Manual, versioned in the repo as a reviewed CSV with a citation per row | State, plus county and city overrides where they exist | Curated | Reviewed annually and on statutory change | Free, labor-intensive | Statutory text is public | C | Roughly 50 state rows plus perhaps 40 notable local overrides covers most of the country. Every row carries a statute citation and a review date. Rows past their review date are flagged as stale in the UI. |
| Typical agent commission | User preference, defaulted | none | User input | n/a | n/a | n/a | Free | n/a | n/a | Commission practice changed materially after the 2024 NAR settlement. Treated as a user assumption with a documented default, never as observed data. |
| Title, escrow, closing costs | User preference, defaulted by region | none | User input | n/a | n/a | n/a | Free | n/a | n/a | Regional custom determines who pays what. Documented as an assumption. |

---

## 2.10 Reference and infrastructure data

| Dataset | Source | Access | Purpose |
|---|---|---|---|
| ZIP to county, tract, CBSA crosswalk with residential address share | HUD USPS Crosswalk | `huduser.gov/hudapi/public/usps`, bearer token, 60 queries per minute | The only defensible way to move between ZIP and Census geography. Quarterly. |
| CBSA delineations | OMB via Census | Census delineation files | CBSA definitions change. Versioned by vintage year. |
| Fair Market Rents and Small Area FMRs | HUD USER | `huduser.gov/hudapi/public/fmr` | Rent sanity check at metro and ZCTA level. Administrative 40th-percentile figure, not market rent. Annual, effective October 1. |
| Income limits | HUD USER | `huduser.gov/hudapi/public/il` | Affordability context. |

HUD API terms explicitly permit commercial use and require the disclaimer "This product uses the HUD User Data API but is not endorsed or certified by HUD User."

---

## 2.11 Commercial upgrade path, priced

Recorded now so the decision can be made later on evidence rather than urgency.

| Provider | What it adds that free data cannot | Published price | License posture | Verdict |
|---|---|---|---|---|
| RentCast | Property records, value and rent AVM, sale and rental comps, active listings, market data for 38,000+ ZIPs, all by REST API | Free tier 50 requests per month; 74 per month for 1,000; 199 for 5,000; 449 for 25,000 | States broad permitted use, no attribution requirement. Most permissive of the group. | **Best first purchase.** Converts PatternIQ from market analysis to address-level underwriting for 74 per month. |
| HouseCanary | AVM, valuation reports, property analytics API | 19, 79, and 199 per month tiers published | Not published in detail | Second cheapest transparent entry. Weaker on distress and parcel breadth. |
| Regrid | Parcel boundaries, ownership, zoning, building footprints, 100 percent US parcel coverage claimed | Not fully published, 30-day sandbox | Separate API terms not reviewed | Worth evaluating if zoning and parcel geometry matter more than comps. |
| PropertyRadar | Foreclosure and pre-foreclosure, owner contact, transaction history | 119 to 599 per month. **API access only on the 599 tier.** | Not published | Only path to self-serve distress data with an API. Buy only when deal sourcing becomes a requirement, not for analysis. |
| ATTOM | Deepest foreclosure dataset, parcel, AVM, sales history, roughly 99 percent county coverage | Not published, contact sales | Negotiated. Historically restricts caching and redistribution. | Richest single vendor. Opaque pricing makes it a later conversation. |
| CoreLogic | Institutional-grade parcel, AVM, HPI | Not published, enterprise only | Historically restrictive | Not accessible to a single-investor tool. Skip. |
| BatchData | Property records, liens, pre-foreclosure, skip tracing | From 1,000 per month | Not published | Disproportionate to this project. Skip. |
| Zillow Bridge | Public records, Zestimate | Approval-gated, not published | **Explicitly forbids storing data locally.** Display-only license. | Incompatible with a cached analytics database. Not usable. |
| MLS via RESO Web API | Full listing detail, cumulative DOM, sold history | IDX and VOW feeds are broker-tier; vendor feeds run from roughly 1,300 to over 100,000 per year depending on MLS size | IDX is display-only. Analytics use requires a BBO or Data Access agreement, generally granted to vendor companies rather than individuals. | Requires a real estate license or broker sponsorship, and even then IDX does not authorize the analytics use PatternIQ needs. Not a near-term path. |

**Minimum meaningful paid step: RentCast at 74 per month.** That is the whole answer. It buys address-level AVM and comps, which is the difference between a market dashboard and an underwriting tool. Distress data costs roughly eight times that and should wait until deal sourcing is an actual requirement.

---

## 2.12 Sources

- FRED API and terms: https://fred.stlouisfed.org/docs/api/terms_of_use.html, key at https://fredaccount.stlouisfed.org/apikeys
- FHFA HPI datasets: https://www.fhfa.gov/data/hpi/datasets
- HUD USER APIs and terms: https://www.huduser.gov/portal/dataset/fmr-api.html, https://www.huduser.gov/portal/dataset/uspszip-api.html, https://www.huduser.gov/portal/dataset/api-terms-of-service.html
- Census BPS: https://www.census.gov/construction/bps/about.html
- Census API and terms: https://www.census.gov/data/developers/data-sets/acs-5year.html, https://www.census.gov/data/developers/about/terms-of-service.html
- Census ZCTA guidance: https://www.census.gov/programs-surveys/geography/guidance/geo-areas/zctas.html
- BLS series ID formats: https://www.bls.gov/help/hlpforma.htm, QCEW bulk files: https://www.bls.gov/cew/downloadable-data-files.htm, PPI commodity codes: https://www.bls.gov/ppi/data-retrieval-guide/producer-price-index-commodity-data-series-id-codes.txt
- BEA regional: https://www.bea.gov/data/gdp/gdp-county-metro-and-other-areas, API signup https://apps.bea.gov/api/signup/
- FEMA NRI: https://www.fema.gov/about/openfema/data-sets/national-risk-index-data, NFHL: https://hazards.fema.gov/arcgis/rest/services/public/NFHL/MapServer, OpenFEMA: https://www.fema.gov/about/openfema/api
- NOAA Storm Events: https://www.ncei.noaa.gov/stormevents/ftp.jsp
- Treasury FIO homeowners insurance data: https://home.treasury.gov/news/press-releases/jy2791
- Freddie Mac PMMS: https://www.freddiemac.com/pmms
- Realtor.com research data: https://www.realtor.com/research/data/
- Redfin Data Center: https://www.redfin.com/news/data-center/downloads/, terms https://www.redfin.com/about/terms-of-use
- Zillow Research: https://www.zillow.com/research/data/, terms https://www.zillow.com/corporate/terms-of-use/
- RentCast API pricing: https://www.rentcast.io/api
- HouseCanary pricing: https://www.housecanary.com/pricing
- PropertyRadar pricing: https://www.propertyradar.com/pricing
- ATTOM: https://www.attomdata.com/solutions/property-data-api/
- Bridge ZG Data Access: https://bridgedataoutput.com/zgdata
- RESO Web API guide: https://www.reso.org/api-guide/, NAR IDX policy: https://www.nar.realtor/handbook-on-multiple-listing-policy/advertising-print-and-electronic-section-1-internet-data-exchange-idx-policy-policy-statement-7-58
- Lincoln Institute property tax study: https://www.lincolninst.edu/publications/other/50-state-property-tax-comparison-study-2024/
