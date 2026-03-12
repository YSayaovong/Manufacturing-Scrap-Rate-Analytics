# Scrap Rate Analytics — Manufacturing Quality & Cost Risk Analysis

## 1. Project Background

As a data analyst supporting a manufacturing quality function, I built this pipeline to answer the questions that matter most on the production floor: *Which defects are costing us the most? Which lines are underperforming? And are our spikes real signals or just noise?*

In manufacturing, scrap is more than a yield problem — it is a financial signal. At $1,200–$3,000 per unit depending on product, a single bad day can generate $78,000 in losses. Without structured analytics, engineering and quality teams are left reacting to problems they could have anticipated. This project converts raw production and scrap records into a repeatable KPI system that surfaces actionable patterns for daily production meetings, CAPA validation, and cost-reduction initiatives.

The dataset covers **180 production days (January–June 2025)** across 4 production lines, 4 product SKUs, and 5 defect categories — 350,111 units produced with 5,516 scrapped at a total financial impact of **$11,383,200**.

Insights and recommendations are structured around four key areas:

- **Defect Pareto Analysis:** Identifying which failure modes drive the majority of scrap cost
- **Line-Level Performance:** Benchmarking production lines against each other on rate and cost
- **Daily Trend & Outlier Detection:** Separating special-cause variation from process noise
- **Product Cost Risk:** Understanding which SKUs amplify scrap cost disproportionately to their volume

---

## 2. Data Structure & Initial Checks

The pipeline is built on a normalized star schema with two fact tables and four dimension tables, enabling line-level, defect-level, product-level, and date-level slicing across all KPIs.

```
dim_date                dim_line            dim_product         dim_defect
────────────────        ────────────        ────────────────    ────────────────
date_id   (PK)          line_code (PK)      sku        (PK)     defect_code (PK)
year                    line_name           product_name        defect_name
quarter                                     unit_cost
month        ◄──┐           ◄──┐                 ◄──┐                ◄──┐
day           │             │                   │                    │
week          │             │                   │                    │
weekday_name  │             │                   │                    │
is_weekend    │             │                   │                    │
              │             │                   │                    │
         fact_scrap  (4,914 rows)               │                    │
         ──────────────────────────────────────────────────────────────
         date_id       (FK → dim_date)
         line_code     (FK → dim_line)
         sku           (FK → dim_product)
         defect_code   (FK → dim_defect)
         units_scrapped

         fact_production  (2,880 rows)
         ──────────────────────────────
         date_id       (FK → dim_date)
         line_code     (FK → dim_line)
         sku           (FK → dim_product)
         units_produced
```

| Table | Grain | Row Count |
|---|---|---|
| `fact_scrap` | One row per line/SKU/defect/day scrap event | 4,914 |
| `fact_production` | One row per line/SKU/day production record | 2,880 |
| `dim_line` | One row per production line | 4 |
| `dim_product` | One row per SKU with unit cost | 4 |
| `dim_defect` | One row per defect category | 5 |
| `dim_date` | One row per production date with weekend flag | 180 |

**Initial Checks Performed:**
- Confirmed no duplicate date/line/SKU/defect combinations in `fact_scrap`
- Validated all foreign key values (`line_code`, `sku`, `defect_code`) resolve cleanly to their dimension tables with zero orphan records
- Confirmed `is_weekend` flag aligns correctly with `weekday_name` for all 180 dates — used to validate the weekend scrap rate hypothesis
- Verified unit costs are consistent and correctly assigned: TX-100 ($1,200), TX-200 ($1,800), TX-300 ($2,200), TX-400 ($3,000)
- Confirmed continuous date coverage from 2025-01-01 to 2025-06-29 with all 180 days represented in both fact tables

