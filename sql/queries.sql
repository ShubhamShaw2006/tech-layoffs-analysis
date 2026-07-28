-- queries.sql
-- Core analysis queries for the layoffs dataset

-- ============================================================
-- Q1: TREND OVER TIME - How have layoffs moved month by month?
-- ============================================================
-- Why: establishes the baseline trend before digging into "why"
SELECT
    month,
    COUNT(*) AS layoff_events,
    SUM(total_laid_off) AS total_people_laid_off
FROM layoffs
WHERE total_laid_off IS NOT NULL
GROUP BY month
ORDER BY month;


-- ============================================================
-- Q2: WORST-HIT INDUSTRIES - Which industries lost the most people overall?
-- ============================================================
-- Why: identifies which sectors to flag as historically risky
SELECT
    industry,
    COUNT(*) AS layoff_events,
    SUM(total_laid_off) AS total_people_laid_off,
    ROUND(AVG(percentage_laid_off), 2) AS avg_pct_of_workforce_cut
FROM layoffs
WHERE total_laid_off IS NOT NULL
GROUP BY industry
ORDER BY total_people_laid_off DESC;


-- ============================================================
-- Q3: FUNDING STAGE VS LAYOFF SEVERITY
-- ============================================================
-- Why: tests the hypothesis "does company maturity affect how deep the cuts go?"
-- Uses percentage_laid_off (not headcount) since it's a fairer comparison
-- across companies of very different sizes
SELECT
    stage_group,
    COUNT(*) AS layoff_events,
    ROUND(AVG(percentage_laid_off), 2) AS avg_pct_workforce_cut,
    ROUND(AVG(funds_raised), 1) AS avg_funds_raised_millions
FROM layoffs
WHERE percentage_laid_off IS NOT NULL
GROUP BY stage_group
ORDER BY avg_pct_workforce_cut DESC;


-- ============================================================
-- Q4: DOES MORE FUNDING MEAN MORE SAFETY? (the "money doesn't equal safety" test)
-- ============================================================
-- Why: directly tests the assumption that well-funded companies are "safer bets"
-- Buckets companies into funding tiers, then checks average layoff severity in each
SELECT
    CASE
        WHEN funds_raised IS NULL THEN 'Undisclosed'
        WHEN funds_raised < 10 THEN 'Under $10M'
        WHEN funds_raised < 100 THEN '$10M - $100M'
        WHEN funds_raised < 500 THEN '$100M - $500M'
        ELSE 'Over $500M'
    END AS funding_tier,
    COUNT(*) AS layoff_events,
    ROUND(AVG(percentage_laid_off), 2) AS avg_pct_workforce_cut
FROM layoffs
WHERE percentage_laid_off IS NOT NULL
GROUP BY funding_tier
ORDER BY avg_pct_workforce_cut DESC;


-- ============================================================
-- Q5: TOP 10 SINGLE LARGEST LAYOFF EVENTS
-- ============================================================
-- Why: useful headline stat, also good for spotting outliers that might skew averages
SELECT
    company,
    industry,
    country,
    date,
    total_laid_off,
    percentage_laid_off
FROM layoffs
WHERE total_laid_off IS NOT NULL
ORDER BY total_laid_off DESC
LIMIT 10;


-- ============================================================
-- Q6: GEOGRAPHIC CONCENTRATION - which countries got hit hardest?
-- ============================================================
SELECT
    country,
    COUNT(*) AS layoff_events,
    SUM(total_laid_off) AS total_people_laid_off
FROM layoffs
WHERE total_laid_off IS NOT NULL
GROUP BY country
ORDER BY total_people_laid_off DESC
LIMIT 15;


-- ============================================================
-- Q7: RECENT TREND - is it accelerating or slowing down? (last 6 months vs prior 6)
-- ============================================================
-- Why: answers "is this getting better or worse right now" - a genuinely current
-- question a job-seeker would care about
WITH monthly_totals AS (
    SELECT month, SUM(total_laid_off) AS monthly_laid_off
    FROM layoffs
    WHERE total_laid_off IS NOT NULL
    GROUP BY month
)
SELECT month, monthly_laid_off,
       AVG(monthly_laid_off) OVER (
           ORDER BY month
           ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
       ) AS rolling_3mo_avg
FROM monthly_totals
ORDER BY month;


-- ============================================================
-- Q8: COMPANIES WITH REPEATED LAYOFFS
-- ============================================================
-- Why: repeated layoffs at the same company is itself a strong risk signal
SELECT
    company,
    COUNT(*) AS layoff_rounds,
    SUM(total_laid_off) AS total_people_laid_off_all_rounds,
    MIN(date) AS first_layoff,
    MAX(date) AS most_recent_layoff
FROM layoffs
WHERE total_laid_off IS NOT NULL
GROUP BY company
HAVING COUNT(*) > 1
ORDER BY layoff_rounds DESC, total_people_laid_off_all_rounds DESC;