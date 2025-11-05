# Scrap Rate Analytics Engine (No Power BI)

Manufacturing KPI project that calculates **scrap rate %, defect drivers (Pareto), and line performance** using a **code-only stack** (SQL + Python + CSV). This version deliberately avoids Power BI and ships **static PNG charts** for a clean GitHub portfolio.

## 🔧 Tech
- SQL (PostgreSQL-first, but not required for demo)
- Python (pandas, matplotlib)
- CSV-based ETL for portability
- Static PNG charts for GitHub visibility

## 📁 Structure
```
Scrap-Rate-Analytics-Engine-No-PowerBI/
├─ data/
│  ├─ raw/            # mock source data (CSV)
│  └─ processed/      # KPI tables (CSV)
├─ sql/               # 01_schema.sql, 02_seed.sql, 03_views.sql, 04_reporting.sql
├─ etl/               # refresh_kpis.py
├─ analysis/          # visualize.py (exports charts to outputs/img)
├─ outputs/
│  ├─ csv/            # convenient exports for reviewers
│  └─ img/            # PNG charts (ready for README/LinkedIn)
├─ docs/              # ERD, notes
└─ .env.example
```

## 🚀 Quick Start (No Database Required)
1. Ensure Python 3.9+ is installed.
2. (Optional) Create a venv and activate it.
3. Install deps:
   ```bash
   pip install pandas matplotlib
   ```
4. Recompute KPIs (from `/data/raw`):
   ```bash
   python etl/refresh_kpis.py
   ```
5. Generate charts:
   ```bash
   python analysis/visualize.py
   ```
6. See charts in `outputs/img/`:
   - `scrap_rate_trend.png`
   - `pareto_defects.png`
   - `scrap_by_line.png`
   - `outliers.png`

## 🗃️ Optional: PostgreSQL Setup
If you want a DB-backed version:
1. Create DB `scrap_analytics`.
2. Run `sql/01_schema.sql`, then `sql/02_seed.sql` (replace `<ABS>` path in COPY).
3. Run `sql/03_views.sql` and `sql/04_reporting.sql` for final queries.

## 📊 KPIs
- **Scrap Rate %** = units_scrapped / units_produced * 100
- **Top Defect Drivers** (Pareto by units_scrapped)
- **Scrap Rate by Line**
- **Outlier Scan** (units_scrapped vs produced)

## 🧠 Findings (from mock data)
- Weekends run lower volume and slightly higher scrap %.
- Line L3 trends higher scrap; target it for root-cause analysis.
- Defects cluster around **Winding Short** and **Insulation Nick**.

## 📝 Resume Bullet (ready-to-paste)
Designed a code-driven Scrap Rate Analytics engine (SQL + Python) that modeled production and scrap across 4 lines and 4 SKUs, automated KPI computation, and produced trend/Pareto/line charts; enabled root‑cause triage without proprietary BI tools.

## 📷 Screenshots
![Scrap Rate Trend](outputs/img/scrap_rate_trend.png)
![Pareto Defects](outputs/img/pareto_defects.png)
![Scrap by Line](outputs/img/scrap_by_line.png)

## 🔁 Re-run
```bash
python etl/refresh_kpis.py
python analysis/visualize.py
```

## 🔒 Data Note
All data is synthetic for portfolio use.
