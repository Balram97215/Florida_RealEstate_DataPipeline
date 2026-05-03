"""
Configuration constants for the Florida Parcels ELT pipeline.
"""
import os
from pathlib import Path

import duckdb

# ── Project Paths ──────────────────────────────────────────────
PROJECT_ROOT = Path(__file__).resolve().parent.parent
GDB_PATH = PROJECT_ROOT / "Parcels.gdb"
RAW_DIR = PROJECT_ROOT / "data" / "raw"
DUCKDB_PATH = PROJECT_ROOT / "data" / "florida_parcels.duckdb"
SQL_DIR = PROJECT_ROOT / "sql"

# ── Extraction Settings ───────────────────────────────────────
BATCH_SIZE = 50_000  # rows per Parquet chunk (tuned for 8GB RAM)
PARQUET_PREFIX = "parcels_batch"

# ── Coordinate Reference Systems ──────────────────────────────
CRS_SOURCE = "EPSG:6439"   # NAD83(2011) / Florida GDL Albers (actual .gdb CRS)
CRS_TARGET = "EPSG:4326"   # WGS84 lat/lon for Superset maps

# ── DuckDB Resource Limits (8GB laptop) ───────────────────────
DUCKDB_MEMORY_LIMIT = "4GB"
DUCKDB_THREADS = 2

# ── DuckDB Credentials (set via environment variables) ────────
# Usage:  export DUCKDB_USER="admin"
#         export DUCKDB_PASSWORD="your_secure_password"
DUCKDB_USER = os.environ.get("DUCKDB_USER", "")
DUCKDB_PASSWORD = os.environ.get("DUCKDB_PASSWORD", "")

# ── Florida Bounding Box (WGS84) for centroid validation ─────
FL_LAT_MIN = 24.39
FL_LAT_MAX = 31.01
FL_LON_MIN = -87.64
FL_LON_MAX = -79.97

# ── Expected Source Record Count ──────────────────────────────
EXPECTED_RECORD_COUNT = 10_834_415


def get_connection(read_only: bool = False) -> duckdb.DuckDBPyConnection:
    """Create a DuckDB connection with resource limits and credentials applied.

    Args:
        read_only: Open in read-only mode (for validation queries).

    Returns:
        Configured DuckDB connection.
    """
    DUCKDB_PATH.parent.mkdir(parents=True, exist_ok=True)

    config = {"threads": str(DUCKDB_THREADS), "memory_limit": DUCKDB_MEMORY_LIMIT}
    if DUCKDB_USER:
        config["user"] = DUCKDB_USER
    if DUCKDB_PASSWORD:
        config["password"] = DUCKDB_PASSWORD

    con = duckdb.connect(str(DUCKDB_PATH), read_only=read_only, config=config)
    return con
