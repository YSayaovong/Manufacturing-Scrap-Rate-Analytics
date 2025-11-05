-- sql/03_views.sql
-- KPI views

CREATE OR REPLACE VIEW sra.v_scrap_daily AS
SELECT
    fp.date_id,
    SUM(fp.units_produced) AS units_produced,
    COALESCE(SUM(fs.units_scrapped),0) AS units_scrapped,
    CASE 
        WHEN SUM(fp.units_produced) = 0 THEN 0
        ELSE ROUND(COALESCE(SUM(fs.units_scrapped),0)::numeric / SUM(fp.units_produced) * 100, 4)
    END AS scrap_rate_pct
FROM sra.fact_production fp
LEFT JOIN sra.fact_scrap fs
  ON fs.date_id = fp.date_id AND fs.line_id = fp.line_id AND fs.product_id = fp.product_id
GROUP BY fp.date_id;

CREATE OR REPLACE VIEW sra.v_scrap_by_line AS
SELECT
    l.line_code,
    SUM(fp.units_produced) AS units_produced,
    COALESCE(SUM(fs.units_scrapped),0) AS units_scrapped,
    CASE 
        WHEN SUM(fp.units_produced) = 0 THEN 0
        ELSE ROUND(COALESCE(SUM(fs.units_scrapped),0)::numeric / SUM(fp.units_produced) * 100, 4)
    END AS scrap_rate_pct
FROM sra.fact_production fp
JOIN sra.dim_line l ON l.line_id = fp.line_id
LEFT JOIN sra.fact_scrap fs
  ON fs.date_id = fp.date_id AND fs.line_id = fp.line_id AND fs.product_id = fp.product_id
GROUP BY l.line_code;

CREATE OR REPLACE VIEW sra.v_defect_pareto AS
SELECT
    d.defect_code,
    d.defect_name,
    SUM(fs.units_scrapped) AS units_scrapped
FROM sra.fact_scrap fs
JOIN sra.dim_defect d ON d.defect_id = fs.defect_id
GROUP BY d.defect_code, d.defect_name
ORDER BY units_scrapped DESC;
