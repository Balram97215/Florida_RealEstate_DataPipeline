-- ============================================================
-- EDA 03: Categorical Column Profiling
-- Cardinality, frequency distributions, top values
-- ============================================================

-- 3a. Cardinality summary (distinct counts)
SELECT 'cardinality_summary' AS section;
SELECT
    COUNT(DISTINCT county_name)           AS n_counties,
    COUNT(DISTINCT land_use_category)     AS n_land_use_categories,
    COUNT(DISTINCT land_use_description)  AS n_land_use_descriptions,
    COUNT(DISTINCT DOR_UC)                AS n_dor_uc_codes,
    COUNT(DISTINCT CONST_CLAS)            AS n_construction_classes,
    COUNT(DISTINCT IMP_QUAL)              AS n_improvement_qualities,
    COUNT(DISTINCT OWN_STATE)             AS n_owner_states,
    COUNT(DISTINCT PHY_CITY)              AS n_physical_cities,
    COUNT(DISTINCT ASMNT_YR)              AS n_assessment_years,
    COUNT(DISTINCT LND_UNTS_C)            AS n_land_unit_codes
FROM parcels;

-- 3b. County distribution (top 20)
SELECT 'county_distribution' AS section;
SELECT
    county_name,
    COUNT(*)                                    AS parcel_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER(), 2) AS pct_of_total
FROM parcels
GROUP BY county_name
ORDER BY parcel_count DESC
LIMIT 20;

-- 3c. Land use category distribution
SELECT 'land_use_category_distribution' AS section;
SELECT
    land_use_category,
    COUNT(*)                                    AS parcel_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER(), 2) AS pct_of_total,
    ROUND(AVG(JV), 0)                          AS avg_just_value
FROM parcels
GROUP BY land_use_category
ORDER BY parcel_count DESC;

-- 3d. Top 20 land use descriptions
SELECT 'top_land_use_descriptions' AS section;
SELECT
    DOR_UC,
    land_use_description,
    COUNT(*)                                    AS parcel_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER(), 2) AS pct_of_total
FROM parcels
GROUP BY DOR_UC, land_use_description
ORDER BY parcel_count DESC
LIMIT 20;

-- 3e. Construction class distribution
SELECT 'construction_class_distribution' AS section;
SELECT
    COALESCE(CAST(CONST_CLAS AS VARCHAR), 'NULL/Missing') AS construction_class,
    COUNT(*)                                    AS parcel_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER(), 2) AS pct_of_total
FROM parcels
GROUP BY CONST_CLAS
ORDER BY parcel_count DESC;

-- 3f. Improvement quality distribution
SELECT 'improvement_quality_distribution' AS section;
SELECT
    COALESCE(CAST(IMP_QUAL AS VARCHAR), 'NULL/Missing') AS improvement_quality,
    COUNT(*)                                    AS parcel_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER(), 2) AS pct_of_total
FROM parcels
GROUP BY IMP_QUAL
ORDER BY parcel_count DESC;

-- 3g. Owner state distribution (top 15 — where do out-of-state owners come from?)
SELECT 'owner_state_distribution' AS section;
SELECT
    COALESCE(OWN_STATE, 'NULL/Missing') AS owner_state,
    COUNT(*)                                    AS parcel_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER(), 2) AS pct_of_total
FROM parcels
GROUP BY OWN_STATE
ORDER BY parcel_count DESC
LIMIT 15;

-- 3h. Assessment year distribution
SELECT 'assessment_year_distribution' AS section;
SELECT
    ASMNT_YR,
    COUNT(*) AS parcel_count
FROM parcels
GROUP BY ASMNT_YR
ORDER BY ASMNT_YR;
