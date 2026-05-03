"""Smoke test: extract 100 records, load, transform, validate."""
import os
import re
import sys

import pyarrow as pa
import pyarrow.parquet as pq

import fiona
from pyproj import Transformer
from shapely.geometry import shape

import duckdb

# ── 1. Extract 100 records to Parquet ────────────────────────
print("=== EXTRACT ===")
transformer = Transformer.from_crs("EPSG:6439", "EPSG:4326", always_xy=True)
records = []

with fiona.open("Parcels.gdb", layer="CADASTRAL_DOR") as src:
    for i, feature in enumerate(src):
        if i >= 100:
            break
        rec = dict(feature["properties"])
        rec["OBJECTID"] = int(feature["id"])
        geom = feature.get("geometry")
        if geom:
            g = shape(geom)
            c = g.centroid
            lon, lat = transformer.transform(c.x, c.y)
            rec["centroid_lat"] = lat
            rec["centroid_lon"] = lon
        else:
            rec["centroid_lat"] = None
            rec["centroid_lon"] = None
        records.append(rec)

columns = {}
for key in records[0]:
    columns[key] = [r.get(key) for r in records]

table = pa.Table.from_pydict(columns)
os.makedirs("data/raw", exist_ok=True)
parquet_path = "data/raw/test_batch.parquet"
with open(parquet_path, "wb") as f:
    pq.write_table(table, f, compression="snappy")
print(f"  Wrote {len(records)} records to {parquet_path}")
print(f"  Sample: lat={records[0]['centroid_lat']:.6f} lon={records[0]['centroid_lon']:.6f}")
print(f"  CO_NO={records[0]['CO_NO']} DOR_UC={records[0]['DOR_UC']} OBJECTID={records[0]['OBJECTID']}")

# ── 2. Load into DuckDB staging ─────────────────────────────
print("\n=== LOAD ===")
db_path = "data/test.duckdb"
con = duckdb.connect(db_path)
con.execute(f"CREATE TABLE staging_parcels AS SELECT * FROM read_parquet('{parquet_path}')")
cnt = con.execute("SELECT COUNT(*) FROM staging_parcels").fetchone()[0]
print(f"  staging_parcels: {cnt} rows")

# ── 3. Transform (run SQL files) ────────────────────────────
print("\n=== TRANSFORM ===")
for sql_file in ["sql/reference_data.sql", "sql/parcels.sql", "sql/sales.sql"]:
    sql_text = open(sql_file).read()
    # Strip comments to avoid semicolons in comments breaking split
    clean_sql = re.sub(r"--[^\n]*", "", sql_text)
    for stmt in clean_sql.split(";"):
        stmt = stmt.strip()
        if not stmt:
            continue
        con.execute(stmt)
    print(f"  Executed {sql_file}")

for t in ["ref_county", "ref_land_use", "parcels", "sales"]:
    cnt = con.execute(f"SELECT COUNT(*) FROM {t}").fetchone()[0]
    print(f"  {t:20s}: {cnt:>6d} rows")

# ── 4. Spot-check enrichment ────────────────────────────────
print("\n=== SPOT CHECK ===")
row = con.execute(
    "SELECT OBJECTID, CO_NO, county_name, DOR_UC, land_use_description, "
    "centroid_lat, centroid_lon FROM parcels LIMIT 1"
).fetchone()
print(f"  OBJECTID={row[0]} CO_NO={row[1]} county={row[2]}")
print(f"  DOR_UC={row[3]} use={row[4]}")
print(f"  lat={row[5]:.6f} lon={row[6]:.6f}")

# Verify enrichment worked
assert row[2] is not None, "county_name should not be NULL"
assert row[4] is not None, "land_use_description should not be NULL"
assert 24.0 < row[5] < 31.5, f"latitude {row[5]} out of FL bounds"
assert -88.0 < row[6] < -79.5, f"longitude {row[6]} out of FL bounds"

# ── 5. Cleanup ──────────────────────────────────────────────
con.close()
os.unlink(db_path)
os.unlink(parquet_path)

print("\n✅ Smoke test PASSED")
