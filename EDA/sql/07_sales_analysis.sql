-- ============================================================
-- EDA 07: Sales Deep Dive
-- Price distributions, qualified vs unqualified, county trends
-- ============================================================

-- 7a. Sales overview
SELECT 'sales_overview' AS section;
SELECT
    COUNT(*) AS total_sales,
    COUNT(DISTINCT PARCEL_ID) AS unique_parcels_sold,
    ROUND(AVG(sale_price), 0) AS avg_sale_price,
    ROUND(MEDIAN(sale_price), 0) AS median_sale_price,
    MIN(sale_price) AS min_sale_price,
    MAX(sale_price) AS max_sale_price,
    ROUND(SUM(sale_price) / 1e9, 2) AS total_volume_billions
FROM sales;

-- 7b. Sale price histogram
SELECT 'sale_price_histogram' AS section;
SELECT
    CASE
        WHEN sale_price < 10000       THEN 'Under $10K'
        WHEN sale_price < 50000       THEN '$10K-$50K'
        WHEN sale_price < 100000      THEN '$50K-$100K'
        WHEN sale_price < 200000      THEN '$100K-$200K'
        WHEN sale_price < 500000      THEN '$200K-$500K'
        WHEN sale_price < 1000000     THEN '$500K-$1M'
        WHEN sale_price < 5000000     THEN '$1M-$5M'
        WHEN sale_price < 10000000    THEN '$5M-$10M'
        ELSE '$10M+'
    END AS price_bucket,
    COUNT(*) AS sale_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER(), 2) AS pct_of_total
FROM sales
GROUP BY price_bucket
ORDER BY MIN(sale_price);

-- 7c. Sales by county (top 15 by volume)
SELECT 'sales_by_county' AS section;
SELECT
    county_name,
    COUNT(*) AS sale_count,
    ROUND(AVG(sale_price), 0) AS avg_price,
    ROUND(MEDIAN(sale_price), 0) AS median_price,
    ROUND(SUM(sale_price) / 1e9, 2) AS total_volume_billions
FROM sales
GROUP BY county_name
ORDER BY total_volume_billions DESC
LIMIT 15;

-- 7d. Qualification code distribution
SELECT 'qualification_code_distribution' AS section;
SELECT
    COALESCE(qualification_code, 'NULL/Missing') AS qual_code,
    COUNT(*) AS sale_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER(), 2) AS pct_of_total,
    ROUND(AVG(sale_price), 0) AS avg_price
FROM sales
GROUP BY qualification_code
ORDER BY sale_count DESC;

-- 7e. Sale sequence analysis (Sale 1 vs Sale 2)
SELECT 'sale_sequence_comparison' AS section;
SELECT
    sale_sequence,
    COUNT(*) AS sale_count,
    ROUND(AVG(sale_price), 0) AS avg_price,
    ROUND(MEDIAN(sale_price), 0) AS median_price
FROM sales
GROUP BY sale_sequence
ORDER BY sale_sequence;

-- 7f. Multi-parcel sales flag
SELECT 'multi_parcel_sales' AS section;
SELECT
    COALESCE(CAST(multi_parcel_sale AS VARCHAR), 'NULL') AS multi_parcel_flag,
    COUNT(*) AS sale_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER(), 2) AS pct_of_total,
    ROUND(AVG(sale_price), 0) AS avg_price
FROM sales
GROUP BY multi_parcel_sale
ORDER BY sale_count DESC;
