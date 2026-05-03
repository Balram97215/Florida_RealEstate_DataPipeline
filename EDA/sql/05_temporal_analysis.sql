-- ============================================================
-- EDA 05: Temporal Analysis
-- Year built trends, construction eras, sale year patterns
-- ============================================================

-- 5a. Effective year built distribution (decade buckets)
SELECT 'year_built_decades' AS section;
SELECT
    CASE
        WHEN EFF_YR_BLT IS NULL OR EFF_YR_BLT = 0 THEN 'Unknown/Vacant'
        WHEN EFF_YR_BLT < 1900  THEN 'Before 1900'
        WHEN EFF_YR_BLT < 1950  THEN '1900-1949'
        WHEN EFF_YR_BLT < 1960  THEN '1950-1959'
        WHEN EFF_YR_BLT < 1970  THEN '1960-1969'
        WHEN EFF_YR_BLT < 1980  THEN '1970-1979'
        WHEN EFF_YR_BLT < 1990  THEN '1980-1989'
        WHEN EFF_YR_BLT < 2000  THEN '1990-1999'
        WHEN EFF_YR_BLT < 2010  THEN '2000-2009'
        WHEN EFF_YR_BLT < 2020  THEN '2010-2019'
        ELSE '2020+'
    END AS era,
    COUNT(*) AS parcel_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER(), 2) AS pct_of_total,
    ROUND(AVG(JV), 0) AS avg_just_value,
    ROUND(AVG(TOT_LVG_AR), 0) AS avg_living_area
FROM parcels
GROUP BY era
ORDER BY MIN(COALESCE(NULLIF(EFF_YR_BLT, 0), 9999));

-- 5b. Year-by-year construction (last 30 years)
SELECT 'recent_construction_by_year' AS section;
SELECT
    CAST(EFF_YR_BLT AS INTEGER) AS year_built,
    COUNT(*) AS parcels_built,
    ROUND(AVG(JV), 0) AS avg_just_value,
    ROUND(AVG(TOT_LVG_AR), 0) AS avg_living_area
FROM parcels
WHERE EFF_YR_BLT >= 1995 AND EFF_YR_BLT <= 2025
GROUP BY EFF_YR_BLT
ORDER BY EFF_YR_BLT;

-- 5c. Building age vs value relationship
SELECT 'age_vs_value' AS section;
SELECT
    CASE
        WHEN EFF_YR_BLT IS NULL OR EFF_YR_BLT = 0 THEN 'No Year'
        WHEN 2025 - EFF_YR_BLT <= 5   THEN '0-5 years'
        WHEN 2025 - EFF_YR_BLT <= 10  THEN '6-10 years'
        WHEN 2025 - EFF_YR_BLT <= 20  THEN '11-20 years'
        WHEN 2025 - EFF_YR_BLT <= 30  THEN '21-30 years'
        WHEN 2025 - EFF_YR_BLT <= 50  THEN '31-50 years'
        ELSE '50+ years'
    END AS age_bucket,
    COUNT(*) AS parcel_count,
    ROUND(AVG(JV), 0) AS avg_just_value,
    ROUND(MEDIAN(JV), 0) AS median_just_value,
    ROUND(AVG(CASE WHEN TOT_LVG_AR > 0 THEN JV * 1.0 / TOT_LVG_AR END), 2) AS avg_value_per_sqft
FROM parcels
GROUP BY age_bucket
ORDER BY MIN(COALESCE(NULLIF(EFF_YR_BLT, 0), 9999)) DESC;

-- 5d. Sale year distribution
SELECT 'sale_year_distribution' AS section;
SELECT
    sale_year,
    COUNT(*) AS sale_count,
    ROUND(AVG(sale_price), 0) AS avg_sale_price,
    ROUND(MEDIAN(sale_price), 0) AS median_sale_price,
    SUM(sale_price) AS total_volume
FROM sales
WHERE sale_year >= 1990 AND sale_year <= 2025
GROUP BY sale_year
ORDER BY sale_year;
