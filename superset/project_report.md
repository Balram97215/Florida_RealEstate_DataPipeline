# Florida Parcels Analytics Platform
## Project Report — Community Dreams Foundation
**Prepared by:** Balram Bhanu Iyengar, Pro Bono BI Developer  
**Organization:** Community Dreams Foundation  
**Engagement Type:** Pro Bono | August 2025 – Present  
**Report Date:** April 2026

---

## Executive Summary

*(For: Leadership, Project Sponsors, Policy Teams)*

Community Dreams Foundation is a nonprofit organization working at the intersection of fair housing advocacy, tenant protection policy, and corporate accountability in real estate. When this engagement began in August 2025, the Foundation had no analytical infrastructure — staff relied on manual spreadsheet work and anecdotal observation to answer questions about housing consolidation patterns affecting millions of Floridians.

This project delivered a production-ready, end-to-end analytics platform that transforms 10.8 million Florida property records into actionable intelligence. For the first time, Foundation staff and policy partners can answer questions like:

- *Which counties show the highest concentration of corporate-owned residential parcels?*
- *What is the year-over-year trend in just values by land use category?*
- *Where are properties being bought in bulk (multi-parcel sales) and who is selling?*
- *Which ZIP codes carry the highest displacement risk based on valuation pressure and ownership change?*

**Key Outcomes:**

| Outcome | Before | After |
|---|---|---|
| Time to generate a county-level valuation report | 2–3 days | Under 1 hour |
| Data coverage | Fragmented, incomplete | All 68 Florida counties, 10.8M parcels |
| Dashboard visibility | None | 8 dashboards, 27+ analytical views |
| Corporate ownership baseline | Unknown | 21.4% identified statewide |
| Policy analysis reliability | Manual, error-prone | Automated validation framework |

The platform now directly supports the Foundation's fair housing regulatory submissions and community displacement risk assessments — reducing the time from data question to policy memo from days to hours.

---

## Why This Project Exists

*(Context for non-technical readers)*

Florida's housing landscape is undergoing a structural shift. Since 2020, corporate and institutional investors have accelerated acquisitions of single-family homes and residential parcels — particularly in high-growth markets like Tampa Bay, Orlando, and South Florida. This concentration has direct consequences for tenant affordability, displacement risk, and long-term community stability.

The Florida Department of Revenue publishes parcel-level data for all 10.8 million taxable properties in the state — including ownership records, assessed values, land use classifications, and sales history. This data is public and freely available, but it is published in a specialized geospatial format (Esri File Geodatabase, `.gdb`) that requires engineering expertise to access and analyze at scale.

Community Dreams Foundation lacked the technical infrastructure to work with this data. The Foundation could not track corporate ownership patterns, could not quantify displacement risk by geography, and could not produce the data-backed analyses needed to support regulatory advocacy with credibility.

This engagement was initiated to solve that problem — not just by answering one question, but by building the infrastructure to answer any question the Foundation needs to ask going forward.

---

## What Was Built

### 1. Data Pipeline (ELT Framework)

A fully automated, phase-based data pipeline was architected and implemented in Python:

```
Raw GDB File → Extract → Parquet Staging → Load → DuckDB Warehouse → Transform → SQL OBT → Validate → Superset Dashboards
```

**Extract Phase**
- Reads 10.8M parcel records from the Esri `.gdb` source format using GeoPandas
- Converts the native Florida GDL Albers coordinate system (EPSG:6439) to WGS84 lat/lon (EPSG:4326) for mapping compatibility
- Outputs data in chunked Parquet files (50,000 records per chunk) to handle memory constraints on standard hardware
- Preserves all 80+ original field columns for downstream analysis

**Load Phase**
- Bulk-loads all Parquet chunks into DuckDB — a high-performance, in-process analytical database
- Builds a staging table with all raw columns intact
- Applies memory limits and threading configuration for reproducibility on constrained hardware (4GB limit, 2 threads)

**Transform Phase**
- Executes a set of SQL scripts in dependency order:
  - **reference_data.sql** — Builds lookup tables mapping county codes → county names, and DOR land use codes → human-readable descriptions and categories
  - **parcels.sql** — Builds the core One Big Table (OBT): a denormalized analytical table joining parcel records with reference enrichment (county names, land use categories, homestead flags, valuation metrics, spatial coordinates)
  - **sales.sql** — Extracts and models the sales sub-table with qualified/disqualified transaction flags, multi-parcel sale indicators, and year/month fields for time-series analysis

