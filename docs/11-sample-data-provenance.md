# Sample Data Provenance

Every real figure used in the tutorial, where it came from, when it was published, and how it was checked.

Compiled August 11, 2026. Machine-readable copy: `data/real-data-2026-08.json`.

---

## The short version of what "last week's data" turned out to mean

The request was for accurate sample data from the last week. Here is what actually exists.

| Published in the last 7 days | Reference period it describes |
|---|---|
| Freddie Mac 30-year mortgage rate, released Aug 6 | The week ending Aug 6. Genuinely current. |
| BLS Employment Situation, released Aug 7 | July 2026. One month back. |

| Published in the last 30 days | Reference period |
|---|---|
| Realtor.com July housing report, released Aug 3 | July 2026 |
| Census New Residential Construction, released Jul 17 | June 2026 |
| FHFA House Price Index monthly, released Jul 28 | **May 2026** |

**Exactly one series in the entire PatternIQ data plan updates weekly: the mortgage rate.** Everything else describing a housing market is monthly at best, and the price index that anchors the whole appreciation picture describes conditions from nearly three months ago.

This is not a gap in the research. It is the single most important operational fact about the product, and the tutorial teaches it in its own chapter. A dashboard that refreshes daily would be showing you the same numbers with a new timestamp.

---

## 1. Realtor.com Monthly Housing Trends Report

**Reference month:** July 2026. **Released:** August 3, 2026. **Geography:** national, with four census regions.
**License class:** `UNVERIFIED`. Published free with no authentication, but terms permitting storage in a private analytics database could not be confirmed. This is the Tier B problem from Step 3, and it applies to every metric in this block.

| Metric | Value | Year over year |
|---|---|---|
| Median list price | $428,950 | −2.4% (flat versus June) |
| Active listings | 1,126,252 | +2.1% |
| New listings | 423,732 | 0.0% |
| Median days on market | 57 days | −1 day |
| Share of listings with a price reduction | 20.0% | −0.6 pp, from 20.6% |
| Median price per square foot | $226 | −2.0% |
| Pending sales | | +1.3%, eighth consecutive month of growth |

Regional median list price, year over year: West −3.9%, South −2.5%, Northeast −1.4%, Midwest +0.2%.
Regional active inventory, year over year: Midwest +9.3%, Northeast +8.3%, South −0.2%.

**Cross-checks performed.** Three of these values appear independently on FRED as mirrored series and match exactly: active listings (`ACTLISCOUUS`), median list price (`MEDLISPRIUS`), new listings (`NEWLISCOUUS`), all last updated August 7, 2026. A second independent report of the same release confirmed the price reduction share, days on market, pending sales, and the 26-month streak. Two sources, no discrepancy.

**One noted inconsistency.** The FRED page for `MEDDAYONMARUS`, read August 11, still showed June 2026 (53 days) as its latest observation while the other three Realtor.com series had already been updated with July. The July value of 57 days therefore comes from the upstream publisher's own report rather than the FRED mirror. This is exactly the kind of thing PatternIQ's cross-source agreement check exists to catch, and it is recorded here rather than smoothed over.

---

## 2. Freddie Mac Primary Mortgage Market Survey

**Week ending:** August 6, 2026. **Released:** August 6, 2026. **Geography:** national only.
**License class:** `PERMISSIVE_ATTRIBUTION`. Use permitted with proper attribution; alteration of the published document prohibited.

| | Current | Prior week | Year ago |
|---|---|---|---|
| 30-year fixed | 6.69% | 6.66% | 6.63% |
| 15-year fixed | 6.01% | 6.04% | 5.75% |

Weekly 30-year history: Jul 9 6.49, Jul 16 6.55, Jul 23 6.58, Jul 30 6.66, Aug 6 6.69. **Five consecutive weekly increases.**

**Cross-check performed.** FRED `MORTGAGE30US` shows the identical value and series, last updated August 6, 2026 at 11:02 CDT, with the next release scheduled August 13.

---

## 3. BLS Employment Situation

**Reference month:** July 2026. **Released:** August 7, 2026. **License class:** `PUBLIC_DOMAIN`.

- Unemployment rate: 4.1%
- Nonfarm payroll change: −23,000

BLS characterized both as little changed. Note the direction: payrolls fell.

---

## 4. Census and HUD, New Residential Construction

**Reference month:** June 2026. **Released:** July 17, 2026. **License class:** `PUBLIC_DOMAIN`. Seasonally adjusted annual rate.

