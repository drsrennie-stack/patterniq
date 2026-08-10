# Step 5. Opportunity Score v1, Defined Mathematically

## 5.1 What this score is and is not

The Flip Opportunity Score is a **cross-sectional ranking instrument**. It answers: relative to comparable markets, how favorable does the currently observable evidence look for a residential flip acquired now and exited within roughly six to twelve months?

It is not a forecast, not a probability, and not a return estimate. Those are Section 15's job and require Phase 3. A market scoring 81 is not "better" in any absolute sense. It sits in the upper tail of its peer set on the measurable factors, on the evidence available on the scoring date.

It is also, in v1, **unvalidated**. `weight_provenance = 'declared_prior'` and `validation_status = 'unvalidated'` are stored on the model version and displayed on every screen that shows the score, until Step 8's backtest says otherwise.

## 5.2 Peer sets

Percentile normalization requires a comparison group. Comparing rural Sierra County to Los Angeles County on inventory volatility produces noise, not signal.

Peer set `P(g, t)` for geography `g` at time `t` is defined as all geographies of the same `geo_level` whose population falls in the same tertile of the national distribution for that level, and which have at least the minimum data coverage defined in 5.7. Tertile boundaries are computed from the point-in-time population estimate, so they are themselves historically correct.

Three population tiers times three geography levels (county, CBSA, ZCTA) gives nine peer sets. Every percentile in this document is computed within the peer set, never nationally across levels.

Minimum peer set size is 30. Below that, no percentile normalization is performed and the market is withheld.

## 5.3 Feature normalization

For a raw feature value `x` for geography `g` at time `t`, in peer set `P`:

**Step 1. Winsorize.** Clip to the 1st and 99th percentiles of `P` to stop a single broken observation from dominating.

**Step 2. Percentile rank.**

```
r(g,t) = 100 * ( rank of x among P, ties averaged ) / |P|
```

Percentile rank rather than z-score, because housing distributions are heavily skewed and fat-tailed, and a z-score built on a non-normal distribution produces a number that looks interpretable and is not.

**Step 3. Orient.** If the feature's polarity is `lower_is_better` (days on market, unemployment, hazard risk), invert:

```
n(g,t) = 100 - r(g,t)
```

Otherwise `n(g,t) = r(g,t)`.

After this step every normalized feature is on 0 to 100 with higher meaning more favorable for a flip.

**Why not z-scores or min-max.** Min-max is destroyed by outliers. Raw z is destroyed by skew. Robust z (median and MAD) is a reasonable alternative and is stored as a secondary normalization so the two can be compared during validation; the model version record names which one produced a given score.

## 5.4 Pillars and features, v1

Seven pillars. Each pillar `p` has a feature set `F_p`. Only features that survive Step 3's automatable-now test appear here.

### P1. Acquisition Opportunity

| Feature key | Definition | Source | Polarity |
|---|---|---|---|
| `price_reduction_share_level` | Share of active listings with a price cut, current month | Realtor.com (Tier B) | higher is better |
| `price_reduction_share_yoy` | Change in that share versus 12 months prior, in percentage points | Realtor.com | higher is better |
| `active_listings_yoy` | Year-over-year change in active listing count | Realtor.com | higher is better |
| `months_supply_level` | Active listings over trailing 3-month average closed sales | Realtor.com and Redfin | higher is better |
| `list_price_vs_hpi_gap` | Median list price year-over-year minus FHFA HPI year-over-year for the same geography, in percentage points | Realtor.com and FHFA | lower is better (asking prices running ahead of the transacted index is a warning) |

**Removed from v1: distressed inventory, foreclosure activity, estimated discount to ARV.** No free source. Recorded in the score breakdown as an unavailable factor with a stated reason.

### P2. Exit Liquidity

| Feature key | Definition | Source | Polarity |
|---|---|---|---|
| `median_dom_level` | Median days on market | Realtor.com (Tier B) | lower is better |
| `median_dom_yoy` | Year-over-year change in days on market | Realtor.com | lower is better |
| `sale_to_list_level` | Sale-to-list price ratio | Redfin (Tier B) | higher is better |
| `pending_to_active_ratio` | Pending listings over active listings | Realtor.com | higher is better |
| `sold_above_list_share` | Share of homes selling above list | Redfin (Tier B) | higher is better |

**This pillar is entirely Tier B.** If the Realtor.com and Redfin licensing questions resolve badly, this pillar cannot be computed from free data and the model drops to six pillars with a standing confidence penalty. That is the single biggest dependency in the score.

### P3. Renovation Economics

