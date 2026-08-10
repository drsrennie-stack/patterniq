# Step 8. Historical Backtesting Methodology

## 8.1 What backtesting has to establish

Three separate questions, each with its own method:

1. **Does the Opportunity Score rank markets usefully?** Cross-sectional rank correlation against a realized outcome, over many periods.
2. **Do the patterns predict anything?** Event study against matched controls.
3. **Are the predictive models calibrated?** Reliability and interval coverage. Phase 3.

None of these can be answered until the point-in-time infrastructure works, which is why it sits at the center of Step 1 rather than being added later.

## 8.2 Point-in-time replay

Every historical evaluation runs through one function:

```sql
core.metric_as_of(knowledge_date)
```

The harness constructs a `score_run` with `is_backtest = true`, `as_of = knowledge_date`, and computes features, scores, and pattern detections using only rows whose `retrieved_at <= knowledge_date`. Peer sets, percentile boundaries, winsorization limits, and population tertiles are all recomputed from the point-in-time cross section. A market that did not have enough data then is withheld then, exactly as it would have been.

Model versions are pinned. A backtest names the `score_model_version_id` it is testing, so re-running a 2022 evaluation with 2026 weights is an explicit choice rather than an accident.

## 8.3 The bootstrap problem, stated plainly

PatternIQ has no observation vintages before its first run. Every historical value it holds is the current restated vintage, not what was published at the time.

This is the single largest methodological weakness in the design and there is no way to engineer it away. The available responses, in order of preference:

**1. Recover genuine vintages where the publisher archives them.** ALFRED, the archival companion to FRED, stores true release vintages for FRED series, including BLS and Census series that flow through it. Where a series is available in ALFRED, real first-release vintages can be loaded and the backtest for that series is honest. This should be done for every eligible Tier A series during Milestone M15.

**2. Model the publication lag where vintages are not recoverable.** For a series with a known lag `L`, a backtest at knowledge date `D` uses only periods with `period_end <= D - L`. This correctly removes the "you could not have seen this yet" error. It does **not** remove the revision error, because the value used is the restated one.

**3. Quantify the revision error rather than ignoring it.** From the point PatternIQ starts running, it accumulates real vintages. After a year, the distribution of first-release-to-current revisions per metric is measurable. That distribution is applied as a sensitivity band on all pre-launch backtest results: if FHFA county HPI year over year revises by a standard deviation of 0.8 points, the backtest is re-run with first-release values simulated by perturbation, and the result is reported as a range.

**4. Label the affected period honestly.** Any backtest window predating PatternIQ's own operation is labeled **synthetic-vintage** in `pattern_validation` and in every UI surface that reports it. A synthetic-vintage result can move a pattern to `in_validation`. It cannot on its own move a pattern to `validated`. Full validation requires at least some genuine-vintage evidence.

This costs time. It is what separates a backtest from a story.

## 8.4 Outcome labels

Without transaction-level flip records, market-level outcomes are proxies. Saying so is not a caveat, it is the finding.

### Primary market-level label: Flip Favorability Realized (FFR)

For market `g`, base period `t`, horizon `h` months (12 in the primary specification, 6 and 18 as robustness checks):

```
FFR(g,t,h) =   0.50 * z( price_appreciation(g, t -> t+h) )
             + 0.30 * z( -1 * change_in_median_dom(g, t -> t+h) )
             + 0.20 * z( change_in_sale_to_list(g, t -> t+h) )
```

where `z()` is a cross-sectional standardization within the peer set at time `t+h`, and `price_appreciation` uses the FHFA repeat-sale index rather than median sale price, because the repeat-sale index is not distorted by mix shift.

**Justification of the weights.** A flip's realized outcome is driven by what the property sells for (appreciation), whether it sells in the planned window (days on market), and whether it sells near asking (sale-to-list). The 50/30/20 split reflects that ordering. The weights are a stated assumption, and results are reported against 60/25/15 and 40/35/25 alternates as a robustness check. If the conclusion flips between them, no conclusion is reported.