| Metric | Value | Month over month | Year over year |
|---|---|---|---|
| Building permits | 1,367,000 | −3.0% | −2.3% |
| Housing starts | 1,427,000 | +19.0% | +3.5% |
| Housing completions | 1,392,000 | +3.3% | +1.5% |

**Read the starts figure carefully.** Census publishes it with a margin of error of ±15.9 percent against a reported change of 19.0 percent, and states the change is not statistically distinguishable from zero. A headline reading "housing starts surge 19 percent" is reporting a number whose error bar nearly swallows it. The tutorial uses this as its worked example of false precision.

---

## 5. FHFA House Price Index

**License class:** `PUBLIC_DOMAIN`.

**Monthly, purchase-only seasonally adjusted.** Reference month May 2026, released July 28, 2026. Up 0.3% from the prior month, up 2.2% from May 2025. Census division monthly changes ranged from −0.6% (Pacific) to +1.4% (East South Central). Twelve-month changes ranged from −0.3% (Pacific) to +4.5% (Middle Atlantic).

**Quarterly.** Reference quarter Q1 2026, released May 26, 2026. Up 0.5% quarter over quarter, up 1.7% year over year.

**The lag is the lesson.** On August 11, the most recent authoritative repeat-sale price reading describes May. Anything more current about prices comes from list prices, which measure what sellers are asking rather than what buyers paid.

---

## 6. What is real and what is illustrative

The tutorial marks every number. Two treatments, used consistently and never mixed:

| Treatment | Meaning |
|---|---|
| **REAL** badge, with source and date | Published figure, retrieved and cross-checked as described above |
| **ILLUSTRATIVE** badge | Invented for teaching. Never describes an actual market. |

Everything in this document and in `data/real-data-2026-08.json` is real. Every county-level figure, every Opportunity Score, every Confidence Score, and every named market in the tutorial and the wireframes is illustrative, because PatternIQ has not been built yet and has therefore never computed a score.

**This distinction is load-bearing.** The failure mode this whole project is designed against is a convincing interface wrapped around numbers nobody checked. A tutorial that blurred real market data into invented scores would be committing the exact error the architecture is built to prevent.

---

## 7. What could not be obtained free

Named here so the tutorial does not imply the data plan is more complete than it is.

- **County and ZIP level listing metrics.** Realtor.com and Redfin publish them, and their license status is unverified. National figures are what this dataset contains.
- **Any distressed or foreclosure figure.** No free national source exists.
- **Sale-to-list ratio and homes sold above list.** Redfin publishes these; the Data Center page did not return metric values to automated retrieval.
- **Local renovation cost.** Does not exist free at any geography.
- **Current insurance cost.** Best free data ends in 2022.

---

## Sources

- [Realtor.com July 2026 Housing Report](https://www.prnewswire.com/news-releases/sellers-cut-as-summer-cools-but-buyers-keep-contracts-moving-realtorcom-july-housing-report-302840361.html)
- [Mortgage Professional America, July 2026 housing coverage](https://www.mpamag.com/us/mortgage-industry/market-updates/us-housing-market-cools-as-price-cuts-close-in-on-last-year/584709)
- [Freddie Mac Primary Mortgage Market Survey](https://www.freddiemac.com/pmms)
- [FRED, 30-Year Fixed Rate Mortgage Average (MORTGAGE30US)](https://fred.stlouisfed.org/series/MORTGAGE30US)
- [FRED, Active Listing Count (ACTLISCOUUS)](https://fred.stlouisfed.org/series/ACTLISCOUUS)
- [FRED, Median Listing Price (MEDLISPRIUS)](https://fred.stlouisfed.org/series/MEDLISPRIUS)
- [FRED, New Listing Count (NEWLISCOUUS)](https://fred.stlouisfed.org/series/NEWLISCOUUS)
- [FRED, Median Days on Market (MEDDAYONMARUS)](https://fred.stlouisfed.org/series/MEDDAYONMARUS)
- [BLS Employment Situation](https://www.bls.gov/news.release/empsit.nr0.htm)
- [Census New Residential Construction](https://www.census.gov/construction/nrc/pdf/newresconst.pdf)
- [FHFA House Price Index](https://www.fhfa.gov/data/hpi)
- [FHFA HPI up 0.3 percent in May](https://www.fhfa.gov/news/news-release/fhfa-house-price-index-up-0.3-percent-in-may-up-2.2-percent-from-last-year)
- [FHFA HPI Q1 2026 release](https://www.fhfa.gov/news/news-release/u.s.-house-prices-rise-1.7-percent-year-over-year-up-0.5-percent-quarter-over-quarter)
