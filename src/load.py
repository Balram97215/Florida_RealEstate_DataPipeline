"""
Load phase: Parquet chunks → DuckDB staging table.
Uses DuckDB's native read_parquet with out-of-core processing.
"""
import logging
import time

from src.config import DUCKDB_PATH, RAW_DIR, get_connection

logger = logging.getLogger(__name__)


def load() -> dict:
    """Load all Parquet files from data/raw/ into DuckDB staging_parcels table.

    Returns a summary dict with row_count and elapsed_seconds.
    """
    parquet_glob = str(RAW_DIR / "parcels_batch_*.parquet")

    start_time = time.time()
    logger.info("Connecting to DuckDB at %s", DUCKDB_PATH)

    con = get_connection()
    try:

        # Idempotent: drop previous staging table
        con.execute("DROP TABLE IF EXISTS staging_parcels")
        logger.info("Loading Parquet files from %s", parquet_glob)

        # DuckDB handles out-of-core processing (spills to disk)
        con.execute(
            f"CREATE TABLE staging_parcels AS SELECT * FROM read_parquet('{parquet_glob}')"
        )

        row_count = con.execute("SELECT COUNT(*) FROM staging_parcels").fetchone()[0]
        elapsed = time.time() - start_time

        logger.info(
            "Staging table loaded: %d rows in %.1fs", row_count, elapsed
        )

        # Log column count for verification
        col_count = len(
            con.execute(
                "SELECT column_name FROM information_schema.columns "
                "WHERE table_name = 'staging_parcels'"
            ).fetchall()
        )
        logger.info("Staging table has %d columns", col_count)

    finally:
        con.close()

    return {
        "row_count": row_count,
        "elapsed_seconds": round(elapsed, 1),
    }
