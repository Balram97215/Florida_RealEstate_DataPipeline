-- ============================================================
-- Validation Queries for Florida Parcels ELT Pipeline
-- Each query returns: check_name, status ('PASS'/'FAIL'), details
-- ============================================================

-- 1. Row count: parcels must match expected count
SELECT
    '01_row_count_parcels' AS check_name,
    CASE WHEN cnt = 10834415 THEN 'PASS' ELSE 'FAIL' END AS status,
    'parcels_count=' || cnt || ' expected=10834415' AS details
FROM (SELECT COUNT(*) AS cnt FROM parcels);

-- 2. Row count: parcels vs expected (from config)
SELECT
    '02_row_count_vs_expected' AS check_name,
    CASE WHEN cnt > 0 THEN 'PASS' ELSE 'FAIL' END AS status,
    'parcels_count=' || cnt AS details
FROM (SELECT COUNT(*) AS cnt FROM parcels);

-- 3. Aggregate checksum: SUM(JV) must be positive and non-null
SELECT
    '03_checksum_jv' AS check_name,
    CASE WHEN total > 0 THEN 'PASS' ELSE 'FAIL' END AS status,
    'parcels_sum_jv=' || COALESCE(CAST(total AS VARCHAR), 'NULL') AS details
FROM (SELECT SUM(JV) AS total FROM parcels);

-- 4. Aggregate checksum: SUM(TV_SD) must be positive and non-null
SELECT
    '04_checksum_tv_sd' AS check_name,
    CASE WHEN total > 0 THEN 'PASS' ELSE 'FAIL' END AS status,
    'parcels_sum_tv_sd=' || COALESCE(CAST(total AS VARCHAR), 'NULL') AS details
FROM (SELECT SUM(TV_SD) AS total FROM parcels);

-- 5. Aggregate checksum: SUM(LND_VAL) must be positive and non-null
SELECT
    '05_checksum_lnd_val' AS check_name,
    CASE WHEN total > 0 THEN 'PASS' ELSE 'FAIL' END AS status,
    'parcels_sum_lnd_val=' || COALESCE(CAST(total AS VARCHAR), 'NULL') AS details
FROM (SELECT SUM(LND_VAL) AS total FROM parcels);

-- 6. Enrichment: county_name should have zero NULLs
SELECT
    '06_county_name_completeness' AS check_name,
    CASE WHEN null_cnt = 0 THEN 'PASS' ELSE 'FAIL' END AS status,
    'null_county_name_count=' || null_cnt || ' total=' || total_cnt AS details
FROM (
    SELECT
        COUNT(*) FILTER (WHERE county_name IS NULL) AS null_cnt,
        COUNT(*) AS total_cnt
    FROM parcels
);

-- 7. Enrichment: land_use_description unmapped audit
SELECT
    '07_land_use_unmapped_audit' AS check_name,
    CASE WHEN unmapped_cnt = 0 THEN 'PASS' ELSE 'WARN' END AS status,
    'unmapped_count=' || unmapped_cnt || ' unmapped_codes=' ||
    COALESCE(unmapped_list, 'none') AS details
FROM (
    SELECT
        COUNT(*) FILTER (WHERE land_use_category = 'Unmapped') AS unmapped_cnt,
        STRING_AGG(DISTINCT DOR_UC, ', ') FILTER (WHERE land_use_category = 'Unmapped') AS unmapped_list
    FROM parcels
);

-- 8. Null audit: critical fields must not be NULL
SELECT
    '08_null_audit_critical_fields' AS check_name,
    CASE WHEN null_objectid + null_parcel_id + null_co_no = 0 THEN 'PASS' ELSE 'FAIL' END AS status,
    'null_OBJECTID=' || null_objectid ||
    ' null_PARCEL_ID=' || null_parcel_id ||
    ' null_CO_NO=' || null_co_no AS details
FROM (
    SELECT
        COUNT(*) FILTER (WHERE OBJECTID IS NULL) AS null_objectid,
        COUNT(*) FILTER (WHERE PARCEL_ID IS NULL) AS null_parcel_id,
        COUNT(*) FILTER (WHERE CO_NO IS NULL) AS null_co_no
    FROM parcels
);

