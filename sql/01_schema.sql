-- sql/01_schema.sql
-- Drop if re-running
DROP TABLE IF EXISTS fact_scrap_detail CASCADE;
DROP TABLE IF EXISTS fact_production CASCADE;
DROP TABLE IF EXISTS dim_defect CASCADE;
DROP TABLE IF EXISTS dim_part CASCADE;
DROP TABLE IF EXISTS dim_line CASCADE;
DROP TABLE IF EXISTS dim_plant CASCADE;
DROP TABLE IF EXISTS dim_date CASCADE;

-- Dimensions
CREATE TABLE dim_date (
  date_key        INT PRIMARY KEY,        -- yyyymmdd
  calendar_date   DATE NOT NULL,
  week_start      DATE NOT NULL,
  month_start     DATE NOT NULL,
  year            INT  NOT NULL
);

CREATE TABLE dim_plant (
  plant_id   SERIAL PRIMARY KEY,
  plant_name TEXT UNIQUE NOT NULL
);

CREATE TABLE dim_line (
  line_id    SERIAL PRIMARY KEY,
  plant_id   INT REFERENCES dim_plant(plant_id),
  line_name  TEXT NOT NULL
);

CREATE TABLE dim_part (
  part_id    SERIAL PRIMARY KEY,
  part_name  TEXT NOT NULL,
  family     TEXT NOT NULL
);

CREATE TABLE dim_defect (
  defect_id   SERIAL PRIMARY KEY,
  defect_code TEXT UNIQUE NOT NULL,
  defect_desc TEXT NOT NULL
);

-- Facts
CREATE TABLE fact_production (
  date_key     INT REFERENCES dim_date(date_key),
  plant_id     INT REFERENCES dim_plant(plant_id),
  line_id      INT REFERENCES dim_line(line_id),
  part_id      INT REFERENCES dim_part(part_id),
  produced_qty INT NOT NULL,
  scrap_qty    INT NOT NULL,
  rework_qty   INT NOT NULL,
  PRIMARY KEY(date_key, plant_id, line_id, part_id)
);

CREATE TABLE fact_scrap_detail (
  date_key   INT REFERENCES dim_date(date_key),
  plant_id   INT REFERENCES dim_plant(plant_id),
  line_id    INT REFERENCES dim_line(line_id),
  part_id    INT REFERENCES dim_part(part_id),
  defect_id  INT REFERENCES dim_defect(defect_id),
  scrap_qty  INT NOT NULL,
  PRIMARY KEY(date_key, plant_id, line_id, part_id, defect_id)
);

-- Helpful indexes
CREATE INDEX ON fact_production(date_key, plant_id, line_id, part_id);
CREATE INDEX ON fact_scrap_detail(date_key, plant_id, line_id, part_id, defect_id);
