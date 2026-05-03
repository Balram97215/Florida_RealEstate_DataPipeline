-- ============================================================
-- SUPERSET DASHBOARD VIEWS
-- Pre-aggregated views optimized for Apache Superset charts
-- Run against: florida_parcels.duckdb
-- ============================================================

-- ────────────────────────────────────────────────────────────
-- DASHBOARD 1: PROPERTY VALUATION OVERVIEW
-- ────────────────────────────────────────────────────────────

-- KPI scorecards: statewide summary
CREATE OR REPLACE VIEW v_dash_statewide_kpi AS
SELECT
    COUNT(*)                                          AS total_parcels,
    ROUND(SUM(JV) / 1e9, 2)                          AS total_jv_billions,
    ROUND(AVG(JV), 0)                                AS avg_just_value,
    ROUND(MEDIAN(JV), 0)                             AS median_just_value,
    ROUND(SUM(TV_SD) / 1e9, 2)                       AS total_taxable_value_billions,
    ROUND(AVG(TV_SD), 0)                             AS avg_taxable_value,
    ROUND(SUM(LND_VAL) / 1e9, 2)                    AS total_land_value_billions,
    COUNT(DISTINCT CO_NO)                             AS county_count,
    COUNT(DISTINCT land_use_category)                 AS land_use_categories
FROM parcels;

-- County-level valuation (bar charts, maps, rankings)
CREATE OR REPLACE VIEW v_dash_valuation_by_county AS
SELECT
    CO_NO,
    county_name,
    COUNT(*)                                          AS parcel_count,
    ROUND(SUM(JV) / 1e9, 2)                          AS total_jv_billions,
    ROUND(AVG(JV), 0)                                AS avg_jv,
    ROUND(MEDIAN(JV), 0)                             AS median_jv,
    ROUND(AVG(LND_VAL), 0)                           AS avg_land_value,
    ROUND(AVG(TV_SD), 0)                             AS avg_taxable_value,
    ROUND(SUM(TV_SD) / 1e9, 2)                       AS total_taxable_billions,
    ROUND(AVG(CASE WHEN TOT_LVG_AR > 0 THEN JV * 1.0 / TOT_LVG_AR END), 2) AS avg_value_per_sqft,
    ROUND(AVG(centroid_lat), 6)                      AS avg_lat,
    ROUND(AVG(centroid_lon), 6)                      AS avg_lon
FROM parcels
GROUP BY CO_NO, county_name
ORDER BY total_jv_billions DESC;

-- Land use category valuation (pie/donut, treemap)
CREATE OR REPLACE VIEW v_dash_valuation_by_land_use AS
SELECT
    land_use_category,
    COUNT(*)                                          AS parcel_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER(), 2) AS pct_of_total,
    ROUND(AVG(JV), 0)                                AS avg_just_value,
    ROUND(SUM(JV) / 1e9, 2)                          AS total_jv_billions,
    ROUND(AVG(TV_SD), 0)                             AS avg_taxable_value,
    ROUND(AVG(LND_VAL), 0)                           AS avg_land_value,
    ROUND(AVG(TOT_LVG_AR), 0)                        AS avg_living_area
FROM parcels
GROUP BY land_use_category
ORDER BY parcel_count DESC;

