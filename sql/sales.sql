-- ============================================================
-- sales: Normalized sale events unpivoted from parcels OBT
-- Sale 1 and Sale 2 become separate rows with a sale_sequence
-- Only rows with actual sale data (price > 0) are included.
-- Self-contained: county_name baked in (no JOIN needed at query time).
-- Idempotent: DROP + CREATE
-- ============================================================

DROP TABLE IF EXISTS sales;

CREATE TABLE sales AS

-- Sale sequence 1
SELECT
    OBJECTID,
    CO_NO,
    county_name,
    PARCEL_ID,
    1                   AS sale_sequence,
    SALE_PRC1           AS sale_price,
    CAST(SALE_YR1 AS INTEGER)  AS sale_year,
    SALE_MO1            AS sale_month,
    M_PAR_SAL1          AS multi_parcel_sale,
    QUAL_CD1            AS qualification_code,
    VI_CD1              AS vacancy_indicator,
    OR_BOOK1            AS official_record_book,
    OR_PAGE1            AS official_record_page,
    CLERK_NO1           AS clerk_number,
    S_CHNG_CD1          AS sale_change_code
FROM parcels
WHERE SALE_PRC1 IS NOT NULL AND SALE_PRC1 > 0

UNION ALL

-- Sale sequence 2
SELECT
    OBJECTID,
    CO_NO,
    county_name,
    PARCEL_ID,
    2                   AS sale_sequence,
    SALE_PRC2           AS sale_price,
    CAST(SALE_YR2 AS INTEGER)  AS sale_year,
    SALE_MO2            AS sale_month,
    M_PAR_SAL2          AS multi_parcel_sale,
    QUAL_CD2            AS qualification_code,
    VI_CD2              AS vacancy_indicator,
    OR_BOOK2            AS official_record_book,
    OR_PAGE2            AS official_record_page,
    CLERK_NO2           AS clerk_number,
    S_CHNG_CD2          AS sale_change_code
FROM parcels
WHERE SALE_PRC2 IS NOT NULL AND SALE_PRC2 > 0;