| Feature key | Definition | Source | Polarity |
|---|---|---|---|
| `construction_wage_level` | QCEW NAICS 23 average weekly wage, county | BLS (Tier A) | lower is better |
| `construction_wage_yoy` | Year-over-year change in that wage | BLS | lower is better |
| `permit_intensity` | Permit units per 1,000 housing units, trailing 12 months | Census BPS and ACS (Tier A) | lower is better, as a contractor-availability proxy |
| `materials_ppi_yoy` | National construction materials PPI, year over year | BLS (Tier A) | lower is better |

**Honest note, carried into the UI.** `materials_ppi_yoy` is national. Every market in a peer set receives the identical value, so its percentile rank is uniform and it contributes zero cross-sectional discrimination. It is retained because it shifts the whole distribution over time and is therefore visible in the market's own history, but it does not help rank one county against another. The pillar's real discriminating power comes from two proxies whose relationship to actual renovation cost is unvalidated. **This is the weakest pillar in the model and it is weighted accordingly.**

### P4. Carrying Costs

| Feature key | Definition | Source | Polarity |
|---|---|---|---|
| `effective_property_tax_rate` | ACS B25103 median real estate taxes paid over B25077 median home value | Census (Tier A) | lower is better |
| `insurance_cost_relative` | FIO 2018 to 2022 ZIP average premium relative to the peer set, rolled to county by housing-unit weight | Treasury (Tier A but stale) | lower is better |
| `mortgage_rate_level` | PMMS 30-year fixed | Freddie Mac (Tier A) | lower is better |

`mortgage_rate_level` is national and carries the same uniform-value caveat as the materials index. It is retained for the time-series view and contributes nothing cross-sectionally. `insurance_cost_relative` is a four-year-old snapshot and carries a heavy freshness penalty in Confidence.

### P5. Transaction Costs

| Feature key | Definition | Source | Polarity |
|---|---|---|---|
| `transfer_tax_rate` | State transfer tax plus any known local override, as a share of price | Curated statute table | lower is better |
| `recording_fee_estimate` | Typical recording and mortgage tax | Curated statute table | lower is better |

Curated by hand, roughly 50 state rows plus perhaps 40 local overrides, each with a statute citation and a review date. Rows past their review date are flagged stale in the UI and their contribution to confidence decays.

### P6. Economic Strength

| Feature key | Definition | Source | Polarity |
|---|---|---|---|
| `unemployment_level` | LAUS unemployment rate | BLS (Tier A) | lower is better |
| `unemployment_12m_change` | Change in unemployment rate over 12 months, percentage points | BLS | lower is better |
| `employment_growth_yoy` | QCEW total covered employment, year over year | BLS | higher is better |
| `population_growth_3y` | PEP population, 3-year compound growth | Census | higher is better |
| `income_growth` | ACS median household income, latest versus prior vintage | Census | higher is better |
| `permit_growth_yoy` | Building permit units, year over year, trailing 12 months | Census BPS | higher is better |

Note the deliberate tension: `permit_intensity` appears in P3 oriented as lower is better (fewer competing jobs for contractors), and `permit_growth_yoy` appears here oriented as higher is better (a growing market). These are different constructs from the same source and the education content says so explicitly. Backtesting will determine whether both earn their place.

### P7. Market Risk (scored so that higher means lower risk)

| Feature key | Definition | Source | Polarity |
|---|---|---|---|
| `price_volatility_20q` | Standard deviation of FHFA HPI quarter-over-quarter change over the trailing 20 quarters | FHFA (Tier A) | lower is better |
| `inventory_acceleration` | Second difference of active listings, trailing 6 months, standardized | Realtor.com (Tier B) | lower is better |
| `hazard_risk_index` | FEMA NRI composite expected annual loss score | FEMA (Tier A) | lower is better |
| `disaster_frequency_10y` | Count of federal disaster declarations affecting the county in 10 years | FEMA OpenFEMA (Tier A) | lower is better |
| `dom_deterioration` | Days on market year over year, positive values only, as a one-sided deterioration measure | Realtor.com (Tier B) | lower is better |

## 5.5 Pillar score

For pillar `p`, geography `g`, time `t`, let `A_p` be the subset of `F_p` whose features are available (non-null after normalization).

```
coverage_p(g,t) = sum of w_f for f in A_p  /  sum of w_f for f in F_p

              sum over f in A_p of ( w_f * n_f(g,t) )
S_p(g,t)  =   ----------------------------------------
                   sum over f in A_p of w_f
```

Within-pillar feature weights `w_f` are equal in v1 except where stated in the model version record. Renormalizing over available features rather than treating missing as zero is the only defensible choice, because zero is a real score meaning "worst in peer set," and a missing observation is not evidence of being worst.

**The missing data does not vanish.** It flows to Confidence through `coverage_p`. Opportunity says how favorable the visible evidence looks. Confidence says how much of the evidence you are actually seeing. Section 7 of the master spec insists these be separate and this is the mechanism.

