"""Reconcile CSV facts and corrected SQL aggregation using an in-memory SQLite adapter.

Only CREATE OR REPLACE VIEW is adapted to SQLite CREATE VIEW. This checks
aggregation logic, not PostgreSQL deployment, imports or permissions.
"""
import csv
import hashlib
import json
from pathlib import Path
import sqlite3
import unittest

ROOT = Path(__file__).resolve().parent

def database():
    db = sqlite3.connect(':memory:')
    db.execute("ATTACH DATABASE ':memory:' AS sra")
    db.executescript('''
    CREATE TABLE sra.fact_production(date_id TEXT,line_id TEXT,product_id TEXT,units_produced INTEGER);
    CREATE TABLE sra.fact_scrap(date_id TEXT,line_id TEXT,product_id TEXT,defect_id TEXT,units_scrapped INTEGER);
    CREATE TABLE sra.dim_line(line_id TEXT,line_code TEXT);
    CREATE TABLE sra.dim_defect(defect_id TEXT,defect_code TEXT,defect_name TEXT);
    ''')
    db.executescript((ROOT / 'sql/03_views.sql').read_text().replace('CREATE OR REPLACE VIEW', 'CREATE VIEW'))
    return db

class AggregationChecks(unittest.TestCase):
    def test_multiple_defects_do_not_multiply_denominator(self):
        db = database()
        db.execute("INSERT INTO sra.fact_production VALUES('2025-01-01','L1','P1',100)")
        db.executemany('INSERT INTO sra.fact_scrap VALUES(?,?,?,?,?)', [('2025-01-01','L1','P1','D1',2), ('2025-01-01','L1','P1','D2',3)])
        self.assertEqual(db.execute('SELECT units_produced,units_scrapped,scrap_rate_pct FROM sra.v_scrap_daily').fetchone(), (100,5,5.0))

    def test_scrap_without_production_remains_visible(self):
        db = database()
        db.execute("INSERT INTO sra.fact_scrap VALUES('2025-01-01','L1','P1','D1',2)")
        self.assertEqual(db.execute('SELECT units_produced,units_scrapped,scrap_rate_pct FROM sra.v_scrap_daily').fetchone(), (0,2,None))

    def test_no_scrap_retains_production(self):
        db = database()
        db.execute("INSERT INTO sra.fact_production VALUES('2025-01-01','L1','P1',100)")
        self.assertEqual(db.execute('SELECT units_produced,units_scrapped,scrap_rate_pct FROM sra.v_scrap_daily').fetchone(), (100,0,0.0))

def rows(name):
    with (ROOT / 'data/raw' / name).open(newline='') as file:
        return list(csv.DictReader(file))

def reconcile():
    db = database()
    prod, scrap = rows('fact_production.csv'), rows('fact_scrap.csv')
    pkeys = {(r['date_id'], r['line_code'], r['sku']) for r in prod}
    orphans = [r for r in scrap if (r['date_id'],r['line_code'],r['sku']) not in pkeys]
    if orphans:
        raise ValueError(f'{len(orphans)} scrap rows lack a matching production key')
    if len(pkeys) != len(prod):
        raise ValueError('Production CSV violates expected date/line/product grain')
    if any(int(r['units_produced']) < 0 for r in prod) or any(int(r['units_scrapped']) < 0 for r in scrap):
        raise ValueError('Negative unit count')
    db.executemany('INSERT INTO sra.fact_production VALUES(?,?,?,?)', [(r['date_id'],r['line_code'],r['sku'],int(r['units_produced'])) for r in prod])
    db.executemany('INSERT INTO sra.fact_scrap VALUES(?,?,?,?,?)', [(r['date_id'],r['line_code'],r['sku'],r['defect_code'],int(r['units_scrapped'])) for r in scrap])
    db.executemany('INSERT INTO sra.dim_line VALUES(?,?)', [(r['line_code'],r['line_code']) for r in rows('dim_line.csv')])
    p, s = sum(int(r['units_produced']) for r in prod), sum(int(r['units_scrapped']) for r in scrap)
    daily = db.execute('SELECT SUM(units_produced),SUM(units_scrapped) FROM sra.v_scrap_daily').fetchone()
    line = db.execute('SELECT SUM(units_produced),SUM(units_scrapped) FROM sra.v_scrap_by_line').fetchone()
    assert daily == line == (p,s), 'SQL totals do not reconcile with CSV facts'
    result = {'scope':'Synthetic data; SQLite aggregation compatibility check, not a PostgreSQL integration test', 'production_rows':len(prod), 'scrap_rows':len(scrap), 'orphan_scrap_rows':len(orphans), 'units_produced':p, 'units_scrapped':s, 'weighted_scrap_rate_pct':round(100*s/p,4), 'daily_and_line_totals_match':True, 'source_sha256':{name:hashlib.sha256((ROOT/'data/raw'/name).read_bytes()).hexdigest() for name in ['fact_production.csv','fact_scrap.csv']}}
    target = ROOT / 'reports/reconciliation.json'
    target.parent.mkdir(exist_ok=True)
    target.write_text(json.dumps(result,indent=2)+'\n')
    print(json.dumps(result,indent=2))

if __name__ == '__main__':
    suite = unittest.defaultTestLoader.loadTestsFromTestCase(AggregationChecks)
    if not unittest.TextTestRunner().run(suite).wasSuccessful():
        raise SystemExit(1)
    reconcile()
