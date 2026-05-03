# Florida Parcels ELT Pipeline — Deep Dive

> **Audience:** Aspiring BI Engineers and Data Engineers who want to understand how
> a production-grade ELT pipeline is built on a constrained laptop, using modern
> open-source tools, and wired to a full BI layer.

---

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [Why ELT, Not ETL?](#2-why-elt-not-etl)
3. [Source Data — What Are We Working With?](#3-source-data--what-are-we-working-with)
4. [Technology Stack — Tools and Libraries](#4-technology-stack--tools-and-libraries)
5. [Architecture — How Everything Fits Together](#5-architecture--how-everything-fits-together)
6. [Phase 1 — Extract](#6-phase-1--extract)
7. [Phase 2 — Load](#7-phase-2--load)
8. [Phase 3 — Transform](#8-phase-3--transform)
9. [Phase 4 — Validate](#9-phase-4--validate)
10. [Data Model — What Gets Built](#10-data-model--what-gets-built)
11. [Compute Strategy — Running on 8 GB of RAM](#11-compute-strategy--running-on-8-gb-of-ram)
12. [Analytics Layer — Apache Superset](#12-analytics-layer--apache-superset)
13. [Exploratory Data Analysis Layer](#13-exploratory-data-analysis-layer)
14. [Project Structure Walkthrough](#14-project-structure-walkthrough)
15. [Running the Pipeline](#15-running-the-pipeline)
16. [Key Engineering Decisions and Lessons](#16-key-engineering-decisions-and-lessons)

---

## 1. Project Overview

This project builds a complete **ELT data pipeline** that ingests ~**10.8 million** Florida
real-estate parcel records from a proprietary geospatial file format, transforms them inside
an embedded analytical database, and surfaces the results through an Apache Superset
BI dashboard.

**In one sentence:** Raw geospatial government data → cleaned, enriched analytical tables →
eight interactive BI dashboards.

| Stat | Value |
|------|-------|
| Source record count | 10,834,415 parcels |
| Final `parcels` table | ~10.8 M rows, 100+ columns |
| Normalized `sales` table | ~1.49 M rows |
| Reference tables | `ref_county` (78 rows), `ref_land_use` (100+ codes) |
| Dashboard views | 27 pre-aggregated Superset views |
| Target machine | 8 GB RAM laptop |
| Runtime database | DuckDB (embedded, no server) |
| Visualization layer | Apache Superset (Docker) |

---

## 2. Why ELT, Not ETL?

This is one of the most important architectural decisions in modern data engineering.

### ETL (Extract → Transform → Load)

In the classic approach you would:
1. Extract data from the source
2. Transform it in Python (clean, reshape, enrich) in memory
3. Load the finished result into a database

The problem: transforming **10.8 million** multi-column geospatial records inside Python
memory would require either enormous RAM or complex chunked streaming logic for every
single transformation.

### ELT (Extract → Load → Transform)

This project uses the modern approach:
1. **Extract** raw data out of the proprietary format into an open format (Parquet)
2. **Load** those Parquet files into DuckDB with zero transformation
3. **Transform** inside DuckDB using pure SQL — the database does the heavy lifting

**Why this is better for this problem:**

- DuckDB executes SQL on Parquet files directly and spills to disk when memory is exhausted
  — no Python memory blowup.
- SQL is the most expressive, readable language for JOINs, CASE WHEN logic, aggregations, and
  window functions. Writing equivalent logic in Python/Pandas is more error-prone.
- Every transformation is declarative (`parcels.sql`, `sales.sql`) and reproducible. Anyone can
  read exactly what the output table contains.
- The pipeline is idempotent: every SQL file starts with `DROP TABLE IF EXISTS`. You can re-run
  any phase and get the same result.

---

## 3. Source Data — What Are We Working With?

### ESRI File Geodatabase (`.gdb`)

The source is `Parcels.gdb` — a proprietary **ESRI File Geodatabase** format published by the
Florida Department of Revenue (DOR). This is the standard format used by GIS professionals
and government agencies for distributing cadastral (land ownership) data.

A `.gdb` is not a single file — it is a **folder** containing dozens of binary files
(`.gdbtable`, `.gdbtablx`, `.gdbindexes`, `.atx` index files, etc.). Each file is a
low-level storage structure that ESRI's ArcGIS tools can read natively, but standard Python
tools cannot.

**Layer:** `CADASTRAL_DOR` — The main parcel feature class.

**What is a parcel?** A parcel is a legal subdivision of land. Every plot of land in Florida
has a parcel record containing:
- Identity fields (`PARCEL_ID`, `PARCELNO`, `OBJECTID`)
- Assessment & valuation (`JV` = Just Value, `TV_SD` = Taxable Value, `LND_VAL` = Land Value)
- Building characteristics (`TOT_LVG_AR`, `NO_BULDNG`, `EFF_YR_BLT`, `ACT_YR_BLT`)
- Ownership (`OWN_NAME`, `OWN_ADDR1`, `OWN_STATE`)
- Land use classification (`DOR_UC` — a 4-digit Florida DOR Use Code)
- County FIPS code (`CO_NO`)
- Sale history (two most recent sales: `SALE_PRC1`, `SALE_YR1`, `SALE_PRC2`, `SALE_YR2`, etc.)
- Polygon geometry (the actual shape of the parcel on the map)

**Coordinate Reference System (CRS):** EPSG:6439 — NAD83(2011) / Florida GDL Albers.
This is a projected coordinate system in meters, not degrees. Latitude/longitude values
do not exist natively in the file — they must be computed.

---

## 4. Technology Stack — Tools and Libraries

### Core Python Libraries

| Library | Version | Role | Why It Was Chosen |
|---------|---------|------|-------------------|
| **Fiona** | ≥ 1.9 | Read ESRI `.gdb` files | Fiona is the standard Python binding for GDAL/OGR. It is the only reliable open-source way to read ESRI geodatabase files without ArcGIS. Provides a dictionary-based feature iterator. |
| **Shapely** | ≥ 2.0 | Geometry operations | Computes polygon centroids. Shapely wraps GEOS (the same engine PostGIS uses) and provides a clean Python API for geometric operations. |
| **PyProj** | ≥ 3.6 | Coordinate reprojection | Transforms coordinates from EPSG:6439 (projected, meters) to EPSG:4326 (WGS84, lat/lon). Uses PROJ 9 under the hood. Thread-safe when built with `Transformer.from_crs()`. |
| **PyArrow** | ≥ 14.0 | Columnar memory + Parquet I/O | Provides an efficient columnar in-memory format. Used to write Parquet files from Python dicts. Also unlocks DuckDB's native Parquet reader. |
| **DuckDB** | ≥ 1.0 | Analytical database | Embedded OLAP database — no server required. Reads Parquet natively, executes SQL with a vectorized engine, supports out-of-core processing (spills to disk), and runs completely in-process. |

### Infrastructure

| Tool | Role |
|------|------|
| **Apache Superset** | BI dashboard and chart layer |
| **Docker / Docker Compose** | Containerized Superset deployment |
| **Python venv** | Isolated dependency environment |

### File Formats

| Format | Stage | Why |
|--------|-------|-----|
| `.gdb` | Source | Government-issued format; no choice |
| **Parquet** | Intermediate (staging) | Columnar, compressed (Snappy), DuckDB-native, schema-preserved. Ideal bridge between Python extraction and DuckDB loading. |
| **DuckDB** (`.duckdb`) | Final store | Single-file OLAP database. Zero infrastructure. Supports SQL, views, and read-only access for Superset. |

---

## 5. Architecture — How Everything Fits Together

```
┌─────────────────────────────────────────────────────────────────────┐
│                         SOURCE                                       │
│   Parcels.gdb  (ESRI File Geodatabase, ~10.8M features, EPSG:6439)  │
└────────────────────────────┬────────────────────────────────────────┘
                             │  Fiona (GDAL/OGR)
                             ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    EXTRACT  (src/extract.py)                         │
│  • Stream features in batches of 50,000                              │
│  • Compute polygon centroid via Shapely                              │
│  • Reproject centroid: EPSG:6439 → EPSG:4326 via PyProj             │
│  • Drop polygon geometry (keep only centroid lat/lon)               │
│  • Write each batch as Parquet (Snappy) via PyArrow                  │
│                                                                      │
│   data/raw/parcels_batch_0000.parquet                                │
│   data/raw/parcels_batch_0001.parquet  ← ~217 files                 │
│   ...                                                                │
└────────────────────────────┬────────────────────────────────────────┘
                             │  DuckDB read_parquet()
                             ▼
┌─────────────────────────────────────────────────────────────────────┐
│                     LOAD  (src/load.py)                              │
│  • DuckDB reads all Parquet chunks in one SQL statement              │
│  • Creates staging_parcels table (all raw columns)                   │
│  • Out-of-core: spills to disk if RAM exceeded                       │
│                                                                      │
│   DuckDB: staging_parcels  (10,834,415 rows)                         │
└────────────────────────────┬────────────────────────────────────────┘
                             │  Pure SQL
                             ▼
┌─────────────────────────────────────────────────────────────────────┐
│                  TRANSFORM  (src/transform.py)                       │
│                                                                      │
│  1. reference_data.sql  → ref_county, ref_land_use                   │
│  2. parcels.sql         → parcels  (OBT, enriched via JOINs)         │
│  3. sales.sql           → sales    (unpivoted sale events)           │
│                                                                      │
│  staging_parcels is DROPPED to reclaim disk space                    │
└────────────────────────────┬────────────────────────────────────────┘
                             │  SQL quality checks
                             ▼
┌─────────────────────────────────────────────────────────────────────┐
│                  VALIDATE  (src/validate.py)                         │
│  • 13+ automated checks (row counts, checksums, nulls, bounds)       │
│  • Returns PASS / WARN / FAIL per check                              │
│  • Exits non-zero on any FAIL (pipeline-safe)                        │
└────────────────────────────┬────────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────────┐
│               ANALYTICS LAYER  (superset/)                           │
│                                                                      │
│  create_views.py   → 27 pre-aggregated v_dash_* views               │
│                    → cross-validation v_cv_* views                   │
│                                                                      │
│  Apache Superset (Docker) → 8 dashboards                             │
│  http://localhost:8088                                               │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 6. Phase 1 — Extract

**File:** `src/extract.py`  
**Input:** `Parcels.gdb`  
**Output:** `data/raw/parcels_batch_NNNN.parquet`

### What happens

The extract phase does the only CPU-intensive Python work in the entire pipeline:
reading features from the `.gdb`, computing centroids, and writing Parquet files.

#### Step-by-step

**1. Layer discovery**

```python
layers = fiona.listlayers(str(gdb_path))
layer_name = layers[0]  # → "CADASTRAL_DOR"
```

Fiona wraps GDAL/OGR to introspect the `.gdb` without loading data. This discovers
the available feature classes (layers) inside the geodatabase.

**2. Coordinate transformer construction**

```python
transformer = Transformer.from_crs("EPSG:6439", "EPSG:4326", always_xy=True)
```

A single `Transformer` object is built once and reused for all 10.8 million features.
`always_xy=True` forces (longitude, latitude) output order regardless of the CRS axis
convention — a common bug source when omitted.

**3. Streaming feature iteration**

```python
with fiona.open(str(GDB_PATH), layer=layer_name) as src:
    for feature in src:
        record = dict(feature["properties"])
        record["OBJECTID"] = int(feature["id"])
        lat, lon = _compute_centroid(feature.get("geometry"), transformer)
        record["centroid_lat"] = lat
        record["centroid_lon"] = lon
        batch_records.append(record)
```

Fiona provides a **lazy iterator** — it reads one feature at a time, never loading the
entire 10.8 million records into RAM. This is the memory-safe design pattern for large
geospatial files.

Key detail: `OBJECTID` lives in `feature["id"]`, not in `feature["properties"]`. This is
a quirk of the `.gdb` format — the object identifier is stored as the feature's row ID,
not as a regular attribute column.

**4. Centroid computation and reprojection**

```python
geom = shape(geometry)          # Shapely geometry object
centroid = geom.centroid        # Point object (x, y) in source CRS
lon, lat = transformer.transform(centroid.x, centroid.y)
```

The polygon geometry (sometimes with thousands of vertices) is converted to a single
`(lat, lon)` centroid. This serves two purposes:
1. Map visualizations in Superset need WGS84 lat/lon
2. Dropping the polygon drastically reduces the output file size

**5. Batch Parquet writing**

```python
if len(batch_records) >= BATCH_SIZE:  # BATCH_SIZE = 50,000
    table = pa.Table.from_pydict(columns)
    pq.write_table(table, f, compression="snappy")
    batch_records.clear()
    gc.collect()
```

Every 50,000 records a Parquet file is written. `gc.collect()` explicitly reclaims
memory after each batch. This keeps the Python process well within 8 GB of RAM.

**Why Snappy compression?** Snappy is a LZ-family codec that prioritizes speed over
compression ratio. For a pipeline that reads and writes Parquet as a transient staging
format, fast decompression is more important than maximum file size reduction.

**Why PyArrow before Fiona?** There is a known import ordering conflict — both PyArrow
and GDAL (used by Fiona) try to register a `file://` filesystem scheme on import. If
Fiona is imported first, PyArrow throws an `ArrowKeyError`. The fix is to import
`pyarrow` before `fiona`.

---

## 7. Phase 2 — Load

**File:** `src/load.py`  
**Input:** `data/raw/parcels_batch_*.parquet`  
**Output:** `staging_parcels` table in DuckDB

### What happens

```python
con.execute(
    f"CREATE TABLE staging_parcels AS "
    f"SELECT * FROM read_parquet('{parquet_glob}')"
)
```

This single SQL statement does everything:
- DuckDB discovers all matching Parquet files via glob pattern
- It infers a unified schema across all files
- It reads the files in parallel (respecting `DUCKDB_THREADS = 2`)
- It materializes the result as a DuckDB table

**Why is this fast?** DuckDB uses a vectorized columnar execution engine. It reads Parquet
columns in batches rather than row-by-row. For this workload (10.8M rows) the load phase
typically completes in minutes on a laptop.

**Out-of-core processing:** DuckDB's memory manager monitors allocation. When working set
size approaches `DUCKDB_MEMORY_LIMIT = "4GB"`, it automatically spills intermediate data
to disk. The query still completes — just slower. This is the "out-of-core" capability.

### DuckDB Connection Configuration

```python
config = {
    "threads": "2",
    "memory_limit": "4GB"
}
con = duckdb.connect(str(DUCKDB_PATH), read_only=False, config=config)
```

Resource limits are applied at connection time. `threads = 2` prevents DuckDB from
consuming all CPU cores on an 8 GB machine (which would cause RAM contention with the OS).

---

## 8. Phase 3 — Transform

**File:** `src/transform.py`  
**Input:** `staging_parcels`, executed SQL scripts  
**Output:** `ref_county`, `ref_land_use`, `parcels`, `sales`

### SQL execution order matters

```python
SQL_FILES = [
    "reference_data.sql",   # Must run first — parcels.sql depends on these tables
    "parcels.sql",          # Must run second — sales.sql depends on parcels
    "sales.sql",
]
```

This is dependency management: each SQL file creates tables that subsequent files JOIN against.

### reference_data.sql — Building Lookup Tables

Two static reference tables are created:

**`ref_county`** — Maps Florida county FIPS codes (integers 0–77) to county names.

```sql
CREATE TABLE ref_county (
    co_no   INTEGER PRIMARY KEY,
    county_name VARCHAR NOT NULL
);
INSERT INTO ref_county VALUES (1, 'Alachua'), (2, 'Baker'), ...  -- 78 rows total
```

Why build this in SQL rather than a CSV import? Because it makes the pipeline
self-contained. No external file dependency. The reference data is version-controlled
directly in the SQL file.

**`ref_land_use`** — Maps 4-digit Florida DOR Use Codes to human-readable descriptions
and broad land use categories (`Residential`, `Commercial`, `Industrial`, `Agricultural`,
`Institutional`, `Government`, `Miscellaneous`).

```sql
CREATE TABLE ref_land_use (
    dor_uc      VARCHAR PRIMARY KEY,   -- e.g. '0001'
    description VARCHAR NOT NULL,      -- e.g. 'Single Family Residential'
    category    VARCHAR NOT NULL       -- e.g. 'Residential'
);
```

The `dor_uc` values are zero-padded 4-character strings because the raw `.gdb` field
stores the code as an integer (`1`). The transform JOIN uses `LPAD()` to normalize:

```sql
LEFT JOIN ref_land_use rl
    ON LPAD(CAST(s.DOR_UC AS VARCHAR), 4, '0') = rl.dor_uc
```

### parcels.sql — Building the One Big Table (OBT)

```sql
CREATE TABLE parcels AS
SELECT
    s.OBJECTID, s.PARCEL_ID, s.CO_NO,
    rc.county_name,                                    -- ← enriched from ref_county
    s.DOR_UC,
    COALESCE(rl.description, 'Unknown (...)') AS land_use_description,   -- ← enriched
    COALESCE(rl.category, 'Unmapped')         AS land_use_category,
    s.JV, s.TV_SD, s.LND_VAL,                         -- ← valuation columns
    s.centroid_lat, s.centroid_lon,                    -- ← computed at extract time
    ... -- 100+ additional columns
FROM staging_parcels s
LEFT JOIN ref_county rc  ON CAST(s.CO_NO AS INTEGER) = rc.co_no
LEFT JOIN ref_land_use rl ON LPAD(CAST(s.DOR_UC AS VARCHAR), 4, '0') = rl.dor_uc;
```

**What is an OBT (One Big Table)?**

The OBT is a denormalized table that collapses all necessary information into a single
wide table. Instead of requiring dashboards to JOIN multiple tables at query time
(which is slow at 10.8M rows), the JOINs are done once at build time. Superset queries
the `parcels` table directly with simple `GROUP BY` aggregations.

This is the correct pattern for OLAP (analytical) workloads where:
- Data is loaded periodically (not streaming)
- Queries are read-heavy (thousands of dashboard refreshes, no writes)
- The audience is business users who want fast responses

**`COALESCE` for graceful degradation:** If a land use code in the raw data doesn't
have a matching entry in `ref_land_use`, instead of NULL silently appearing in dashboards,
the pipeline produces `'Unknown (0099)'` — a self-documenting value that reveals the
unmapped code.

### sales.sql — Unpivoting Sale History

The raw parcel data stores up to two sale events per parcel as pairs of columns:
`SALE_PRC1`, `SALE_YR1`, `SALE_MO1`, ... and `SALE_PRC2`, `SALE_YR2`, `SALE_MO2`, ...

This is a **wide (pivoted) format** — inconvenient for time-series analysis and aggregation.
The `sales` table normalizes this into a **tall (unpivoted) format**:

```sql
CREATE TABLE sales AS
SELECT OBJECTID, PARCEL_ID, county_name, 1 AS sale_sequence,
       SALE_PRC1 AS sale_price, SALE_YR1 AS sale_year, ...
FROM parcels WHERE SALE_PRC1 > 0

UNION ALL

SELECT OBJECTID, PARCEL_ID, county_name, 2 AS sale_sequence,
       SALE_PRC2 AS sale_price, SALE_YR2 AS sale_year, ...
FROM parcels WHERE SALE_PRC2 > 0;
```

Result: ~1.49 million rows where each row is one sale event with `sale_sequence` (1 or 2)
identifying which slot it came from. This enables clean SQL like:

```sql
SELECT sale_year, AVG(sale_price) FROM sales GROUP BY sale_year ORDER BY sale_year;
```

**Note:** `county_name` is baked directly into the `sales` table (denormalized). This
means sales queries need zero JOINs — they are self-contained for Superset performance.

### Cleanup

```python
con.execute("DROP TABLE IF EXISTS staging_parcels")
```

Once the `parcels` table is built, `staging_parcels` is dropped. It is no longer needed
and consuming significant disk space.

---

## 9. Phase 4 — Validate

**File:** `src/validate.py`, `sql/validation.sql`  
**Input:** `parcels`, `sales`, `ref_county`, `ref_land_use`  
**Output:** PASS / WARN / FAIL report

### Why validate at all?

In a data pipeline, silent errors are more dangerous than loud failures. If 50,000 records
were dropped during extraction due to a bug, the `parcels` table would still exist and
Superset would still show charts — but with quietly wrong numbers.

Validation gates the pipeline. Any `FAIL` status causes `sys.exit(1)`, stopping downstream
processes.

### Validation checks

| Check | Type | What it verifies |
|-------|------|-----------------|
| `01_row_count_parcels` | PASS/FAIL | Exactly 10,834,415 rows in `parcels` |
| `03_checksum_jv` | PASS/FAIL | `SUM(JV)` is positive and non-null |
| `04_checksum_tv_sd` | PASS/FAIL | `SUM(TV_SD)` is positive and non-null |
| `05_checksum_lnd_val` | PASS/FAIL | `SUM(LND_VAL)` is positive and non-null |
| `06_county_name_completeness` | PASS/FAIL | Zero NULL `county_name` values |
| `07_land_use_unmapped_audit` | PASS/WARN | Count and list any unmapped DOR use codes |
| `08_null_audit_critical_fields` | PASS/FAIL | `OBJECTID`, `PARCEL_ID`, `CO_NO` never NULL |
| `09_centroid_bounds_check` | PASS/WARN | All centroids within Florida bounding box |
| `10_county_distribution` | PASS/WARN | All `CO_NO` values map to `ref_county` |
| `11_sales_price_checksum` | PASS/FAIL | `SUM(sales.sale_price)` matches original columns |
| `12_ref_county_count` | PASS/FAIL | Exactly 78 rows in `ref_county` |
| `13_objectid_uniqueness` | PASS/FAIL | No duplicate `OBJECTID` values in `parcels` |

Each query returns three columns: `check_name`, `status`, `details`. The `details`
column provides machine-readable context (`parcels_count=10834415 expected=10834415`)
that makes failures self-explanatory in logs.

**Aggregate checksum validation** is a core DQE (Data Quality Engineering) pattern:
if any extraction bug truncated data, changed types, or dropped rows, the sum of a
financial field like `JV` (Just Value) will diverge from the expected value — and the
FAIL check catches it.

---

## 10. Data Model — What Gets Built

```
florida_parcels.duckdb
│
├── staging_parcels          (temporary — dropped after transform)
│   └── All raw columns from Parquet, including centroid_lat/lon
│
├── ref_county               (78 rows)
│   ├── co_no INTEGER PK
│   └── county_name VARCHAR
│
├── ref_land_use             (100+ rows)
│   ├── dor_uc VARCHAR PK    -- '0001', '0002', etc.
│   ├── description VARCHAR
│   └── category VARCHAR
│
├── parcels                  (10,834,415 rows — OBT)
│   ├── OBJECTID             -- Unique row identifier from .gdb
│   ├── PARCEL_ID            -- Official parcel identifier string
│   ├── CO_NO + county_name  -- Raw code + enriched name
│   ├── DOR_UC + land_use_description + land_use_category
│   ├── JV, TV_SD, LND_VAL, AV_SD, AV_NSD, ...   -- Valuation
│   ├── TOT_LVG_AR, NO_BULDNG, EFF_YR_BLT, ...   -- Building
│   ├── OWN_NAME, OWN_ADDR1, OWN_STATE, ...       -- Ownership
│   ├── SALE_PRC1/2, SALE_YR1/2, SALE_MO1/2, ... -- Raw sale cols (kept for checksums)
│   ├── centroid_lat, centroid_lon                 -- Computed at extract
│   └── Shape_Area, Shape_Length                   -- From .gdb properties
│
├── sales                    (~1,491,760 rows — normalized)
│   ├── OBJECTID             -- FK to parcels
│   ├── CO_NO + county_name
│   ├── PARCEL_ID
│   ├── sale_sequence        -- 1 or 2
│   ├── sale_price
│   ├── sale_year, sale_month
│   ├── qualification_code, vacancy_indicator
│   └── official_record_book, official_record_page, clerk_number
│
└── Views (v_dash_*, v_cv_*)  -- Pre-aggregated for Superset
```

---

## 11. Compute Strategy — Running on 8 GB of RAM

This pipeline was intentionally designed to run on a **commodity 8 GB laptop**. Every
decision below is motivated by that constraint.

### The problem

- Raw `.gdb` file: several GB on disk
- ~10.8 million rows × 100+ columns × mixed types
- Python process + DuckDB process both need RAM simultaneously
- macOS kernel itself needs ~1–2 GB

### Strategy 1 — Batch streaming extraction (BATCH_SIZE = 50,000)

The extraction loop never holds more than 50,000 records in Python's heap at once. After
each batch is written to Parquet, the list is cleared and `gc.collect()` is called to
force CPython to reclaim the memory immediately rather than waiting for the garbage
collector's next cycle.

```python
BATCH_SIZE = 50_000   # 50K rows × ~200 bytes avg = ~10 MB per batch peak
```

At 10.8 million records this produces approximately 217 Parquet files, each roughly
3–8 MB (Snappy-compressed), totalling ~1 GB of intermediate storage.

### Strategy 2 — DuckDB memory cap

```python
DUCKDB_MEMORY_LIMIT = "4GB"
DUCKDB_THREADS = 2
```

DuckDB is capped at 4 GB. If a query's working set exceeds this, DuckDB spills
to disk automatically — the query slows down but does not OOM-kill the process.

`DUCKDB_THREADS = 2` limits parallelism. More threads = more concurrent memory
pressure. On 8 GB with a memory cap of 4 GB, 2 threads is the safe balance between
throughput and stability.

### Strategy 3 — Drop staging after transform

The `staging_parcels` table is temporary scaffolding. Once `parcels` and `sales` are
built, it is dropped:

```python
con.execute("DROP TABLE IF EXISTS staging_parcels")
```

DuckDB reclaims the disk space. The final `.duckdb` file only needs to hold the
analytically useful tables and views.

### Strategy 4 — Geometry dropped at extract time

The polygon geometry from the `.gdb` (sometimes thousands of lat/lon vertex pairs per
parcel) is discarded immediately after centroid computation. Storing polygon geometry
in DuckDB would require a geospatial extension and would increase the database size
dramatically. For BI dashboards, a single centroid point per parcel is sufficient for
map visualizations.

### Strategy 5 — Parquet as the bridge

Parquet's columnar layout means DuckDB can read only the columns it needs from each
file (column pruning). When the `CREATE TABLE staging_parcels AS SELECT * FROM read_parquet()`
statement runs, DuckDB reads all columns — but for a future query like
`SELECT OBJECTID, JV FROM parcels`, DuckDB would only decompress those two Parquet columns.

---

## 12. Analytics Layer — Apache Superset

### Why Superset?

Apache Superset is an open-source BI platform that connects to databases via SQLAlchemy
connection strings. It supports DuckDB through the `duckdb-engine` SQLAlchemy dialect.
The connection string for read-only access:

```
duckdb:////data/florida_parcels.duckdb?access_mode=read_only
```

Superset is deployed via **Docker Compose** (`superset/docker-compose.yml`). This means:
- No manual installation of Superset's Python dependencies into the project venv
- Superset runs in an isolated container
- The DuckDB file is mounted as a **read-only volume** inside the container:

```yaml
volumes:
  - ../data:/data:ro
```

`ro` (read-only mount) is a security measure — Superset cannot accidentally modify the
analytical database.

### Pre-aggregated Views

Rather than letting Superset run `SELECT county_name, SUM(JV) FROM parcels GROUP BY county_name`
against 10.8 million rows on every dashboard refresh, **27 pre-aggregated views** are
created in DuckDB:

```sql
CREATE OR REPLACE VIEW v_dash_valuation_by_county AS
SELECT
    CO_NO, county_name,
    COUNT(*) AS parcel_count,
    ROUND(SUM(JV) / 1e9, 2) AS total_jv_billions,
    ROUND(AVG(JV), 0) AS avg_jv,
    ...
FROM parcels
GROUP BY CO_NO, county_name
ORDER BY total_jv_billions DESC;
```

Superset queries `v_dash_valuation_by_county` (67 rows) instead of scanning 10.8 million
rows on every chart render. Dashboard response time drops from seconds to milliseconds.

### Dashboard Structure

| Dashboard | Views Used | Key Questions Answered |
|-----------|-----------|----------------------|
| 1 – Property Valuation Overview | `v_dash_statewide_kpi`, `v_dash_valuation_by_county`, `v_dash_valuation_by_land_use`, `v_dash_jv_distribution` | What is Florida's total property value? Which counties are most valuable? |
| 2 – Sales Analysis | `v_dash_sales_kpi`, `v_dash_sales_by_year`, `v_dash_sales_by_county`, `v_dash_sale_price_distribution` | How has real estate transaction volume changed over time? |
| 3 – County Comparison | `v_dash_county_scorecard`, `v_dash_county_map` | How does Broward compare to Miami-Dade in median JV? |
| 4 – Land Use Deep Dive | `v_dash_land_use_by_county`, `v_dash_top_land_use_codes` | What fraction of each county is agricultural vs residential? |
| 5 – Building Characteristics | `v_dash_year_built_decades`, `v_dash_construction_class`, `v_dash_improvement_quality` | How old is Florida's housing stock? |
| 6 – Spatial / Maps | `v_dash_county_map`, `v_dash_latitude_bands` | Geographic distribution of parcels and values |
| 7 – Assessment Analysis | `v_dash_assessment_ratio`, `v_dash_land_value_share`, `v_dash_zero_value_analysis` | Assessment ratios and anomalies |
| 8 – Ownership | `v_dash_owner_state`, `v_dash_top_parcels_by_jv` | Where do out-of-state owners live? What are the highest-value parcels? |

### Cross-Validation Views

A second set of views (`v_cv_*`) reproduces the exact numbers generated during EDA
(Exploratory Data Analysis). These exist to answer the question: *"Are the Superset
dashboard numbers accurate?"*

For example, `v_cv_valuation_stats` produces the same `JV mean=485,242` statistic that
the EDA notebook computed from a raw SQL query — confirming the OBT was built correctly.

---

## 13. Exploratory Data Analysis Layer

**Files:** `EDA/run_eda.py`, `EDA/sql/*.sql`

The EDA layer was built during the data understanding phase (before the pipeline was
finalized). It answers questions like:
- How many NULLs are in each column? (`02_completeness.sql`)
- What is the distribution of land use categories? (`03_categorical_profile.sql`)
- What are the mean, median, p95 of Just Value? (`04_numerical_profile.sql`)
- Which years had the most sales? (`05_temporal_analysis.sql`)
- Are all centroids within Florida? (`08_spatial_analysis.sql`)

The EDA orchestrator (`EDA/run_eda.py`) connects to the same `florida_parcels.duckdb`,
runs each SQL file, formats the output as text tables, and can export results as CSV
files (`EDA/output/`).

These CSV outputs became the **expected values** baked into `sql/validation.sql` and
`superset/sql/validation_views.sql`. The EDA came first; the validation checks confirm
the pipeline produces the same numbers EDA found.

---

## 14. Project Structure Walkthrough

```
NewProject_Pipeline/
│
├── src/                       Core pipeline modules
│   ├── __init__.py
│   ├── __main__.py            Entry point: from src.pipeline import main
│   ├── config.py              All paths, constants, DuckDB connection factory
│   ├── extract.py             Phase 1: .gdb → Parquet
│   ├── load.py                Phase 2: Parquet → DuckDB staging
│   ├── transform.py           Phase 3: SQL transformations
│   ├── validate.py            Phase 4: Data quality checks
│   └── pipeline.py            CLI orchestrator (argparse, logging, timing)
│
├── sql/                       SQL files executed by the pipeline
│   ├── reference_data.sql     CREATE TABLE ref_county, ref_land_use
│   ├── parcels.sql            CREATE TABLE parcels (OBT)
│   ├── sales.sql              CREATE TABLE sales (normalized sale events)
│   └── validation.sql         13+ data quality check queries
│
├── superset/                  Analytics and BI layer
│   ├── create_views.py        Creates v_dash_* and v_cv_* views in DuckDB
│   ├── validate_superset.py   Compares dashboard views against EDA CSVs
│   ├── sql/
│   │   ├── dashboard_views.sql    27 pre-aggregated views for Superset
│   │   └── validation_views.sql   Cross-validation views
│   ├── docker-compose.yml     Superset container configuration
│   ├── Dockerfile             Custom Superset image with duckdb-engine
│   ├── superset_config.py     Superset app configuration
│   ├── setup_superset.sh      One-command Superset startup script
│   └── DASHBOARD_BUILD_GUIDE.md   Step-by-step chart & dashboard instructions
│
├── EDA/                       Exploratory data analysis
│   ├── run_eda.py             Orchestrates all EDA SQL scripts
│   ├── sql/                   8 EDA scripts (overview, nulls, profiling, etc.)
│   └── output/                CSV exports from EDA runs
│
├── data/
│   ├── florida_parcels.duckdb The final analytical database
│   └── raw/                   Temporary Parquet chunks (extract output)
│
├── Parcels.gdb/               Source ESRI File Geodatabase (read-only)
│
├── tests/
│   └── smoke_test.py          End-to-end test: 100 records through full pipeline
│
├── Ed/
│   └── duckdb_basics.py       DuckDB learning notes and exploration
│
├── requirements.txt           fiona, shapely, pyproj, pyarrow, duckdb
└── pipeline.log               Append-mode log of all pipeline runs
```

---

## 15. Running the Pipeline

### Prerequisites

```bash
# Create and activate virtual environment
python -m venv .venv
source .venv/bin/activate

# Install dependencies
pip install -r requirements.txt
```

### Run full pipeline

```bash
python -m src.pipeline --phase all
```

### Run individual phases

```bash
python -m src.pipeline --phase extract    # .gdb → Parquet only
python -m src.pipeline --phase load       # Parquet → DuckDB staging only
python -m src.pipeline --phase transform  # SQL transformations only
python -m src.pipeline --phase validate   # Data quality checks only
```

### Run smoke test (100-record end-to-end check)

```bash
python tests/smoke_test.py
```

### Build Superset views and launch dashboards

```bash
# Create all v_dash_* views in DuckDB
python superset/create_views.py

# Launch Superset via Docker
cd superset
chmod +x setup_superset.sh
./setup_superset.sh

# Open browser → http://localhost:8088
# Login: admin / admin
```

### Run EDA

```bash
python EDA/run_eda.py              # Print all EDA results
python EDA/run_eda.py --save-csv   # Also export to EDA/output/
python EDA/run_eda.py --only 06    # Run only valuation analysis
```

---

## 16. Key Engineering Decisions and Lessons

### Decision 1 — Fiona over GeoPandas for extraction

GeoPandas (the common Python geospatial library) loads the **entire** geodatabase into
a `GeoDataFrame` in memory before you can iterate over it. At 10.8 million features,
that would instantly exhaust 8 GB of RAM.

Fiona provides a lazy iterator and is the underlying engine GeoPandas calls internally.
Using Fiona directly gives full control over batch size and memory.

### Decision 2 — PyArrow over Pandas for Parquet writing

Pandas can write Parquet via `df.to_parquet()`, but building a Pandas DataFrame from
50,000 dictionaries is slower and more memory-intensive than `pa.Table.from_pydict()`.
PyArrow's columnar format is also what DuckDB natively reads — no internal conversion
needed at load time.

### Decision 3 — DuckDB over PostgreSQL

A traditional pipeline might load staging data into a PostgreSQL database. DuckDB was
chosen because:
- **No server process** — DuckDB is an in-process library like SQLite
- **OLAP-optimized** — columnar storage and vectorized query execution for analytics
- **Native Parquet support** — `read_parquet()` with glob patterns
- **DuckDB-engine SQLAlchemy dialect** — Superset can connect directly
- **Zero infrastructure** — no `pg_hba.conf`, no port management, no service to keep running

### Decision 4 — OBT over star schema

A classic data warehouse would use a **star schema**: a fact table (`parcels`) with
foreign keys to dimension tables (`dim_county`, `dim_land_use`). For a BI tool like
Superset querying 10+ million rows, every JOIN is an additional cost.

The OBT trades storage space for query speed and simplicity. With only one table to
query, dashboard developers don't need to understand the schema — they just group by
`county_name` or `land_use_category` directly on the `parcels` table.

### Decision 5 — OBJECTID sourced from feature ID

This is a non-obvious detail. In ESRI geodatabases, `OBJECTID` is stored as the feature's
row identifier (`feature["id"]`), not as a regular property (`feature["properties"]`).
Using `feature["properties"]["OBJECTID"]` would return `None` for every record.

The correct pattern is:
```python
record["OBJECTID"] = int(feature["id"])
```

This was discovered via smoke testing (`tests/smoke_test.py`) early in development and
then validated in the `08_null_audit_critical_fields` check.

### Decision 6 — Idempotent pipeline design

Every SQL file begins with `DROP TABLE IF EXISTS`. The extract phase deletes previous
Parquet files at startup. The load phase drops the staging table before recreating it.

This means the pipeline can be re-run at any time without leaving corrupt or partial state.
In production data engineering, idempotency is a fundamental property — it makes
debugging, reprocessing, and automation safe.

### Decision 7 — Logging to both console and file

```python
handlers = [
    logging.StreamHandler(sys.stdout),
    logging.FileHandler("pipeline.log", mode="a"),
]
```

`mode="a"` (append) preserves all historical runs in `pipeline.log`. The log contains
timing for each phase, row counts after each operation, and PASS/FAIL for every
validation check. This is essential for debugging a run that completed hours ago without
an active terminal.

### Decision 8 — Environment variables for credentials

```python
DUCKDB_USER = os.environ.get("DUCKDB_USER", "")
DUCKDB_PASSWORD = os.environ.get("DUCKDB_PASSWORD", "")
```

Credentials are never hardcoded in source files. This follows the
[12-Factor App](https://12factor.net/config) principle and prevents accidental exposure
through version control.

---

## Summary

This pipeline demonstrates a complete, production-quality data engineering workflow at
a meaningful scale (10+ million records) on constrained hardware:

| Concern | Solution Used |
|---------|--------------|
| Read proprietary geospatial format | Fiona (GDAL wrapper) |
| Coordinate reprojection | PyProj + Shapely |
| Memory-safe extraction at scale | Batch streaming, 50K rows/batch, gc.collect() |
| Efficient intermediate storage | Parquet (Snappy) via PyArrow |
| Analytics database (no server) | DuckDB (embedded OLAP) |
| Heavy transformation without OOM | ELT: SQL inside DuckDB |
| Data quality assurance | 13-check validation layer, PASS/WARN/FAIL |
| Fast BI dashboard queries | 27 pre-aggregated views |
| BI visualization | Apache Superset via Docker |
| Reproducibility | Idempotent SQL, environment variables |
| Compute on 8 GB RAM | Memory cap, thread limit, out-of-core spill |

The architecture scales: the same patterns (batch Parquet extraction → DuckDB ELT →
Superset dashboards) are used at companies running petabyte-scale pipelines, just with
distributed Parquet storage (S3), a distributed query engine (Spark, Trino), and a
managed Superset deployment.
