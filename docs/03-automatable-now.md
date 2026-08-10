# Step 3. What Can Be Legally and Reliably Automated Now

This section answers one question per source: can PatternIQ fetch it on a schedule, store it in a private database, compute derived metrics from it, and show those derived metrics to the investor, without violating anyone's terms?

Three tiers. The tier is stored on every dataset in the database as `license_class` and enforced at write time.

---

## Tier A. Green light. Build against these on day one.

Public domain federal data, or an explicit permissive grant. Storage, derivation, and display are all clearly permitted. Some require a disclaimer line, which is a display obligation, not a usage restriction.

| Dataset | Key or auth | Disclaimer required | Notes |
|---|---|---|---|
| FHFA House Price Index, all files including annual county, ZIP5, and tract | None | No | The single most valuable free dataset in the whole plan. Public domain, deep history, and it reaches ZIP5 and tract, which nothing else free does. |
| Census Building Permits Survey | Census API key for the API path; none for bulk files | Census disclaimer if using the API | Leading supply indicator down to permit-issuing place. |
| Census ACS 5-year and 1-year | Census API key, free, instant | Yes: "This product uses the Census Bureau Data API but is not endorsed or certified by the Census Bureau." | A key is now required for all queries, including small ones. |
| Census Population Estimates Program | Census API key | Yes, same disclaimer | |
| BLS LAUS, QCEW, CES, CPI, PPI | Free registration key, `data.bls.gov/registrationEngine/` | No | v2 limits: 500 queries per day, 50 series per query, 20 years per query. The 500 per day limit is the binding constraint at national county coverage and shapes the ingestion schedule. |
| BEA Regional, CAINC and CAGDP | Free key, `apps.bea.gov/api/signup/` | Terms text unverified, treated as standard federal open data | Table code names should be confirmed against the Swagger UI at build time. |
| FEMA National Risk Index | None | No | Bulk files, or ArcGIS FeatureServer for query access. |
| FEMA National Flood Hazard Layer | None | No | ArcGIS REST, point queries. |
| FEMA OpenFEMA disaster declarations | None, no key required | No | |
| NOAA NCEI Storm Events | None | No | Bulk CSV. |
| HUD USER: FMR, Income Limits, USPS ZIP crosswalk | Bearer token, free | Yes: "This product uses the HUD User Data API but is not endorsed or certified by HUD User." | Terms explicitly permit commercial use. Rate limit 60 per minute. |
| Freddie Mac PMMS | None | Attribution required | Terms permit use with proper attribution and prohibit altering the published document. |
| US Treasury FIO homeowners insurance ZIP file | None | No | Public domain, but a one-time 2018 to 2022 snapshot. |
| FRED, for series that originate with a government agency | Free key | Yes: "This product uses the FRED API but is not endorsed or certified by the Federal Reserve Bank of St. Louis." | See the caveat below. |

**The FRED caveat.** FRED's own terms are permissive, but FRED republishes third-party copyrighted series, including several sourced from Zillow and Realtor.com. FRED's terms explicitly place responsibility for those on the user: "You're solely responsible for complying with any requirements or restrictions imposed by data owners." Pulling `MEDDAYONMAR12086` from FRED does not launder Realtor.com's terms. The connector therefore checks each FRED series' copyright metadata and assigns Tier B to any series with a third-party owner, regardless of the fact that it arrived through a Tier A API.

---

## Tier B. Usable, but the license question is open and must be closed.

Free, no authentication, actively published for research use, and central to flip analysis. But the publisher's own terms either do not address bulk download and private storage, or address them in language written for a different part of the site.

| Dataset | The specific problem | Recommended action |
|---|---|---|
| **Realtor.com Residential Inventory Core Metrics** | The research page could not be retrieved programmatically during this research, so its terms were not read. The files sit on an open S3 bucket with no authentication and are widely used in research and by FRED. | Read `realtor.com/research/data/` and the site Terms of Use manually. Email the research team to request written confirmation of permitted use for a private analytics tool. Record the answer in the `license_terms` table with the date and the text. |
| **Redfin Data Center** | Redfin's general Terms of Use grant only a personal, non-transferable license and prohibit automated querying "for any purpose" without prior written permission. No Data-Center-specific license exists, but Redfin actively invites bulk download and publishes `econdata@redfin.com` for research collaboration. The general terms and the observed intent point in opposite directions. | Email `econdata@redfin.com` requesting written permission for automated retrieval and private storage. Until a reply arrives, ingest manually rather than on a schedule, or do not ingest. |
| **Zillow Research files** | Section 4(C) of Zillow's Terms of Use permits non-personal use of aggregate data for "real estate market analysis," requires "Data Provided by Zillow Group" attribution on any page displaying derived work, and prohibits displaying other Zillow data without written approval. That clause is written about Local-Info Pages, and whether it governs the Research CSVs is unverified. Note that the separate Zillow API terms forbid local storage entirely, which is a warning about how Zillow thinks about its data. | Ingest under the conservative reading: store privately, attribute on any display, never redistribute the raw files, never use Zillow's logo. Request written clarification before any commercial launch. |
| **FRED series with third-party copyright owners** | See the FRED caveat above. | Prefer fetching from the original publisher rather than through FRED, so the terms question is asked once at the right door. |

