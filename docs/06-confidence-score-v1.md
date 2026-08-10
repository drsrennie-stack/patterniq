# Step 6. Confidence Score v1, Defined Mathematically

## 6.1 What confidence measures

Confidence measures **the strength of the evidence behind a number**, not the chance the number is right. It is a property of the data, not of the market.

The distinction the master spec insists on in Section 7 is real and load-bearing:

- **High opportunity, low confidence.** The visible evidence looks favorable, but you are seeing a fraction of it, some of it is old, and the sources disagree. Investigate before believing.
- **Moderate opportunity, high confidence.** The picture is unexciting and the picture is solid. This is often the better place to put money.

Confidence is never called accuracy anywhere in the product. Accuracy would require knowing the truth, which is what backtesting is for and what Step 8 handles separately.

## 6.2 Seven components

```
Confidence(g,t) = sum over c of ( W_c * C_c(g,t) )
```

Each `C_c` is on 0 to 100. Weights sum to 1.

| Key | Component | `W_c` |
|---|---|---|
| C1 | Coverage | 0.25 |
| C2 | Freshness | 0.20 |
| C3 | Source agreement and independence | 0.15 |
| C4 | Historical depth | 0.10 |
| C5 | Sample adequacy | 0.15 |
| C6 | Geographic precision | 0.10 |
| C7 | Model stability | 0.05 |

---

### C1. Coverage, weight 0.25

The share of expected evidence actually present, weighted by how much each feature matters to the Opportunity Score.

```
                 sum over f present of ( W_pillar(f) * w_f )
C1(g,t) = 100 * -------------------------------------------
                 sum over f expected of ( W_pillar(f) * w_f )
```

The expected set is every feature in the v1 model, including features that are unavailable everywhere. Distress features are in the denominator and never in the numerator, so **every market in the country carries a permanent coverage penalty of roughly 6 points for the missing distress pillar**. That is correct. The system should not feel fully confident about flip opportunity when it cannot see foreclosure activity anywhere.

A feature counts as present when a non-null observation exists within the freshness window of C2. Present but stale contributes to C1 and is penalized in C2, so staleness is counted once rather than twice.

---

### C2. Freshness, weight 0.20

Each feature ages against its own expected cadence, declared on the source dataset.

For feature `f` with expected cadence interval `T_f` (7 days weekly, 30 monthly, 91 quarterly, 365 annual) and observation age `a_f` in days measured from `period_end`:

```
half_life_f = 1.5 * T_f
fresh_f     = 100 * 2 ^ ( - a_f / half_life_f )
```

Then the feature-importance-weighted mean of `fresh_f` over present features.

Exponential decay rather than a cliff, because data does not become worthless the day after it is due. Half-life at 1.5 cadence intervals means an on-schedule observation scores near 100, one interval late scores about 63, three intervals late scores about 25.

Two structural consequences worth naming:

- ACS-derived features (property tax rate, income) are annual with a one-year publication lag, so they sit near 50 permanently. That is honest.
- The Treasury FIO insurance file ends in 2022. Its `fresh` score in 2026 is effectively zero. It contributes almost nothing to confidence, which is the correct treatment of a four-year-old snapshot.

---

### C3. Source agreement and independence, weight 0.15

Two sub-parts, averaged.

**C3a. Independence.** Count distinct independent publishers contributing to the market's feature set. Realtor.com data pulled through FRED is not independent of Realtor.com pulled directly.

```
C3a = 100 * min(1, n_independent_sources / 5)
```

Five is the target: FHFA, BLS, Census, FEMA, and at least one listing publisher.

**C3b. Agreement.** For each pair of sources estimating the same construct, measure normalized disagreement. The three overlapping constructs available in v1:

| Construct | Estimator A | Estimator B | Estimator C |
|---|---|---|---|
| Price change | FHFA HPI year over year | Zillow ZHVI year over year | Realtor.com median list year over year |
| Days on market | Realtor.com median DOM | Redfin median DOM | |
| Inventory direction | Realtor.com active listings year over year | Redfin inventory year over year | |

For construct `k` with estimates `x_1 ... x_m` and cross-sectional interquartile range `IQR_k` computed over the peer set:

```
gap_k    = mean over all pairs (i,j) of | x_i - x_j |
agree_k  = 100 * ( 1 - min(1, gap_k / IQR_k) )
```

Normalizing by the peer set IQR rather than an absolute threshold makes the measure scale-free and comparable across constructs.

`C3b` is the mean of `agree_k` over constructs where at least two estimators exist. When only one estimator exists for every construct, `C3b = 50`, a neutral value, because a single source is neither corroborated nor contradicted.

Any `agree_k` below 40 also writes a row to `analytics.source_discrepancy` and surfaces in the UI as a flagged conflict. Section 12 requires that disagreement be shown rather than reconciled.

---

### C4. Historical depth, weight 0.10

