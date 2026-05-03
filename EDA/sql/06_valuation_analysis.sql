-- ============================================================
-- EDA 06: Valuation Deep Dive
-- Value distributions by county, land use, homestead status
-- ============================================================

-- 6a. Valuation by county (top 20 by total just value)
SELECT 'valuation_by_county' AS section;
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
ORDER BY total_jv_billions DESC
LIMIT 20;

-- 6b. Valuation by land use category
SELECT 'valuation_by_land_use' AS section;
SELECT
    land_use_category,
    COUNT(*) AS parcel_count,
    ROUND(SUM(JV) / 1e9, 2) AS total_jv_billions,
    ROUND(AVG(JV), 0) AS avg_jv,
    ROUND(MEDIAN(JV), 0) AS median_jv,
    ROUND(SUM(LND_VAL) / 1e9, 2) AS total_land_val_billions
FROM parcels
GROUP BY land_use_category
ORDER BY total_jv_billions DESC;

-- 6c. Homestead vs non-homestead comparison
SELECT 'homestead_analysis' AS section;
SELECT
    CASE
        WHEN JV_HMSTD > 0 THEN 'Homesteaded'
        ELSE 'Non-Homesteaded'
    END AS homestead_status,
    COUNT(*) AS parcel_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER(), 2) AS pct_of_total,
    ROUND(AVG(JV), 0) AS avg_jv,
    ROUND(MEDIAN(JV), 0) AS median_jv,
    ROUND(AVG(TV_SD), 0) AS avg_taxable_value,
    ROUND(AVG(TOT_LVG_AR), 0) AS avg_living_area
FROM parcels
GROUP BY homestead_status;

-- 6d. Assessment ratio: JV vs taxable value
SELECT 'assessment_ratio' AS section;
SELECT
    county_name,
    COUNT(*) AS parcel_count,
    ROUND(AVG(CASE WHEN JV > 0 THEN TV_SD * 1.0 / JV END), 4) AS avg_taxable_ratio,
    ROUND(MEDIAN(CASE WHEN JV > 0 THEN TV_SD * 1.0 / JV END), 4) AS median_taxable_ratio
FROM parcels
WHERE JV > 0
GROUP BY county_name
ORDER BY avg_taxable_ratio
LIMIT 20;

-- 6e. Land value as percentage of total value
SELECT 'land_value_share' AS section;
SELECT
    land_use_category,
    COUNT(*) AS parcel_count,
    ROUND(AVG(CASE WHEN JV > 0 THEN LND_VAL * 100.0 / JV END), 2) AS avg_land_pct_of_jv,
    ROUND(MEDIAN(CASE WHEN JV > 0 THEN LND_VAL * 100.0 / JV END), 2) AS median_land_pct_of_jv
FROM parcels
WHERE JV > 0
GROUP BY land_use_category
ORDER BY avg_land_pct_of_jv DESC;

-- 6f. Value distribution histogram (JV buckets)
SELECT 'jv_histogram' AS section;
SELECT
    CASE
        WHEN JV IS NULL           THEN 'NULL'
        WHEN JV = 0               THEN '$0'
        WHEN JV < 50000           THEN '$1-$50K'
        WHEN JV < 100000          THEN '$50K-$100K'
        WHEN JV < 200000          THEN '$100K-$200K'
        WHEN JV < 500000          THEN '$200K-$500K'
        WHEN JV < 1000000         THEN '$500K-$1M'
        WHEN JV < 5000000         THEN '$1M-$5M'
        WHEN JV < 10000000        THEN '$5M-$10M'
        WHEN JV < 50000000        THEN '$10M-$50M'
        ELSE '$50M+'
    END AS jv_bucket,
    COUNT(*) AS parcel_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER(), 2) AS pct_of_total
FROM parcels
GROUP BY jv_bucket
ORDER BY MIN(COALESCE(JV, -1));
