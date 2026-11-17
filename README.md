# Manufacturing Scrap Rate Analytics

**Engineering data quality | Manufacturing reporting | SQL | Python**

I developed this project to demonstrate how I validate manufacturing KPIs before using them to support decisions. A scrap-rate dashboard is only useful when its production denominator, defect records and aggregation rules are correct.

## The problem I addressed

A production record can have more than one associated defect record. Joining production directly to defect-level scrap records can duplicate production quantities and produce an inaccurate scrap rate.

In this synthetic example, the earlier direct join inflated the production denominator to **611,914 units**. I corrected the reporting approach by aggregating production and scrap at their appropriate levels before joining them. The reporting logic also preserves scrap-only groups and returns an undefined rate as `NULL` when there is no positive production denominator.

## Verified sample result

| Metric | Synthetic dataset |
|---|---:|
| Units produced | 350,111 |
| Units scrapped | 5,516 |
| Weighted scrap rate | **1.5755%** |

I use a weighted rate rather than averaging daily percentages because the daily production volumes are not necessarily equal. These figures describe the sample dataset, not an employer's performance.

## What I built

- CSV production, scrap and dimension tables in `data/raw/`
- Python KPI processing in [etl/refresh_kpis.py](etl/refresh_kpis.py)
- Visual reporting in [analysis/visualize.py](analysis/visualize.py)
- PostgreSQL reporting views in [sql/03_views.sql](sql/03_views.sql)
- Data model notes in [docs/ERD.md](docs/ERD.md)
- Automated reconciliation and regression checks in [validate_metrics.py](validate_metrics.py)
- Recorded source totals and hashes in [reports/reconciliation.json](reports/reconciliation.json)

The regression cases cover multiple defects per production record, scrap without production and production without scrap. Additional checks examine duplicate production keys, orphan records, negative quantities and daily/line reconciliation.

## How to review my work

Run from the repository root with Python 3.10 or newer:

```bash
python -m pip install -r requirements.txt
python validate_metrics.py
python etl/refresh_kpis.py
python analysis/visualize.py
```

The [GitHub Actions workflow](.github/workflows/checks.yml) runs the documented checks. Historical screenshots and exports may not reflect the corrected SQL logic; the validation script and current source files are the stronger evidence. The SQLite compatibility test checks aggregation behavior but does **not** verify a live PostgreSQL deployment or its import scripts.

## Why this matters for engineering analyst work

I approach data-quality issues as business risks. An incorrect denominator can distort quality trends, misdirect investigation and undermine trust in reports. This project demonstrates my focus on traceable calculations, repeatable validation and explaining what the data can—and cannot—support.

**Scope:** The data and costs are illustrative. Defect patterns identify investigation priorities; they do not establish root causes or realized savings.