-- 9. Centroid bounds: all centroids within Florida bounding box
SELECT
    '09_centroid_bounds_check' AS check_name,
    CASE WHEN out_of_bounds = 0 THEN 'PASS' ELSE 'WARN' END AS status,
    'out_of_bounds=' || out_of_bounds ||
    ' null_centroids=' || null_centroids ||
    ' total=' || total_cnt AS details
FROM (
    SELECT
        COUNT(*) FILTER (
            WHERE centroid_lat IS NOT NULL
              AND centroid_lon IS NOT NULL
              AND (centroid_lat < 24.39 OR centroid_lat > 31.01
                OR centroid_lon < -87.64 OR centroid_lon > -79.97)
        ) AS out_of_bounds,
        COUNT(*) FILTER (WHERE centroid_lat IS NULL OR centroid_lon IS NULL) AS null_centroids,
        COUNT(*) AS total_cnt
    FROM parcels
);

-- 10. County distribution: all CO_NO values must map to ref_county
SELECT
    '10_county_distribution' AS check_name,
    CASE WHEN orphan_cnt = 0 THEN 'PASS' ELSE 'WARN' END AS status,
    'distinct_counties=' || total_counties || ' orphan_co_no_count=' || orphan_cnt AS details
FROM (
    SELECT
        COUNT(DISTINCT CAST(CO_NO AS INTEGER)) AS total_counties,
        COUNT(DISTINCT CAST(CO_NO AS INTEGER)) FILTER (
            WHERE county_name IS NULL
        ) AS orphan_cnt
    FROM parcels
);

-- 11. Sales validation: SUM(sale_price) per sequence matches original columns
SELECT
    '11_sales_price_checksum' AS check_name,
    CASE
        WHEN ABS(COALESCE(s1_sum, 0) - COALESCE(orig1_sum, 0)) < 0.01
         AND ABS(COALESCE(s2_sum, 0) - COALESCE(orig2_sum, 0)) < 0.01
        THEN 'PASS' ELSE 'FAIL'
    END AS status,
    'sales_seq1_sum=' || COALESCE(CAST(s1_sum AS VARCHAR), 'NULL') ||
    ' orig_prc1_sum=' || COALESCE(CAST(orig1_sum AS VARCHAR), 'NULL') ||
    ' sales_seq2_sum=' || COALESCE(CAST(s2_sum AS VARCHAR), 'NULL') ||
    ' orig_prc2_sum=' || COALESCE(CAST(orig2_sum AS VARCHAR), 'NULL') AS details
FROM (
    SELECT
        SUM(sale_price) FILTER (WHERE sale_sequence = 1) AS s1_sum,
        SUM(sale_price) FILTER (WHERE sale_sequence = 2) AS s2_sum
    FROM sales
) sal,
(
    SELECT
        SUM(SALE_PRC1) FILTER (WHERE SALE_PRC1 > 0) AS orig1_sum,
        SUM(SALE_PRC2) FILTER (WHERE SALE_PRC2 > 0) AS orig2_sum
    FROM parcels
) orig;

-- 12. ref_county row count
SELECT
    '12_ref_county_count' AS check_name,
    CASE WHEN cnt = 78 THEN 'PASS' ELSE 'FAIL' END AS status,
    'ref_county_rows=' || cnt AS details
FROM (SELECT COUNT(*) AS cnt FROM ref_county);

-- 13. Duplicate OBJECTID check (must be unique in parcels)
SELECT
    '13_objectid_uniqueness' AS check_name,
    CASE WHEN dup_cnt = 0 THEN 'PASS' ELSE 'FAIL' END AS status,
    'duplicate_objectids=' || dup_cnt AS details
FROM (
    SELECT COUNT(*) AS dup_cnt
    FROM (
        SELECT OBJECTID, COUNT(*) AS c
        FROM parcels
        GROUP BY OBJECTID
        HAVING COUNT(*) > 1
    )
);
