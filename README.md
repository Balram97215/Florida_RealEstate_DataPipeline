# Florida Real Estate Data Pipeline

A production-grade ELT (Extract → Load → Transform → Validate) pipeline and analytics platform.

The platform processes **10.8 million Florida property parcel records** across all 68 counties, transforming raw geospatial data into a fully validated analytical warehouse with interactive Superset dashboards.

---

## Table of Contents

- [Project Overview](#project-overview)
- [Architecture](#architecture)
- [Repository Structure](#repository-structure)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Pipeline Phases](#pipeline-phases)
- [SQL Layer](#sql-layer)
- [Exploratory Data Analysis](#exploratory-data-analysis)
- [Superset Dashboards](#superset-dashboards)
- [Data Validation](#data-validation)
- [Configuration](#configuration)
- [Running Tests](#running-tests)

---

## Project Overview

Florida's Department of Revenue publishes parcel-level data for all 10.8 million taxable properties in the state — ownership records, assessed values, land use classifications, and sales history. This data is published in Esri File Geodatabase (`.gdb`) format, which requires engineering work to access at scale.

This project delivers:

| Capability | Detail |
|---|---|
| **Data Coverage** | All 68 Florida counties, 10,834,415 parcel records |
| **Pipeline** | Automated 4-phase ELT: Extract → Load → Transform → Validate |
| **Warehouse** | DuckDB analytical database with denormalized OBT |
| **Analytics** | 8 EDA modules + 27+ Superset dashboard views |
| **Validation** | Automated cross-validation framework (12+ quality checks) |
| **Key Finding** | 21.4% corporate ownership concentration identified statewide |

---

## Architecture

```
Parcels.gdb (Esri Geodatabase)
        │
        ▼
┌──────────────┐
│   EXTRACT    │  fiona + pyproj + shapely
│              │  CRS: EPSG:6439 → EPSG:4326
│              │  Output: Parquet chunks (50k rows each)
└──────┬───────┘
       │
       ▼
┌──────────────┐
│     LOAD     │  DuckDB read_parquet (out-of-core)
│              │  → staging_parcels table
└──────┬───────┘
       │
       ▼
┌──────────────┐
│  TRANSFORM   │  SQL execution (reference_data → parcels → sales)
│              │  → ref_county, ref_land_use, parcels (OBT), sales
└──────┬───────┘
       │
       ▼
┌──────────────┐
│   VALIDATE   │  12+ automated data quality checks
│              │  Row counts, null rates, geographic bounds, etc.
└──────┬───────┘
       │
       ▼
┌──────────────┐
│   SUPERSET   │  Docker: Superset + Postgres + Redis
│              │  27+ pre-aggregated views, 8 dashboards
└──────────────┘
```

---

## Repository Structure

```
.
├── src/                        # Pipeline source code
│   ├── config.py               # Paths, constants, DuckDB connection factory
│   ├── extract.py              # GDB → Parquet extraction
│   ├── load.py                 # Parquet → DuckDB staging
│   ├── transform.py            # SQL-based transformations
│   ├── validate.py             # Data quality checks
│   ├── pipeline.py             # CLI orchestrator
│   └── __main__.py             # Entry point (python -m src)
│
├── sql/                        # Core transformation SQL
│   ├── reference_data.sql      # County and land use lookup tables
│   ├── parcels.sql             # Core OBT (One Big Table)
│   ├── sales.sql               # Sales sub-table with flags
│   └── validation.sql          # Validation query set
│
├── EDA/                        # Exploratory Data Analysis
│   ├── run_eda.py              # EDA orchestrator
│   └── sql/                    # 8 analytical SQL modules
│       ├── 01_overview.sql
│       ├── 02_completeness.sql
│       ├── 03_categorical_profile.sql
│       ├── 04_numerical_profile.sql
│       ├── 05_temporal_analysis.sql
│       ├── 06_valuation_analysis.sql
│       ├── 07_sales_analysis.sql
│       └── 08_spatial_analysis.sql
│
├── superset/                   # Dashboard infrastructure
│   ├── docker-compose.yml      # Superset + Postgres + Redis stack
│   ├── Dockerfile              # Custom Superset image with duckdb-engine
│   ├── superset_config.py      # Superset configuration (reads from env)
│   ├── .env.example            # Environment variable template
│   ├── setup_superset.sh       # One-command stack launcher
│   ├── create_views.py         # Creates DuckDB views for dashboards
│   ├── validate_superset.py    # Cross-validates dashboard vs EDA output
│   └── sql/
│       ├── dashboard_views.sql # 27+ v_dash_* analytical views
│       └── validation_views.sql# 9 v_cv_* cross-validation views
│
├── tests/
│   └── smoke_test.py           # End-to-end smoke test (100 records)
│
└── requirements.txt            # Python dependencies
```

> **Not in this repo (data files):** `Parcels.gdb/`, `data/florida_parcels.duckdb` — too large for version control. See [Prerequisites](#prerequisites) for data acquisition.

---

## Prerequisites

### System Requirements
- Python 3.11+
- Docker Desktop (for Superset dashboards)
- ~15 GB free disk space (GDB source ~4 GB, DuckDB warehouse ~8 GB)
- 8 GB RAM recommended (pipeline configured for 4 GB DuckDB limit)

### Python Dependencies

```bash
pip install -r requirements.txt
```

| Package | Purpose |
|---|---|
| `fiona` | Read Esri `.gdb` geospatial format |
| `shapely` | Geometry centroid computation |
| `pyproj` | CRS reprojection (EPSG:6439 → WGS84) |
| `pyarrow` | Parquet file I/O |
| `duckdb` | Analytical database engine |

### Data Source

The pipeline expects the **Florida Department of Revenue parcel dataset** in Esri File Geodatabase format, placed at `Parcels.gdb/` in the project root. This is a public dataset available from:

> Florida Department of Revenue — Property Tax Data  
> https://floridarevenue.com/property/Pages/DataPortal.aspx

---

## Quick Start

### 1. Set up environment

```bash
python -m venv .venv
source .venv/bin/activate          # Windows: .venv\Scripts\activate
pip install -r requirements.txt
```

### 2. Run the full pipeline

```bash
# Full pipeline (all 4 phases)
python -m src --phase all

# Or run individual phases
python -m src --phase extract
python -m src --phase load
python -m src --phase transform
python -m src --phase validate
```

### 3. Run EDA

```bash
# Print all analyses to console
python EDA/run_eda.py

# Save results to EDA/output/ as CSV
python EDA/run_eda.py --save-csv

# Run a specific module (e.g. module 03)
python EDA/run_eda.py --only 03
```

### 4. Launch Superset dashboards

```bash
# Copy and configure the env file
cp superset/.env.example superset/.env
# Edit superset/.env — set a strong SUPERSET_SECRET_KEY

# Create DuckDB dashboard views
python superset/create_views.py

# Launch the Docker stack
cd superset
./setup_superset.sh
```

Open **http://localhost:8088** — login with `admin` / `admin` (local development only).

For full dashboard setup instructions, see [superset/DASHBOARD_BUILD_GUIDE.md](superset/DASHBOARD_BUILD_GUIDE.md).

---

## Pipeline Phases

### Extract (`src/extract.py`)

Reads from `Parcels.gdb` using `fiona`, processes records in batches of 50,000, and writes Parquet chunks to `data/raw/`. For each feature:
- Extracts all 80+ property fields from the GDB layer
- Computes centroid coordinates and reprojects from **EPSG:6439** (Florida GDL Albers / NAD83) to **EPSG:4326** (WGS84) using `pyproj`
- Drops polygon geometry — stores only centroid lat/lon for mapping

### Load (`src/load.py`)

Bulk-loads all Parquet chunks into DuckDB as `staging_parcels` using `read_parquet()`. DuckDB's out-of-core processing handles datasets larger than available RAM.

### Transform (`src/transform.py`)

Executes SQL files in dependency order:

1. **`reference_data.sql`** — Builds `ref_county` (67 county code → name mappings) and `ref_land_use` (DOR land use code → category/description)
2. **`parcels.sql`** — Builds `parcels` OBT: joins staging data with reference tables, computes derived fields (homestead flag, just value per sqft, building age), and drops staging
3. **`sales.sql`** — Builds `sales` table: extracts qualified/disqualified transactions, flags multi-parcel sales, parses year/month

### Validate (`src/validate.py`)

Executes `sql/validation.sql` — a set of named SQL queries each returning `(check_name, status, details)` where status is `PASS`, `WARN`, or `FAIL`. Checks include:

- Record count reconciliation (expected: 10,834,415)
- Null rates for critical columns
- Geographic bounds validation (Florida lat/lon bounding box)
- Referential integrity (county codes, land use codes)
- Sales price sanity checks

---

## SQL Layer

### `sql/parcels.sql`

Builds the core analytical table from `staging_parcels` + reference tables. Key derived columns:

| Column | Description |
|---|---|
| `county_name` | Human-readable county name (joined from `ref_county`) |
| `land_use_category` | Grouped land use category (Residential / Commercial / etc.) |
| `homestead_flag` | Boolean — parcel qualifies for homestead exemption |
| `jv_per_sqft` | Just value ÷ living area (valuation density metric) |
| `building_age` | Current year − year built |
| `centroid_lat/lon` | WGS84 coordinates for map visualizations |

### `sql/sales.sql`

Extracts from the embedded sales fields in parcel records. Key columns:

| Column | Description |
|---|---|
| `qualified_sale` | Boolean — meets arm's length criteria |
| `multi_parcel_flag` | True if multiple parcels sold in same transaction |
| `sale_year` / `sale_month` | Parsed from sale date for time-series analysis |
| `price_per_sqft` | Sale price ÷ living area |

---

## Exploratory Data Analysis

Eight SQL analysis modules under `EDA/sql/`:

| Module | Scope |
|---|---|
| `01_overview` | Table row counts, schema inventory, sample rows |
| `02_completeness` | NULL rates per column for all tables |
| `03_categorical_profile` | Cardinality, top values, distributions for string columns |
| `04_numerical_profile` | Min/max/mean/stddev/percentiles for numeric columns |
| `05_temporal_analysis` | Year built distribution, sale year trends, decade buckets |
| `06_valuation_analysis` | JV histograms, assessment ratios, land value share, homestead analysis |
| `07_sales_analysis` | Sales overview, qualification breakdown, multi-parcel detection |
| `08_spatial_analysis` | County density, centroid coverage, latitude band distribution |

---

## Superset Dashboards

The `superset/` directory contains a Docker Compose stack with:

- **Apache Superset** — dashboard and BI layer
- **PostgreSQL** — Superset metadata database
- **Redis** — query result cache and Celery broker

### Dashboard Views (`superset/sql/dashboard_views.sql`)

27+ pre-aggregated views named `v_dash_*`:

| View | Purpose |
|---|---|
| `v_dash_county_summary` | Parcel counts and median JV by county |
| `v_dash_land_use_breakdown` | Distribution across land use categories |
| `v_dash_corporate_ownership` | Owner-state analysis (in-state vs out-of-state) |
| `v_dash_valuation_by_county` | Median/mean just values per county |
| `v_dash_sales_by_year` | Annual sales volume and average price |
| `v_dash_building_age_dist` | Year-built distribution by decade |
| `v_dash_map_centroids` | Parcel centroid lat/lon for map charts |
| `v_dash_assessment_ratio` | Assessed vs just value ratios by county |
| *(and 19 more)* | |

### Cross-Validation Views (`superset/sql/validation_views.sql`)

9 `v_cv_*` views that expose validation metrics directly in Superset — ensuring dashboard numbers are independently verifiable against the EDA output CSVs.

---

## Data Validation

Run cross-validation between Superset views and EDA output:

```bash
python superset/validate_superset.py
```

This script compares key metrics (row counts, distributions, valuation figures) between the `v_cv_*` DuckDB views and the CSV files in `EDA/output/`, reporting pass/fail for each check.

---

## Configuration

All configurable values are in `src/config.py`. Sensitive values are read from environment variables:

| Variable | Description |
|---|---|
| `DUCKDB_USER` | DuckDB username (optional) |
| `DUCKDB_PASSWORD` | DuckDB password (optional) |

Key constants (edit in `src/config.py`):

| Constant | Default | Description |
|---|---|---|
| `BATCH_SIZE` | `50_000` | Records per Parquet chunk |
| `DUCKDB_MEMORY_LIMIT` | `"4GB"` | DuckDB memory cap |
| `DUCKDB_THREADS` | `2` | DuckDB thread count |
| `CRS_SOURCE` | `"EPSG:6439"` | Source CRS of the GDB |
| `CRS_TARGET` | `"EPSG:4326"` | Output CRS (WGS84) |

For Superset, copy `superset/.env.example` to `superset/.env` and set:

```bash
SUPERSET_SECRET_KEY=<strong-random-key>
```

---

## Running Tests

```bash
# Smoke test — runs end-to-end pipeline on 100 records
python tests/smoke_test.py
```

The smoke test extracts 100 records from the GDB, loads them into an in-memory DuckDB instance, and verifies that all pipeline phases complete without error.
