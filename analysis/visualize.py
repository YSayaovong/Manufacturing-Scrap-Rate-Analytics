import pandas as pd
import matplotlib.pyplot as plt
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

def main():
    daily = pd.read_csv(ROOT/'data/processed/kpi_daily.csv', parse_dates=['date_id'])
    pareto = pd.read_csv(ROOT/'data/processed/kpi_defect_pareto.csv')
    by_line = pd.read_csv(ROOT/'data/processed/kpi_by_line.csv')

    # 1) Trend
    d = daily.sort_values('date_id')
    plt.figure()
    plt.plot(d['date_id'], d['scrap_rate_pct'])
    plt.title('Scrap Rate Trend (%)')
    plt.xlabel('Date')
    plt.ylabel('Scrap Rate (%)')
    plt.tight_layout()
    plt.savefig(ROOT/'outputs/img/scrap_rate_trend.png')
    plt.close()

    # 2) Pareto (Top 10)
    t = pareto.sort_values('units_scrapped', ascending=False).head(10)
    plt.figure()
    plt.bar(t['defect_name'].fillna(t['defect_code']), t['units_scrapped'])
    plt.title('Top Defect Drivers (Units Scrapped)')
    plt.xlabel('Defect')
    plt.ylabel('Units Scrapped')
    plt.xticks(rotation=30, ha='right')
    plt.tight_layout()
    plt.savefig(ROOT/'outputs/img/pareto_defects.png')
    plt.close()

    # 3) By line
    plt.figure()
    plt.bar(by_line['line_code'], by_line['scrap_rate_pct'])
    plt.title('Scrap Rate by Line (%)')
    plt.xlabel('Line')
    plt.ylabel('Scrap Rate (%)')
    plt.tight_layout()
    plt.savefig(ROOT/'outputs/img/scrap_by_line.png')
    plt.close()

    # 4) Outliers (prod vs scrap)
    plt.figure()
    plt.scatter(d['units_produced'], d['units_scrapped'])
    plt.title('Daily Scrap vs Production (Outlier Scan)')
    plt.xlabel('Units Produced')
    plt.ylabel('Units Scrapped')
    plt.tight_layout()
    plt.savefig(ROOT/'outputs/img/outliers.png')
    plt.close()

if __name__ == '__main__':
    main()
