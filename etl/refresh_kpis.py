# Rebuilds processed KPI CSVs directly from raw CSVs (no database needed).
import pandas as pd
import numpy as np
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

def main():
    dim_defect = pd.read_csv(ROOT/'data/raw/dim_defect.csv')
    fact_prod = pd.read_csv(ROOT/'data/raw/fact_production.csv', parse_dates=['date_id'])
    fact_scrap = pd.read_csv(ROOT/'data/raw/fact_scrap.csv', parse_dates=['date_id'])

    # Daily
    daily = (fact_prod.groupby('date_id', as_index=False)['units_produced'].sum()
             .merge(fact_scrap.groupby('date_id', as_index=False)['units_scrapped'].sum(),
                    on='date_id', how='left').fillna({'units_scrapped':0}))
    daily['scrap_rate_pct'] = np.where(daily['units_produced']==0, 0,
                                       (daily['units_scrapped']/daily['units_produced'])*100.0)
    daily.to_csv(ROOT/'data/processed/kpi_daily.csv', index=False)

    # By line
    prod_line = fact_prod.groupby(['line_code'], as_index=False)['units_produced'].sum()
    scrap_line = fact_scrap.groupby(['line_code'], as_index=False)['units_scrapped'].sum()
    by_line = prod_line.merge(scrap_line, on='line_code', how='left').fillna({'units_scrapped':0})
    by_line['scrap_rate_pct'] = np.where(by_line['units_produced']==0, 0,
                                         (by_line['units_scrapped']/by_line['units_produced'])*100.0)
    by_line.to_csv(ROOT/'data/processed/kpi_by_line.csv', index=False)

    # Pareto
    pareto = (fact_scrap.groupby(['defect_code'], as_index=False)['units_scrapped'].sum()
              .merge(dim_defect, on='defect_code', how='left')
              .sort_values('units_scrapped', ascending=False))
    pareto.to_csv(ROOT/'data/processed/kpi_defect_pareto.csv', index=False)

if __name__ == '__main__':
    main()
