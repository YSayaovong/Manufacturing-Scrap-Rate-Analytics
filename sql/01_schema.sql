-- sql/01_schema.sql
-- Create schema + tables (PostgreSQL). Safe to re-run.

CREATE SCHEMA IF NOT EXISTS sra;

-- Dimensions
CREATE TABLE IF NOT EXISTS sra.dim_date (
    date_id        date PRIMARY KEY,
    year           int,
    quarter        int,
    month          int,
    day            int,
    week           int,
    weekday_name   text,
    is_weekend     boolean
);

CREATE TABLE IF NOT EXISTS sra.dim_line (
    line_id        serial PRIMARY KEY,
    line_code      text UNIQUE,
    line_name      text
);

CREATE TABLE IF NOT EXISTS sra.dim_product (
    product_id     serial PRIMARY KEY,
    sku            text UNIQUE,
    product_name   text,
    unit_cost      numeric(12,2) DEFAULT 0
);

CREATE TABLE IF NOT EXISTS sra.dim_defect (
    defect_id      serial PRIMARY KEY,
    defect_code    text UNIQUE,
    defect_name    text
);

-- Facts
CREATE TABLE IF NOT EXISTS sra.fact_production (
    prod_id        bigserial PRIMARY KEY,
    date_id        date REFERENCES sra.dim_date(date_id),
    line_id        int  REFERENCES sra.dim_line(line_id),
    product_id     int  REFERENCES sra.dim_product(product_id),
    units_produced int  CHECK (units_produced >= 0)
);

CREATE TABLE IF NOT EXISTS sra.fact_scrap (
    scrap_id       bigserial PRIMARY KEY,
    date_id        date REFERENCES sra.dim_date(date_id),
    line_id        int  REFERENCES sra.dim_line(line_id),
    product_id     int  REFERENCES sra.dim_product(product_id),
    defect_id      int  REFERENCES sra.dim_defect(defect_id),
    units_scrapped int  CHECK (units_scrapped >= 0)
);

-- Helpful indexes
CREATE INDEX IF NOT EXISTS idx_prod_date ON sra.fact_production(date_id);
CREATE INDEX IF NOT EXISTS idx_scrap_date ON sra.fact_scrap(date_id);
CREATE INDEX IF NOT EXISTS idx_prod_line ON sra.fact_production(line_id);
CREATE INDEX IF NOT EXISTS idx_scrap_line ON sra.fact_scrap(line_id);
CREATE INDEX IF NOT EXISTS idx_prod_product ON sra.fact_production(product_id);
CREATE INDEX IF NOT EXISTS idx_scrap_product ON sra.fact_scrap(product_id);
