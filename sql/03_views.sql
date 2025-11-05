-- sql/03_views.sql

-- Handy join
WITH plant_names AS (
  SELECT plant_id, plant_name FROM dim_plant
),
line_names AS (
  SELECT line_id, line_name, plant_id FROM dim_line
),
part_names AS (
  SELECT part_id, part_name, family FROM dim_part
)
SELECT 1; -- placeholder to keep transaction happy

-- Daily scrap metrics with rolling 7/28 and YTD
DROP VIEW IF EXISTS vw_daily_scrap_metrics CASCADE;
CREATE VIEW vw_daily_scrap_metrics AS
WITH base AS (
  SELECT
    dd.calendar_date,
    dd.date_key,
    p.plant_id, p.plant_name,
    l.line_id, l.line_name,
    pr.part_id, pr.part_name, pr.family,
    fp.produced_qty,
    fp.scrap_qty,
    fp.rework_qty,
    CASE WHEN fp.produced_qty = 0 THEN 0::float
         ELSE fp.scrap_qty::float / fp.produced_qty END AS scrap_rate
  FROM fact_production fp
  JOIN dim_date dd ON dd.date_key = fp.date_key
  JOIN dim_plant p ON p.plant_id = fp.plant_id
  JOIN dim_line l ON l.line_id = fp.line_id
  JOIN dim_part pr ON pr.part_id = fp.part_id
),
rolling AS (
  SELECT
    *,
    AVG(scrap_rate) OVER (
      PARTITION BY plant_id, line_id, part_id
      ORDER BY calendar_date
      ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) AS scrap_rate_7d,
    AVG(scrap_rate) OVER (
      PARTITION BY plant_id, line_id, part_id
      ORDER BY calendar_date
      ROWS BETWEEN 27 PRECEDING AND CURRENT ROW
    ) AS scrap_rate_28d
  FROM base
),
ytd AS (
  SELECT
    *,
    SUM(scrap_qty)    OVER (PARTITION BY plant_id, line_id, part_id, date_part('year', calendar_date))::float
    / NULLIF(SUM(produced_qty) OVER (PARTITION BY plant_id, line_id, part_id, date_part('year', calendar_date)),0)
      AS scrap_rate_ytd
  FROM rolling
)
SELECT * FROM ytd;

-- Monthly defect Pareto (per plant/line/month)
DROP VIEW IF EXISTS vw_monthly_defect_pareto CASCADE;
CREATE VIEW vw_monthly_defect_pareto AS
WITH x AS (
  SELECT
    date_trunc('month', d.calendar_date)::date AS month_start,
    p.plant_id, p.plant_name,
    l.line_id, l.line_name,
    pr.part_id, pr.part_name,
    de.defect_id, de.defect_code, de.defect_desc,
    SUM(fs.scrap_qty) AS scrap_qty
  FROM fact_scrap_detail fs
  JOIN dim_date d ON d.date_key = fs.date_key
  JOIN dim_plant p ON p.plant_id = fs.plant_id
  JOIN dim_line l ON l.line_id = fs.line_id
  JOIN dim_part pr ON pr.part_id = fs.part_id
  JOIN dim_defect de ON de.defect_id = fs.defect_id
  GROUP BY 1,2,3,4,5,6,7,8,9
),
y AS (
  SELECT
    *,
    SUM(scrap_qty) OVER (PARTITION BY month_start, plant_id, line_id) AS total_month_line,
    RANK() OVER (PARTITION BY month_start, plant_id, line_id ORDER BY scrap_qty DESC) AS defect_rank,
    SUM(scrap_qty) OVER (
      PARTITION BY month_start, plant_id, line_id
      ORDER BY scrap_qty DESC
      ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    )::float
    / NULLIF(SUM(scrap_qty) OVER (PARTITION BY month_start, plant_id, line_id)::float,0) AS cum_share
  FROM x
)
SELECT
  month_start, plant_id, plant_name, line_id, line_name,
  defect_id, defect_code, defect_desc,
  scrap_qty, total_month_line, defect_rank, cum_share
