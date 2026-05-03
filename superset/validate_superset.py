#!/usr/bin/env python3
"""
validate_superset.py – Run validation queries against DuckDB and
compare results with EDA outputs to ensure Superset will show
accurate numbers.

Usage:
    python superset/validate_superset.py
"""

import csv
import os
import sys

project_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, project_dir)

import duckdb

DUCKDB_PATH = os.path.join(project_dir, "data", "florida_parcels.duckdb")
EDA_OUTPUT = os.path.join(project_dir, "EDA", "output")


def load_csv(filename: str) -> list[dict]:
    path = os.path.join(EDA_OUTPUT, filename)
    with open(path) as f:
        return list(csv.DictReader(f))


def check(name: str, expected, actual, tolerance=0.01):
    """Compare two values with tolerance for floats."""
    if isinstance(expected, str):
        try:
            expected = float(expected)
        except ValueError:
            pass
    if isinstance(actual, str):
        try:
            actual = float(actual)
        except ValueError:
            pass

    if isinstance(expected, (int, float)) and isinstance(actual, (int, float)):
        if expected == 0:
            match = actual == 0
        else:
            match = abs(expected - actual) / max(abs(expected), 1) < tolerance
    else:
        match = str(expected) == str(actual)

    status = "✓" if match else "✗"
    print(f"  {status} {name}: expected={expected}, got={actual}")
    return match


def main():
    if not os.path.exists(DUCKDB_PATH):
        print(f"ERROR: Database not found at {DUCKDB_PATH}")
        sys.exit(1)

    conn = duckdb.connect(DUCKDB_PATH, read_only=True)
    passed = 0
    failed = 0

    # ── Test 1: Row counts ───────────────────────────────────
    print("\n[CV-01] Table Row Counts")
    eda_rows = load_csv("01_overview_table_row_counts.csv")
    for row in eda_rows:
        table = row["table_name"]
        expected = int(row["row_count"])
        actual = conn.execute(
            f"SELECT row_count FROM v_cv_table_row_counts WHERE table_name = '{table}'"
        ).fetchone()[0]
        if check(table, expected, actual):
            passed += 1
        else:
            failed += 1

    # ── Test 2: Land use distribution ────────────────────────
    print("\n[CV-02] Land Use Category Distribution")
    eda_lu = load_csv("03_categorical_profile_land_use_category_distribution.csv")
    for row in eda_lu:
        cat = row["land_use_category"]
        expected_count = int(row["parcel_count"])
        result = conn.execute(
            f"SELECT parcel_count FROM v_cv_land_use_distribution WHERE land_use_category = ?",
            [cat],
        ).fetchone()
        actual = result[0] if result else 0
        if check(f"{cat} count", expected_count, actual):
            passed += 1
        else:
            failed += 1

    # ── Test 3: Valuation stats ──────────────────────────────
    print("\n[CV-03] Valuation Statistics")
    eda_val = load_csv("04_numerical_profile_valuation_stats.csv")[0]
    val_row = conn.execute("SELECT * FROM v_cv_valuation_stats").fetchone()
    cols = [d[0] for d in conn.description]
    val_dict = dict(zip(cols, val_row))

    for key in ["jv_count", "jv_mean", "jv_median", "jv_max", "lnd_val_mean", "tv_sd_mean"]:
        expected = float(eda_val[key])
        actual = float(val_dict[key])
        if check(key, expected, actual):
            passed += 1
        else:
            failed += 1

    # ── Test 4: Sales overview ───────────────────────────────
    print("\n[CV-05] Sales Overview")
    eda_sales = load_csv("07_sales_analysis_sales_overview.csv")[0]
    sales_row = conn.execute("SELECT * FROM v_cv_sales_overview").fetchone()
    cols = [d[0] for d in conn.description]
    sales_dict = dict(zip(cols, sales_row))

    for key in ["total_sales", "unique_parcels_sold", "avg_sale_price", "median_sale_price"]:
        expected = float(eda_sales[key])
        actual = float(sales_dict[key])
        if check(key, expected, actual):
            passed += 1
        else:
            failed += 1

    # ── Test 5: Homestead analysis ───────────────────────────
    print("\n[CV-07] Homestead Analysis")
    eda_hs = load_csv("06_valuation_analysis_homestead_analysis.csv")
    for row in eda_hs:
        status = row["homestead_status"]
        expected = int(row["parcel_count"])
        result = conn.execute(
            "SELECT parcel_count FROM v_cv_homestead_analysis WHERE homestead_status = ?",
            [status],
        ).fetchone()
        actual = result[0] if result else 0
        if check(f"{status} count", expected, actual):
            passed += 1
        else:
            failed += 1

    conn.close()

    # ── Summary ──────────────────────────────────────────────
    total = passed + failed
    print(f"\n{'='*50}")
    print(f"  VALIDATION RESULTS: {passed}/{total} passed")
    if failed > 0:
        print(f"  ⚠ {failed} checks failed – investigate before using Superset")
    else:
        print(f"  ✓ All checks passed – Superset data is accurate")
    print(f"{'='*50}")

    sys.exit(1 if failed > 0 else 0)


if __name__ == "__main__":
    main()