### The enforcement mechanism

`license_class = 'UNVERIFIED'` is a database-level property with teeth:

- Ingestion is allowed. Analysis is allowed. Display inside the private single-user app is allowed.
- Export, sharing, public URL, screenshot-to-clipboard, and the emailed weekly report are **blocked** for any figure whose lineage touches an unverified dataset, unless the user explicitly overrides with an acknowledgement that is recorded.
- The provenance panel shows the license status of every contributing source, so the investor can see at a glance which numbers are on solid legal ground.
- Promotion from `UNVERIFIED` to `PERMISSIVE_ATTRIBUTION` requires a row in `license_terms` containing the actual permission text, its source, and the date it was obtained.

This costs almost nothing to build and it means that if PatternIQ ever becomes a product, the licensing cleanup is a query rather than an archaeology project.

---

## Tier C. Not available. Do not build features that assume it.

| What the spec asks for | Reality |
|---|---|
| Distressed inventory, foreclosure activity, notices of default | No free national source exists. County recorders hold the primary records across more than 3,000 jurisdictions in inconsistent formats, many with terms prohibiting bulk automated access, and judicial-foreclosure states route through fragmented court dockets. HUD, Fannie Mae, and Freddie Mac REO listings are free but cover only FHA-insured and GSE-owned inventory and offer no bulk feed. The commercial options are ATTOM (price not published) and PropertyRadar (API only on the 599 per month tier). |
| MLS-grade listing data, cumulative days on market, verified sold comps | Requires a real estate license and MLS membership, or broker sponsorship. Even then, IDX authorizes display, not analytics. Building an analytics product on MLS data requires a BBO or Data Access agreement, which MLSs grant to vendor companies rather than to individuals. |
| Local renovation unit cost index | RSMeans has no free equivalent. BLS producer price indexes for materials are national only. |
| Statutory property tax millage, assessment ratios, exemptions | Lives on individual county assessor websites with no standard format. The Lincoln Institute study is rigorous but covers roughly 130 jurisdictions and ships as a PDF. |
| Current homeowners insurance costs | The Treasury FIO ZIP-level file ends in 2022, in the middle of the largest premium repricing in decades. NAIC reports are state-level narrative PDFs. State insurance department rate filings are state-by-state with no unified access. |
| Regional or product-specific mortgage rates, hard money and rehab loan rates | PMMS is national and conventional-conforming only. The rate a flipper actually pays is not published anywhere. |
| Property-level records, AVM, sold comps | Not available free. RentCast at 74 per month is the cheapest credible path. |

---

## What this means for the product, concretely

**1. The Opportunity Score loses a pillar and part of another.**
Distress is removed from v1 outright. Renovation economics survives only as a county wage and permit-capacity proxy, with the national materials index applied as a level shift that does not discriminate between markets. Both facts are surfaced in the score breakdown, not buried.

**2. Geographic reach is uneven, and the UI has to say so.**
FHFA reaches ZIP5 and tract. Realtor.com and Redfin reach ZIP. BLS LAUS and QCEW stop at county. BEA stops at county with a twelve-month lag. ACS reaches tract but describes a five-year average. A ZIP-level view of a market is therefore a mixture of ZIP-native price data and county-level economic data, and every number carries its native level as a visible label.

**3. The refresh cadence is monthly, not daily.**
Redfin and Realtor.com publish weekly headline figures, but the full geographic breakdown is monthly. Everything below CBSA is effectively monthly or quarterly. A daily-refresh dashboard would be theater.

**4. Two emails should be sent this week.**
One to Realtor.com research, one to `econdata@redfin.com`. Both asking for written confirmation that automated retrieval and private storage of the published research files are permitted. The answers determine whether the exit-liquidity pillar can be computed at all. Nothing else in the build plan has this much leverage for this little effort.

**5. Phase 1 ships without any of the following, and says so in the UI.**
Distressed inventory. Foreclosure activity. Property-level analysis. Local renovation cost. Current insurance pricing. Each appears in the Data and Sources screen under "Known gaps" with the reason and the cost to close it.
