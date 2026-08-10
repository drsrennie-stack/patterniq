# Step 7. Initial Pattern Detection Framework

## 7.1 The design problem

Pattern detection is where a product like this most easily starts lying. Scan 900 metros and 3,100 counties against 15 patterns every week and you generate roughly 60,000 evaluations a week. Some will fire. Narrating them as insight, with a confident story about what historically follows, is the failure mode this whole package exists to prevent.

Three rules control it.

**Rule 1. Patterns are declarative data, not code.** A pattern is a JSONB specification in `analytics.pattern_definition`, evaluated by one generic engine. Adding a pattern is inserting a row. This means every pattern is inspectable, diffable, versioned, and testable, and no pattern can quietly acquire special-case logic.

**Rule 2. A pattern cannot claim historical behavior until it has been validated.** `validation_status` starts at `unvalidated`. Until `analytics.pattern_validation` has rows meeting the sample gates in Step 8, the UI renders "No historical validation yet. This pattern is a described combination of current signals, not a demonstrated predictor." It does not narrate what usually happens next, because nobody knows.

**Rule 3. Thresholds are relative, never magic numbers.** A threshold is expressed against the market's own history or against its peer set, never as an absolute. "Inventory up 14 percent" means something different in Boise than in Buffalo. "Inventory year-over-year change above the 75th percentile of this market's own trailing five years" means the same thing everywhere.

## 7.2 Pattern specification

```jsonc
{
  "pattern_key": "increasing_buyer_leverage",
  "version_label": "v1.0.0",
  "display_name": "Increasing Buyer Leverage",
  "eligible_geo_levels": ["cbsa", "county"],
  "min_confidence": 60,
  "min_feature_coverage": 0.80,

  "required_signals": [
    {
      "feature_key": "active_listings_yoy",
      "operator": "gte",
      "threshold_basis": "own_history_pctile",
      "threshold_value": 70,
      "lookback_quarters": 20,
      "persistence_periods": 3,
      "weight": 1.0
    },
    {
      "feature_key": "median_dom_yoy",
      "operator": "gte",
      "threshold_basis": "own_history_pctile",
      "threshold_value": 70,
      "lookback_quarters": 20,
      "persistence_periods": 3,
      "weight": 1.0
    },
    {
      "feature_key": "price_reduction_share_yoy",
      "operator": "gte",
      "threshold_basis": "own_history_pctile",
      "threshold_value": 70,
      "lookback_quarters": 20,
      "persistence_periods": 2,
      "weight": 1.0
    }
  ],

  "corroborating_signals": [
    {
      "feature_key": "median_sale_price_yoy",
      "operator": "between",
      "threshold_basis": "absolute_pct",
      "threshold_value": [-2.0, 4.0],
      "weight": 0.5,
      "note": "prices still broadly stable, so this is leverage shifting rather than a price break"
    },
    {
      "feature_key": "unemployment_12m_change",
      "operator": "lte",
      "threshold_basis": "absolute_pp",
      "threshold_value": 0.5,
      "weight": 0.5,
      "note": "local labor market has not deteriorated"
    }
  ],

  "invalidation_conditions": [
    { "feature_key": "unemployment_12m_change", "operator": "gt",
      "threshold_basis": "absolute_pp", "threshold_value": 1.5,
      "reason": "employment deterioration reclassifies this as demand collapse, not buyer leverage" },
    { "feature_key": "median_sale_price_yoy", "operator": "lt",
      "threshold_basis": "absolute_pct", "threshold_value": -6.0,
      "reason": "prices are already breaking; the acquisition window has become a falling knife" },
    { "feature_key": "active_listings_yoy", "operator": "lt",
      "threshold_basis": "own_history_pctile", "threshold_value": 50,
      "persistence_periods": 2,
      "reason": "inventory build has reversed" }
  ],

  "watch_next": [
    "sale_to_list_level",
    "pending_to_active_ratio",
    "months_supply_level"
  ]
}
```

### Field semantics