**Validate Phase**
- Runs 12+ automated data quality checks:
  - Row count reconciliation (10,834,415 expected records vs actual)
  - Aggregate checksums for all valuation fields (JV, TV_SD, LND_VAL)
  - Referential integrity checks for enrichment joins
  - Null audits for critical identifier fields
  - Geographic boundary validation (all centroids within Florida bounding box)
  - Land use unmapping audit (flags any DOR codes without a category assignment)
- Each check returns a PASS/FAIL/WARN status and a human-readable detail string

### 2. Analytical Warehouse (DuckDB)

The pipeline produces a single, optimized DuckDB database file (`florida_parcels.duckdb`) containing:

- **`parcels`** — 10.8M row OBT with 80+ columns including valuation, ownership, building characteristics, land use, homestead status, and spatial coordinates
- **`sales`** — Sales transaction sub-table with qualification flags, price per square foot, and time fields
- **27 dashboard views** (`v_dash_*`) — Pre-aggregated analytical views, each optimized for a specific chart type in Superset
- **9 cross-validation views** (`v_cv_*`) — Views that reproduce EDA output exactly for independent verification

The choice of DuckDB was deliberate:
- **Zero infrastructure cost** — no server, no cloud bill, runs on a laptop or any standard machine
- **Columnar storage** — sub-second aggregation queries on 10M+ rows without indexing
- **SQL-native** — every transformation is written in standard SQL, auditable and portable
- **Read-only mount** — the database is mounted read-only inside Docker, preventing accidental writes from the dashboard layer

### 3. Dashboard Platform (Apache Superset)

Eight dashboards were designed and built on Apache Superset, served via Docker Compose (Superset app + PostgreSQL metadata store + Redis cache):

#### Dashboard 1: Property Valuation Overview
Statewide KPI cards (total parcels, total just value $5.26T, avg JV $485K, median JV $269K, county count 68), county-level valuation bar charts and rankings, land use breakdown by value share (donut + treemap), JV distribution histogram, and value-per-sqft comparisons by land use.

#### Dashboard 2: Sales Analysis
Sales volume and price KPIs, county-level sales rankings, year-over-year sales trend lines, sale price distribution histogram, qualified vs. disqualified transaction breakdown, and multi-parcel sale identification.

#### Dashboard 3: County Comparison
Side-by-side county scorecards covering parcel count, average JV, total taxable value, and sales metrics. Spatial scatter map showing county centroids weighted by total just value.

#### Dashboard 4: Land Use Deep Dive
Stacked county-by-land-use bar charts, top DOR land use codes table with counts and average values.

#### Dashboard 5: Building Characteristics
Year-built decade distribution, construction class breakdown, improvement quality distribution, living area histogram, and homestead exemption penetration analysis.

#### Dashboard 6: Spatial / Maps
County-level Deck.gl scatter map with value-weighted bubbles, latitude band analysis.

#### Dashboard 7: Assessment Analysis
Assessment ratio (JV/TV) by county, land value as a share of total just value, zero-value parcel analysis identifying data quality anomalies.

#### Dashboard 8: Owner Analysis
Owner state distribution (in-state vs. out-of-state vs. corporate), top 50 parcels by just value.

---

## Data Quality & Validation Framework

*(For: Finance/Operations Managers, Audit Teams)*

One of the most deliberate design decisions in this project was building validation in as a first-class component — not as an afterthought.

**Why this matters:** In a 10.8M record dataset, errors are invisible without systematic checking. A missing county join on even 0.1% of records = 10,800 mis-categorized parcels. A missing sales qualification flag = distorted price trend analysis.

**What was built:**
- 12 automated validation checks run at the end of every pipeline execution
- 9 cross-validation views that reproduce independent EDA numbers exactly — so any dashboard can be spot-checked against an independently computed CSV
- Geographic bounding box validation ensures all centroids fall within Florida's actual lat/lon range, catching any CRS conversion failures
- Every validation result is logged to `pipeline.log` with timestamp, check name, status, and detail string

This framework mirrors enterprise data quality practices (analogous to Great Expectations, dbt tests) but is implemented in pure SQL and Python — no additional dependencies, fully auditable.

---

## Technical Architecture Summary

*(For: IT Teams, BI Developers, Technical Reviewers)*

