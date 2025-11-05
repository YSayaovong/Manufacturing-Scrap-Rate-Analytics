-- sql/04_queries.sql

-- 1) Top 10 lines by monthly scrap rate (current month)
SELECT
  month_start, plant_name, line_name,
  SUM(scrap_qty)::float / NULLIF(SUM(produced_qty),0) AS scrap_rate
FROM vw_kpi_rollups
WHERE g_month = 0 AND month_start = date_trunc('month', current_date)::date
GROUP BY 1,2,3
ORDER BY scrap_rate DESC
LIMIT 10;

-- 2) Pareto 80% cutoff defects this month for Plant A
WITH p AS (
  SELECT *
  FROM vw_monthly_defect_pareto
  WHERE plant_name = 'Plant A'
    AND month_start = date_trunc('month', current_date)::date
)
SELECT *
FROM p
WHERE cum_share <= 0.80
ORDER BY scrap_qty DESC;

-- 3) Lines breaching 3-sigma control limit today
SELECT *
FROM vw_line_control_chart
WHERE calendar_date = current_date
  AND (scrap_rate > ucl_3sigma OR scrap_rate < lcl_3sigma);

-- 4) Rolling improvement check: 28d vs 7d trend (line/part)
SELECT
  plant_name, line_name, part_name, calendar_date,
  scrap_rate_28d, scrap_rate_7d,
  (scrap_rate_7d - scrap_rate_28d) AS delta_recent_vs_trend
FROM vw_daily_scrap_metrics
WHERE calendar_date >= current_date - 30
ORDER BY plant_name, line_name, part_name, calendar_date;

-- 5) Fast daily KPI for exec readout (company-wide, last 30 days)
SELECT
  calendar_date,
  SUM(scrap_qty) AS scrap_qty,
  SUM(produced_qty) AS produced_qty,
  SUM(scrap_qty)::float / NULLIF(SUM(produced_qty),0) AS scrap_rate
FROM vw_kpi_rollups
WHERE g_day = 0 AND g_plant = 1 -- day grain, all plants
  AND calendar_date >= current_date - 30
GROUP BY 1
ORDER BY 1;
