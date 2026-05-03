# Apache Superset – Florida Parcels Dashboards

## Quick Start

### 1. Create Views in DuckDB
```bash
python superset/create_views.py
```

### 2. Validate Data Accuracy
```bash
python superset/validate_superset.py
```
This compares all dashboard views against EDA output CSVs to confirm numbers match.

### 3. Launch Superset (Docker)
```bash
cd superset
chmod +x setup_superset.sh
./setup_superset.sh
```
Or step by step:
```bash
cd superset
docker compose build
docker compose up -d
```

### 4. Access Superset
- **URL:** http://localhost:8088
- **Username:** `admin`
- **Password:** `admin`

---

## Connect DuckDB to Superset

1. Go to **Settings → Database Connections → + Database**
2. Select **Other** database type
3. Use this SQLAlchemy URI:
   ```
   duckdb:////data/florida_parcels.duckdb?access_mode=read_only
   ```
4. Click **Test Connection** → **Connect**

> The database file is mounted read-only at `/data/florida_parcels.duckdb` inside the container.

---

## Dashboard Views (Datasets)

After connecting, add these views as **Datasets** in Superset (`Data → Datasets → + Dataset`):

### Dashboard 1: Property Valuation Overview
| Dataset | Best Chart Types |
|---------|-----------------|
| `v_dash_statewide_kpi` | Big Number / KPI cards |
| `v_dash_valuation_by_county` | Bar chart, Table, Bubble map |
| `v_dash_valuation_by_land_use` | Pie/Donut, Treemap |
| `v_dash_jv_distribution` | Bar chart (histogram) |
| `v_dash_value_per_sqft` | Bar chart, Heatmap |

### Dashboard 2: Sales Analysis
| Dataset | Best Chart Types |
|---------|-----------------|
| `v_dash_sales_kpi` | Big Number / KPI cards |
| `v_dash_sales_by_county` | Bar chart, Table |
| `v_dash_sales_by_year` | Line chart (time series) |
| `v_dash_sales_year_county` | Heatmap, Multi-line |
| `v_dash_sale_price_distribution` | Bar chart (histogram) |
| `v_dash_sales_qualification` | Pie chart, Table |
| `v_dash_multi_parcel_sales` | Pie chart |

### Dashboard 3: County Comparison
| Dataset | Best Chart Types |
|---------|-----------------|
| `v_dash_county_scorecard` | Pivot Table, Big Number with Trendline |
| `v_dash_county_map` | Deck.gl Scatter plot (map) |

### Dashboard 4: Land Use Deep Dive
| Dataset | Best Chart Types |
|---------|-----------------|
| `v_dash_land_use_by_county` | Stacked bar, Heatmap |
| `v_dash_top_land_use_codes` | Table, Bar chart |

### Dashboard 5: Building Characteristics
| Dataset | Best Chart Types |
|---------|-----------------|
| `v_dash_year_built_decades` | Bar chart |
| `v_dash_construction_class` | Pie chart, Table |
| `v_dash_improvement_quality` | Pie chart, Table |
| `v_dash_living_area_distribution` | Bar chart |
| `v_dash_homestead_analysis` | Bar chart, KPI cards |

### Dashboard 6: Spatial / Maps
| Dataset | Best Chart Types |
|---------|-----------------|
| `v_dash_county_map` | Deck.gl Scatter, Bubble map |
| `v_dash_latitude_bands` | Bar chart |

### Dashboard 7: Assessment Analysis
| Dataset | Best Chart Types |
|---------|-----------------|
| `v_dash_assessment_ratio` | Bar chart, Table |
| `v_dash_land_value_share` | Heatmap, Table |
| `v_dash_zero_value_analysis` | Bar chart, Table |

### Dashboard 8: Owner Analysis
| Dataset | Best Chart Types |
|---------|-----------------|
| `v_dash_owner_state` | Bar chart, Pie chart, Choropleth |
| `v_dash_top_parcels_by_jv` | Table |

---

## Cross-Validation

Validation views (prefixed `v_cv_`) reproduce EDA numbers exactly:

| View | EDA File to Compare |
|------|-------------------|
| `v_cv_table_row_counts` | `01_overview_table_row_counts.csv` |
| `v_cv_land_use_distribution` | `03_categorical_profile_land_use_category_distribution.csv` |
| `v_cv_valuation_stats` | `04_numerical_profile_valuation_stats.csv` |
| `v_cv_valuation_by_county` | `06_valuation_analysis_valuation_by_county.csv` |
| `v_cv_sales_overview` | `07_sales_analysis_sales_overview.csv` |
| `v_cv_sales_by_county` | `07_sales_analysis_sales_by_county.csv` |
| `v_cv_homestead_analysis` | `06_valuation_analysis_homestead_analysis.csv` |
| `v_cv_year_built_decades` | `05_temporal_analysis_year_built_decades.csv` |
| `v_cv_county_distribution` | `03_categorical_profile_county_distribution.csv` |

Use Superset's **SQL Lab** to query any `v_cv_*` view and compare against the CSV.

---

## Manage Superset

```bash
# View logs
docker compose logs -f superset-app

# Stop
docker compose down

# Stop and remove volumes (full reset)
docker compose down -v

# Rebuild after config changes
docker compose build && docker compose up -d
```

---

## Folder Structure
```
superset/
├── docker-compose.yml      # Docker stack (Postgres, Redis, Superset)
├── Dockerfile              # Custom image with duckdb-engine
├── .env                    # Environment variables
├── superset_config.py      # Superset Python config
├── setup_superset.sh       # One-command setup script
├── create_views.py         # Create dashboard views in DuckDB
├── validate_superset.py    # Cross-validate views vs EDA
├── sql/
│   ├── dashboard_views.sql # 30+ pre-aggregated views for charts
│   └── validation_views.sql# 9 views matching EDA outputs
└── README.md               # This file
```
