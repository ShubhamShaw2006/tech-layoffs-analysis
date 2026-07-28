-- schema.sql
 
CREATE TABLE IF NOT EXISTS layoffs (
    id                  SERIAL PRIMARY KEY,
    company             VARCHAR(255) NOT NULL,
    location            VARCHAR(255),
    industry            VARCHAR(100),
    total_laid_off      INTEGER,
    percentage_laid_off NUMERIC(5,2),
    date                DATE,
    stage               VARCHAR(100),
    stage_group         VARCHAR(50),
    funds_raised        NUMERIC(12,2),
    country             VARCHAR(100),
    source              TEXT,
    date_added          DATE,
    year                INTEGER,
    month               VARCHAR(7)
);
 
-- Index on date and industry since those will be common filter/group-by columns
CREATE INDEX idx_layoffs_date ON layoffs(date);
CREATE INDEX idx_layoffs_industry ON layoffs(industry);
CREATE INDEX idx_layoffs_stage_group ON layoffs(stage_group);