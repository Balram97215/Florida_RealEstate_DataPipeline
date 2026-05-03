"""Apache Superset configuration for Florida Parcels project."""

import os

# ── Secret key ─────────────────────────────────────────
SECRET_KEY = os.environ.get("SUPERSET_SECRET_KEY", "change-me-in-production")

# ── Metadata database ─────────────────────────────────
SQLALCHEMY_DATABASE_URI = os.environ.get(
    "SQLALCHEMY_DATABASE_URI",
    "postgresql+psycopg2://superset:superset@superset-db:5432/superset",
)

# ── Cache ──────────────────────────────────────────────
CACHE_CONFIG = {
    "CACHE_TYPE": "RedisCache",
    "CACHE_DEFAULT_TIMEOUT": 300,
    "CACHE_KEY_PREFIX": "superset_",
    "CACHE_REDIS_HOST": os.environ.get("REDIS_HOST", "superset-cache"),
    "CACHE_REDIS_PORT": int(os.environ.get("REDIS_PORT", 6379)),
    "CACHE_REDIS_DB": 2,
}

DATA_CACHE_CONFIG = {
    "CACHE_TYPE": "RedisCache",
    "CACHE_DEFAULT_TIMEOUT": 600,
    "CACHE_KEY_PREFIX": "superset_data_",
    "CACHE_REDIS_HOST": os.environ.get("REDIS_HOST", "superset-cache"),
    "CACHE_REDIS_PORT": int(os.environ.get("REDIS_PORT", 6379)),
    "CACHE_REDIS_DB": 3,
}

# ── Celery ─────────────────────────────────────────────
class CeleryConfig:
    broker_url = os.environ.get("CELERY_BROKER_URL", "redis://superset-cache:6379/0")
    result_backend = os.environ.get("CELERY_RESULT_BACKEND", "redis://superset-cache:6379/1")
    worker_prefetch_multiplier = 1
    task_acks_late = True

CELERY_CONFIG = CeleryConfig

# ── Feature flags ──────────────────────────────────────
FEATURE_FLAGS = {
    "ENABLE_TEMPLATE_PROCESSING": True,
    "DASHBOARD_CROSS_FILTERS": True,
    "DASHBOARD_NATIVE_FILTERS": True,
    "ALERT_REPORTS": False,
    "EMBEDDED_SUPERSET": True,
}

# ── SQL Lab ────────────────────────────────────────────
SQL_MAX_ROW = 100000
SQLLAB_TIMEOUT = 120
SUPERSET_WEBSERVER_TIMEOUT = 120

# ── Misc ───────────────────────────────────────────────
ENABLE_PROXY_FIX = True
MAPBOX_API_KEY = os.environ.get("MAPBOX_API_KEY", "")

# ── Don't load examples ───────────────────────────────
SUPERSET_LOAD_EXAMPLES = False

# ── Allow DuckDB engine ──────────────────────────────
# DuckDB is not in the default allow list
PREVENT_UNSAFE_DB_CONNECTIONS = False

# ── Additional DB engine specs ─────────────────────────
DB_CONNECTION_MUTATOR = None