-- JV distribution histogram buckets
CREATE OR REPLACE VIEW v_dash_jv_distribution AS
SELECT
    CASE
        WHEN JV = 0                   THEN '$0'
        WHEN JV BETWEEN 1 AND 50000   THEN '$1-50K'
        WHEN JV BETWEEN 50001 AND 100000 THEN '$50K-100K'
        WHEN JV BETWEEN 100001 AND 200000 THEN '$100K-200K'
        WHEN JV BETWEEN 200001 AND 300000 THEN '$200K-300K'
        WHEN JV BETWEEN 300001 AND 500000 THEN '$300K-500K'
        WHEN JV BETWEEN 500001 AND 750000 THEN '$500K-750K'
        WHEN JV BETWEEN 750001 AND 1000000 THEN '$750K-1M'
        WHEN JV BETWEEN 1000001 AND 2000000 THEN '$1M-2M'
        WHEN JV BETWEEN 2000001 AND 5000000 THEN '$2M-5M'
        ELSE '$5M+'
    END AS jv_bucket,
    CASE
        WHEN JV = 0                   THEN 0
        WHEN JV BETWEEN 1 AND 50000   THEN 1
        WHEN JV BETWEEN 50001 AND 100000 THEN 2
        WHEN JV BETWEEN 100001 AND 200000 THEN 3
        WHEN JV BETWEEN 200001 AND 300000 THEN 4
        WHEN JV BETWEEN 300001 AND 500000 THEN 5
        WHEN JV BETWEEN 500001 AND 750000 THEN 6
        WHEN JV BETWEEN 750001 AND 1000000 THEN 7
        WHEN JV BETWEEN 1000001 AND 2000000 THEN 8
        WHEN JV BETWEEN 2000001 AND 5000000 THEN 9
        ELSE 10
    END AS bucket_order,
    COUNT(*) AS parcel_count
FROM parcels
GROUP BY 1, 2
ORDER BY bucket_order;

-- Value per sqft by land use (box plot / bar)
CREATE OR REPLACE VIEW v_dash_value_per_sqft AS
SELECT
    land_use_category,
    county_name,
    ROUND(AVG(CASE WHEN TOT_LVG_AR > 0 THEN JV * 1.0 / TOT_LVG_AR END), 2)    AS avg_value_per_sqft,
    ROUND(MEDIAN(CASE WHEN TOT_LVG_AR > 0 THEN JV * 1.0 / TOT_LVG_AR END), 2)  AS median_value_per_sqft,
    COUNT(CASE WHEN TOT_LVG_AR > 0 THEN 1 END)                                   AS parcels_with_area
FROM parcels
GROUP BY land_use_category, county_name
HAVING parcels_with_area > 10
ORDER BY avg_value_per_sqft DESC;


-- ────────────────────────────────────────────────────────────
-- DASHBOARD 2: SALES ANALYSIS
-- ────────────────────────────────────────────────────────────

-- Sales KPI
CREATE OR REPLACE VIEW v_dash_sales_kpi AS
SELECT
    COUNT(*)                                          AS total_sales,
    COUNT(DISTINCT PARCEL_ID)                         AS unique_parcels_sold,
    ROUND(AVG(sale_price), 0)                         AS avg_sale_price,
    ROUND(MEDIAN(sale_price), 0)                      AS median_sale_price,
    MIN(sale_price)                                   AS min_sale_price,
    MAX(sale_price)                                   AS max_sale_price,
    ROUND(SUM(sale_price) / 1e9, 2)                   AS total_volume_billions
FROM sales;

-- Sales by county (bar chart, ranking table)
CREATE OR REPLACE VIEW v_dash_sales_by_county AS
SELECT
    county_name,
    COUNT(*)                                          AS sale_count,
    ROUND(AVG(sale_price), 0)                         AS avg_price,
    ROUND(MEDIAN(sale_price), 0)                      AS median_price,
    ROUND(SUM(sale_price) / 1e9, 2)                   AS total_volume_billions,
    COUNT(DISTINCT PARCEL_ID)                         AS unique_parcels
FROM sales
GROUP BY county_name
ORDER BY total_volume_billions DESC;

-- Sales by year (time series)
CREATE OR REPLACE VIEW v_dash_sales_by_year AS
SELECT
    sale_year,
    COUNT(*)                                          AS sale_count,
    ROUND(AVG(sale_price), 0)                         AS avg_price,
    ROUND(MEDIAN(sale_price), 0)                      AS median_price,
    ROUND(SUM(sale_price) / 1e9, 2)                   AS total_volume_billions,
    COUNT(DISTINCT PARCEL_ID)                         AS unique_parcels
FROM sales
WHERE sale_year > 0
GROUP BY sale_year
ORDER BY sale_year;

-- Sales by year and county (heatmap, multi-line)
CREATE OR REPLACE VIEW v_dash_sales_year_county AS
SELECT
    sale_year,
    county_name,
    COUNT(*)                                          AS sale_count,
    ROUND(AVG(sale_price), 0)                         AS avg_price,
    ROUND(MEDIAN(sale_price), 0)                      AS median_price,
    ROUND(SUM(sale_price) / 1e9, 2)                   AS total_volume_billions
