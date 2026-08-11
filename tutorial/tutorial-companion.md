# PatternIQ, How To Read It

Printable companion to the interactive course. The course itself is `patterniq-tutorial.html`, 23 lessons across 6 modules, each with a check-yourself question. This document is the reference version: the same substance, condensed, for searching and printing.

All real figures below were retrieved from their publishers on 11 August 2026 and cross-checked where a second independent source existed. Full provenance: `docs/11-sample-data-provenance.md`.

---

## The one-page summary

**What PatternIQ is.** A research instrument that reads public housing and economic data, organises it into a picture of a local market, tells you how strong the evidence behind that picture is, and teaches you to read it yourself.

**Four refusals built into the product:**

1. No number when the evidence is thin. Markets failing a gate show as withheld, with the gate named.
2. No claim about what usually happens next until backtesting has checked.
3. No blurring of fact, inference, pattern and prediction. Each is typed and displayed differently.
4. No hiding what it cannot see. Missing distress data costs every US market a permanent confidence penalty, stated on screen.

**The governing sentence.** Show the evidence. Explain the pattern. Quantify uncertainty. Teach the investor. Track the outcome. Learn from the outcome.

**The idea most likely to be lost.** Opportunity and Confidence are different questions, computed independently, never blended. High opportunity with low confidence is the trap: thin data produces extreme percentile ranks, so the score is high because the measurement is noisy, not because the market is good.

---

## Module 1. Orientation

**1.1 What it is and the four refusals.** Above.

**1.2 The six obligations.** Each cashes out into something checkable on screen: provenance on every number, signal-by-signal pattern detail, a seven-component confidence score at equal visual weight, a ten-part explanation per metric, a decision journal, and personal outcome tracking. The last two compound; the others inform.

**1.3 The four quadrants.**

| | High confidence | Low confidence |
|---|---|---|
| **High opportunity** | Investigate properly. Rare. | The trap. Noise, usually. |
| **Moderate opportunity** | Often the better market. | Ignore. |

---

## Module 2. Where the numbers come from

**2.1 The lag problem.** Real release calendar as of 11 August 2026:

| Series | Publisher | Reference period | Lag |
|---|---|---|---|
| Mortgage rate, 30-year | Freddie Mac | week ending 6 Aug | 0 days |
| Listing metrics | Realtor.com | July | 3 days |
| Unemployment rate | BLS | July | 7 days |
| Building permits | Census | June | 17 days |
| House price index | FHFA | **May** | 58 days |
| County employment and wages | BLS QCEW | Q1 | ~150 days |
| Income, property tax | Census ACS | 5-year window | ~365 days |
| Homeowners insurance | Treasury FIO | 2018 to 2022 | ~1,320 days |

**Exactly one series updates weekly: the mortgage rate.** Everything describing a housing market is monthly at best. A daily-refreshing dashboard would be theatre. A single market page necessarily mixes July listing data, May price data, Q1 wages and a five-year income average, and the interface labels the age of each because the mixture is unavoidable.

**2.2 Three tiers of source.**

- **Tier A, public domain.** FHFA, Census, BLS, BEA, FEMA, HUD, Freddie Mac.
- **Tier B, unverified.** Realtor.com, Redfin, Zillow. Free, no authentication, no confirmable permission to store privately.
- **Tier C, does not exist free.** Foreclosure and distress, MLS, local renovation cost, current insurance, property-level comps.

The uncomfortable part: days on market, active inventory, new listings, price reductions and sale-to-list all sit in Tier B. Those are the metrics that tell you whether you could sell the house, and there is no federal substitute. PatternIQ ingests them, marks them unverified, and blocks export of any figure whose lineage touches them.

FRED trap: FRED republishes many of these and FRED's terms are permissive, but Realtor.com still owns the series. FRED says so explicitly.

**2.3 Revisions.** Every observation stores the period it describes and the moment it was retrieved. Revisions are new rows, never overwrites. This is what makes an honest backtest possible: scoring 2023 with today's restated values means the model is quietly using the future, which is flattering and worthless. PatternIQ has no vintages predating its own operation, so backtests over those windows are labelled synthetic-vintage and cannot alone validate a pattern.

**2.4 Geography.** FHFA reaches ZIP5 and tract. Realtor.com and Redfin reach ZIP. BLS stops at county. ACS reaches tract but describes a five-year average. So a ZIP view is a mixture, and PatternIQ aggregates upward but never disaggregates downward. County analysis scores near 100 on geographic precision; ZIP analysis scores in the sixties or seventies because its economic data is borrowed from one level up. What Census calls a ZIP is really a ZCTA, and the provenance panel says so.

---

## Module 3. Reading the metrics

All figures: real, July 2026, Realtor.com Monthly Housing Trends released 3 August 2026, unless noted.

### 3.1 Days on market: 57 days, down 1 day year over year

First outright annual decline after 26 consecutive months of increases. Monthly path: Feb 70, Mar 57, Apr 52, May 52, Jun 53, Jul 57.

