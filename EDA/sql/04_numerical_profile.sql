-- ============================================================
-- EDA 04: Numerical Column Profiling
-- Descriptive statistics, percentiles, outlier detection
-- ============================================================

-- 4a. Valuation descriptive stats
SELECT 'valuation_stats' AS section;
SELECT
    -- Just Value (JV)
    COUNT(JV)                        AS jv_count,
    ROUND(AVG(JV), 2)               AS jv_mean,
    ROUND(STDDEV(JV), 2)            AS jv_std,
    MIN(JV)                          AS jv_min,
    PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY JV) AS jv_p25,
    PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY JV) AS jv_median,
    PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY JV) AS jv_p75,
    PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY JV) AS jv_p95,
    PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY JV) AS jv_p99,
    MAX(JV)                          AS jv_max,
    -- Land Value
    COUNT(LND_VAL)                   AS lnd_val_count,
    ROUND(AVG(LND_VAL), 2)          AS lnd_val_mean,
    PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY LND_VAL) AS lnd_val_median,
    MAX(LND_VAL)                     AS lnd_val_max,
    -- Taxable Value (School District)
    COUNT(TV_SD)                     AS tv_sd_count,
    ROUND(AVG(TV_SD), 2)            AS tv_sd_mean,
    PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY TV_SD) AS tv_sd_median,
    MAX(TV_SD)                       AS tv_sd_max
FROM parcels;

-- 4b. Building/structure stats
SELECT 'building_stats' AS section;
SELECT
    -- Total Living Area
    COUNT(TOT_LVG_AR)               AS lvg_ar_count,
    ROUND(AVG(TOT_LVG_AR), 0)      AS lvg_ar_mean,
    PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY TOT_LVG_AR) AS lvg_ar_median,
    PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY TOT_LVG_AR) AS lvg_ar_p95,
    MAX(TOT_LVG_AR)                  AS lvg_ar_max,
    -- Number of Buildings
    COUNT(NO_BULDNG)                 AS bldng_count,
    ROUND(AVG(NO_BULDNG), 2)        AS bldng_mean,
    MAX(NO_BULDNG)                   AS bldng_max,
    -- Number of Residential Units
    COUNT(NO_RES_UNT)               AS res_unt_count,
    ROUND(AVG(NO_RES_UNT), 2)      AS res_unt_mean,
    MAX(NO_RES_UNT)                  AS res_unt_max
FROM parcels;

-- 4c. Land area stats
SELECT 'land_area_stats' AS section;
SELECT
    COUNT(LND_SQFOOT)                AS sqft_count,
    ROUND(AVG(LND_SQFOOT), 0)       AS sqft_mean,
    PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY LND_SQFOOT) AS sqft_p25,
    PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY LND_SQFOOT) AS sqft_median,
    PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY LND_SQFOOT) AS sqft_p75,
    PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY LND_SQFOOT) AS sqft_p95,
    MAX(LND_SQFOOT)                  AS sqft_max,
    -- Shape Area (geodesic)
    COUNT(Shape_Area)                AS shape_area_count,
    ROUND(AVG(Shape_Area), 2)        AS shape_area_mean,
    PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY Shape_Area) AS shape_area_median,
    MAX(Shape_Area)                  AS shape_area_max
FROM parcels;

-- 4d. Zero-value analysis (how many parcels have $0 values?)
SELECT 'zero_value_analysis' AS section;
SELECT
    COUNT(*)                                                 AS total_rows,
    COUNT(*) FILTER (WHERE JV = 0)                           AS jv_zero,
    COUNT(*) FILTER (WHERE LND_VAL = 0)                      AS lnd_val_zero,
    COUNT(*) FILTER (WHERE TV_SD = 0)                        AS tv_sd_zero,
    COUNT(*) FILTER (WHERE TOT_LVG_AR = 0 OR TOT_LVG_AR IS NULL) AS no_living_area,
    COUNT(*) FILTER (WHERE NO_BULDNG = 0 OR NO_BULDNG IS NULL)   AS no_buildings,
    COUNT(*) FILTER (WHERE LND_SQFOOT = 0 OR LND_SQFOOT IS NULL) AS no_land_sqft
FROM parcels;

-- 4e. Outlier detection — parcels with extreme Just Values (top 20)
SELECT 'jv_outliers_top20' AS section;
SELECT
    PARCEL_ID,
    county_name,
    land_use_description,
    JV,
    LND_VAL,
    TOT_LVG_AR,
    EFF_YR_BLT
FROM parcels
WHERE JV IS NOT NULL
ORDER BY JV DESC
LIMIT 20;

-- 4f. Value per sq ft distribution (where living area > 0)
SELECT 'value_per_sqft' AS section;
SELECT
    ROUND(AVG(JV * 1.0 / TOT_LVG_AR), 2)        AS avg_value_per_sqft,
    PERCENTILE_CONT(0.10) WITHIN GROUP (ORDER BY JV * 1.0 / TOT_LVG_AR) AS p10,
    PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY JV * 1.0 / TOT_LVG_AR) AS p25,
    PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY JV * 1.0 / TOT_LVG_AR) AS median,
    PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY JV * 1.0 / TOT_LVG_AR) AS p75,
    PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY JV * 1.0 / TOT_LVG_AR) AS p90,
    PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY JV * 1.0 / TOT_LVG_AR) AS p99
FROM parcels
WHERE TOT_LVG_AR > 0 AND JV > 0;