```
C4 = 100 * min(1, usable_quarters / 20)
```

`usable_quarters` is the number of trailing quarters in which at least 70 percent of the market's feature set has a non-null observation. Twenty quarters is the target because pattern validation and volatility measurement both need roughly five years.

Realtor.com listing history begins in July 2016 and ZIP-level history is shorter, so ZCTA-level markets will score meaningfully lower on C4 than counties. That is the truth about the data.

---

### C5. Sample adequacy, weight 0.15

Uses `metric_observation.sample_size` where the publisher provides it: FHFA repeat-sale pair counts, Realtor.com active listing counts, Redfin closed transaction counts.

For feature `f` with sample size `s_f` and a declared minimum `m_f`:

```
adeq_f = 100 * min(1, log(1 + s_f) / log(1 + 4 * m_f) )
```

Log scaling because the difference between 20 and 80 transactions matters far more than the difference between 800 and 860. The factor of 4 sets the point of saturation at four times the declared minimum.

Declared minimums in v1: 30 closed transactions per month for sale-based metrics, 50 active listings for listing-based metrics, 25 repeat-sale pairs per period for FHFA-derived features.

Where the publisher gives no sample size, `adeq_f` is set to 50 and the fact is recorded in the component detail, so the investor can see that adequacy is assumed rather than measured.

`C5` is the feature-importance-weighted mean of `adeq_f`.

---

### C6. Geographic precision, weight 0.10

Penalizes evidence that arrived at this geography through a crosswalk rather than natively.

For each feature, `prec_f = 100` when `value_native_geo_level` equals the analysis level. When the value was reached by allocation:

```
prec_f = 100 * allocation_weight ^ 0.5
```

Square root so that a ZIP receiving a county value at an allocation weight of 0.85 scores 92 rather than 85. Allocation is a real loss of precision but not a catastrophic one when the weight is high.

`C6` is the feature-importance-weighted mean. In practice, county-level analysis scores near 100, and ZCTA-level analysis scores in the 60s to 70s because all the economic data arrives from county level.

---

### C7. Model stability, weight 0.05

Small weight in v1 because there is little to measure yet.

**Before any backtest exists:** rank stability. Spearman correlation between the market's peer-set percentile rank now and its rank in each of the trailing 4 score runs, averaged, rescaled from correlation to 0 to 100. A market whose rank swings violently from week to week is producing an unstable signal.

**Once a backtest exists:** replaced by realized historical predictive performance for markets in the same peer set, per Section 7 of the master spec. The model version record names which definition was in force.

---

## 6.3 Bands

| Range | Band | Product behavior |
|---|---|---|
| 0 to 39 | Low | Opportunity Score is withheld. The market appears in Discover only under an explicit "show low-confidence markets" toggle, with the score suppressed. |
| 40 to 59 | Limited | Score published with a persistent inline caution. Excluded from ranked lists by default. |
| 60 to 74 | Moderate | Score published and ranked normally. |
| 75 to 89 | High | Score published and ranked. Eligible to trigger alerts. |
| 90 to 100 | Very High | As above. Realistically unreachable in v1: the permanent distress-coverage penalty plus ACS annual lag caps most markets in the high 70s to mid 80s. |

The ceiling being unreachable is intentional and worth stating in the UI. It is a standing reminder that the free data set is incomplete.

## 6.4 Required display

Confidence never appears as a bare number. It appears as score, band, and the components that produced it, in the format Section 7 of the master spec specifies:

```
Confidence  68  Moderate

What supports this
  Coverage        22 of 28 expected indicators present            (C1  79)
  Freshness       19 updated within their expected cycle          (C2  74)
  Agreement       FHFA, Zillow, and Realtor.com price change
                  within 1.4 points of each other                 (C3  71)
  History         20 quarters of usable history                   (C4 100)
  Sample          Median 214 closed transactions per month        (C5  81)
  Precision       All features native to county level             (C6 100)
  Stability       Rank moved 6 percentile points over 4 runs      (C7  62)

What limits this
  No distressed inventory or foreclosure data is available
  for any US market from free sources. This costs every
  market roughly 6 coverage points.

  Homeowners insurance cost is a 2018 to 2022 snapshot and
  contributes almost nothing to confidence.

  Median household income and property tax rate come from
  ACS 5-year estimates published with a one-year lag.
```

The "What limits this" block is generated from the component detail JSONB, not written by the AI layer. It lists actual missing and stale inputs, in descending order of their weighted contribution to the shortfall. Its content is a database query.

## 6.5 What confidence is not allowed to do

- It never modifies the Opportunity Score. The two are computed independently and displayed together. Blending them would destroy exactly the distinction the spec asks for.
- It is never described as accuracy, reliability, or probability of being correct.
- It never rises because a value looks plausible. Only coverage, freshness, independence, agreement, depth, sample, precision, and stability move it.
- It never uses a default value to fill a gap. Missing lowers confidence and stays missing.
