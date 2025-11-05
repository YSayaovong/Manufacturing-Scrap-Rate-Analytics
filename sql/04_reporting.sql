-- sql/04_reporting.sql
-- Final report queries used by analysis scripts

-- Trend
SELECT * FROM sra.v_scrap_daily ORDER BY date_id;

-- Scrap by line
SELECT * FROM sra.v_scrap_by_line ORDER BY scrap_rate_pct DESC;

-- Pareto
SELECT * FROM sra.v_defect_pareto ORDER BY units_scrapped DESC;