| Field | Meaning |
|---|---|
| `threshold_basis: own_history_pctile` | Percentile of this market's own trailing `lookback_quarters` distribution for that feature. |
| `threshold_basis: peer_pctile` | Percentile within the current peer set. |
| `threshold_basis: absolute_pct` / `absolute_pp` | An absolute bound, permitted only where the quantity is already dimensionless and economically meaningful. Every use requires a written justification in the spec. |
| `persistence_periods` | Consecutive periods the condition must hold. The single most effective false-positive control available. |
| `min_feature_coverage` | Share of required and corroborating features that must be present. Below this, the pattern is not evaluated at all. Not evaluated is different from not detected, and the UI distinguishes them. |
| `invalidation_conditions` | Any one firing suppresses detection and, if the pattern was previously detected, marks it `invalidated` with the stated reason. |

## 7.3 Detection and strength

A pattern is detected when every required signal fires with its persistence satisfied, no invalidation condition fires, feature coverage clears `min_feature_coverage`, and market confidence clears `min_confidence`.

```
              sum of weights of firing signals (required + corroborating)
strength =   ------------------------------------------------------------- * 100
              sum of weights of all signals (required + corroborating)
```

Detection requires all required signals, so strength ranges from the required-only floor to 100 depending on corroboration. In the example above the floor is 3.0 / 4.0, which is 75.

Detection confidence is the lower of the market's Confidence Score and a sample-based cap:

```
detection_confidence = min( market_confidence, historical_sample_cap )

historical_sample_cap = 40                                   when validation_status = 'unvalidated'
                      = 40 + 50 * min(1, n_instances / 100)  when validated
```

An unvalidated pattern can never be presented above confidence 40, which places it in the Low band. That is deliberate. Until a pattern has been tested, PatternIQ describes it and does not lean on it.

Status transitions are tracked across runs: `new`, `strengthening` (strength rose for 2 consecutive runs), `stable`, `weakening`, `invalidated`.

## 7.4 Three worked patterns for v1

Three, not fifteen. Each is fully specified, each maps to features that exist in the automatable set, and each has a clear invalidation story. The remaining twelve names in Section 9 of the master spec stay in the Pattern Library as educational entries marked "not implemented," which is more honest than shipping thin implementations of all of them.

### Pattern 1. Increasing Buyer Leverage

Specification above.

**Definition.** Supply is building, homes are taking longer to sell, and sellers are cutting prices, while transaction prices and local employment have not yet broken.

**Why it matters.** This is the combination that widens acquisition discounts before it damages exit conditions. It is the most commonly cited favorable setup for a flip entry, and it is also the setup most easily confused with the early stage of a genuine downturn. The invalidation conditions exist to force that distinction.

**Failure conditions to teach.** The pattern fires identically at the start of a normal seasonal inventory build and at the start of a real correction. Seasonality is partly handled by using year-over-year features throughout, but a market with an unusual seasonal profile can still trip it. Historical validation, when it exists, will show the base rate of each case.

**What to watch next.** Sale-to-list ratio, pending-to-active ratio, months of supply. If those deteriorate alongside, the read shifts from buyer leverage to demand deterioration.

### Pattern 2. Exit Liquidity Deterioration

**Required signals**, each with 3-period persistence:

- `median_dom_yoy` at or above the 80th percentile of the market's own 20-quarter history
- `pending_to_active_ratio` at or below the 25th percentile of own history
- `sale_to_list_level` at or below the 30th percentile of own history

**Corroborating:** `sold_above_list_share` falling year over year; `months_supply_level` above the 70th percentile of own history.

**Invalidation:** `median_dom_yoy` returning below its own 50th percentile for 2 consecutive periods.

**Why it matters.** This is the pattern that should stop an acquisition even when acquisition conditions look excellent. A flip with no exit is a rental you did not plan for. In the product this pattern is displayed as a warning at equal prominence to any favorable pattern in the same market, never subordinated to it.

**Note on data dependency.** Every signal here is Tier B. If Realtor.com and Redfin become unusable, this pattern cannot be implemented at all.

### Pattern 3. Employment-Supported Demand

**Required signals:**

- `employment_growth_yoy` at or above the 70th percentile of the peer set, 4-period persistence
- `unemployment_12m_change` at or below 0.0 percentage points, 4-period persistence
- `population_growth_3y` above 0