![Schema Design](https://github.com/YSayaovong/Scrap-Rate-Analytics/blob/main/assets/schema_design.PNG?raw=true)

---

## 3. Executive Summary

Across 180 production days and 350,111 units produced, the operation scrapped **5,516 units at a total cost of $11,383,200** — an overall scrap rate of **1.58%** and a yield of **98.42%**. At an average of **$63,240 in scrap cost per day**, this is a significant and measurable operational baseline.

The monthly aggregate rate is remarkably stable (1.57%–1.60% across six months), which means the scrap problem is not a trending crisis — it is a **chronic cost that is not being actively reduced**. Two defects account for **56.4% of all scrapped units**. One production line runs **28.9% more scrap volume** than the best-performing line. And weekends produce scrap at a rate **45.5% higher** than weekdays. Each of these patterns is consistent, quantified, and addressable.

| KPI | Value |
|---|---|
| Total Units Produced | 350,111 |
| Total Units Scrapped | 5,516 |
| Overall Scrap Rate | 1.58% |
| Overall Yield | 98.42% |
| Total Scrap Cost (H1 2025) | $11,383,200 |
| Avg Daily Scrap Cost | $63,240 |
| Peak Daily Scrap Cost | $78,200 |
| Top Defect — Winding Short (D-01) | 32.0% of all scrap, $3,645,600 |
| Top 2 Defects Combined | 56.4% of scrap volume, 56.3% of cost |
| Highest Scrap Rate Line (L3 Reactor) | 1.76% |
| Lowest Scrap Rate Line (L4 Booster) | 1.36% |
| Weekend vs. Weekday Scrap Rate | 2.11% vs. 1.45% (+45.5%) |
| Statistical Outlier Days (> 2σ) | 5 |

> **The core finding:** Scrap is concentrated and predictable — not random. Two defects, one underperforming line, and a systematic weekend premium account for the majority of excess cost above the process baseline. This is not a systemic quality failure requiring a facility-wide overhaul. It is a targeted corrective action opportunity: fix Winding Short, close the L3–L4 gap, and address weekend operating conditions.

---

## 4. Insights Deep Dive

### 4a. Two Defects Account for 56% of All Scrap — Three Cover 74%

**Metric:** Units Scrapped and Cost by Defect Category (Pareto)

**Finding:** Five defect types drive all 5,516 scrapped units, but the distribution follows a clear Pareto pattern. Winding Short (D-01) is the single largest contributor at **1,764 units (32.0%)** and **$3,645,600 in cost**. Combined with Insulation Nick (D-02) at 1,347 units, the top two defects represent **3,111 units — 56.4% of all scrap volume and $6,407,600 in cost (56.3%)**. Adding Core Burr (D-03) brings cumulative coverage to **73.9% of all scrapped units**.

![Defect Pareto Chart](https://github.com/YSayaovong/Scrap-Rate-Analytics/blob/main/outputs/img/pareto_defects.png?raw=true)

| Defect | Code | Units Scrapped | % of Total | Scrap Cost | % of Cost |
|---|---|---|---|---|---|
| Winding Short | D-01 | 1,764 | 32.0% | $3,645,600 | 32.0% |
| Insulation Nick | D-02 | 1,347 | 24.4% | $2,762,000 | 24.3% |
| Core Burr | D-03 | 963 | 17.5% | $2,014,400 | 17.7% |
| Lead Misroute | D-04 | 892 | 16.2% | $1,825,400 | 16.0% |
| Tank Dent | D-05 | 550 | 10.0% | $1,135,800 | 10.0% |

Critically, Winding Short is the **#1 defect on all four production lines simultaneously** — L1: 434, L2: 462, L3: 477, L4: 391. This is not a line-specific anomaly. A shared upstream cause — winding equipment calibration, incoming wire quality specifications, or operator technique standardization — is the most likely driver. A single CAPA addressing Winding Short would reduce scrap across the entire facility.

---

### 4b. L3 Reactor Runs 28.9% More Scrap Volume Than L4 Booster — at $687,400 in Additional Cost

**Metric:** Scrap Rate % and Total Scrap Cost by Production Line

**Finding:** Line scrap rates span a 0.40 percentage point range from **1.36% (L4 Booster)** to **1.76% (L3 Reactor)**. In absolute terms, L3 scrapped **1,539 units** versus L4's **1,194 — 28.9% more volume** — generating **$3,169,400 in scrap cost versus $2,482,000** on L4, a difference of **$687,400 over six months**.

![Scrap by Line](https://github.com/YSayaovong/Scrap-Rate-Analytics/blob/main/outputs/img/scrap_by_line.png?raw=true)

| Line | Name | Units Scrapped | Scrap Rate | Scrap Cost | % of Total Cost |
|---|---|---|---|---|---|
| L1 | Core & Coil | 1,364 | 1.55% | $2,818,200 | 24.8% |
| L2 | E-Assembly | 1,419 | 1.63% | $2,913,600 | 25.6% |
| L3 | Reactor | 1,539 | **1.76%** | **$3,169,400** | **27.8%** |
| L4 | Booster | 1,194 | **1.36%** | **$2,482,000** | **21.8%** |

L4 Booster is the performance benchmark. The question is not why L3 is bad — it is what L4 does differently. A structured comparison of L4's preventive maintenance schedule, operator qualification records, and setup verification procedures against L3's would identify the controllable gap and provide a concrete improvement roadmap.

---

### 4c. Daily Rate Is Statistically Stable — but 5 Outlier Days Signal Specific Events Worth Investigating

**Metric:** Daily Scrap Rate Trend and 2-Sigma Outlier Detection

**Finding:** The daily scrap rate has a mean of **1.64%**, a median of **1.49%**, and a standard deviation of **0.31%**. Monthly aggregates span only **1.57%–1.60%** over six months — a 0.03 percentage point range confirming the process is in statistical control at the macro level. However, **five individual days exceed the 2-sigma threshold** (> 2.26%), reaching a peak of **2.44% on April 26**.

![Scrap Rate Daily Trend](https://github.com/YSayaovong/Scrap-Rate-Analytics/blob/main/outputs/img/scrap_rate_trend.png?raw=true)

![Statistical Outliers](https://github.com/YSayaovong/Scrap-Rate-Analytics/blob/main/outputs/img/outliers.png?raw=true)

| Outlier Date | Scrap Rate | Units Scrapped | Units Produced |
|---|---|---|---|
| 2025-04-26 | 2.44% | 30 | 1,231 |
| 2025-06-28 | 2.34% | 29 | 1,240 |
| 2025-03-15 | 2.33% | 29 | 1,247 |
| 2025-04-05 | 2.33% | 28 | 1,204 |
| 2025-05-11 | 2.27% | 27 | 1,191 |

All five outlier days share a common characteristic: **below-average production volume** (1,191–1,247 units versus the overall daily average of ~1,945). Reduced-volume days are consistent with weekend or partial-shift production — and the weekend scrap premium (see 4d) provides a likely structural explanation. Each date still warrants a line-level log review to confirm the driver.

---

### 4d. Weekend Scrap Rate Is 45.5% Higher Than Weekdays — Consistent Across the Full Six Months

**Metric:** Average Daily Scrap Rate by Weekday vs. Weekend

**Finding:** Across 52 weekend days, the average scrap rate was **2.11%** versus **1.45%** across 128 weekdays — a gap of **0.66 percentage points** representing a **45.5% higher scrap rate** on non-standard production days. This pattern is too large and too consistent to attribute to random variation.

| Day Type | Days | Avg Scrap Rate |
|---|---|---|
| Weekday | 128 | 1.45% |
| Weekend | 52 | 2.11% |
| Overall (mean) | 180 | 1.64% |

Common drivers in manufacturing include reduced supervisor coverage, fewer experienced operators on weekend shifts, less rigorous pre-shift equipment checks, and smaller production batches that magnify rate calculations. Regardless of root cause, the data is clear: **weekend production conditions are systematically producing worse quality outcomes**, and that gap has a calculable cost that justifies targeted intervention.

---

### 4e. TX-400 Generates 35.7% of Total Scrap Cost on Only 24.6% of Scrap Volume

**Metric:** Scrap Cost and Rate Contribution by Product SKU

**Finding:** TX-400 (SKU-400) at $3,000/unit creates a disproportionate financial exposure. With **1,356 units scrapped (24.6% of volume)**, it drives **$4,068,000 in cost — 35.7% of total scrap cost**. By contrast, TX-100 at $1,200/unit accounts for 23.1% of scrap volume but only 13.4% of cost. TX-400's scrap rate (1.56%) is actually **below the facility average of 1.58%** — its cost dominance is entirely a function of unit value, not a quality failure.

| SKU | Product | Unit Cost | Units Scrapped | % Volume | Scrap Cost | % Cost |
|---|---|---|---|---|---|---|
| SKU-100 | TX-100 | $1,200 | 1,272 | 23.1% | $1,526,400 | 13.4% |
| SKU-200 | TX-200 | $1,800 | 1,412 | 25.6% | $2,541,600 | 22.3% |
| SKU-300 | TX-300 | $2,200 | 1,476 | 26.8% | $3,247,200 | 28.5% |
| SKU-400 | TX-400 | $3,000 | 1,356 | 24.6% | $4,068,000 | **35.7%** |

This means scrap prevention efforts applied specifically to TX-400 production deliver **2.5x the financial return** of the same effort applied to TX-100. Scheduling TX-400 on the best-performing line (L4 Booster) during weekday shifts — the lowest scrap rate conditions — would reduce the exposure with no process change required.

---

## 5. Recommendations

Based on the above findings, the following actions are recommended:

- **Open a facility-wide CAPA on Winding Short (D-01).** At 32.0% of all scrap and $3,645,600 in cost — and ranking #1 on every line — this defect has a shared upstream cause. A structured root cause analysis focused on winding equipment calibration tolerances, incoming wire quality specifications, and operator technique standardization would address the highest-impact defect at its source rather than fighting it line by line.

- **Use L4 Booster as the process benchmark to close the L3 Reactor gap.** The $687,400 six-month cost difference between L3 and L4 is the clearest improvement opportunity in the line data. Rather than launching a general L3 improvement initiative, a targeted comparison of L4's maintenance cadence, setup verification procedures, and operator qualification requirements against L3's practices would identify the specific controllable differences worth replicating.

- **Implement a weekend scrap reduction protocol.** A 45.5% higher scrap rate on weekends (2.11% vs. 1.45%) is consistent across all six months and represents the most controllable component of total scrap cost. Options include adding a quality lead to weekend shifts, requiring additional pre-shift equipment verification steps, or scheduling high-value TX-400 production exclusively on weekdays to reduce financial exposure during the highest-risk operating window.

- **Prioritize TX-400 production on L4 during weekday shifts.** TX-400 generates 35.7% of total scrap cost despite an average scrap rate. Concentrating its production on L4 Booster (lowest scrap rate) during weekdays (lowest scrap rate conditions) reduces financial risk without any quality system change — it is a scheduling decision with immediate cost impact.

- **Review shift logs and line data for the five outlier days individually.** April 26 (2.44%), June 28 (2.34%), March 15 (2.33%), April 5 (2.33%), and May 11 (2.27%) all exceed the 2-sigma threshold. Each represents a specific event — not a trend — and a 30-minute log review per date would either confirm the weekend/reduced-volume hypothesis or surface a previously undetected special-cause failure worth documenting in the CAPA system.

- **Extend the pipeline to compute daily scrap cost by line for production floor accountability.** The current KPI tables aggregate scrap cost at the facility level. Adding a `kpi_daily_by_line.csv` output would allow each line supervisor to review their own financial contribution to daily scrap totals, creating direct operational ownership of cost outcomes and enabling faster escalation when a specific line's numbers move.

---

## Tools Used

- Python (pandas, matplotlib)
- SQL (KPI aggregation via views and analytical queries)
- Star schema data modeling (fact/dim architecture)
- Statistical process control (2-sigma outlier detection)
- Pareto analysis (defect cost concentration)
- Synthetic manufacturing dataset (transformer production simulation)