FROM sales
WHERE sale_year > 0
GROUP BY sale_year, county_name
ORDER BY sale_year, county_name;

-- Sale price distribution histogram
CREATE OR REPLACE VIEW v_dash_sale_price_distribution AS
SELECT
    CASE
        WHEN sale_price BETWEEN 1 AND 50000       THEN '$1-50K'
        WHEN sale_price BETWEEN 50001 AND 100000   THEN '$50K-100K'
        WHEN sale_price BETWEEN 100001 AND 200000  THEN '$100K-200K'
        WHEN sale_price BETWEEN 200001 AND 300000  THEN '$200K-300K'
        WHEN sale_price BETWEEN 300001 AND 500000  THEN '$300K-500K'
        WHEN sale_price BETWEEN 500001 AND 750000  THEN '$500K-750K'
        WHEN sale_price BETWEEN 750001 AND 1000000 THEN '$750K-1M'
        WHEN sale_price BETWEEN 1000001 AND 2000000 THEN '$1M-2M'
        WHEN sale_price BETWEEN 2000001 AND 5000000 THEN '$2M-5M'
        ELSE '$5M+'
    END AS price_bucket,
    CASE
        WHEN sale_price BETWEEN 1 AND 50000       THEN 1
        WHEN sale_price BETWEEN 50001 AND 100000   THEN 2
        WHEN sale_price BETWEEN 100001 AND 200000  THEN 3
        WHEN sale_price BETWEEN 200001 AND 300000  THEN 4
        WHEN sale_price BETWEEN 300001 AND 500000  THEN 5
        WHEN sale_price BETWEEN 500001 AND 750000  THEN 6
        WHEN sale_price BETWEEN 750001 AND 1000000 THEN 7
        WHEN sale_price BETWEEN 1000001 AND 2000000 THEN 8
        WHEN sale_price BETWEEN 2000001 AND 5000000 THEN 9
        ELSE 10
    END AS bucket_order,
    COUNT(*) AS sale_count,
    ROUND(SUM(sale_price) / 1e9, 2) AS volume_billions
FROM sales
WHERE sale_price > 0
GROUP BY 1, 2
ORDER BY bucket_order;

-- Qualification code analysis
CREATE OR REPLACE VIEW v_dash_sales_qualification AS
SELECT
    qualification_code,
    COUNT(*)                                          AS sale_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER(), 2) AS pct_of_total,
    ROUND(AVG(sale_price), 0)                         AS avg_price,
    ROUND(MEDIAN(sale_price), 0)                      AS median_price
FROM sales
GROUP BY qualification_code
ORDER BY sale_count DESC;

-- Multi-parcel sale analysis
CREATE OR REPLACE VIEW v_dash_multi_parcel_sales AS
SELECT
    multi_parcel_sale,
    COUNT(*)                                          AS sale_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER(), 2) AS pct_of_total,
    ROUND(AVG(sale_price), 0)                         AS avg_price
FROM sales
GROUP BY multi_parcel_sale
ORDER BY sale_count DESC;


-- ────────────────────────────────────────────────────────────
-- DASHBOARD 3: COUNTY COMPARISON
-- ────────────────────────────────────────────────────────────

-- Comprehensive county metrics (big table, cross-filter source)
CREATE OR REPLACE VIEW v_dash_county_scorecard AS
SELECT
    p.CO_NO,
    p.county_name,
    -- Parcel counts
    p.parcel_count,
    -- Valuation
    p.total_jv_billions,
    p.avg_jv,
    p.median_jv,
    p.avg_taxable_value,
    p.avg_land_value,
    -- Per sqft
    p.avg_value_per_sqft,
    -- Sales
    COALESCE(s.sale_count, 0)                         AS sale_count,
    COALESCE(s.avg_price, 0)                          AS avg_sale_price,
    COALESCE(s.median_price, 0)                       AS median_sale_price,
    COALESCE(s.total_volume_billions, 0)              AS sales_volume_billions,
    -- Ratios
    ROUND(100.0 * p.parcel_count / (SELECT COUNT(*) FROM parcels), 2) AS pct_of_state_parcels,
    -- Location
    p.avg_lat,
    p.avg_lon
