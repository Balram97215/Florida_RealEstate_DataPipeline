#!/usr/bin/env python3
"""
create_views.py – Standalone script to create dashboard + validation
views in DuckDB. Run this if you only need to refresh views without
restarting Superset.

Usage:
    python superset/create_views.py
"""

import os
import sys

# Add project root to path
project_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, project_dir)

import duckdb

DUCKDB_PATH = os.path.join(project_dir, "data", "florida_parcels.duckdb")
SQL_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "sql")


def execute_sql_file(conn: duckdb.DuckDBPyConnection, filepath: str) -> int:
    """Execute a SQL file, splitting on semicolons. Returns statement count."""
    with open(filepath) as f:
        content = f.read()

    count = 0
    for stmt in content.split(";"):
        # Strip comments-only blocks but keep statements with inline comments
        lines = [l for l in stmt.strip().splitlines() if l.strip() and not l.strip().startswith("--")]
        cleaned = "\n".join(lines).strip()
        if cleaned:
            conn.execute(stmt.strip())
            count += 1
    return count


def main():
    if not os.path.exists(DUCKDB_PATH):
        print(f"ERROR: Database not found at {DUCKDB_PATH}")
        print("       Run the ELT pipeline first.")
        sys.exit(1)

    conn = duckdb.connect(DUCKDB_PATH)

    dashboard_sql = os.path.join(SQL_DIR, "dashboard_views.sql")
    validation_sql = os.path.join(SQL_DIR, "validation_views.sql")

    print("Creating dashboard views...")
    n = execute_sql_file(conn, dashboard_sql)
    print(f"  ✓ {n} dashboard views/statements executed")

    print("Creating validation views...")
    n = execute_sql_file(conn, validation_sql)
    print(f"  ✓ {n} validation views/statements executed")

    # Quick verification
    views = conn.execute(
        "SELECT table_name FROM information_schema.tables "
        "WHERE table_type = 'VIEW' AND table_name LIKE 'v_%' "
        "ORDER BY table_name"
    ).fetchall()
    print(f"\n  Total views created: {len(views)}")
    for v in views:
        print(f"    - {v[0]}")

    conn.close()
    print("\nDone.")


if __name__ == "__main__":
    main()
