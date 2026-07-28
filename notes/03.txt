# Key Findings — Tech Layoffs Analysis

## Dataset Overview
- 4,523 layoff events, spanning March 2020 to present
- Covers 31 industries, 17 funding stages, 67 countries
- ~35% of rows missing exact headcount (`total_laid_off`), ~37% missing percentage — both left as-is (not filled) since guessing would distort the analysis. Any finding using these numbers implicitly excludes rows where that field wasn't reported.

## Finding 1: Funding stage strongly predicts how deep the cuts go — not whether they happen
Grouping companies into broader stages:

| Stage Group | Avg % of Workforce Cut | Avg Funds Raised ($M) |
|---|---|---|
| Early (Seed–Series B) | 48% | 71.8 |
| Growth (Series C–E) | 22% | 356.7 |
| Late (Series F–J) | 15% | 1,136.0 |
| Mature/Exit (Post-IPO, Acquired, PE, Subsidiary) | 20% | 1,623.3 |

**Takeaway:** Early-stage companies don't just lay off — when they do, they cut nearly half their workforce on average. Late-stage and mature companies lay off far more conservatively, likely because they have more runway and don't need to gut the org to survive.

## Finding 2: More funding = shallower cuts (confirmed independently)
Bucketing by total funds raised, regardless of stage:

| Funding Raised | Avg % of Workforce Cut |
|---|---|
| Under $10M | 61% |
| Undisclosed | 40% |
| $10M – $100M | 38% |
| $100M – $500M | 21% |
| Over $500M | 18% |

**Takeaway:** This confirms Finding 1 from a different angle. Funding doesn't prevent layoffs, but it clearly correlates with less severe ones. A company raising under $10M that lays off is a much bigger red flag than a well-funded company doing the same.

## Finding 3: Industry severity depends on which lens you use
- **By raw headcount lost:** Retail, Hardware, Consumer, and Finance lost the most people overall (100K+ each)
- **By severity (% of workforce cut):** Aerospace (40%), Energy (30%), Food/Healthcare/Construction (~29%) were hit hardest proportionally, despite having fewer total layoff events

**Takeaway:** A large industry can have huge headcount losses without necessarily being "risky" per company — smaller industries with high average % cuts may actually be riskier bets individually.

## Finding 4: Repeat layoffs are common at the largest tech companies
Top repeat offenders by number of separate layoff rounds:

| Company | Rounds | Total Laid Off | First → Most Recent |
|---|---|---|---|
| Amazon | 15 | 59,291 | 2022 → 2026 |
| Salesforce | 13 | 16,611 | 2020 → 2026 |
| Microsoft | 11 | 34,855 | 2023 → 2026 |
| Google | 10 | 13,697 | 2023 → 2025 |
| Intel | 9 | 43,115 | 2022 → 2025 |
| Meta | 9 | 35,700 | 2022 → 2026 |

**Takeaway:** Big Tech layoffs aren't one-time corrections — they're recurring. A company having laid off once is not a reliable signal that it's "done"; several of the largest companies have cut staff in 5+ separate rounds over multiple years.

## Finding 5: Layoffs spiked sharply in two distinct waves
- **Wave 1 (COVID):** April–May 2020, peaking around 26–27K/month, driven by pandemic shutdowns
- **Wave 2 (Tech correction):** Ramped from mid-2022, peaking at **~90K in January 2023** — the largest single month in the dataset — and has stayed elevated since, rather than returning to pre-2022 baseline levels

**Takeaway:** The current layoff environment (2023–present) is structurally different and more sustained than the COVID-era spike, which was sharp but short-lived.

## Implications for Job Seekers (the "so what")
Based on these findings, a simple heuristic for evaluating employer risk:
1. **Check funding stage and amount** — early-stage/low-funded companies carry meaningfully higher layoff-severity risk
2. **Check layoff history** — a company with multiple past rounds is more likely to have another, not less
3. **Don't rely on industry alone** — a "safe-looking" large industry can still have high-severity individual companies

These three factors form the basis of the risk score to be built in Phase 6.