FROM v_dash_valuation_by_county p
LEFT JOIN v_dash_sales_by_county s USING (county_name);


-- ────────────────────────────────────────────────────────────
-- DASHBOARD 4: LAND USE DEEP DIVE
-- ────────────────────────────────────────────────────────────

-- Land use by county (stacked bar, heatmap)
CREATE OR REPLACE VIEW v_dash_land_use_by_county AS
SELECT
    county_name,
    land_use_category,
    COUNT(*)                                          AS parcel_count,
    ROUND(AVG(JV), 0)                                AS avg_jv,
    ROUND(SUM(JV) / 1e9, 2)                          AS total_jv_billions,
    ROUND(AVG(TOT_LVG_AR), 0)                        AS avg_living_area,
    ROUND(AVG(LND_SQFOOT), 0)                        AS avg_land_sqft
FROM parcels
GROUP BY county_name, land_use_category
ORDER BY county_name, parcel_count DESC;

-- Top DOR use codes (detailed view)
CREATE OR REPLACE VIEW v_dash_top_land_use_codes AS
SELECT
    DOR_UC,
    land_use_description,
    land_use_category,
    COUNT(*)                                          AS parcel_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER(), 2) AS pct_of_total,
    ROUND(AVG(JV), 0)                                AS avg_jv,
    ROUND(SUM(JV) / 1e9, 2)                          AS total_jv_billions
FROM parcels
GROUP BY DOR_UC, land_use_description, land_use_category
ORDER BY parcel_count DESC;


-- ────────────────────────────────────────────────────────────
-- DASHBOARD 5: BUILDING CHARACTERISTICS
-- ────────────────────────────────────────────────────────────

-- Year built decades (bar chart)
CREATE OR REPLACE VIEW v_dash_year_built_decades AS
SELECT
    CASE
        WHEN EFF_YR_BLT = 0 OR EFF_YR_BLT IS NULL THEN 'Unknown/Vacant'
        WHEN EFF_YR_BLT < 1900                     THEN 'Before 1900'
        ELSE CONCAT(CAST(FLOOR(EFF_YR_BLT / 10) * 10 AS INT), 's')
    END AS decade,
    CASE
        WHEN EFF_YR_BLT = 0 OR EFF_YR_BLT IS NULL THEN 0
        WHEN EFF_YR_BLT < 1900                     THEN 1800
        ELSE FLOOR(EFF_YR_BLT / 10) * 10
    END AS decade_sort,
    COUNT(*)                                          AS parcel_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER(), 2) AS pct_of_total,
    ROUND(AVG(JV), 0)                                AS avg_just_value,
    ROUND(AVG(TOT_LVG_AR), 0)                        AS avg_living_area,
    ROUND(AVG(CASE WHEN TOT_LVG_AR > 0 THEN JV * 1.0 / TOT_LVG_AR END), 2) AS avg_value_per_sqft
FROM parcels
GROUP BY 1, 2
ORDER BY decade_sort;

-- Construction class distribution
CREATE OR REPLACE VIEW v_dash_construction_class AS
SELECT
    COALESCE(CONST_CLAS, 'Unknown') AS construction_class,
    COUNT(*)                                          AS parcel_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER(), 2) AS pct_of_total,
    ROUND(AVG(JV), 0)                                AS avg_jv,
    ROUND(AVG(TOT_LVG_AR), 0)                        AS avg_living_area
FROM parcels
GROUP BY COALESCE(CONST_CLAS, 'Unknown')
ORDER BY parcel_count DESC;

-- Improvement quality distribution
CREATE OR REPLACE VIEW v_dash_improvement_quality AS
SELECT
    COALESCE(IMP_QUAL, 'Unknown') AS improvement_quality,
    COUNT(*)                                          AS parcel_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER(), 2) AS pct_of_total,
    ROUND(AVG(JV), 0)                                AS avg_jv,
    ROUND(AVG(TOT_LVG_AR), 0)                        AS avg_living_area
