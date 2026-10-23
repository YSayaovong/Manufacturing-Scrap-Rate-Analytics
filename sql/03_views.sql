-- Aggregate each fact before joining so defect rows cannot multiply production.
-- PostgreSQL views; NULL rate means no positive production denominator.
CREATE OR REPLACE VIEW sra.v_scrap_daily AS
WITH p AS (
 SELECT date_id, SUM(units_produced) AS units_produced
 FROM sra.fact_production GROUP BY date_id
), s AS (
 SELECT date_id, SUM(units_scrapped) AS units_scrapped
 FROM sra.fact_scrap GROUP BY date_id
), keys AS (SELECT date_id FROM p UNION SELECT date_id FROM s)
SELECT k.date_id, COALESCE(p.units_produced,0) AS units_produced,
 COALESCE(s.units_scrapped,0) AS units_scrapped,
 ROUND(100.0 * COALESCE(s.units_scrapped,0) / NULLIF(p.units_produced,0),4) AS scrap_rate_pct
FROM keys k LEFT JOIN p ON p.date_id=k.date_id LEFT JOIN s ON s.date_id=k.date_id;

CREATE OR REPLACE VIEW sra.v_scrap_by_line AS
WITH p AS (
 SELECT line_id, SUM(units_produced) AS units_produced
 FROM sra.fact_production GROUP BY line_id
), s AS (
 SELECT line_id, SUM(units_scrapped) AS units_scrapped
 FROM sra.fact_scrap GROUP BY line_id
), keys AS (SELECT line_id FROM p UNION SELECT line_id FROM s)
SELECT l.line_code, COALESCE(p.units_produced,0) AS units_produced,
 COALESCE(s.units_scrapped,0) AS units_scrapped,
 ROUND(100.0 * COALESCE(s.units_scrapped,0) / NULLIF(p.units_produced,0),4) AS scrap_rate_pct
FROM keys k JOIN sra.dim_line l ON l.line_id=k.line_id
LEFT JOIN p ON p.line_id=k.line_id LEFT JOIN s ON s.line_id=k.line_id;

CREATE OR REPLACE VIEW sra.v_defect_pareto AS
SELECT d.defect_code, d.defect_name, SUM(fs.units_scrapped) AS units_scrapped
FROM sra.fact_scrap fs JOIN sra.dim_defect d ON d.defect_id=fs.defect_id
GROUP BY d.defect_code,d.defect_name ORDER BY units_scrapped DESC;
