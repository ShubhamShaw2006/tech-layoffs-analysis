# Tech Layoffs Analysis: Risk Patterns 2020-2026

**Live Dashboard:** https://public.tableau.com/app/profile/shubham.shaw4256/viz/TechLayoffsAnalysisRiskPatterns2020-2026/TechLayoffsAnalysisRiskPatterns2020-2026

## Problem Statement
Since 2020, the tech industry has experienced repeated waves of layoffs, but the pattern isn't random. This project analyzes 4,500+ real layoff events to answer: **which types of companies are most vulnerable, and were there early warning signs visible before layoffs happened?**

The end goal is genuinely practical — a data-backed way for a job seeker (or workforce planner) to evaluate employer risk before joining a company.

## Data Sources
This project combines three independent data sources into one analysis:

1. **[Layoffs Dataset (Kaggle)](https://www.kaggle.com/datasets/swaptr/layoffs-2022)** — 4,523 tech layoff events, 2020-present, including company, industry, funding stage, headcount, and funds raised
2. **Yahoo Finance API (`yfinance`)** — stock price data for 24 public companies, ~30 days before/after each layoff event, to test whether stock price decline preceded layoff announcements
3. **U.S. Bureau of Labor Statistics API** — monthly unemployment rate for the Information sector, to test whether official macro data led or lagged company-level layoffs

## Tech Stack
- **Python** (pandas, numpy) — data cleaning and API ingestion
- **PostgreSQL** — relational database, schema design, analytical SQL (joins, window functions, CTEs)
- **APIs** — `yfinance` (financial data), BLS public API (government data), handled via `requests`
- **Tableau Public** — interactive dashboard and visualization
- **Git/GitHub** — version control

## Key Findings

1. **Funding stage strongly predicts layoff severity, not likelihood.** Early-stage companies cut an average of **48%** of their workforce when they lay off, vs. **15%** for late-stage companies.
2. **More funding raised correlates with shallower cuts.** Companies with under $10M raised cut an average of **61%** of staff; companies with over $500M raised cut only **18%**.
3. **Industry severity depends on the lens used.** By total headcount lost, Retail/Hardware/Consumer lead; by average % of workforce cut, Aerospace (40%) and Energy (30%) are the most severe.
4. **Repeat layoffs are common at major tech companies.** Amazon, Google, and Microsoft each had 15+ distinct layoff events over the dataset's timeframe — a single past layoff is not a reliable signal a company is "done."
5. **Stock price decline is not a reliable universal predictor** of layoffs (average pre-layoff stock movement was slightly positive across 209 events), though it was a strong signal in specific high-profile cases (Chegg, Intel, Wayfair all saw 25-40% declines beforehand).
6. **Sector unemployment data lags rather than leads.** The Nov 2022 layoff spike preceded the Jan 2023 unemployment rate peak by roughly two months — official government stats moved after company announcements, not before.

Full write-up with methodology in [`notes/findings.md`](notes/findings.md).

## Tableau Workbook
The full Tableau workbook (with embedded data extracts) is available at [`dashboard/tech_layoffs_dashboard.twbx`](dashboard/tech_layoffs_dashboard.twbx) — open with Tableau Public or Tableau Desktop to explore offline, no live database connection required.

## Repository Structure
```
tech-layoffs-analysis/
├── data/
│   ├── raw/              # original Kaggle CSV (not committed, see below)
│   ├── processed/        # cleaned data, exported tables for Tableau
│   └── mapping/          # company-to-stock-ticker mapping
├── notebooks/            # exploratory data analysis
├── scripts/
│   ├── clean_data.py     # data cleaning pipeline
│   ├── load_to_postgres.py
│   └── ingest_apis.py    # yfinance + BLS API integration
├── sql/
│   ├── schema.sql
│   ├── schema_api_tables.sql
│   ├── queries.sql       # core analysis queries
│   ├── join_analysis.sql # cross-table analysis
│   └── risk_score.sql    # composite risk scoring logic
├── dashboard/
│   └── tech_layoffs_dashboard.twbx   # packaged Tableau workbook with embedded data
├── notes/
│   └── findings.md
└── requirements.txt
```

*Note: the raw dataset isn't committed to this repo — download it from the [Kaggle link above](https://www.kaggle.com/datasets/swaptr/layoffs-2022) and place it at `data/raw/layoffs.csv` to reproduce the pipeline.*

## How to Reproduce
1. Clone the repo, create a virtual environment, `pip install -r requirements.txt`
2. Download the dataset from Kaggle, place at `data/raw/layoffs.csv`
3. Run `python scripts/clean_data.py`
4. Create a PostgreSQL database, run `sql/schema.sql` and `sql/schema_api_tables.sql`
5. Add your DB credentials and a free [BLS API key](https://data.bls.gov/registrationEngine/) to a `.env` file
6. Run `python scripts/load_to_postgres.py` then `python scripts/ingest_apis.py`
7. Explore `sql/queries.sql`, `sql/join_analysis.sql`, and `sql/risk_score.sql` in your SQL client
8. Export tables to CSV and connect Tableau Public to build/refresh the dashboard

## Challenges Faced
A few real debugging problems worth noting (details in commit history):
- **Mixed date formats** in the raw data (`4/13/2026` vs `04-12-2026`) required custom parsing logic rather than a single `pd.to_datetime()` call
- **`yfinance` returning multi-level columns** in recent versions broke price extraction — required flattening the column index
- **BLS API returning `"-"` for suppressed data points** instead of omitting them, which needed explicit handling
- **UTF-8 encoding mismatch** when exporting from PostgreSQL on Windows, due to non-ASCII characters in company names
- **Row-count discrepancy** between SQL query results and the Tableau dashboard, traced to two different valid definitions of "a layoff round" (headcount-disclosed events only vs. all reported events) — resolved by explicitly choosing and documenting the broader definition
- **Tableau Public's live-connection restriction** required converting all data sources to extracts before publishing

## Author
Shubham Shaw — [GitHub](https://github.com/ShubhamShaw2006) [LinkedIn](https://www.linkedin.com/in/shaw-shubham/)