**Corroborating:** `income_growth` above the peer set median; `permit_growth_yoy` positive but below the 90th percentile of the peer set, which reads as growth without an obvious oversupply response.

**Invalidation:** `unemployment_12m_change` above 0.75 percentage points; or `employment_growth_yoy` falling below the peer set 40th percentile for 2 consecutive periods.

**Why it matters.** This is the only one of the three built entirely on Tier A public-domain data, with the best history and the highest confidence ceiling. It is a slow-moving structural signal rather than a timing signal, and the education content says so. It supports the exit side of a flip thesis, and it never on its own justifies an acquisition.

## 7.5 False positive control

Six mechanisms, applied together.

**Persistence.** The single most effective control. A signal that must hold for three consecutive months eliminates most single-period noise, at the cost of two to three months of lag. That tradeoff is stated in the pattern's education content so the investor understands why PatternIQ is not the first to say something.

**Confidence floor.** `min_confidence` of 60 means patterns are not evaluated in markets where the data is too thin to support them. Combined with the Opportunity Score's own gates, this removes most small-county noise before pattern evaluation begins.

**Coverage floor.** A pattern with 80 percent required coverage cannot fire on two of five signals with three unknown.

**Invalidation before detection.** Invalidation conditions are evaluated first. A market cannot be reported as showing buyer leverage while its employment is collapsing.

**Multiple comparison control at the reporting layer.** Weekly evaluation across thousands of markets guarantees false positives. Two responses:

- The weekly report ranks by strength times confidence times financial materiality and reports a bounded number, with the count of detections not shown stated explicitly. Section 23 of the master spec requires avoiding information overload, and silent truncation would violate Section 27.
- Any statistical claim in `pattern_validation` uses Benjamini-Hochberg false discovery rate control at q = 0.10 across all pattern and horizon and outcome combinations tested, and the adjusted p-value is stored in the table and shown in the Pattern Library.

**Base rate reporting.** Every validated pattern displays its base rate next to its hit rate. "Followed by favorable exit conditions 58 percent of the time, against a base rate of 51 percent across all markets in the same periods, n = 84" is an honest presentation of a weak edge. "Followed by favorable exit conditions 58 percent of the time" alone is not.

## 7.6 Pattern lifecycle

```
unvalidated  ->  in_validation  ->  validated  ->  retired
                       |                |
                       +----------------+---> retired (failed validation)
```

| Status | Meaning | UI treatment |
|---|---|---|
| `unvalidated` | Specified and firing, never tested | Confidence capped at 40. Labeled "Described pattern, not yet validated." No historical narrative. |
| `in_validation` | Backtest running or below sample gates | Partial results shown with sample counts and confidence intervals. |
| `validated` | Cleared the Step 8 gates | Full presentation with historical behavior, base rate, lift, confidence interval, and sample size. |
| `retired` | Failed validation, or its data source disappeared | Kept visible in the Pattern Library with the retirement reason, as an educational record. Section 9 of the master spec asks the library to teach failure conditions, and a retired pattern is the best available teaching material. |

Retirement rule: a pattern with at least 50 instances across at least 15 markets and 3 calendar years whose lift confidence interval contains zero at the FDR-adjusted level is retired. It does not linger because it is intuitive.

## 7.7 Personal patterns (Phase 2, specified here for schema completeness)

The same engine runs against `app.project_line_item` and `app.project_financial` instead of the market feature store. The specification format is identical. The sample gates are different because the sample sizes are tiny.

| Completed projects in category | Presentation |
|---|---|
| 1 to 2 | Nothing shown. Not enough to say anything. |
| 3 to 5 | "Early signal, low confidence," with the sample size stated in the headline and an explicit statement that this is not yet a reliable personal pattern. |
| 6 to 9 | Shown as a personal pattern with a confidence interval on the effect size. |
| 10 or more | Shown as a personal pattern, and eligible to adjust personalized estimates per Section 22 of the master spec. |

The effect estimate for a category is the mean of `(actual - planned) / planned` across completed line items, with a bootstrap 80 percent confidence interval. Below 10 observations the interval will be wide, and showing that wide interval is the whole point.

Personal patterns never adjust an underwriting default automatically. They surface a suggestion, the investor accepts or declines, and the acceptance is recorded in the decision journal.