FROM y;

-- KPI rollups using GROUPING SETS across time grains & entities
DROP VIEW IF EXISTS vw_kpi_rollups CASCADE;
CREATE VIEW vw_kpi_rollups AS
WITH base AS (
  SELECT
    d.calendar_date,
    date_trunc('week', d.calendar_date)::date  AS week_start,
    date_trunc('month', d.calendar_date)::date AS month_start,
    p.plant_id, p.plant_name,
    l.line_id, l.line_name,
    pr.part_id, pr.part_name, pr.family,
    SUM(fp.produced_qty) AS produced_qty,
    SUM(fp.scrap_qty)    AS scrap_qty,
    SUM(fp.rework_qty)   AS rework_qty
  FROM fact_production fp
  JOIN dim_date d ON d.date_key = fp.date_key
  JOIN dim_plant p ON p.plant_id = fp.plant_id
  JOIN dim_line l  ON l.line_id  = fp.line_id
  JOIN dim_part pr ON pr.part_id = fp.part_id
  GROUP BY 1,2,3,4,5,6,7,8,9
),
roll AS (
  SELECT
    calendar_date, week_start, month_start,
    plant_id, plant_name,
    line_id, line_name,
    part_id, part_name, family,
    produced_qty, scrap_qty, rework_qty,
    GROUPING(calendar_date) AS g_day,
    GROUPING(week_start)    AS g_week,
    GROUPING(month_start)   AS g_month,
    GROUPING(plant_id)      AS g_plant,
    GROUPING(line_id)       AS g_line,
    GROUPING(part_id)       AS g_part
  FROM base
  GROUP BY GROUPING SETS (
    (calendar_date, plant_id, line_id, part_id),
    (week_start,   plant_id, line_id, part_id),
    (month_start,  plant_id, line_id, part_id),
    (calendar_date, plant_id, line_id),
    (week_start,    plant_id, line_id),
    (month_start,   plant_id, line_id),
    (calendar_date, plant_id),
    (week_start,    plant_id),
    (month_start,   plant_id),
    (month_start) -- pure company-wide monthly
  )
)
SELECT
  calendar_date, week_start, month_start,
  plant_id, plant_name, line_id, line_name, part_id, part_name, family,
  produced_qty, scrap_qty, rework_qty,
  CASE WHEN produced_qty = 0 THEN 0::float ELSE scrap_qty::float/produced_qty END AS scrap_rate,
  g_day, g_week, g_month, g_plant, g_line, g_part
FROM roll;

-- Control-chart-ish check per line: mean and 3-sigma of scrap rate (daily)
DROP VIEW IF EXISTS vw_line_control_chart CASCADE;
CREATE VIEW vw_line_control_chart AS
WITH dly AS (
  SELECT
    d.calendar_date, p.plant_name, l.line_name,
    SUM(fp.scrap_qty)::float / NULLIF(SUM(fp.produced_qty),0) AS scrap_rate
  FROM fact_production fp
  JOIN dim_date d ON d.date_key = fp.date_key
  JOIN dim_plant p ON p.plant_id = fp.plant_id
  JOIN dim_line l ON l.line_id = fp.line_id
  GROUP BY 1,2,3
),
stats AS (
  SELECT
    *,
    AVG(scrap_rate) OVER (PARTITION BY plant_name, line_name) AS mean_rate,
    STDDEV_SAMP(scrap_rate) OVER (PARTITION BY plant_name, line_name) AS sd_rate
  FROM dly
)
SELECT
  calendar_date, plant_name, line_name, scrap_rate,
  mean_rate,
  mean_rate + 3*sd_rate AS ucl_3sigma,
  mean_rate - 3*sd_rate AS lcl_3sigma
FROM stats;