**What FFR is not.** It is not profit. It ignores acquisition discount, renovation cost, and carrying cost, none of which are observable at market level from free data. A market can score well on FFR and be a poor flip market because contractors are unavailable or property taxes are brutal. This is stated wherever an FFR-derived result is shown.

### Secondary labels

| Label | Definition | Use |
|---|---|---|
| `exit_speed` | Median DOM at `t+h` below the peer set median | Binary outcome for the exit liquidity pattern |
| `margin_hold` | FHFA HPI appreciation over `h` exceeding the national rate | Binary, simple, interpretable |
| `drawdown_avoided` | No 4-quarter interval in `t` to `t+h` with HPI change below -3 percent | Downside-focused |

### Personal labels, Phase 2

Once completed projects exist, the real label is available: actual net profit, actual ROI, actual annualized return, actual holding period, per project. This is the only label in the system that measures what the investor actually cares about. Ten to fifteen completed projects will not support market-level model fitting, but they are enough to validate personal patterns and to check whether market-level scores were directionally informative for the deals actually done. That check runs continuously from the first completed project.

## 8.5 Evaluation design

**Walk-forward, expanding window.** Train on everything up to `T`, evaluate on `T+1`, advance. No shuffling, no random splits, no k-fold anywhere in this codebase.

**Embargo for overlapping horizons.** A 12-month horizon means an observation at `T-6` has an outcome resolving after `T`. Without an embargo, training data leaks into the evaluation. All observations with `t` in `[T - h, T]` are dropped from training for the fold evaluated at `T+1`. This is standard purging and it is not optional.

**Cross-sectional rank information coefficient.** The primary metric.

```
IC(t) = Spearman( Opportunity(g,t) over g in peer set,  FFR(g,t,h) over g in peer set )
```

Compute per period, then test whether the mean IC differs from zero using a Newey-West standard error with lag `h` periods, because overlapping horizons make consecutive ICs autocorrelated. Reporting a naive t-statistic on overlapping windows overstates significance by a large factor and is the most common way backtests deceive.

**Baselines that must be beaten.** A score that does not beat all four is not promoted to `validated`:

| Baseline | Why it matters |
|---|---|
| Random ranking | Floor |
| Price momentum only, trailing 12-month HPI change | The cheapest possible model. Momentum is stubbornly hard to beat in housing. |
| Population rank | Tests whether the score is secretly just a size proxy |
| Prior period's Opportunity Score | Tests whether new data is adding anything |

**Stability requirements.** The mean IC must be positive in at least 60 percent of individual evaluation periods, and positive in each of at least three distinct calendar years. A result driven by one extraordinary period is not a result.

**Decile spread.** Report mean FFR by Opportunity Score decile. Monotonicity across deciles is more convincing than a single correlation coefficient, and a non-monotonic pattern with a strong overall IC usually indicates the score works only in the tails, which is useful to know and should be said.

## 8.6 Pattern validation by event study

For each pattern and horizon and outcome combination:

1. Collect every detection instance: (market, period) pairs where the pattern fired under point-in-time replay.
2. Build a matched control set. For each detection, sample control (market, period) pairs from the same geography level, the same population tertile, the same calendar period, and a similar Confidence Score, that did not show the pattern. Matching on calendar period is essential, because a pattern that fires mostly in 2021 would otherwise be credited with the entire 2021 housing market.
3. Compute the outcome rate in the detection group and the control group.
4. `lift = detection_rate - control_rate`. Bootstrap a 90 percent confidence interval over 2,000 resamples, clustered by market to respect the fact that a market's periods are not independent.
5. Apply Benjamini-Hochberg FDR control at q = 0.10 across every pattern, horizon, and outcome combination tested in the run. Store the adjusted p-value.

### Promotion gates

A pattern moves to `validated` only when all hold:

| Gate | Threshold |
|---|---|
| Instances | At least 30 |
| Distinct markets | At least 8 |
| Distinct calendar years | At least 3 |
| Lift confidence interval | Excludes zero after FDR adjustment |
| Vintage quality | At least some genuine-vintage instances, not synthetic-vintage alone |
| Robustness | Sign of the lift is stable across the alternate FFR weightings in 8.4 |

