-- sql/02_seed_data.sql
-- Date dimension: last 180 days
WITH d AS (
  SELECT gs::date AS dt
  FROM generate_series(current_date - 179, current_date, interval '1 day') gs
)
INSERT INTO dim_date(date_key, calendar_date, week_start, month_start, year)
SELECT
  EXTRACT(YEAR FROM dt)::INT * 10000 + EXTRACT(MONTH FROM dt)::INT * 100 + EXTRACT(DAY FROM dt)::INT AS date_key,
  dt,
  date_trunc('week', dt)::date,
  date_trunc('month', dt)::date,
  EXTRACT(YEAR FROM dt)::INT
FROM d
ON CONFLICT DO NOTHING;

-- Plants
INSERT INTO dim_plant(plant_name) VALUES
 ('Plant A'), ('Plant B')
ON CONFLICT DO NOTHING;

-- Lines (2 plants x 3 lines)
INSERT INTO dim_line(plant_id, line_name)
SELECT p.plant_id, x.line_name
FROM dim_plant p
CROSS JOIN (VALUES ('Line 1'), ('Line 2'), ('Line 3')) AS x(line_name)
ON CONFLICT DO NOTHING;

-- Parts (6 parts, 2 families)
INSERT INTO dim_part(part_name, family) VALUES
 ('Widget-100', 'Widgets'),
 ('Widget-200', 'Widgets'),
 ('Gadget-10',  'Gadgets'),
 ('Gadget-20',  'Gadgets'),
 ('Module-A',   'Modules'),
 ('Module-B',   'Modules')
ON CONFLICT DO NOTHING;

-- Defects
INSERT INTO dim_defect(defect_code, defect_desc) VALUES
 ('BURR',   'Edge burr / sharp edge'),
 ('CRACK',  'Surface crack'),
 ('WARP',   'Warping / deformation'),
 ('VOID',   'Material void'),
 ('COAT',   'Coating blemish'),
 ('DIM',    'Dimensional out-of-tolerance')
ON CONFLICT DO NOTHING;

-- Synthetic production & scrap
-- Strategy: for each date x line x part, create produced qty with noise,
-- scrap qty biased by line & part, and rework as small fraction.
WITH params AS (
  SELECT
    0.01::float8 AS base_scrap_rate,   -- 1%
    0.40::float8 AS part_variation,    -- +/- on parts
    0.30::float8 AS line_variation     -- +/- on lines
),
keys AS (
  SELECT d.date_key, p.plant_id, l.line_id, pr.part_id, d.calendar_date::date AS dte
  FROM dim_date d
  CROSS JOIN dim_plant p
  JOIN dim_line l ON l.plant_id = p.plant_id
  CROSS JOIN dim_part pr
),
prod AS (
  SELECT
    k.*,
    -- produced qty: 400 to 1200 depending on weekday/weekend
    CASE WHEN EXTRACT(DOW FROM k.dte) IN (0,6) -- Sun/Sat
         THEN (400 + (random()*200))::int
         ELSE (800 + (random()*400))::int
    END AS produced_qty
  FROM keys k
),
bias AS (
  SELECT
    pr.part_id,
    1.0 + (random() - 0.5) * 2 * (SELECT part_variation FROM params) AS part_bias
  FROM dim_part pr
),
lbias AS (
  SELECT
    l.line_id,
    1.0 + (random() - 0.5) * 2 * (SELECT line_variation FROM params) AS line_bias
  FROM dim_line l
),
base AS (
  SELECT
    pr.date_key, pr.plant_id, pr.line_id, pr.part_id, pr.produced_qty,
    GREATEST(0,
      round((SELECT base_scrap_rate FROM params) 
            * (SELECT part_bias FROM bias WHERE bias.part_id = pr.part_id)
            * (SELECT line_bias FROM lbias WHERE lbias.line_id = pr.line_id)
            * pr.produced_qty
            + random()*2  -- random noise up to ~2 units
      )::int
    ) AS scrap_qty
  FROM prod pr
)
INSERT INTO fact_production(date_key, plant_id, line_id, part_id, produced_qty, scrap_qty, rework_qty)
SELECT
  date_key, plant_id, line_id, part_id, produced_qty, scrap_qty,
  GREATEST(0, round(scrap_qty * (0.15 + random()*0.10))::int) AS rework_qty
FROM base;

-- Allocate scrap to defects for Pareto analysis
-- Randomly distribute each key's scrap qty across 1-3 defects.
WITH s AS (
  SELECT fp.*, dd.defect_id
  FROM fact_production fp
  CROSS JOIN LATERAL (
     SELECT array_agg(defect_id ORDER BY random())[:(1 + (random()*2)::int)] AS picks
     FROM dim_defect
  ) pick
  JOIN LATERAL unnest(pick.picks) AS dd(defect_id) ON TRUE
),
shares AS (
  SELECT s.*,
         CASE WHEN array_length((SELECT array_agg(defect_id) FROM dim_defect),1) IS NULL THEN 1 ELSE 1 END
  FROM s
),
alloc AS (
  SELECT
    s.date_key, s.plant_id, s.line_id, s.part_id, s.defect_id,
    CASE
      WHEN s.scrap_qty = 0 THEN 0
      ELSE GREATEST(0, round((s.scrap_qty::float / (SELECT COUNT(*) FROM s s2 WHERE s2.date_key=s.date_key AND s2.plant_id=s.plant_id AND s2.line_id=s.line_id AND s2.part_id=s.part_id))::numeric))
    END AS alloc_qty
  FROM s
)
INSERT INTO fact_scrap_detail(date_key, plant_id, line_id, part_id, defect_id, scrap_qty)
SELECT date_key, plant_id, line_id, part_id, defect_id, alloc_qty
FROM alloc
WHERE alloc_qty > 0;

-- Index reorg/analyze is optional here