```
┌─────────────────────────────────────────────────────────────────┐
│  SOURCE DATA                                                    │
│  Florida DOR Parcel GDB (~4GB, 10.8M records, EPSG:6439)        │
└────────────────────┬────────────────────────────────────────────┘
                     │ GeoPandas + CRS Transform
                     ▼
┌─────────────────────────────────────────────────────────────────┐
│  STAGING LAYER                                                  │
│  Parquet chunks (50K rows/file) — data/raw/                     │
└────────────────────┬────────────────────────────────────────────┘
                     │ DuckDB bulk load
                     ▼
┌─────────────────────────────────────────────────────────────────┐
│  ANALYTICAL WAREHOUSE: florida_parcels.duckdb                   │
│  ┌──────────────┐  ┌────────────────┐  ┌──────────────────────┐ │
│  │ parcels OBT  │  │ sales          │  │ reference tables     │ │
│  │ 10.8M rows   │  │ (transactions) │  │ county / land use    │ │
│  └──────────────┘  └────────────────┘  └──────────────────────┘ │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │  27 v_dash_* views  +  9 v_cv_* validation views           │ │
│  └─────────────────────────────────────────────────────────────┘ │
└────────────────────┬────────────────────────────────────────────┘
                     │ SQLAlchemy (read-only mount)
                     ▼
┌─────────────────────────────────────────────────────────────────┐
│  PRESENTATION LAYER                                             │
│  Apache Superset (Docker)                                       │
│  8 Dashboards | 27 Charts | KPIs, Bar, Line, Donut, Map, Table  │
│  PostgreSQL (metadata) + Redis (cache)                          │
└─────────────────────────────────────────────────────────────────┘
```

**Technology choices and rationale:**

| Component | Tool | Why |
|---|---|---|
| Data extraction | Python + GeoPandas | Only reliable open-source parser for Esri GDB format |
| CRS transformation | pyproj | Standard for geodetic coordinate transforms |
| Analytical database | DuckDB | Zero-cost, columnar, handles 10M+ rows on laptop hardware |
| Transformation layer | SQL (DuckDB-native) | Portable, auditable, no ORM overhead |
| Dashboard platform | Apache Superset | Open-source, production-grade BI with 30+ chart types |
| Containerization | Docker Compose | Reproducible environment; one command to spin up |
| Data staging | Apache Parquet | Columnar, compressed, fast DuckDB bulk load |
| Validation | Custom SQL checks + Python | No external dependencies; results logged and auditable |

---

## Skills Demonstrated

*(Organized for hiring reviewers)*

**Data Engineering**
- End-to-end ELT pipeline design and implementation
- Geospatial data processing and CRS transformation
- Schema design (OBT pattern for analytical workloads)
- Data quality framework with automated validation checks

**Business Intelligence**
- Dashboard architecture for diverse stakeholder audiences (executive KPIs, operational detail, spatial analysis)
- Pre-aggregated view design for query performance
- Self-service analytics enablement via dataset-first Superset architecture

**SQL & Analytics**
- Complex multi-join transformations, window functions, CTEs
- Aggregate checksum and referential integrity validation in SQL
- Histogram bucketing, distribution analysis, time-series modeling

**Project Management (Pro Bono)**
- Scoped a multi-phase project independently with zero prior infrastructure
- Delivered in phases (Extract → Load → Transform → Validate → Dashboard) with working outputs at each stage
- Documented architecture, build guide, and validation procedures for handoff

---

## Mission Alignment

This project was built pro bono because the underlying data matters. Corporate consolidation of residential real estate is not an abstract trend — it is the mechanism by which communities lose affordable housing stock, and by which families face displacement from neighborhoods they have lived in for generations.

Community Dreams Foundation needed a way to see this happening in real time, at scale, with enough geographic specificity to take action. This platform gives them that capability.

The 21.4% corporate ownership baseline this analysis surfaced is not a final answer — it is a starting point. The platform is designed to be updated as new data vintages are released, and to grow as the Foundation's policy questions evolve.

---

## How to Access the Work

| Resource | Format | Description |
|---|---|---|
| Dashboard Screenshot | PNG (attached) | Property Valuation Overview — Dashboard 1 |
| GitHub Repository | [github.com/Balram97215](https://github.com/Balram97215) | Full source code: pipeline, SQL, Superset config |
| Live Walkthrough | Available on request | 20-min screen share of all 8 dashboards |

---

*Report prepared by Balram Bhanu Iyengar | iyengarbalram97@gmail.com | (413) 612-8297*
