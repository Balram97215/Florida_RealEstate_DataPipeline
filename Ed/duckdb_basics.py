"""
DuckDB Basics — Check, Connect, Query
======================================
Run this file from the project root:

    python Ed/duckdb_basics.py

Or run individual sections in an interactive Python session.
"""

import duckdb
from pathlib import Path

# ── Path to your existing DuckDB file ────────────────────────
DB_PATH = Path(__file__).resolve().parent.parent / "data" / "florida_parcels.duckdb"


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 1. CHECK IF DUCKDB IS INSTALLED & GET VERSION
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#   DuckDB is an *embedded* database (like SQLite). There is no
#   separate server process to "turn on/off". It runs inside your
#   Python process the moment you import it.
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
print("=" * 60)
print("1. DuckDB Version Check")
print("=" * 60)
print(f"   DuckDB version : {duckdb.__version__}")
print(f"   DB file path   : {DB_PATH}")
print(f"   DB file exists : {DB_PATH.exists()}")
print()


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 2. CONNECT TO THE DATABASE (read-only — safe for exploration)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#   read_only=True prevents accidental writes.
#   Remove it (or set False) when you need to INSERT/UPDATE.
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
print("=" * 60)
print("2. Connecting to DuckDB")
print("=" * 60)

con = duckdb.connect(str(DB_PATH), read_only=True)
print("   ✓ Connected successfully (read-only mode)")
print()


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 3. LIST ALL TABLES IN THE DATABASE
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
print("=" * 60)
print("3. Tables in the database")
print("=" * 60)

tables = con.execute("SHOW TABLES").fetchall()
if tables:
    for t in tables:
        print(f"   • {t[0]}")
else:
    print("   (no tables found — run the pipeline first)")
print()


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 4. DESCRIBE A TABLE (show columns & types)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
print("=" * 60)
print("4. Table schema (first table)")
print("=" * 60)

if tables:
    first_table = tables[0][0]
    cols = con.execute(f"DESCRIBE {first_table}").fetchall()
    print(f"   Table: {first_table}")
    print(f"   {'Column':<35} {'Type':<20} {'Null?'}")
    print(f"   {'-'*35} {'-'*20} {'-'*5}")
    for col in cols[:15]:  # show first 15 columns
        print(f"   {col[0]:<35} {col[1]:<20} {col[2]}")
    if len(cols) > 15:
        print(f"   ... and {len(cols) - 15} more columns")
else:
    print("   (skipped — no tables)")
print()


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 5. RUN A SAMPLE QUERY
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
print("=" * 60)
print("5. Sample query (first 5 rows)")
print("=" * 60)

if tables:
    first_table = tables[0][0]
    rows = con.execute(f"SELECT * FROM {first_table} LIMIT 5").fetchall()
    col_names = [desc[0] for desc in con.description]
    # Print header (first 5 columns to fit terminal)
    display_cols = col_names[:5]
    print(f"   {' | '.join(c[:20] for c in display_cols)}")
    print(f"   {' | '.join('-'*20 for _ in display_cols)}")
    for row in rows:
        print(f"   {' | '.join(str(v)[:20] for v in row[:5])}")
    if len(col_names) > 5:
        print(f"   ... ({len(col_names) - 5} more columns not shown)")
else:
    print("   (skipped — no tables)")
print()


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 6. ROW COUNTS PER TABLE
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
print("=" * 60)
print("6. Row counts")
print("=" * 60)

if tables:
    for t in tables:
        count = con.execute(f"SELECT COUNT(*) FROM {t[0]}").fetchone()[0]
        print(f"   {t[0]:<35} {count:>12,} rows")
else:
    print("   (skipped — no tables)")
print()


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 7. CLOSE THE CONNECTION
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
con.close()
print("=" * 60)
print("7. Connection closed.")
print("=" * 60)
print()
print("Done! DuckDB is working correctly.")
