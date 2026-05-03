"""
EDA Orchestrator — Exploratory Data Analysis for Florida Parcels
================================================================
Runs all SQL-based EDA scripts against the DuckDB database,
prints formatted results to the console, and optionally saves
each section's output to CSV for further analysis.

Usage (from project root):
    python EDA/run_eda.py              # run all analyses
    python EDA/run_eda.py --save-csv   # also save results to EDA/output/
    python EDA/run_eda.py --only 03    # run only script 03
"""

import argparse
import csv
import sys
import re
from pathlib import Path

import duckdb

# ── Paths ─────────────────────────────────────────────────────
PROJECT_ROOT = Path(__file__).resolve().parent.parent
DB_PATH = PROJECT_ROOT / "data" / "florida_parcels.duckdb"
SQL_DIR = Path(__file__).resolve().parent / "sql"
OUTPUT_DIR = Path(__file__).resolve().parent / "output"

# ── SQL script order & titles ─────────────────────────────────
SCRIPTS = [
    ("01_overview.sql",            "DATABASE OVERVIEW"),
    ("02_completeness.sql",        "DATA COMPLETENESS (NULL ANALYSIS)"),
    ("03_categorical_profile.sql", "CATEGORICAL PROFILING"),
    ("04_numerical_profile.sql",   "NUMERICAL PROFILING"),
    ("05_temporal_analysis.sql",   "TEMPORAL ANALYSIS"),
    ("06_valuation_analysis.sql",  "VALUATION DEEP DIVE"),
    ("07_sales_analysis.sql",      "SALES ANALYSIS"),
    ("08_spatial_analysis.sql",    "SPATIAL & GEOGRAPHIC ANALYSIS"),
]


def parse_sql_sections(sql_text: str) -> list[tuple[str, str]]:
    """Split a SQL file into (section_name, sql_block) pairs.

    Convention: each section starts with a query like:
        SELECT 'section_name' AS section;
    followed by the actual analytical query.
    """
    # Split on section markers
    pattern = r"SELECT\s+'(\w+)'\s+AS\s+section\s*;"
    parts = re.split(pattern, sql_text, flags=re.IGNORECASE)

    sections = []
    # parts = [preamble, name1, sql1, name2, sql2, ...]
    for i in range(1, len(parts), 2):
        section_name = parts[i]
        section_sql = parts[i + 1].strip() if i + 1 < len(parts) else ""
        if section_sql:
            sections.append((section_name, section_sql))
    return sections


def format_table(columns: list[str], rows: list[tuple], max_col_width: int = 30) -> str:
    """Format query results as a readable text table."""
    if not rows:
        return "    (no rows returned)\n"

    # Convert all values to strings
    str_rows = []
    for row in rows:
        str_row = []
        for val in row:
            if val is None:
                str_row.append("NULL")
            elif isinstance(val, float):
                # Format large numbers with commas, small with decimals
                if abs(val) >= 1000 and val == int(val):
                    str_row.append(f"{int(val):,}")
                elif abs(val) >= 1:
                    str_row.append(f"{val:,.2f}")
                else:
                    str_row.append(f"{val:.4f}")
            elif isinstance(val, int):
                str_row.append(f"{val:,}")
            else:
                str_row.append(str(val))
        str_rows.append(str_row)

    # Calculate column widths
    widths = []
    for i, col in enumerate(columns):
        col_width = len(col)
        for row in str_rows:
            if i < len(row):
                col_width = max(col_width, len(row[i]))
        widths.append(min(col_width, max_col_width))

    # Build output
    lines = []
    # Header
    header = "    " + " | ".join(c[:w].ljust(w) for c, w in zip(columns, widths))
    lines.append(header)
    lines.append("    " + "-+-".join("-" * w for w in widths))

    # Rows
    for row in str_rows:
        cells = []
        for i, w in enumerate(widths):
            val = row[i] if i < len(row) else ""
            # Right-align numbers
            if val.replace(",", "").replace(".", "").replace("-", "").isdigit():
                cells.append(val[:w].rjust(w))
            else:
                cells.append(val[:w].ljust(w))
        lines.append("    " + " | ".join(cells))

    return "\n".join(lines) + "\n"


def run_eda(con: duckdb.DuckDBPyConnection, save_csv: bool = False,
            only: str | None = None) -> None:
    """Execute all EDA SQL scripts and print formatted results."""

    if save_csv:
        OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    for script_file, title in SCRIPTS:
        # Filter if --only specified
        if only and not script_file.startswith(only):
            continue

        sql_path = SQL_DIR / script_file
        if not sql_path.exists():
            print(f"  ⚠ Script not found: {sql_path}")
            continue

        sql_text = sql_path.read_text()
        sections = parse_sql_sections(sql_text)

        # Print script header
        print()
        print("═" * 70)
        print(f"  {title}")
        print(f"  Script: {script_file}")
        print("═" * 70)

        for section_name, section_sql in sections:
            print(f"\n  ── {section_name} {'─' * max(1, 50 - len(section_name))}")
            try:
                result = con.execute(section_sql)
                columns = [desc[0] for desc in result.description]
                rows = result.fetchall()

                print(format_table(columns, rows))

                # Save to CSV if requested
                if save_csv and rows:
                    csv_path = OUTPUT_DIR / f"{script_file.replace('.sql', '')}_{section_name}.csv"
                    with open(csv_path, "w", newline="") as f:
                        writer = csv.writer(f)
                        writer.writerow(columns)
                        writer.writerows(rows)

            except Exception as e:
                print(f"    ✗ ERROR: {e}\n")

    if save_csv:
        print(f"\n✓ CSV files saved to: {OUTPUT_DIR}/")


def main():
    parser = argparse.ArgumentParser(description="Run EDA on Florida Parcels DuckDB")
    parser.add_argument("--save-csv", action="store_true",
                        help="Save each section's output to CSV in EDA/output/")
    parser.add_argument("--only", type=str, default=None,
                        help="Run only scripts starting with this prefix (e.g. '03')")
    args = parser.parse_args()

    if not DB_PATH.exists():
        print(f"✗ Database not found: {DB_PATH}")
        print("  Run the pipeline first to create the database.")
        sys.exit(1)

    print(f"Connecting to: {DB_PATH}")
    con = duckdb.connect(str(DB_PATH), read_only=True)
    print("✓ Connected (read-only mode)\n")

    try:
        run_eda(con, save_csv=args.save_csv, only=args.only)
    finally:
        con.close()

    print("\n" + "═" * 70)
    print("  EDA COMPLETE")
    print("═" * 70)


if __name__ == "__main__":
    main()
