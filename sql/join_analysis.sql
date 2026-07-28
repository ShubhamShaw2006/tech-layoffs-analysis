-- join_analysis.sql
-- Combines layoffs with stock_snapshots and macro_trends to test whether
-- warning signs were visible before layoffs happened.

-- ============================================================
-- Q9: DID STOCK PRICE ALREADY DECLINE BEFORE THE LAYOFF WAS ANNOUNCED?
-- ============================================================
-- pct_change_before = % stock price moved in the 30 days leading up to the layoff.
-- Negative = price was already falling before the announcement.
SELECT
    l.company,
    l.date,
    l.total_laid_off,
    l.percentage_laid_off,
    s.pct_change_before,
    s.pct_change_after
FROM layoffs l
JOIN stock_snapshots s
    ON l.company = s.company AND l.date = s.layoff_date
WHERE s.pct_change_before IS NOT NULL
ORDER BY s.pct_change_before ASC;  -- worst pre-layoff stock decline first


-- ============================================================
-- Q10: AVERAGE STOCK BEHAVIOR AROUND LAYOFFS (aggregate signal check)
-- ============================================================
-- Why: a single event is noise, the average across all events is a real signal
SELECT
    ROUND(AVG(pct_change_before)::numeric, 2) AS avg_pct_change_before_layoff,
    ROUND(AVG(pct_change_after)::numeric, 2) AS avg_pct_change_after_layoff,
    COUNT(*) AS events_with_data
FROM stock_snapshots
WHERE pct_change_before IS NOT NULL AND pct_change_after IS NOT NULL;


-- ============================================================
-- Q11: WAS SECTOR UNEMPLOYMENT ALREADY RISING BEFORE MAJOR LAYOFF MONTHS?
-- ============================================================
-- Joins on year_month so we can see if the macro trend led or lagged the layoffs
SELECT
    l.month,
    COUNT(*) AS layoff_events,
    SUM(l.total_laid_off) AS total_people_laid_off,
    m.unemployment_rate AS sector_unemployment_rate
FROM layoffs l
LEFT JOIN macro_trends m
    ON l.month = m.year_month AND m.sector = 'Information'
WHERE l.total_laid_off IS NOT NULL
GROUP BY l.month, m.unemployment_rate
ORDER BY l.month;