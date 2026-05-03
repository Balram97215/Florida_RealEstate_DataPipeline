-- ============================================================
-- EDA 01: Database Overview
-- Table sizes, column counts, data types, sample values
-- ============================================================

-- 1a. Table row counts
SELECT 'table_row_counts' AS section;
SELECT
    table_name,
    estimated_size AS row_count
FROM duckdb_tables()
WHERE schema_name = 'main'
ORDER BY estimated_size DESC;

-- 1b. Column inventory for parcels table
SELECT 'parcels_column_inventory' AS section;
SELECT
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_name = 'parcels'
ORDER BY ordinal_position;

-- 1c. Column inventory for sales table
SELECT 'sales_column_inventory' AS section;
SELECT
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_name = 'sales'
ORDER BY ordinal_position;

-- 1d. Quick sample (first 5 rows, key columns only)
SELECT 'parcels_sample' AS section;
SELECT
    PARCEL_ID,
    county_name,
    land_use_category,
    JV,
    TOT_LVG_AR,
    EFF_YR_BLT,
    centroid_lat,
    centroid_lon
FROM parcels
LIMIT 5;
