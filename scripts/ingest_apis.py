"""
ingest_apis.py
Pulls two external data sources and loads them into PostgreSQL:

1. yfinance  -> stock price ~30 days before/after each public company's layoff date
2. BLS API   -> monthly unemployment rate for the "Information" sector (covers tech)

Run from the scripts/ folder:
    python ingest_apis.py
"""

import pandas as pd
import yfinance as yf
import requests
import os
import json
from datetime import timedelta
from sqlalchemy import create_engine
from dotenv import load_dotenv

load_dotenv()

DB_USER = os.getenv('DB_USER')
DB_PASSWORD = os.getenv('DB_PASSWORD')
DB_HOST = os.getenv('DB_HOST', 'localhost')
DB_PORT = os.getenv('DB_PORT', '5432')
DB_NAME = os.getenv('DB_NAME')
BLS_API_KEY = os.getenv('BLS_API_KEY')

engine = create_engine(
    f'postgresql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}'
)

# =========================================================
# PART 1: yfinance - stock prices around layoff dates
# =========================================================

def get_stock_snapshot(ticker, layoff_date):
    """
    Fetch closing price ~30 days before, on/near, and ~30 days after a given date.
    Returns None values if data isn't available (e.g. date too recent, ticker delisted).
    """
    start = layoff_date - timedelta(days=35)
    end = layoff_date + timedelta(days=35)

    try:
        hist = yf.download(ticker, start=start, end=end, progress=False)
    except Exception as e:
        print(f"  [ERROR] Failed to fetch {ticker}: {e}")
        return None, None, None

    if hist.empty:
        print(f"  [WARN] No data returned for {ticker} around {layoff_date}")
        return None, None, None

    # Recent yfinance versions return multi-level columns (e.g. ('Close', 'AMZN'))
    # even for a single ticker - flatten to plain column names so hist['Close']
    # is a simple Series, not a nested DataFrame.
    if isinstance(hist.columns, pd.MultiIndex):
        hist.columns = hist.columns.get_level_values(0)

    # Closest available trading day to each target date
    before_target = layoff_date - timedelta(days=30)
    after_target = layoff_date + timedelta(days=30)

    def closest_price(target_date):
        idx = hist.index[hist.index.get_indexer([pd.Timestamp(target_date)], method='nearest')]
        return float(hist.loc[idx, 'Close'].iloc[0]) if len(idx) else None

    price_before = closest_price(before_target)
    price_on = closest_price(layoff_date)
    price_after = closest_price(after_target)

    return price_before, price_on, price_after


def run_stock_ingestion():
    print("=== Pulling stock data via yfinance ===")

    # Load ticker mapping
    tickers_df = pd.read_csv('data/mapping/company_tickers.csv')

    # Load layoffs data, keep only companies we have tickers for
    layoffs_df = pd.read_csv('data/processed/layoffs_clean.csv', parse_dates=['date'])
    merged = layoffs_df.merge(tickers_df, on='company', how='inner')

    print(f"Found {len(merged)} layoff events matching {merged['company'].nunique()} public companies")

    results = []
    for _, row in merged.iterrows():
        ticker = row['ticker']
        layoff_date = row['date']
        print(f"Fetching {ticker} around {layoff_date.date()}...")

        price_before, price_on, price_after = get_stock_snapshot(ticker, layoff_date)

        pct_change_before = (
            round((price_on - price_before) / price_before * 100, 2)
            if price_before and price_on else None
        )
        pct_change_after = (
            round((price_after - price_on) / price_on * 100, 2)
            if price_after and price_on else None
        )

        results.append({
            'company': row['company'],
            'ticker': ticker,
            'layoff_date': layoff_date,
            'price_30d_before': price_before,
            'price_on_layoff_day': price_on,
            'price_30d_after': price_after,
            'pct_change_before': pct_change_before,
            'pct_change_after': pct_change_after
        })

    stock_df = pd.DataFrame(results)
    stock_df.to_sql('stock_snapshots', engine, if_exists='append', index=False)
    print(f"Loaded {len(stock_df)} stock snapshot rows into PostgreSQL")


# =========================================================
# PART 2: BLS API - sector unemployment rate
# =========================================================

def run_bls_ingestion():
    print("=== Pulling unemployment data via BLS API ===")

    # NOTE: verify this series ID is correct on https://data.bls.gov before relying on it -
    # search "Information sector unemployment rate" on the BLS site and confirm the ID.
    # This one targets the LNS-series unemployment rate for the Information sector.
    series_id = 'LNU04032231'

    headers = {'Content-type': 'application/json'}
    payload = json.dumps({
        "seriesid": [series_id],
        "startyear": "2019",
        "endyear": "2026",
        "registrationkey": BLS_API_KEY
    })

    response = requests.post(
        'https://api.bls.gov/publicAPI/v2/timeseries/data/',
        data=payload,
        headers=headers
    )
    data = response.json()

    if data.get('status') != 'REQUEST_SUCCEEDED':
        print("  [ERROR] BLS API request failed:", data.get('message'))
        return

    records = data['Results']['series'][0]['data']
    rows = []
    skipped = 0
    for r in records:
        # BLS returns period like 'M01' for January - convert to a real month number
        month_num = r['period'].replace('M', '')
        if month_num == '13':  # M13 is an annual average row, skip it
            continue
        if r['value'] == '-':  # BLS uses '-' for suppressed/unavailable data points
            skipped += 1
            continue
        rows.append({
            'year_month': f"{r['year']}-{month_num}",
            'sector': 'Information',
            'unemployment_rate': float(r['value'])
        })

    if skipped:
        print(f"  Skipped {skipped} rows with no reported value ('-')")

    macro_df = pd.DataFrame(rows)
    macro_df.to_sql('macro_trends', engine, if_exists='append', index=False)
    print(f"Loaded {len(macro_df)} macro trend rows into PostgreSQL")


if __name__ == '__main__':
    run_stock_ingestion()
    run_bls_ingestion()
    print("Done.")