Failing any gate leaves the pattern at `unvalidated` or `in_validation`, capped at confidence 40, with no historical narrative.

### Retirement gate

At least 50 instances across at least 15 markets and 3 calendar years with a lift confidence interval containing zero after FDR adjustment. The pattern retires with its statistics preserved in the Pattern Library as a teaching example.

## 8.7 Weight fitting

Only after the harness runs and the label is stable.

**Method.** Ridge regression of FFR on the seven pillar scores, with sign constraints so that no fitted weight can invert a pillar's economic direction. A fitted model that wants a negative weight on economic strength has found a data artifact, not an insight, and the constraint surfaces that rather than shipping it.

**Data requirements.** At least 200 market-period observations spanning at least 3 calendar years and at least 100 distinct markets.

**Promotion rule.** A fitted weight vector replaces the declared prior only when it beats the prior on out-of-sample mean IC across the walk-forward folds, with the improvement exceeding the Newey-West standard error of the difference. Otherwise the declared prior stays and the fitting attempt is recorded as a negative result.

**Regularization is not optional.** With seven correlated pillars and a few hundred observations, unregularized least squares will produce large offsetting weights that fit noise. The ridge penalty is selected by nested cross-validation inside the training window only.

## 8.8 Prediction calibration, Phase 3

For probabilistic outputs:

- **Reliability diagram** in 10 bins. Predicted probability against observed frequency. Published in the Data and Sources screen.
- **Brier score** against a base-rate baseline.
- **Interval coverage.** An 80 percent interval must contain the actual value in 75 to 85 percent of held-out cases. Outside that band, the intervals are wrong and no probability is displayed.
- **Conformal prediction** is the default interval method, because it gives distribution-free coverage guarantees and does not require the residuals to behave.

Gate: no probability or interval appears anywhere in the product until it has passed calibration. Until then, predictions are shown as scenario ranges built from stated assumptions in the Deal Analyzer, clearly labeled as arithmetic on the investor's own inputs rather than as a model output.

## 8.9 Look-ahead traps, checked explicitly

Each has a named test in the harness test suite.

| Trap | Test |
|---|---|
| Publication lag ignored | Assert no feature at knowledge date `D` uses a period ending after `D - L` for its source's declared lag |
| Restated values used as first release | Assert `vintage_seq` selected is the maximum with `retrieved_at <= D`, and flag windows with no genuine vintages |
| Index rebasing | Assert HPI features use ratios of index values within a series, never levels across rebasings |
| Geography boundary change | Assert peer sets are constructed from the geography vintage in force at `D` |
| Survivorship in coverage | Include markets that later lost coverage; a market present at `D` stays in that period's cross section |
| ACS window straddling | Assert no ACS 5-year vintage whose window extends past `D` is used at `D` |
| Peer set leakage | Assert percentile boundaries come from the point-in-time cross section, never the full-sample distribution |
| Winsorization leakage | Assert clip limits come from the point-in-time peer set |
| Outcome contamination | Assert no feature used in the score is also a component of the label at the same period |

That last one deserves attention. FFR includes change in days on market, and the Opportunity Score includes the level and year-over-year change in days on market. These are not the same quantity, since one is measured over `t` to `t+h` and the other up to `t`, but they are related through autocorrelation. The harness therefore also reports a version of FFR built only from price appreciation, which shares no component with the exit liquidity pillar, as a contamination check. If the score's IC collapses under that version, the apparent skill was partly autocorrelation.

## 8.10 Reporting

Every backtest writes a versioned report containing: model version, evaluation window, vintage quality per period, IC time series with the Newey-West statistic, decile spread table, baseline comparison, per-pattern lift with confidence intervals and FDR-adjusted p-values, and a plain-language summary of what was and was not established.

Results are shown inside the product, in the Data and Sources screen, not kept in a separate analyst folder. If a pattern's edge is weak, the investor sees the weak number next to the pattern, every time.

Negative results are published with the same prominence as positive ones. A backtest that shows the Opportunity Score does not beat momentum is the most valuable output this system can produce in its first year, because it prevents money being placed on it.