**Pillar availability gate.** If `coverage_p(g,t) < 0.60`, the pillar is marked unavailable, `S_p` is not computed, and its weight is redistributed proportionally across the available pillars.

## 5.6 Composite

Let `V` be the set of available pillars.

```
                    sum over p in V of ( W_p * S_p(g,t) )
Opportunity(g,t) =  -------------------------------------
                         sum over p in V of W_p
```

### v1 prior weights

| Pillar | `W_p` | Reasoning for the prior |
|---|---|---|
| P1 Acquisition | 0.22 | Buying right is the largest controllable driver of flip outcome. Reduced from an intuitive 0.30 because distress data is missing, so the pillar is measuring less than it should. |
| P2 Exit Liquidity | 0.24 | The failure mode that kills flips is not selling. Highest weight in the model. |
| P3 Renovation Economics | 0.06 | Deliberately small. The pillar has no local cost data, two unvalidated proxies, and one national series. Weighting it higher would be pretending. |
| P4 Carrying Costs | 0.10 | Real and measurable, but second order at typical six-month holds. |
| P5 Transaction Costs | 0.05 | Real, largely static, low cross-sectional variance within a state. |
| P6 Economic Strength | 0.18 | Underpins both exit demand and downside protection. Best data quality in the model. |
| P7 Market Risk | 0.15 | Scored so that higher is safer. Guards against the score rewarding a market that is falling apart quickly. |

Sum: 1.00. Stored as JSONB on the model version row, never in code.

**These are declared priors, not fitted weights.** They reflect a reading of how flips fail and an explicit discount for data quality. They have no empirical backing yet. Every screen showing the score shows the label "Prior weights, not yet validated." Step 8 defines how they get replaced: constrained ridge regression against realized proxy outcomes, with sign constraints so a fitted weight cannot flip a pillar's economic direction, minimum 200 market-period observations across at least 3 calendar years, and a fitted model must beat the declared prior out of sample before it is promoted.

## 5.7 Publication gates

A market receives a published Opportunity Score only when all of these hold. Otherwise the score row is written with a null value and a `withheld_reason`.

| Gate | Threshold | Why |
|---|---|---|
| G1 Pillars available | At least 4 of 7, and both P1 and P2 must be among them | A score without acquisition or exit signal is not a flip score. |
| G2 Peer set size | At least 30 comparable geographies | Percentile ranks on a small set are noise. |
| G3 Confidence floor | Confidence at or above 40 | Below this, the number would mislead more than it informs. |
| G4 Freshness floor | The most recent observation for at least 70 percent of contributing features is within 2 expected cadence intervals | Stale inputs produce a confident-looking picture of last year. |
| G5 No unresolved blocking quarantine | No contributing source has an open blocking quality failure | |

Expected effect at launch: roughly 900 CBSAs mostly pass. Of about 3,100 counties, the ones failing will be low-population counties where Realtor.com and Redfin suppress listing metrics and QCEW suppresses construction wages. ZCTA-level scoring will pass in dense metros and fail widely elsewhere. **A large withheld count is the correct output, not a bug.**

## 5.8 Presentation requirements

Every displayed Opportunity Score must be accompanied by:

1. The Confidence Score and band, at equal visual weight. Never the opportunity number alone.
2. The pillar breakdown, showing each pillar's score, weight, and signed point contribution against the peer set median.
3. Unavailable pillars and features, named, with reasons. Distress absence appears on every market.
4. The peer set used, its size, and the market's rank within it.
5. The model version and its validation status.
6. The as-of date and the oldest contributing observation date.

## 5.9 A worked example, with invented numbers for illustration

Peer set: counties in the top population tertile, 1,033 members.

| Pillar | `S_p` | `W_p` | Contribution | Note |
|---|---|---|---|---|
| Acquisition | 78 | 0.22 | 17.2 | Price cuts at the 81st percentile, inventory up 19 percent year over year |
| Exit Liquidity | 44 | 0.24 | 10.6 | Days on market at the 62nd percentile and rising |
| Renovation | 55 | 0.06 | 3.3 | Construction wages mid-pack |
| Carrying | 38 | 0.10 | 3.8 | Effective property tax rate in the top quartile |
| Transaction | 61 | 0.05 | 3.1 | |
| Economic | 66 | 0.18 | 11.9 | Employment growth positive, unemployment flat |
| Risk | 51 | 0.15 | 7.7 | Elevated hazard index offset by low price volatility |
| **Composite** | | 1.00 | **57.6** | |

Reading: acquisition conditions have improved meaningfully while exit conditions have softened. This is the classic and dangerous combination in a flip market, which is exactly why the pillar breakdown is mandatory rather than optional. A single 58 tells you nothing. The breakdown tells you the whole story.

The values above are illustrative and do not describe any real market.
