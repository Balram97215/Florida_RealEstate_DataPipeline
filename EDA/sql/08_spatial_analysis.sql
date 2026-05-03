-- ============================================================
-- EDA 08: Spatial & Geographic Analysis
-- Centroid coverage, county density, geographic patterns
-- ============================================================

-- 8a. Centroid coverage summary
SELECT 'centroid_coverage' AS section;
SELECT
    COUNT(*) AS total_parcels,
    COUNT(centroid_lat) AS has_centroid,
    COUNT(*) - COUNT(centroid_lat) AS missing_centroid,
    ROUND(100.0 * COUNT(centroid_lat) / COUNT(*), 2) AS pct_geocoded,
    ROUND(MIN(centroid_lat), 4) AS min_lat,
    ROUND(MAX(centroid_lat), 4) AS max_lat,
    ROUND(MIN(centroid_lon), 4) AS min_lon,
    ROUND(MAX(centroid_lon), 4) AS max_lon
FROM parcels;

-- 8b. Parcel density by county (parcels per county + avg shape area)
SELECT 'county_density' AS section;
SELECT
    county_name,
    COUNT(*) AS parcel_count,
    ROUND(AVG(Shape_Area), 2) AS avg_shape_area,
    ROUND(MEDIAN(Shape_Area), 2) AS median_shape_area,
    ROUND(AVG(LND_SQFOOT), 0) AS avg_land_sqft
FROM parcels
WHERE county_name IS NOT NULL
GROUP BY county_name
ORDER BY parcel_count DESC
LIMIT 20;

-- 8c. Latitude bands (rough N/S Florida segmentation)
SELECT 'latitude_bands' AS section;
SELECT
    CASE
        WHEN centroid_lat IS NULL        THEN 'No Centroid'
        WHEN centroid_lat >= 29.0        THEN 'North Florida (>=29°N)'
        WHEN centroid_lat >= 27.0        THEN 'Central Florida (27-29°N)'
        WHEN centroid_lat >= 25.5        THEN 'South Florida (25.5-27°N)'
        ELSE 'Keys & Southernmost (<25.5°N)'
    END AS region,
    COUNT(*) AS parcel_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER(), 2) AS pct_of_total,
    ROUND(AVG(JV), 0) AS avg_just_value,
    ROUND(MEDIAN(JV), 0) AS median_just_value
FROM parcels
GROUP BY region
ORDER BY MIN(COALESCE(centroid_lat, 0)) DESC;

-- 8d. Parcels outside Florida bounding box (anomalies)
SELECT 'out_of_bounds_parcels' AS section;
SELECT
    county_name,
    COUNT(*) AS out_of_bounds_count,
    ROUND(MIN(centroid_lat), 4) AS min_lat,
    ROUND(MAX(centroid_lat), 4) AS max_lat,
    ROUND(MIN(centroid_lon), 4) AS min_lon,
    ROUND(MAX(centroid_lon), 4) AS max_lon
FROM parcels
WHERE centroid_lat IS NOT NULL
  AND centroid_lon IS NOT NULL
  AND (centroid_lat < 24.39 OR centroid_lat > 31.01
    OR centroid_lon < -87.64 OR centroid_lon > -79.97)
GROUP BY county_name
ORDER BY out_of_bounds_count DESC;
