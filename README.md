# Manufacturing Scrap Rate Analytics
## Scope
Independent manufacturing analytics demonstration using synthetic production and scrap CSVs, Python KPI processing and PostgreSQL examples. No employer losses, realized savings or confirmed root causes are claimed.

## Files
- `data/raw/`: dimension and fact CSVs.
- `etl/refresh_kpis.py`: independently aggregates production and scrap into daily, line and defect KPI CSVs.
- `data/processed/`: saved KPI outputs.
- `analysis/visualize.py`: reporting/visualization code.
- `sql/`: PostgreSQL schema, seed and reporting examples.
- `outputs/`: saved charts and CSVs.
- `docs/ERD.md`: model notes.

## Python workflow
With pandas, numpy and matplotlib installed, run from the repository root:
```bash
python etl/refresh_kpis.py
python analysis/visualize.py
```
Inspect paths and expected input columns before execution. This documentation update did not run the full application.

## Verified source-data reconciliation
The supplied raw CSVs total 350,111 produced units and 5,516 scrapped units, giving a weighted overall scrap rate of approximately 1.5755%. A mean of daily percentages is a different metric and should be labeled separately.

## Known SQL issue — do not use the current views for decisions
`sql/03_views.sql` joins production directly to defect-level scrap before summing production. Multiple defect rows repeat the denominator. For the supplied data that join counts 611,914 production units and produces approximately 0.9014%, rather than the correct overall rate.

The Python refresh script aggregates the facts separately. The SQL views still need repair: aggregate each fact to the same date/line/product grain before joining, then reconcile SQL and Python outputs. This limitation is documented rather than silently treating the existing views as validated.

## Analytical boundaries
High defect frequency suggests investigation priorities, not a proven shared cause. Differences between lines, products or weekends require exposure-adjusted comparisons and operational context. A two-standard-deviation flag alone does not establish statistical process control, and estimated scrap cost is not the same as recoverable savings.

## Next steps
Fix SQL aggregation, add denominator and duplicate-grain tests, document synthetic-data generation and cost assumptions, and regenerate all outputs after reconciliation.
