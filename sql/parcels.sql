-- ============================================================
-- parcels: One Big Table (OBT) enriched from staging
-- One-time JOIN at build time; Superset queries this directly.
-- Idempotent: DROP + CREATE
-- ============================================================

DROP TABLE IF EXISTS parcels;

CREATE TABLE parcels AS
SELECT
    -- Identity
    s.OBJECTID,
    s.PARCEL_ID,
    s.PARCELNO,
    s.STATE_PAR_,
    s.ALT_KEY,
    s.FILE_T,
    s.OID_,

    -- County (natural key + enriched name)
    s.CO_NO,
    rc.county_name,

    -- Land Use (natural key + enriched description & category)
    s.DOR_UC,
    COALESCE(rl.description, 'Unknown (' || COALESCE(s.DOR_UC, 'NULL') || ')') AS land_use_description,
    COALESCE(rl.category, 'Unmapped')  AS land_use_category,

    -- Assessment
    s.ASMNT_YR,
    s.BAS_STRT,
    s.ATV_STRT,
    s.GRP_NO,
    s.PA_UC,
    s.SPASS_CD,

    -- Valuation measures
    s.JV,
    s.JV_CHNG,
    s.JV_CHNG_CD,
    s.AV_SD,
    s.AV_NSD,
    s.TV_SD,
    s.TV_NSD,
    s.LND_VAL,
    s.NCONST_VAL,
    s.DEL_VAL,

    -- Homestead
    s.JV_HMSTD,
    s.AV_HMSTD,
    s.JV_NON_HMS,
    s.AV_NON_HMS,

    -- Classification
    s.JV_RESD_NO,
    s.AV_RESD_NO,
    s.JV_CLASS_U,
    s.AV_CLASS_U,

    -- Special valuations
    s.JV_H2O_REC,
    s.AV_H2O_REC,
    s.JV_CONSRV_,
    s.AV_CONSRV_,
    s.JV_HIST_CO,
    s.AV_HIST_CO,
    s.JV_HIST_SI,
    s.AV_HIST_SI,
    s.JV_WRKNG_W,
    s.AV_WRKNG_W,

    -- Building
    s.TOT_LVG_AR,
    s.NO_BULDNG,
    s.NO_RES_UNT,
    s.EFF_YR_BLT,
    s.ACT_YR_BLT,
    s.CONST_CLAS,
    s.IMP_QUAL,
    s.SPEC_FEAT_,

    -- Land
    s.LND_SQFOOT,
    s.NO_LND_UNT,
    s.LND_UNTS_C,
    s.DT_LAST_IN,
    s.PAR_SPLT,

    -- Owner
    s.OWN_NAME,
    s.OWN_ADDR1,
    s.OWN_ADDR2,
    s.OWN_CITY,
    s.OWN_STATE,
    s.OWN_ZIPCD,
    s.OWN_STATE_,

    -- Fiduciary
    s.FIDU_NAME,
    s.FIDU_ADDR1,
    s.FIDU_ADDR2,
    s.FIDU_CITY,
    s.FIDU_STATE,
    s.FIDU_ZIPCD,
    s.FIDU_CD,

    -- Legal
    s.S_LEGAL,
    s.APP_STAT,
    s.CO_APP_STA,

    -- Location
    s.PHY_ADDR1,
    s.PHY_ADDR2,
    s.PHY_CITY,
    s.PHY_ZIPCD,
    s.MKT_AR,
    s.NBRHD_CD,
    s.TWN,
    s.RNG,
    s.SEC,
    s.CENSUS_BK,

    -- Administrative
    s.PUBLIC_LND,
    s.TAX_AUTH_C,
    s.DISTR_CD,
    s.DISTR_YR,

    -- Transfer / Portability
    s.ASS_TRNSFR,
    s.PREV_HMSTD,
    s.ASS_DIF_TR,
    s.CONO_PRV_H,
    s.PARCEL_ID_,
    s.YR_VAL_TRN,
    s.SEQ_NO,

    -- IDs
    s.RS_ID,
    s.MP_ID,
    s.SPC_CIR_CD,
    s.SPC_CIR_YR,
    s.SPC_CIR_TX,

    -- Sale columns (kept on OBT for direct access; also unpivoted into sales table)
    s.M_PAR_SAL1,
    s.QUAL_CD1,
    s.VI_CD1,
    s.SALE_PRC1,
    s.SALE_YR1,
    s.SALE_MO1,
    s.OR_BOOK1,
    s.OR_PAGE1,
    s.CLERK_NO1,
    s.S_CHNG_CD1,
    s.M_PAR_SAL2,
    s.QUAL_CD2,
    s.VI_CD2,
    s.SALE_PRC2,
    s.SALE_YR2,
    s.SALE_MO2,
    s.OR_BOOK2,
    s.OR_PAGE2,
    s.CLERK_NO2,
    s.S_CHNG_CD2,

    -- Spatial (computed during extraction)
    s.centroid_lat,
    s.centroid_lon,
    s.Shape_Area,
    s.Shape_Length

FROM staging_parcels s
LEFT JOIN ref_county rc
    ON CAST(s.CO_NO AS INTEGER) = rc.co_no
LEFT JOIN ref_land_use rl
    ON LPAD(CAST(s.DOR_UC AS VARCHAR), 4, '0') = rl.dor_uc;
