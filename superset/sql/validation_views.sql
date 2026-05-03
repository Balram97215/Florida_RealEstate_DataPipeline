-- ============================================================
-- CROSS-VALIDATION VIEWS
-- These views reproduce EDA output numbers exactly so you can
-- compare Superset dashboard values against known-good EDA results.
--
-- Usage: Query each view and compare against the matching CSV
--        in EDA/output/
-- ============================================================

-- ────────────────────────────────────────────────────────────
-- CV-01: Table Row Counts
-- Compare with: 01_overview_table_row_counts.csv
-- Expected: parcels=10,834,415 | sales=1,491,760
-- ────────────────────────────────────────────────────────────
CREATE OR REPLACE VIEW v_cv_table_row_counts AS
SELECT 'parcels' AS table_name, COUNT(*) AS row_count FROM parcels
UNION ALL
SELECT 'sales', COUNT(*) FROM sales
UNION ALL
SELECT 'ref_land_use', COUNT(*) FROM ref_land_use
UNION ALL
SELECT 'ref_county', COUNT(*) FROM ref_county;


-- ────────────────────────────────────────────────────────────
-- CV-02: Land Use Category Distribution
-- Compare with: 03_categorical_profile_land_use_category_distribution.csv
-- ────────────────────────────────────────────────────────────
CREATE OR REPLACE VIEW v_cv_land_use_distribution AS
SELECT
    land_use_category,
    COUNT(*)                                          AS parcel_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER(), 2) AS pct_of_total,
    ROUND(AVG(JV), 0)                                AS avg_just_value
FROM parcels
GROUP BY land_use_category
ORDER BY parcel_count DESC;


-- ────────────────────────────────────────────────────────────
-- CV-03: Valuation Statistics
-- Compare with: 04_numerical_profile_valuation_stats.csv
-- Expected: JV mean=485,242 | median=269,456 | max=1,224,794,027
-- ────────────────────────────────────────────────────────────
CREATE OR REPLACE VIEW v_cv_valuation_stats AS
SELECT
    -- Just Value
    COUNT(JV) AS jv_count,
    ROUND(AVG(JV), 2) AS jv_mean,
    ROUND(STDDEV(JV), 2) AS jv_std,
    MIN(JV) AS jv_min,
    ROUND(PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY JV), 0) AS jv_p25,
    ROUND(MEDIAN(JV), 0) AS jv_median,
    ROUND(PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY JV), 0) AS jv_p75,
    ROUND(PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY JV), 2) AS jv_p95,
    ROUND(PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY JV), 2) AS jv_p99,
    MAX(JV) AS jv_max,
    -- Land Value
    COUNT(LND_VAL) AS lnd_val_count,
    ROUND(AVG(LND_VAL), 2) AS lnd_val_mean,
    ROUND(MEDIAN(LND_VAL), 0) AS lnd_val_median,
    MAX(LND_VAL) AS lnd_val_max,
    -- Taxable Value
    COUNT(TV_SD) AS tv_sd_count,
    ROUND(AVG(TV_SD), 2) AS tv_sd_mean,
    ROUND(MEDIAN(TV_SD), 0) AS tv_sd_median,
    MAX(TV_SD) AS tv_sd_max
FROM parcels;


-- ────────────────────────────────────────────────────────────
-- CV-04: Valuation by County (top 10)
-- Compare with: 06_valuation_analysis_valuation_by_county.csv
-- ────────────────────────────────────────────────────────────
CREATE OR REPLACE VIEW v_cv_valuation_by_county AS
SELECT
    county_name,
    COUNT(*) AS parcel_count,
    ROUND(SUM(JV) / 1e9, 2) AS total_jv_billions,
    ROUND(AVG(JV), 0) AS avg_jv,
    ROUND(MEDIAN(JV), 0) AS median_jv,
    ROUND(AVG(LND_VAL), 0) AS avg_land_value,
    ROUND(AVG(CASE WHEN TOT_LVG_AR > 0 THEN JV * 1.0 / TOT_LVG_AR END), 2) AS avg_value_per_sqft
FROM parcels
GROUP BY county_name
ORDER BY total_jv_billions DESC;


-- ────────────────────────────────────────────────────────────
-- CV-05: Sales Overview
-- Compare with: 07_sales_analysis_sales_overview.csv
-- Expected: total_sales=1,491,760 | avg=744,714 | median=162,000
-- ────────────────────────────────────────────────────────────
CREATE OR REPLACE VIEW v_cv_sales_overview AS
SELECT
    COUNT(*) AS total_sales,
    COUNT(DISTINCT PARCEL_ID) AS unique_parcels_sold,
    ROUND(AVG(sale_price), 0) AS avg_sale_price,
    ROUND(MEDIAN(sale_price), 0) AS median_sale_price,
    MIN(sale_price) AS min_sale_price,
    MAX(sale_price) AS max_sale_price,
    ROUND(SUM(sale_price) / 1e9, 2) AS total_volume_billions
