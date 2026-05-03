"""
Transform phase: Execute SQL scripts to build OBT and sales from staging.
Runs inside DuckDB — all heavy lifting done by the SQL engine.
"""
import logging
import time

from src.config import DUCKDB_PATH, SQL_DIR, get_connection

logger = logging.getLogger(__name__)

# SQL execution order matters: reference tables → OBT → sales
SQL_FILES = [
    "reference_data.sql",
    "parcels.sql",
    "sales.sql",
]


def _strip_sql_comments(sql_text: str) -> str:
    """Remove single-line (--) comments so semicolons in comments don't break splitting."""
    import re
    return re.sub(r"--[^\n]*", "", sql_text)


def _execute_sql_file(con: duckdb.DuckDBPyConnection, sql_file: str) -> None:
    """Read and execute a SQL file. Supports multiple statements separated by ';'."""
    path = SQL_DIR / sql_file
    logger.info("Executing %s ...", path.name)
    sql_text = path.read_text(encoding="utf-8")

    # Strip comments first so semicolons inside comments don't split statements
    clean_sql = _strip_sql_comments(sql_text)
    statements = [s.strip() for s in clean_sql.split(";") if s.strip()]

    executed = 0
    for stmt in statements:
        if not stmt:
            continue
        con.execute(stmt)
        executed += 1

    logger.info("Completed %s (%d statements)", path.name, executed)


def transform() -> dict:
    """Run all transformation SQL files in dependency order.

    Returns a summary dict with table row counts and elapsed time.
    """
    start_time = time.time()

    con = get_connection()
    try:

        for sql_file in SQL_FILES:
            _execute_sql_file(con, sql_file)

        # Collect row counts for summary
        counts = {}
        for table in ["ref_county", "ref_land_use", "parcels", "sales"]:
            cnt = con.execute(f"SELECT COUNT(*) FROM {table}").fetchone()[0]
            counts[table] = cnt
            logger.info("Table %-15s: %d rows", table, cnt)

        # Drop staging to reclaim disk space
        con.execute("DROP TABLE IF EXISTS staging_parcels")
        logger.info("Dropped staging_parcels to reclaim disk space")

    finally:
        con.close()

    elapsed = time.time() - start_time
    counts["elapsed_seconds"] = round(elapsed, 1)
    logger.info("Transform complete in %.1fs", elapsed)
    return counts