Month over month the market is slowing. Year over year it is one day faster. **Seasonal slowing is not deterioration** — homes always take longer as summer ends, which is why every pattern signal is framed year over year.

Three ways it misleads: it only describes homes that sold; relistings restart the clock; publishers define it differently, so compare a market to itself over time.

### 3.2 Active inventory 1,126,252 (+2.1%), new listings 423,732 (0.0%)

Supply grew while the inflow of new sellers did not, so the build came from slower clearing rather than a wave of sellers. But +2.1% is soft against a period when inventory has been rebuilding at double-digit rates, which is why thresholds are always relative to a market's own history rather than absolute.

National figures hide everything: Midwest inventory +9.3%, Northeast +8.3%, South −0.2%.

### 3.3 Price reduction share: 20.0%, versus 20.6% a year ago

**The headline and the number disagree.** Coverage led with sellers cutting prices as summer cools, which is true month over month. The share of listings with a cut is *lower* than last July. Fewer sellers are cutting now.

Read with days on market:

| Price cuts | Days on market | Suggests |
|---|---|---|
| Rising | Rising | Capitulation. The classic acquisition window. |
| Flat | Rising | Standoff. Leverage has not shifted. |
| Rising | Flat | Aggressive pricing meeting steady demand. Often mix shift. |
| Falling | Falling | Tightening. The current national reading. |

### 3.4 List price $428,950 (−2.4%) versus FHFA repeat-sale index (+2.2%)

Both correct. They differ because of mix shift (a median follows whatever happened to be listed; a repeat-sale index follows the same homes), because asking is not selling, and because they describe different months (July versus May). Price per square foot, $226 and −2.0%, partially controls for size mix.

PatternIQ stores both, records a discrepancy when overlapping estimators diverge, and never silently averages them.

### 3.5 Pending sales: +1.3% year over year

Eighth consecutive month of growth, the longest run since June 2021. Also: May +4.1%, June +3.7%, July +1.3%. Growth fell by two thirds in two months.

The level is positive; the second derivative is not. Three points is not a trend you can act on, which is why signals require persistence across three consecutive periods.

### 3.6 Carrying cost and labour

**Mortgage rate 6.69%**, week ending 6 August 2026. Five consecutive weekly increases: 6.49, 6.55, 6.58, 6.66, 6.69. Year ago 6.63%. 15-year at 6.01%.

PMMS surveys conventional conforming mortgages for owner-occupants. **The rate a flipper actually pays is not published anywhere free.** PMMS matters because it sets what your buyer can afford: it is an exit input, not a carrying-cost input.

**Unemployment 4.1%, nonfarm payrolls −23,000**, July 2026, BLS released 7 August. In the pattern framework a deteriorating labour market is an invalidation condition: it reclassifies an apparent acquisition window as demand collapse.

---

## Module 4. How the scores are built

**4.1 Peer sets and percentiles.** A peer set is all geographies of the same level in the same population third. Three levels times three tiers gives nine peer sets, minimum size 30.

Four steps: winsorise to the 1st and 99th percentile; rank within the peer set; orient so higher always means more favourable; combine as a coverage-weighted mean. Percentiles rather than z-scores because housing distributions are skewed and fat-tailed. The cost is that a percentile gives position, not magnitude, so the interface always shows the raw value beside the rank.

**4.2 The seven pillars.**

| Pillar | Weight | What it can actually see |
|---|---|---|
| Exit liquidity | 0.24 | DOM, sale-to-list, pending ratio. All Tier B. |
| Acquisition | 0.22 | Price cuts, inventory, months of supply. Distress missing entirely. |
| Economic strength | 0.18 | Unemployment, employment, population, income, permits. Best data in the model. |
| Market risk | 0.15 | Volatility, inventory acceleration, FEMA hazard, disaster history |
| Carrying costs | 0.10 | ACS property tax, 2022 insurance snapshot, national mortgage rate |
| Renovation economics | 0.06 | County construction wages and permits as proxies. No local cost data exists. |
| Transaction costs | 0.05 | Hand-curated transfer tax per state |

Read the weights as an admission rather than a claim. Renovation is 0.06 because it is nearly blind: materials indexes are national, so every market in a peer set gets an identical value and it contributes nothing to relative ranking.

Missing features are never treated as zero, because zero means worst-in-peer-set and missing means unknown. Below 60% coverage a pillar is marked unavailable and its weight redistributed.

**4.3 Confidence, seven components.** Coverage 0.25, freshness 0.20, sample adequacy 0.15, source agreement 0.15, historical depth 0.10, geographic precision 0.10, model stability 0.05.

Distress features sit in the coverage denominator and never the numerator, costing roughly 6 points to every market permanently. With annual ACS lag and insurance data ending in 2022, a confidence above 90 is effectively unreachable on free data. That ceiling is intentional.

Confidence is not accuracy. It measures evidence strength, not correctness.

**4.4 The five gates.** G1 at least 4 of 7 pillars including acquisition and exit; G2 peer set of 30+; G3 confidence at or above 40; G4 70% of features within two cadence intervals; G5 no unresolved data quality failure.

