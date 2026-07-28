-- risk_score.sql
-- Builds a company-level risk score combining:
--   1. Stage risk       (from Finding 1: early-stage cuts deeper)
--   2. Funding risk      (from Finding 2: less funding = deeper cuts)
--   3. Industry risk      (from Finding 3: avg severity by industry)
--   4. Repeat-layoff risk  (from Finding 4: repeat offenders are a red flag)
--
-- Each factor is scored 0-10 (10 = highest risk), then combined with weights.
-- Run this once to create the table; re-run CREATE OR REPLACE to rebuild it
-- if your underlying data changes.

DROP TABLE IF EXISTS risk_scores;

CREATE TABLE risk_scores AS

WITH company_stats AS (
    -- One row per company, with the info we need to score it
    SELECT
        company,
        MAX(stage_group) AS stage_group,        -- most recent-looking value; simplification, fine for this use
        MAX(industry) AS industry,
        MAX(funds_raised) AS funds_raised,
        COUNT(*) AS layoff_rounds,
        SUM(total_laid_off) AS total_laid_off_all_rounds,
        MAX(date) AS most_recent_layoff
    FROM layoffs
    GROUP BY company
),

industry_severity AS (
    -- Avg % workforce cut per industry, reused from Q2 logic
    SELECT industry, AVG(percentage_laid_off) AS avg_industry_severity
    FROM layoffs
    WHERE percentage_laid_off IS NOT NULL
    GROUP BY industry
),

scored AS (
    SELECT
        cs.company,
        cs.industry,
        cs.stage_group,
        cs.funds_raised,
        cs.layoff_rounds,
        cs.total_laid_off_all_rounds,
        cs.most_recent_layoff,

        -- Stage risk: mirrors Finding 1 (Early=highest risk, Late=lowest)
        CASE cs.stage_group
            WHEN 'Early' THEN 10
            WHEN 'Unknown' THEN 7
            WHEN 'Growth' THEN 5
            WHEN 'Mature/Exit' THEN 4
            WHEN 'Late' THEN 2
            ELSE 5
        END AS stage_risk,

        -- Funding risk: mirrors Finding 2 (less funding = higher risk)
        CASE
            WHEN cs.funds_raised IS NULL THEN 6
            WHEN cs.funds_raised < 10 THEN 10
            WHEN cs.funds_raised < 100 THEN 7
            WHEN cs.funds_raised < 500 THEN 4
            ELSE 2
        END AS funding_risk,

        -- Repeat-layoff risk: more rounds = higher risk, capped at 10
        LEAST(cs.layoff_rounds * 2, 10) AS repeat_risk,

        COALESCE(ind.avg_industry_severity, 0.20) * 10 AS industry_risk  -- scale 0-1 severity to 0-10

    FROM company_stats cs
    LEFT JOIN industry_severity ind ON cs.industry = ind.industry
)

SELECT
    company,
    industry,
    stage_group,
    funds_raised,
    layoff_rounds,
    total_laid_off_all_rounds,
    most_recent_layoff,
    stage_risk,
    funding_risk,
    repeat_risk,
    ROUND(industry_risk::numeric, 2) AS industry_risk,

    -- Weighted composite score, 0-10 scale.
    -- Weights: stage 30%, funding 30%, repeat history 25%, industry 15%
    -- These weights reflect how strong each signal was in the findings -
    -- stage and funding had the clearest, most dramatic splits (Findings 1 & 2),
    -- so they're weighted highest.
    ROUND((
        stage_risk * 0.30 +
        funding_risk * 0.30 +
        repeat_risk * 0.25 +
        industry_risk * 0.15
    )::numeric, 2) AS composite_risk_score

FROM scored
ORDER BY composite_risk_score DESC;


-- Quick check: see your highest and lowest risk companies
SELECT * FROM risk_scores ORDER BY composite_risk_score DESC LIMIT 15;
SELECT * FROM risk_scores ORDER BY composite_risk_score ASC LIMIT 15;