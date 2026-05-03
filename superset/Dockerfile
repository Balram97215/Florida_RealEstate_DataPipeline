FROM apache/superset:4.1.1

USER root

# Install DuckDB SQLAlchemy driver + psycopg2 for metadata DB
RUN pip install --no-cache-dir \
    duckdb==1.2.2 \
    duckdb-engine==0.15.0 \
    psycopg2-binary==2.9.9

USER superset

# Copy custom Superset config
COPY superset_config.py /app/pythonpath/superset_config.py
