# Scrap Rate Analytics Engine (PostgreSQL + Window Functions + KPI Rollups)

This mini-warehouse generates realistic manufacturing scrap metrics from synthetic data, then computes rolling KPIs and Pareto views using **PostgreSQL window functions** and **GROUPING SETS** for flexible rollups. A companion DAX sheet is included for Power BI.

---

## What this solves (business need)
Manufacturing leaders need **fast, trustworthy scrap visibility** by plant/line/part/defect with trendlines and Pareto. This project creates:
- A star-schema with daily **production** and **scrap details**
- Window-function KPIs: **rolling 7/28-day scrap rate**, **YTD**, **cumulative Pareto**, **top-N defects**
- Flexible rollups (day/week/month; plant/line/part) with **GROUPING SETS**
- A clean base for a Power BI dashboard

Use it to answer: *Which lines are bleeding yield this month? Which defects drive 80% of scrap? Are we improving week over week?*

---

## Quickstart (PostgreSQL)

> Requires PostgreSQL 12+

1) Create a database (optional):
```bash
createdb scrap_analytics
```

2) Run the SQL in order:
```bash
psql -d scrap_analytics -f sql/01_schema.sql
psql -d scrap_analytics -f sql/02_seed_data.sql
psql -d scrap_analytics -f sql/03_views.sql
psql -d scrap_analytics -f sql/04_queries.sql
```

3) Explore:
```sql
-- Daily KPIs with rolling 7/28-day scrap rates
SELECT * FROM vw_daily_scrap_metrics LIMIT 50;

-- Monthly Pareto by defect (cumulative share)
SELECT * FROM vw_monthly_defect_pareto WHERE plant_name = 'Plant A' LIMIT 50;

-- KPI rollups by (day/week/month) x (plant/line/part)
SELECT * FROM vw_kpi_rollups LIMIT 50;
```

---

## Schema (star-ish)

- **dim_date(date_key, calendar_date, week_start, month_start, year)**  
- **dim_plant(plant_id, plant_name)**  
- **dim_line(line_id, plant_id, line_name)**  
- **dim_part(part_id, part_name, family)**  
- **dim_defect(defect_id, defect_code, defect_desc)**  

- **fact_production(date_key, plant_id, line_id, part_id, produced_qty, scrap_qty, rework_qty)**
- **fact_scrap_detail(date_key, plant_id, line_id, part_id, defect_id, scrap_qty)**

> `fact_production.scrap_qty` equals the sum of `fact_scrap_detail.scrap_qty` per key.

---

## Outputs

- **vw_daily_scrap_metrics** – per day/plant/line/part KPIs + rolling 7/28 + YTD
- **vw_monthly_defect_pareto** – defect Pareto with cumulative % and rank
- **vw_kpi_rollups** – flexible rollups using GROUPING SETS
- **vw_line_control_chart** – mean and 3-sigma bounds (stat check)

---

## Power BI

Import tables/views via the `scrap_analytics` connection. Use `powerbi/measure_definitions.md` for DAX measures (Scrap Rate, Rolling 28d, Pareto cumulative, etc.).

---

## Notes

- All data here is synthetic and safe.
- Tune volume in `02_seed_data.sql` by changing date range or # of parts/lines.
- Indexes are added for the most common filters/joins.
