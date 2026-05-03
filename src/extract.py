"""
Extract phase: Stream features from Parcels.gdb → Parquet chunks.
Computes centroid lat/lon (reprojected to WGS84), drops polygon geometry.
OBJECTID sourced from feature['id']; Shape_Area/Shape_Length from properties.
"""
import gc
import logging
import time
from pathlib import Path

# pyarrow MUST be imported before fiona to avoid ArrowKeyError
# (both register the 'file' filesystem scheme via Arrow/GDAL)
import pyarrow as pa
import pyarrow.parquet as pq
import fiona
from pyproj import Transformer
from shapely.geometry import shape

from src.config import (
    BATCH_SIZE,
    CRS_SOURCE,
    CRS_TARGET,
    GDB_PATH,
    PARQUET_PREFIX,
    RAW_DIR,
)

logger = logging.getLogger(__name__)


def _get_layer_name(gdb_path: Path) -> str:
    """Discover the first available layer in the geodatabase."""
    layers = fiona.listlayers(str(gdb_path))
    if not layers:
        raise RuntimeError(f"No layers found in {gdb_path}")
    logger.info("Available layers: %s — using '%s'", layers, layers[0])
    return layers[0]


def _build_transformer() -> Transformer:
    """Build a thread-safe coordinate transformer (source CRS → WGS84)."""
    return Transformer.from_crs(CRS_SOURCE, CRS_TARGET, always_xy=True)


def _compute_centroid(geometry: dict, transformer: Transformer) -> tuple:
    """Compute centroid of a geometry and reproject to WGS84.

    Returns (latitude, longitude) or (None, None) if geometry is missing.
    """
    if geometry is None:
        return None, None
    try:
        geom = shape(geometry)
        centroid = geom.centroid
        lon, lat = transformer.transform(centroid.x, centroid.y)
        return lat, lon
    except Exception as e:
        logger.debug("Centroid computation failed: %s", e)
        return None, None


def _write_batch(records: list, batch_num: int, output_dir: Path) -> Path:
    """Convert a list of record dicts to a Parquet file."""
    if not records:
        return None

    # Pivot list-of-dicts → dict-of-lists for PyArrow
    columns = {}
    for key in records[0]:
        columns[key] = [r.get(key) for r in records]

    table = pa.Table.from_pydict(columns)
    out_path = output_dir / f"{PARQUET_PREFIX}_{batch_num:04d}.parquet"
    # Write via file handle to avoid pyarrow/GDAL filesystem scheme conflict
    with open(out_path, "wb") as f:
        pq.write_table(table, f, compression="snappy")
    return out_path


def extract() -> dict:
    """Run the full extraction: .gdb → Parquet chunks.

    Returns a summary dict with total_records, num_files, elapsed_seconds.
    """
    RAW_DIR.mkdir(parents=True, exist_ok=True)

    # Clean previous run (idempotent)
    for old_file in RAW_DIR.glob(f"{PARQUET_PREFIX}_*.parquet"):
        old_file.unlink()
        logger.debug("Removed previous file: %s", old_file.name)

    layer_name = _get_layer_name(GDB_PATH)
    transformer = _build_transformer()

    total_records = 0
    batch_num = 0
    batch_records = []
    start_time = time.time()

    logger.info("Opening %s, layer '%s'...", GDB_PATH, layer_name)

    with fiona.open(str(GDB_PATH), layer=layer_name) as src:
        source_crs = src.crs
        logger.info("Source CRS: %s, feature count: %s", source_crs, len(src))

        for feature in src:
            # Extract all attribute fields
            record = dict(feature["properties"])

            # Add OBJECTID from feature ID (not in properties for .gdb)
            record["OBJECTID"] = int(feature["id"])

            # Compute centroid (reprojected to WGS84)
            lat, lon = _compute_centroid(feature.get("geometry"), transformer)
            record["centroid_lat"] = lat
            record["centroid_lon"] = lon

            # Shape_Area and Shape_Length already in properties from .gdb

            batch_records.append(record)
            total_records += 1

            # Flush batch when full
            if len(batch_records) >= BATCH_SIZE:
                out_path = _write_batch(batch_records, batch_num, RAW_DIR)
                logger.info(
                    "Batch %04d: %d records → %s (total: %d, elapsed: %.1fs)",
                    batch_num,
                    len(batch_records),
                    out_path.name,
                    total_records,
                    time.time() - start_time,
                )
                batch_num += 1
                batch_records.clear()
                gc.collect()

    # Flush remaining records
    if batch_records:
        out_path = _write_batch(batch_records, batch_num, RAW_DIR)
        logger.info(
            "Batch %04d: %d records → %s (final, total: %d)",
            batch_num,
            len(batch_records),
            out_path.name,
            total_records,
        )
        batch_num += 1
        batch_records.clear()
        gc.collect()

    elapsed = time.time() - start_time
    summary = {
        "total_records": total_records,
        "num_files": batch_num,
        "elapsed_seconds": round(elapsed, 1),
    }
    logger.info(
        "Extraction complete: %d records → %d Parquet files in %.1fs",
        total_records,
        batch_num,
        elapsed,
    )
    return summary