FROM parcels
GROUP BY COALESCE(IMP_QUAL, 'Unknown')
ORDER BY parcel_count DESC;

-- Living area distribution
CREATE OR REPLACE VIEW v_dash_living_area_distribution AS
SELECT
    CASE
        WHEN TOT_LVG_AR = 0 OR TOT_LVG_AR IS NULL THEN 'No Building'
        WHEN TOT_LVG_AR BETWEEN 1 AND 500          THEN '<500 sqft'
        WHEN TOT_LVG_AR BETWEEN 501 AND 1000       THEN '500-1K sqft'
        WHEN TOT_LVG_AR BETWEEN 1001 AND 1500      THEN '1K-1.5K sqft'
        WHEN TOT_LVG_AR BETWEEN 1501 AND 2000      THEN '1.5K-2K sqft'
        WHEN TOT_LVG_AR BETWEEN 2001 AND 3000      THEN '2K-3K sqft'
        WHEN TOT_LVG_AR BETWEEN 3001 AND 5000      THEN '3K-5K sqft'
        WHEN TOT_LVG_AR BETWEEN 5001 AND 10000     THEN '5K-10K sqft'
        ELSE '10K+ sqft'
    END AS area_bucket,
    CASE
        WHEN TOT_LVG_AR = 0 OR TOT_LVG_AR IS NULL THEN 0
        WHEN TOT_LVG_AR BETWEEN 1 AND 500          THEN 1
        WHEN TOT_LVG_AR BETWEEN 501 AND 1000       THEN 2
        WHEN TOT_LVG_AR BETWEEN 1001 AND 1500      THEN 3
        WHEN TOT_LVG_AR BETWEEN 1501 AND 2000      THEN 4
        WHEN TOT_LVG_AR BETWEEN 2001 AND 3000      THEN 5
        WHEN TOT_LVG_AR BETWEEN 3001 AND 5000      THEN 6
        WHEN TOT_LVG_AR BETWEEN 5001 AND 10000     THEN 7
        ELSE 8
    END AS bucket_order,
    COUNT(*) AS parcel_count,
    ROUND(AVG(JV), 0) AS avg_jv,
    ROUND(AVG(CASE WHEN TOT_LVG_AR > 0 THEN JV * 1.0 / TOT_LVG_AR END), 2) AS avg_value_per_sqft
FROM parcels
GROUP BY 1, 2
ORDER BY bucket_order;

-- Homestead analysis
CREATE OR REPLACE VIEW v_dash_homestead_analysis AS
SELECT
    CASE WHEN JV_HMSTD > 0 THEN 'Homesteaded' ELSE 'Non-Homesteaded' END AS homestead_status,
    COUNT(*)                                          AS parcel_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER(), 2) AS pct_of_total,
    ROUND(AVG(JV), 0)                                AS avg_jv,
    ROUND(MEDIAN(JV), 0)                             AS median_jv,
    ROUND(AVG(TV_SD), 0)                             AS avg_taxable_value,
    ROUND(AVG(TOT_LVG_AR), 0)                        AS avg_living_area
FROM parcels
GROUP BY homestead_status
ORDER BY parcel_count DESC;


-- ────────────────────────────────────────────────────────────
-- DASHBOARD 6: SPATIAL / MAP VIEWS
-- ────────────────────────────────────────────────────────────

-- County centroids with metrics (bubble map)
CREATE OR REPLACE VIEW v_dash_county_map AS
SELECT
    county_name,
    ROUND(AVG(centroid_lat), 6)                       AS latitude,
    ROUND(AVG(centroid_lon), 6)                       AS longitude,
    COUNT(*)                                          AS parcel_count,
    ROUND(SUM(JV) / 1e9, 2)                          AS total_jv_billions,
    ROUND(AVG(JV), 0)                                AS avg_jv,
    ROUND(MEDIAN(JV), 0)                             AS median_jv
FROM parcels
WHERE centroid_lat IS NOT NULL
  AND centroid_lon IS NOT NULL
GROUP BY county_name;

