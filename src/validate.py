"""
Validate phase: Run data quality checks against the DuckDB database.
Executes validation SQL and reports pass/fail for each check.
"""
import logging
import time

from src.config import DUCKDB_PATH, SQL_DIR, get_connection

logger = logging.getLogger(__name__)


def validate() -> dict:
    """Run all validation queries from sql/validation.sql.

    Returns a summary dict with results per check and overall pass/fail.
    """
    start_time = time.time()
    sql_path = SQL_DIR / "validation.sql"
    sql_text = sql_path.read_text(encoding="utf-8")

    # Strip comments so semicolons in comments don't break splitting
    import re
    clean_sql = re.sub(r"--[^\n]*", "", sql_text)
    queries = [s.strip() for s in clean_sql.split(";") if s.strip()]

    # Filter to only SELECT statements
    select_queries = [q for q in queries if "SELECT" in q.upper()]

    con = get_connection(read_only=True)
    results = []
    all_passed = True
    has_warnings = False

    try:

        for query in select_queries:
            try:
                row = con.execute(query).fetchone()
                if row is None:
                    continue
                check_name, status, details = row[0], row[1], row[2]
                results.append({
                    "check": check_name,
                    "status": status,
                    "details": details,
                })

                if status == "FAIL":
                    all_passed = False
                    logger.error("FAIL  %s — %s", check_name, details)
                elif status == "WARN":
                    has_warnings = True
                    logger.warning("WARN  %s — %s", check_name, details)
                else:
                    logger.info("PASS  %s — %s", check_name, details)

            except Exception as e:
                check_name = "unknown"
                # Try to extract check name from query
                for line in query.splitlines():
                    if "check_name" in line and "AS" in line:
                        parts = line.split("'")
                        if len(parts) >= 2:
                            check_name = parts[1]
                        break
                results.append({
                    "check": check_name,
                    "status": "ERROR",
                    "details": str(e),
                })
                all_passed = False
                logger.error("ERROR %s — %s", check_name, e)

    finally:
        con.close()

    elapsed = time.time() - start_time

    # Summary
    passed = sum(1 for r in results if r["status"] == "PASS")
    warned = sum(1 for r in results if r["status"] == "WARN")
    failed = sum(1 for r in results if r["status"] in ("FAIL", "ERROR"))
    total = len(results)

    logger.info("=" * 60)
    logger.info(
        "VALIDATION SUMMARY: %d/%d passed, %d warnings, %d failed (%.1fs)",
        passed,
        total,
        warned,
        failed,
        elapsed,
    )
    if all_passed and not has_warnings:
        logger.info("ALL CHECKS PASSED")
    elif all_passed:
        logger.info("ALL CHECKS PASSED (with warnings)")
    else:
        logger.error("VALIDATION FAILED — review errors above")
    logger.info("=" * 60)

    return {
        "results": results,
        "passed": passed,
        "warned": warned,
        "failed": failed,
        "total": total,
        "all_passed": all_passed,
        "elapsed_seconds": round(elapsed, 1),
    }