Expect roughly half of US counties to be withheld, because publishers suppress listing metrics in low-population areas. Scored plus withheld equals evaluated, exactly.

---

## Module 5. Patterns

**5.1 Anatomy.** Required signals (all must fire), thresholds relative to own history or peer set, persistence across consecutive periods, corroborating signals that raise strength, invalidation conditions that override everything, and a watch-next list.

Multiple comparisons: roughly 4,000 markets times 15 patterns weekly is 60,000 tests, and some will fire by chance. Defences are persistence, confidence and coverage floors, invalidation evaluated first, false discovery rate control, and base rates published beside hit rates.

**5.2 Worked capstone: does Increasing Buyer Leverage fire in July 2026?**

| Required signal | Observed | Needed | Fires? |
|---|---|---|---|
| Active listings YoY | +2.1% | High vs own history | No, soft |
| Median DOM YoY | −1 day | Rising | No, wrong sign |
| Price reduction share YoY | −0.6 pp | Rising | No, wrong sign |

**Zero of three. The pattern does not exist here.** Two of the three point in the opposite direction.

The coverage of this exact release was headlined around sellers cutting prices. That headline describes month-over-month seasonal softening. The pattern framework asks whether this market is weaker than a year ago by its own historical standards, and the answer is no.

What the system saves you from is not a bad market but a bad reading of an ordinary one.

Two caveats: national is not a market, and individual counties inside the Midwest's +9.3% inventory build will absolutely show buyer leverage; and this was evaluated against direction rather than a fitted own-history distribution, which is safe here only because two signals have the wrong sign.

**5.3 Validation status.** Unvalidated patterns are capped at confidence 40 and display no historical narrative. Promotion requires 30+ instances across 8+ markets and 3+ calendar years, a lift interval excluding zero after FDR adjustment, some genuine-vintage evidence, and sign stability across alternative outcome definitions. Every pattern in PatternIQ today is unvalidated, because no backtest has been run.

Retirement keeps failed patterns visible with their statistics, because an intuitive pattern that does not work is more instructive than one never tested.

---

## Module 6. Using it

**6.1 The Deal Analyzer is arithmetic.** No model, no forecast, no probability, and none until calibration passes. ARV, interest rate, renovation budget, commission and holding period are all your assumptions and are labelled as such. Market data enters only through the context card, which compares your assumptions to measured behaviour and is tagged as inference.

Use the sensitivity grid before the point estimate. The useful question is not what you expect to make but how wrong your two biggest assumptions can be before the deal loses money.

**6.2 Your own history.** Sample gates: nothing below 3 completed projects; early signal with n in the headline at 3 to 5; a personal pattern with a confidence interval at 6 to 9; eligible to adjust personalised estimates at 10 or more, with your approval. Nothing adjusts automatically.

This is where discipline is hardest, because two projects that both ran over budget feel like a pattern and you were there.

**6.3 The Monday routine.**

1. Read the withheld count before any score.
2. Check confidence changes before opportunity changes.
3. Read warning patterns before favourable ones.
4. Open the pillar breakdown on anything tempting.
5. Answer one follow-up prompt.
6. Read the learning topic.

Legitimate reasons to override: local knowledge the data cannot hold, such as an employer announcement not yet in the statistics. Not legitimate: the score is lower than you hoped. The decision journal records what was on screen and what you decided, so this becomes checkable rather than a matter of memory.

**The last thing.** PatternIQ succeeds if you get better at reading markets, to the point where you see the pattern before the software names it. A tool that makes you dependent on it has failed even if every number it produced was correct.

---

## Sources for every real figure in this course

- [Realtor.com July 2026 Housing Report](https://www.prnewswire.com/news-releases/sellers-cut-as-summer-cools-but-buyers-keep-contracts-moving-realtorcom-july-housing-report-302840361.html)
- [Mortgage Professional America, July 2026 housing coverage](https://www.mpamag.com/us/mortgage-industry/market-updates/us-housing-market-cools-as-price-cuts-close-in-on-last-year/584709)
- [Freddie Mac Primary Mortgage Market Survey](https://www.freddiemac.com/pmms)
- [FRED, MORTGAGE30US](https://fred.stlouisfed.org/series/MORTGAGE30US) · [ACTLISCOUUS](https://fred.stlouisfed.org/series/ACTLISCOUUS) · [MEDLISPRIUS](https://fred.stlouisfed.org/series/MEDLISPRIUS) · [NEWLISCOUUS](https://fred.stlouisfed.org/series/NEWLISCOUUS) · [MEDDAYONMARUS](https://fred.stlouisfed.org/series/MEDDAYONMARUS)
- [BLS Employment Situation](https://www.bls.gov/news.release/empsit.nr0.htm)
- [Census New Residential Construction](https://www.census.gov/construction/nrc/pdf/newresconst.pdf)
- [FHFA House Price Index](https://www.fhfa.gov/data/hpi) · [May 2026 release](https://www.fhfa.gov/news/news-release/fhfa-house-price-index-up-0.3-percent-in-may-up-2.2-percent-from-last-year)