-- Latitude bands (geographic distribution)
CREATE OR REPLACE VIEW v_dash_latitude_bands AS
SELECT
    FLOOR(centroid_lat) AS lat_band,
    COUNT(*)                                          AS parcel_count,
    ROUND(AVG(JV), 0)                                AS avg_jv,
    ROUND(SUM(JV) / 1e9, 2)                          AS total_jv_billions
FROM parcels
WHERE centroid_lat IS NOT NULL
GROUP BY lat_band
ORDER BY lat_band;


-- ────────────────────────────────────────────────────────────
-- DASHBOARD 7: ASSESSMENT ANALYSIS
-- ────────────────────────────────────────────────────────────

-- Assessment ratio by county
CREATE OR REPLACE VIEW v_dash_assessment_ratio AS
SELECT
    county_name,
    ROUND(AVG(CASE WHEN JV > 0 THEN AV_SD * 1.0 / JV END), 4) AS avg_assessment_ratio_sd,
    ROUND(AVG(CASE WHEN JV > 0 THEN AV_NSD * 1.0 / JV END), 4) AS avg_assessment_ratio_nsd,
    ROUND(AVG(CASE WHEN JV > 0 THEN TV_SD * 1.0 / JV END), 4) AS avg_taxable_ratio,
    COUNT(*)                                          AS parcel_count
FROM parcels
WHERE JV > 0
GROUP BY county_name
ORDER BY avg_assessment_ratio_sd;

-- Land value share analysis
CREATE OR REPLACE VIEW v_dash_land_value_share AS
SELECT
    land_use_category,
    county_name,
    ROUND(AVG(CASE WHEN JV > 0 THEN LND_VAL * 100.0 / JV END), 2) AS avg_land_pct_of_jv,
    ROUND(AVG(JV), 0)                                AS avg_jv,
    COUNT(*)                                          AS parcel_count
FROM parcels
WHERE JV > 0
GROUP BY land_use_category, county_name
HAVING parcel_count > 50
ORDER BY avg_land_pct_of_jv DESC;

-- Zero value analysis
CREATE OR REPLACE VIEW v_dash_zero_value_analysis AS
SELECT
    land_use_category,
    COUNT(*)                                          AS total_parcels,
    SUM(CASE WHEN JV = 0 THEN 1 ELSE 0 END)          AS zero_jv_count,
    ROUND(100.0 * SUM(CASE WHEN JV = 0 THEN 1 ELSE 0 END) / COUNT(*), 2) AS zero_jv_pct,
    SUM(CASE WHEN TV_SD = 0 THEN 1 ELSE 0 END)       AS zero_tv_count,
    ROUND(100.0 * SUM(CASE WHEN TV_SD = 0 THEN 1 ELSE 0 END) / COUNT(*), 2) AS zero_tv_pct
FROM parcels
GROUP BY land_use_category
ORDER BY zero_jv_pct DESC;


-- ────────────────────────────────────────────────────────────
-- DASHBOARD 8: OWNER ANALYSIS
-- ────────────────────────────────────────────────────────────

-- Out-of-state ownership
CREATE OR REPLACE VIEW v_dash_owner_state AS
SELECT
    COALESCE(OWN_STATE, 'Unknown')                    AS owner_state,
    COUNT(*)                                          AS parcel_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER(), 2) AS pct_of_total,
    ROUND(AVG(JV), 0)                                AS avg_jv,
    ROUND(SUM(JV) / 1e9, 2)                          AS total_jv_billions
FROM parcels
GROUP BY COALESCE(OWN_STATE, 'Unknown')
ORDER BY parcel_count DESC;

-- Top 20 parcels by Just Value (data table)
CREATE OR REPLACE VIEW v_dash_top_parcels_by_jv AS
SELECT
    PARCEL_ID,
    county_name,
    land_use_description,
    land_use_category,
    JV,
    TV_SD,
    LND_VAL,
    TOT_LVG_AR,
    EFF_YR_BLT,
    PHY_ADDR1,
    PHY_CITY,
    centroid_lat,
    centroid_lon
FROM parcels
ORDER BY JV DESC
LIMIT 100;
