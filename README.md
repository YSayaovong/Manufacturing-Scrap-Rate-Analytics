Scrap-Rate-Analytics/
│
├── data/
│   └── raw/
│       ├── fact_scrap.csv
│       ├── fact_production.csv
│       ├── dim_line.csv
│       ├── dim_product.csv
│       ├── dim_defect.csv
│       └── dim_date.csv
│
├── src/
│   ├── etl.py
│   └── analysis.py
│
├── outputs/
│   ├── kpi_daily.csv
│   ├── kpi_by_line.csv
│   ├── kpi_defect_pareto.csv
│   └── img/
│       ├── scrap_rate_trend.png
│       ├── pareto_defects.png
│       ├── scrap_by_line.png
│       └── outliers.png
│
├── assets/
│   ├── 00_database.PNG
│   ├── 01_schema.PNG
│   ├── 02_seed_data.PNG
│   ├── 03_views.PNG
│   ├── 04_queries.PNG
│   └── schema_design.PNG
│
├── requirements.txt
└── README.md
