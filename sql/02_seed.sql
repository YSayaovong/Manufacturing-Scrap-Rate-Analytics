-- sql/02_seed.sql
-- Load CSVs from /data/raw into staging then merge into dimensions/facts.
-- Use psql with \copy from your client machine.

CREATE SCHEMA IF NOT EXISTS staging;

DROP TABLE IF EXISTS staging.dim_date;
CREATE TABLE staging.dim_date(
    date_id date,
    year int, quarter int, month int, day int, week int, weekday_name text, is_weekend boolean
);

DROP TABLE IF EXISTS staging.dim_line;
CREATE TABLE staging.dim_line(line_code text, line_name text);

DROP TABLE IF EXISTS staging.dim_product;
CREATE TABLE staging.dim_product(sku text, product_name text, unit_cost numeric(12,2));

DROP TABLE IF EXISTS staging.dim_defect;
CREATE TABLE staging.dim_defect(defect_code text, defect_name text);

DROP TABLE IF EXISTS staging.fact_production;
CREATE TABLE staging.fact_production(date_id date, line_code text, sku text, units_produced int);

DROP TABLE IF EXISTS staging.fact_scrap;
CREATE TABLE staging.fact_scrap(date_id date, line_code text, sku text, defect_code text, units_scrapped int);

-- Replace <ABS> with your absolute path to repo
-- \copy staging.dim_date     FROM '<ABS>/data/raw/dim_date.csv'       WITH CSV HEADER;
-- \copy staging.dim_line     FROM '<ABS>/data/raw/dim_line.csv'       WITH CSV HEADER;
-- \copy staging.dim_product  FROM '<ABS>/data/raw/dim_product.csv'    WITH CSV HEADER;
-- \copy staging.dim_defect   FROM '<ABS>/data/raw/dim_defect.csv'     WITH CSV HEADER;
-- \copy staging.fact_production FROM '<ABS>/data/raw/fact_production.csv' WITH CSV HEADER;
-- \copy staging.fact_scrap      FROM '<ABS>/data/raw/fact_scrap.csv'      WITH CSV HEADER;

-- Merge into dims
INSERT INTO sra.dim_date(date_id, year, quarter, month, day, week, weekday_name, is_weekend)
SELECT DISTINCT date_id, year, quarter, month, day, week, weekday_name, is_weekend
FROM staging.dim_date
ON CONFLICT (date_id) DO NOTHING;

INSERT INTO sra.dim_line(line_code, line_name)
SELECT DISTINCT line_code, line_name
FROM staging.dim_line
ON CONFLICT (line_code) DO NOTHING;

INSERT INTO sra.dim_product(sku, product_name, unit_cost)
SELECT DISTINCT sku, product_name, unit_cost
FROM staging.dim_product
ON CONFLICT (sku) DO NOTHING;

INSERT INTO sra.dim_defect(defect_code, defect_name)
SELECT DISTINCT defect_code, defect_name
FROM staging.dim_defect
ON CONFLICT (defect_code) DO NOTHING;

-- Merge facts (resolve FKs)
INSERT INTO sra.fact_production(date_id, line_id, product_id, units_produced)
SELECT p.date_id,
       l.line_id,
       pr.product_id,
       p.units_produced
FROM staging.fact_production p
JOIN sra.dim_line l     ON l.line_code = p.line_code
JOIN sra.dim_product pr ON pr.sku = p.sku;

INSERT INTO sra.fact_scrap(date_id, line_id, product_id, defect_id, units_scrapped)
SELECT s.date_id,
       l.line_id,
       pr.product_id,
       d.defect_id,
       s.units_scrapped
FROM staging.fact_scrap s
JOIN sra.dim_line l     ON l.line_code = s.line_code
JOIN sra.dim_product pr ON pr.sku = s.sku
JOIN sra.dim_defect d   ON d.defect_code = s.defect_code;
