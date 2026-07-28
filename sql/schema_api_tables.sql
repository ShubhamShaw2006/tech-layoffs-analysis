-- schema_api_tables.sql
-- New tables for API-sourced data: stock prices and sector unemployment

CREATE TABLE IF NOT EXISTS stock_snapshots (
    id                  SERIAL PRIMARY KEY,
    company             VARCHAR(255) NOT NULL,
    ticker              VARCHAR(10) NOT NULL,
    layoff_date         DATE NOT NULL,
    price_30d_before    NUMERIC(10,2),
    price_on_layoff_day NUMERIC(10,2),
    price_30d_after     NUMERIC(10,2),
    pct_change_before   NUMERIC(6,2),  -- price movement in the 30 days leading up to the layoff
    pct_change_after    NUMERIC(6,2)   -- price movement in the 30 days following
);

CREATE TABLE IF NOT EXISTS macro_trends (
    id                  SERIAL PRIMARY KEY,
    year_month          VARCHAR(7) NOT NULL,   -- format: 'YYYY-MM'
    sector              VARCHAR(100) NOT NULL,
    unemployment_rate   NUMERIC(5,2)
);