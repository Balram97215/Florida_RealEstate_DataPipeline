#!/usr/bin/env bash
# ============================================================
# setup_superset.sh
# One-command setup: creates views in DuckDB, builds & starts
# the Superset Docker stack.
# ============================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
DUCKDB_PATH="$PROJECT_DIR/data/florida_parcels.duckdb"

echo "============================================"
echo "  Florida Parcels – Superset Setup"
echo "============================================"
echo ""

# ── Step 1: Create dashboard views in DuckDB ──────────────
echo "[1/4] Creating dashboard views in DuckDB..."
if [ ! -f "$DUCKDB_PATH" ]; then
    echo "ERROR: DuckDB database not found at $DUCKDB_PATH"
    echo "       Run the ELT pipeline first."
    exit 1
fi

# Use create_views.py (handles comment-aware SQL parsing)
PYTHON_CMD="${PYTHON_CMD:-$PROJECT_DIR/.venv/bin/python}"
if [ ! -f "$PYTHON_CMD" ]; then
    PYTHON_CMD="python3"
fi
"$PYTHON_CMD" "$SCRIPT_DIR/create_views.py"

# ── Step 2: Build Docker image ─────────────────────────────
echo ""
echo "[2/4] Building Superset Docker image (with DuckDB driver)..."
cd "$SCRIPT_DIR"
docker compose build --no-cache
echo "  ✓ Docker image built"

# ── Step 3: Start services ─────────────────────────────────
echo ""
echo "[3/4] Starting Superset services..."
docker compose up -d
echo "  ✓ Services starting..."

# ── Step 4: Wait for health ────────────────────────────────
echo ""
echo "[4/4] Waiting for Superset to be ready..."
MAX_WAIT=180
ELAPSED=0
while [ $ELAPSED -lt $MAX_WAIT ]; do
    if curl -sf http://localhost:8088/health > /dev/null 2>&1; then
        echo ""
        echo "============================================"
        echo "  Superset is READY!"
        echo ""
        echo "  URL:      http://localhost:8088"
        echo "  Username: admin"
        echo "  Password: admin"
        echo ""
        echo "  Next: Add DuckDB database connection"
        echo "  (see README.md for connection string)"
        echo "============================================"
        exit 0
    fi
    printf "."
    sleep 5
    ELAPSED=$((ELAPSED + 5))
done

echo ""
echo "  ⚠ Superset not responding yet."
echo "  Check logs with: docker compose logs -f superset-app"
echo "  It may still be initializing..."