FROM sales;


-- ────────────────────────────────────────────────────────────
-- CV-06: Sales by County
-- Compare with: 07_sales_analysis_sales_by_county.csv
-- ────────────────────────────────────────────────────────────
CREATE OR REPLACE VIEW v_cv_sales_by_county AS
SELECT
    county_name,
    COUNT(*) AS sale_count,
    ROUND(AVG(sale_price), 0) AS avg_price,
    ROUND(MEDIAN(sale_price), 0) AS median_price,
    ROUND(SUM(sale_price) / 1e9, 2) AS total_volume_billions
FROM sales
GROUP BY county_name
ORDER BY total_volume_billions DESC;


-- ────────────────────────────────────────────────────────────
-- CV-07: Homestead Analysis
-- Compare with: 06_valuation_analysis_homestead_analysis.csv
-- ────────────────────────────────────────────────────────────
CREATE OR REPLACE VIEW v_cv_homestead_analysis AS
SELECT
    CASE WHEN JV_HMSTD > 0 THEN 'Homesteaded' ELSE 'Non-Homesteaded' END AS homestead_status,
    COUNT(*) AS parcel_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER(), 2) AS pct_of_total,
    ROUND(AVG(JV), 0) AS avg_jv,
    ROUND(MEDIAN(JV), 0) AS median_jv,
    ROUND(AVG(TV_SD), 0) AS avg_taxable_value,
    ROUND(AVG(TOT_LVG_AR), 0) AS avg_living_area
FROM parcels
GROUP BY homestead_status
ORDER BY parcel_count DESC;


-- ────────────────────────────────────────────────────────────
-- CV-08: Year Built Decades
-- Compare with: 05_temporal_analysis_year_built_decades.csv
-- ────────────────────────────────────────────────────────────
CREATE OR REPLACE VIEW v_cv_year_built_decades AS
SELECT
    CASE
        WHEN EFF_YR_BLT = 0 OR EFF_YR_BLT IS NULL THEN 'Unknown/Vacant'
        WHEN EFF_YR_BLT < 1900                     THEN 'Before 1900'
        WHEN EFF_YR_BLT BETWEEN 1900 AND 1949      THEN '1900-1949'
        WHEN EFF_YR_BLT BETWEEN 1950 AND 1959      THEN '1950-1959'
        WHEN EFF_YR_BLT BETWEEN 1960 AND 1969      THEN '1960-1969'
        WHEN EFF_YR_BLT BETWEEN 1970 AND 1979      THEN '1970-1979'
        WHEN EFF_YR_BLT BETWEEN 1980 AND 1989      THEN '1980-1989'
        WHEN EFF_YR_BLT BETWEEN 1990 AND 1999      THEN '1990-1999'
        WHEN EFF_YR_BLT BETWEEN 2000 AND 2009      THEN '2000-2009'
        WHEN EFF_YR_BLT BETWEEN 2010 AND 2019      THEN '2010-2019'
        ELSE '2020+'
    END AS era,
    COUNT(*) AS parcel_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER(), 2) AS pct_of_total,
    ROUND(AVG(JV), 0) AS avg_just_value,
    ROUND(AVG(TOT_LVG_AR), 0) AS avg_living_area
FROM parcels
GROUP BY era
ORDER BY
    CASE era
        WHEN 'Unknown/Vacant' THEN 0
        WHEN 'Before 1900' THEN 1
        WHEN '1900-1949' THEN 2
        WHEN '1950-1959' THEN 3
        WHEN '1960-1969' THEN 4
        WHEN '1970-1979' THEN 5
        WHEN '1980-1989' THEN 6
        WHEN '1990-1999' THEN 7
        WHEN '2000-2009' THEN 8
        WHEN '2010-2019' THEN 9
        WHEN '2020+' THEN 10
    END;


-- ────────────────────────────────────────────────────────────
-- CV-09: County Distribution (parcel counts)
-- Compare with: 03_categorical_profile_county_distribution.csv
-- ────────────────────────────────────────────────────────────
CREATE OR REPLACE VIEW v_cv_county_distribution AS
SELECT
    county_name,
    COUNT(*) AS parcel_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER(), 2) AS pct_of_total
FROM parcels
GROUP BY county_name
ORDER BY parcel_count DESC;
