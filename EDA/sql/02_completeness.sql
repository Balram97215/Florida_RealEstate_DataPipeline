-- ============================================================
-- EDA 02: Data Completeness (NULL / Missing Analysis)
-- Identifies columns with missing data and coverage rates
-- ============================================================

-- 2a. NULL counts and fill rates for key parcels columns
SELECT 'parcels_completeness' AS section;
SELECT
    COUNT(*)                                                     AS total_rows,
    -- Identity
    ROUND(100.0 * COUNT(PARCEL_ID)  / COUNT(*), 2)              AS pct_parcel_id,
    ROUND(100.0 * COUNT(PARCELNO)   / COUNT(*), 2)              AS pct_parcelno,
    ROUND(100.0 * COUNT(CO_NO)      / COUNT(*), 2)              AS pct_co_no,
    ROUND(100.0 * COUNT(county_name)/ COUNT(*), 2)              AS pct_county_name,
    -- Land Use
    ROUND(100.0 * COUNT(DOR_UC)             / COUNT(*), 2)      AS pct_dor_uc,
    ROUND(100.0 * COUNT(land_use_category)  / COUNT(*), 2)      AS pct_land_use_category,
    -- Valuation
    ROUND(100.0 * COUNT(JV)       / COUNT(*), 2)                AS pct_jv,
    ROUND(100.0 * COUNT(AV_SD)    / COUNT(*), 2)                AS pct_av_sd,
    ROUND(100.0 * COUNT(TV_SD)    / COUNT(*), 2)                AS pct_tv_sd,
    ROUND(100.0 * COUNT(LND_VAL)  / COUNT(*), 2)                AS pct_lnd_val,
    -- Building
    ROUND(100.0 * COUNT(TOT_LVG_AR)  / COUNT(*), 2)             AS pct_tot_lvg_ar,
    ROUND(100.0 * COUNT(NO_BULDNG)   / COUNT(*), 2)             AS pct_no_buldng,
    ROUND(100.0 * COUNT(EFF_YR_BLT)  / COUNT(*), 2)             AS pct_eff_yr_blt,
    ROUND(100.0 * COUNT(ACT_YR_BLT)  / COUNT(*), 2)             AS pct_act_yr_blt,
    -- Land
    ROUND(100.0 * COUNT(LND_SQFOOT)  / COUNT(*), 2)             AS pct_lnd_sqfoot,
    -- Owner
    ROUND(100.0 * COUNT(OWN_NAME)    / COUNT(*), 2)             AS pct_own_name,
    ROUND(100.0 * COUNT(OWN_STATE)   / COUNT(*), 2)             AS pct_own_state,
    -- Location
    ROUND(100.0 * COUNT(PHY_ADDR1)   / COUNT(*), 2)             AS pct_phy_addr1,
    ROUND(100.0 * COUNT(PHY_CITY)    / COUNT(*), 2)             AS pct_phy_city,
    -- Spatial
    ROUND(100.0 * COUNT(centroid_lat) / COUNT(*), 2)             AS pct_centroid_lat,
    ROUND(100.0 * COUNT(centroid_lon) / COUNT(*), 2)             AS pct_centroid_lon,
    ROUND(100.0 * COUNT(Shape_Area)   / COUNT(*), 2)             AS pct_shape_area,
    -- Sales
    ROUND(100.0 * COUNT(SALE_PRC1)   / COUNT(*), 2)              AS pct_sale_prc1,
    ROUND(100.0 * COUNT(SALE_PRC2)   / COUNT(*), 2)              AS pct_sale_prc2
FROM parcels;

-- 2b. Completeness for sales table
SELECT 'sales_completeness' AS section;
SELECT
    COUNT(*)                                                      AS total_rows,
    ROUND(100.0 * COUNT(sale_price)        / COUNT(*), 2)         AS pct_sale_price,
    ROUND(100.0 * COUNT(sale_year)         / COUNT(*), 2)         AS pct_sale_year,
    ROUND(100.0 * COUNT(sale_month)        / COUNT(*), 2)         AS pct_sale_month,
    ROUND(100.0 * COUNT(qualification_code)/ COUNT(*), 2)         AS pct_qualification_code,
    ROUND(100.0 * COUNT(county_name)       / COUNT(*), 2)         AS pct_county_name
FROM sales;
