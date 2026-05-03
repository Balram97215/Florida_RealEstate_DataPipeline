# Superset Dashboard Build Guide
## Florida Parcels — Step-by-Step Instructions

---

## PART 0 — ONE-TIME SETUP (Do this first, only once)

### Step 0.1 — Create all views in DuckDB
Open a terminal in the project root and run:
```bash
source .venv/bin/activate
python superset/create_views.py
```
This creates all `v_dash_*` views in `data/florida_parcels.duckdb`.

### Step 0.2 — Launch Superset
```bash
cd superset
./setup_superset.sh
```
Wait ~60 seconds, then open **http://localhost:8088**  
Login: `admin` / `admin`

---

## PART 1 — CONNECT DATABASE (One-time)

1. Click **Settings** (top-right gear icon) → **Database Connections**
2. Click **+ Database** (top-right)
3. Select **Other** from the database type list
4. In the **SQLAlchemy URI** field enter:
   ```
   duckdb:////data/florida_parcels.duckdb?access_mode=read_only
   ```
5. Click **Test Connection** — should show "Connection looks good!"
6. In the **Display Name** field enter: `Florida Parcels DuckDB`
7. Click **Connect**

---

## PART 2 — ADD ALL DATASETS (One-time, add all before building charts)

For each view below: go to **Data → Datasets → + Dataset**  
Select **Database:** `Florida Parcels DuckDB` | **Schema:** `main` | **Table:** (view name below)  
Click **Add Dataset and Create Chart** → click **Cancel** on the chart dialog (you'll create charts separately)

Add all 20 datasets in this order:

| # | View Name | Used In |
|---|-----------|---------|
| 1 | `v_dash_statewide_kpi` | Dashboard 1 |
| 2 | `v_dash_valuation_by_county` | Dashboard 1, 3 |
| 3 | `v_dash_valuation_by_land_use` | Dashboard 1 |
| 4 | `v_dash_jv_distribution` | Dashboard 1 |
| 5 | `v_dash_value_per_sqft` | Dashboard 1 |
| 6 | `v_dash_sales_kpi` | Dashboard 2 |
| 7 | `v_dash_sales_by_county` | Dashboard 2, 3 |
| 8 | `v_dash_sales_by_year` | Dashboard 2 |
| 9 | `v_dash_sales_year_county` | Dashboard 2 |
| 10 | `v_dash_sale_price_distribution` | Dashboard 2 |
| 11 | `v_dash_sales_qualification` | Dashboard 2 |
| 12 | `v_dash_multi_parcel_sales` | Dashboard 2 |
| 13 | `v_dash_county_scorecard` | Dashboard 3 |
| 14 | `v_dash_county_map` | Dashboard 3, 6 |
| 15 | `v_dash_land_use_by_county` | Dashboard 4 |
| 16 | `v_dash_top_land_use_codes` | Dashboard 4 |
| 17 | `v_dash_year_built_decades` | Dashboard 5 |
| 18 | `v_dash_construction_class` | Dashboard 5 |
| 19 | `v_dash_improvement_quality` | Dashboard 5 |
| 20 | `v_dash_living_area_distribution` | Dashboard 5 |
| 21 | `v_dash_homestead_analysis` | Dashboard 5 |
| 22 | `v_dash_latitude_bands` | Dashboard 6 |
| 23 | `v_dash_assessment_ratio` | Dashboard 7 |
| 24 | `v_dash_land_value_share` | Dashboard 7 |
| 25 | `v_dash_zero_value_analysis` | Dashboard 7 |
| 26 | `v_dash_owner_state` | Dashboard 8 |
| 27 | `v_dash_top_parcels_by_jv` | Dashboard 8 |

---

## HOW TO CREATE A CHART (General steps, referenced below)

1. Go to **Charts → + Chart**
2. Select the **Dataset** named
3. Select the **Chart Type** named
4. Click **Create New Chart**
5. Fill in the fields exactly as described (Metrics, Dimensions, Filters, etc.)
6. Click **Save** at top-right
7. Name the chart as instructed
8. Click **Save** in the save dialog

---

## DASHBOARD 1 — PROPERTY VALUATION OVERVIEW

### Create the dashboard first
1. Go to **Dashboards → + Dashboard**
2. Title: `Property Valuation Overview`
3. Click **Save**  
   *(You will add charts to it after creating them)*

---

### CHART 1-A — Total Parcels (Big Number)
- **Chart type:** Big Number
- **Dataset:** `v_dash_statewide_kpi`
- **Metric:** `total_parcels` → Aggregation: **SUM**
- **Subheader:** `Total Parcels Statewide`
- **Time comparison:** leave empty
- **Number format:** `,d` (comma-separated integer)
- **Save as:** `KPI – Total Parcels`

### CHART 1-B — Total Just Value $B (Big Number)
- **Chart type:** Big Number
- **Dataset:** `v_dash_statewide_kpi`
- **Metric:** `total_jv_billions` → Aggregation: **SUM**
- **Subheader:** `Total Just Value (Billions $)`
- **Number format:** `,.2f`
- **Save as:** `KPI – Total Just Value $B`

### CHART 1-C — Average Just Value (Big Number)
- **Chart type:** Big Number
- **Dataset:** `v_dash_statewide_kpi`
- **Metric:** `avg_just_value` → Aggregation: **SUM**
- **Subheader:** `Avg Just Value Per Parcel`
- **Number format:** `$,.0f`
- **Save as:** `KPI – Avg Just Value`

### CHART 1-D — Median Just Value (Big Number)
- **Chart type:** Big Number
- **Dataset:** `v_dash_statewide_kpi`
- **Metric:** `median_just_value` → Aggregation: **SUM**
- **Subheader:** `Median Just Value`
- **Number format:** `$,.0f`
- **Save as:** `KPI – Median Just Value`

### CHART 1-E — Total Taxable Value $B (Big Number)
- **Chart type:** Big Number
- **Dataset:** `v_dash_statewide_kpi`
- **Metric:** `total_taxable_value_billions` → Aggregation: **SUM**
- **Subheader:** `Total Taxable Value (Billions $)`
- **Number format:** `,.2f`
- **Save as:** `KPI – Total Taxable Value $B`

### CHART 1-F — County Count (Big Number)
- **Chart type:** Big Number
- **Dataset:** `v_dash_statewide_kpi`
- **Metric:** `county_count` → Aggregation: **SUM**
- **Subheader:** `Counties`
- **Number format:** `d`
- **Save as:** `KPI – County Count`

---

### CHART 1-G — Total Just Value by County (Horizontal Bar)
- **Chart type:** Bar Chart
- **Dataset:** `v_dash_valuation_by_county`
- **Orientation:** Horizontal
- **Y-axis (Dimensions):** `county_name`
- **X-axis (Metrics):** `total_jv_billions` → Aggregation: **SUM**
  - **Label:** `Total JV ($B)`
- **Sort bars by:** `total_jv_billions` descending
- **Show data labels:** ON
- **X-axis label:** `Just Value (Billions $)`
- **Y-axis label:** `County`
- **Number format on label:** `,.1f`
- **Save as:** `Valuation by County – Bar`

### CHART 1-H — Avg Just Value vs Avg Taxable Value by County (Bar Chart, grouped)
- **Chart type:** Bar Chart
- **Dataset:** `v_dash_valuation_by_county`
- **Orientation:** Horizontal
- **Y-axis (Dimensions):** `county_name`
- **X-axis (Metrics):**
  - `avg_jv` → Aggregation: **SUM** → Label: `Avg Just Value`
  - `avg_taxable_value` → Aggregation: **SUM** → Label: `Avg Taxable Value`
- **Sort bars by:** `avg_jv` descending
- **Bar chart style:** Grouped
- **Number format:** `$,.0f`
- **Save as:** `Avg JV vs Taxable Value by County`

### CHART 1-I — Parcel Count by County (Horizontal Bar)
- **Chart type:** Bar Chart
- **Dataset:** `v_dash_valuation_by_county`
- **Orientation:** Horizontal
- **Y-axis (Dimensions):** `county_name`
- **X-axis (Metrics):** `parcel_count` → Aggregation: **SUM** → Label: `Parcels`
- **Sort bars by:** `parcel_count` descending
- **Show data labels:** ON
- **Number format:** `,d`
- **Save as:** `Parcel Count by County`

---

### CHART 1-J — Just Value by Land Use Category (Pie Chart)
- **Chart type:** Pie Chart
- **Dataset:** `v_dash_valuation_by_land_use`
- **Dimensions (Group by):** `land_use_category`
- **Metric:** `total_jv_billions` → Aggregation: **SUM**
- **Show labels:** ON
- **Label type:** `Category and percentage`
- **Show legend:** ON
- **Donut:** ON (inner radius ~30%)
- **Save as:** `JV Share by Land Use – Pie`

### CHART 1-K — Parcel Count by Land Use (Treemap)
- **Chart type:** Treemap
- **Dataset:** `v_dash_valuation_by_land_use`
- **Dimensions (Group by):** `land_use_category`
- **Metric:** `parcel_count` → Aggregation: **SUM**
- **Show labels:** ON
- **Save as:** `Parcel Count by Land Use – Treemap`

---

### CHART 1-L — Just Value Distribution Histogram (Bar Chart)
- **Chart type:** Bar Chart
- **Dataset:** `v_dash_jv_distribution`
- **Orientation:** Vertical
- **X-axis (Dimensions):** `jv_bucket`
- **Y-axis (Metrics):** `parcel_count` → Aggregation: **SUM** → Label: `Parcels`
- **Sort bars by:** `bucket_order` ascending  
  *(In the query panel set **Sort:** `bucket_order` → ASC)*
- **Show data labels:** OFF
- **X-axis label:** `Just Value Range`
- **Y-axis label:** `Number of Parcels`
- **Number format:** `,d`
- **Save as:** `JV Distribution Histogram`

---

### CHART 1-M — Avg Value per Sqft by Land Use (Horizontal Bar)
- **Chart type:** Bar Chart
- **Dataset:** `v_dash_value_per_sqft`
- **Orientation:** Horizontal
- **Y-axis (Dimensions):** `land_use_category`
- **X-axis (Metrics):**
  - `avg_value_per_sqft` → Aggregation: **SUM** → Label: `Avg $/sqft`
  - `median_value_per_sqft` → Aggregation: **SUM** → Label: `Median $/sqft`
- **Bar style:** Grouped
- **Sort bars by:** `avg_value_per_sqft` descending
- **Number format:** `$,.2f`
- **Save as:** `Value Per Sqft by Land Use`

---

### CHART 1-N — County Valuation Summary Table
- **Chart type:** Table
- **Dataset:** `v_dash_valuation_by_county`
- **Columns to display (in order):**
  1. `county_name` → Label: `County`
  2. `parcel_count` → Label: `Parcels` → Format: `,d`
  3. `total_jv_billions` → Label: `Total JV ($B)` → Format: `,.2f`
  4. `avg_jv` → Label: `Avg JV` → Format: `$,.0f`
  5. `median_jv` → Label: `Median JV` → Format: `$,.0f`
  6. `avg_taxable_value` → Label: `Avg Taxable Val` → Format: `$,.0f`
  7. `avg_value_per_sqft` → Label: `$/sqft` → Format: `$,.2f`
- **Page size:** 20
- **Sort by:** `total_jv_billions` descending
- **Search bar:** ON
- **Save as:** `County Valuation Summary Table`

---

### Assemble Dashboard 1

1. Open **Dashboards → Property Valuation Overview**
2. Click **Edit Dashboard** (pencil icon top-right)
3. Click **+ Add Charts** and add all charts above
4. Arrange in this layout (drag to position):

```
Row 1 (6 small KPI cards side by side):
  [1-A Total Parcels] [1-B Total JV $B] [1-C Avg JV] [1-D Median JV] [1-E Taxable $B] [1-F County Count]

Row 2 (2 columns, equal width):
  Left:  [1-G Total JV by County – Bar]
  Right: [1-H Avg JV vs Taxable by County]

Row 3 (3 columns):
  Left:  [1-J JV Share by Land Use – Pie]
  Mid:   [1-K Parcel Count by Land Use – Treemap]
  Right: [1-I Parcel Count by County]

Row 4 (2 columns):
  Left:  [1-L JV Distribution Histogram]
  Right: [1-M Value Per Sqft by Land Use]

Row 5 (full width):
  [1-N County Valuation Summary Table]
```

5. Click **Save** (top-right)

---

## DASHBOARD 2 — SALES ANALYSIS

### Create the dashboard
1. **Dashboards → + Dashboard**
2. Title: `Sales Analysis`
3. Click **Save**

---

### CHART 2-A — Total Sales (Big Number)
- **Chart type:** Big Number
- **Dataset:** `v_dash_sales_kpi`
- **Metric:** `total_sales` → Aggregation: **SUM**
- **Subheader:** `Total Sales Transactions`
- **Number format:** `,d`
- **Save as:** `KPI – Total Sales`

### CHART 2-B — Unique Parcels Sold (Big Number)
- **Chart type:** Big Number
- **Dataset:** `v_dash_sales_kpi`
- **Metric:** `unique_parcels_sold` → Aggregation: **SUM**
- **Subheader:** `Unique Parcels Sold`
- **Number format:** `,d`
- **Save as:** `KPI – Unique Parcels Sold`

### CHART 2-C — Average Sale Price (Big Number)
- **Chart type:** Big Number
- **Dataset:** `v_dash_sales_kpi`
- **Metric:** `avg_sale_price` → Aggregation: **SUM**
- **Subheader:** `Average Sale Price`
- **Number format:** `$,.0f`
- **Save as:** `KPI – Avg Sale Price`

### CHART 2-D — Median Sale Price (Big Number)
- **Chart type:** Big Number
- **Dataset:** `v_dash_sales_kpi`
- **Metric:** `median_sale_price` → Aggregation: **SUM**
- **Subheader:** `Median Sale Price`
- **Number format:** `$,.0f`
- **Save as:** `KPI – Median Sale Price`

### CHART 2-E — Total Sales Volume $B (Big Number)
- **Chart type:** Big Number
- **Dataset:** `v_dash_sales_kpi`
- **Metric:** `total_volume_billions` → Aggregation: **SUM**
- **Subheader:** `Total Sales Volume (Billions $)`
- **Number format:** `,.2f`
- **Save as:** `KPI – Total Sales Volume $B`

---

### CHART 2-F — Sales Volume by County (Horizontal Bar)
- **Chart type:** Bar Chart
- **Dataset:** `v_dash_sales_by_county`
- **Orientation:** Horizontal
- **Y-axis (Dimensions):** `county_name`
- **X-axis (Metrics):** `total_volume_billions` → Aggregation: **SUM** → Label: `Volume ($B)`
- **Sort by:** `total_volume_billions` descending
- **Show data labels:** ON
- **Number format:** `,.2f`
- **Save as:** `Sales Volume by County`

### CHART 2-G — Avg vs Median Price by County (Grouped Bar)
- **Chart type:** Bar Chart
- **Dataset:** `v_dash_sales_by_county`
- **Orientation:** Horizontal
- **Y-axis (Dimensions):** `county_name`
- **X-axis (Metrics):**
  - `avg_price` → Aggregation: **SUM** → Label: `Avg Price`
  - `median_price` → Aggregation: **SUM** → Label: `Median Price`
- **Bar style:** Grouped
- **Sort by:** `avg_price` descending
- **Number format:** `$,.0f`
- **Save as:** `Avg vs Median Price by County`

---

### CHART 2-H — Annual Sales Volume Trend (Line Chart)
- **Chart type:** Line Chart
- **Dataset:** `v_dash_sales_by_year`
- **X-axis (Dimension):** `sale_year`
- **Metrics:**
  - `total_volume_billions` → Aggregation: **SUM** → Label: `Volume ($B)`
- **Show data markers:** ON
- **X-axis label:** `Year`
- **Y-axis label:** `Sales Volume ($B)`
- **Number format:** `,.2f`
- **Save as:** `Annual Sales Volume Trend`

### CHART 2-I — Annual Sale Count Trend (Line Chart)
- **Chart type:** Line Chart
- **Dataset:** `v_dash_sales_by_year`
- **X-axis (Dimension):** `sale_year`
- **Metrics:**
  - `sale_count` → Aggregation: **SUM** → Label: `Transactions`
  - `unique_parcels` → Aggregation: **SUM** → Label: `Unique Parcels`
- **Show data markers:** ON
- **X-axis label:** `Year`
- **Y-axis label:** `Count`
- **Number format:** `,d`
- **Save as:** `Annual Sale Count Trend`

### CHART 2-J — Avg Sale Price Over Time (Line Chart)
- **Chart type:** Line Chart
- **Dataset:** `v_dash_sales_by_year`
- **X-axis (Dimension):** `sale_year`
- **Metrics:**
  - `avg_price` → Aggregation: **SUM** → Label: `Avg Price`
  - `median_price` → Aggregation: **SUM** → Label: `Median Price`
- **Show data markers:** ON
- **X-axis label:** `Year`
- **Y-axis label:** `Sale Price ($)`
- **Number format:** `$,.0f`
- **Save as:** `Sale Price Trend Over Time`

---

### CHART 2-K — Sales by Year and County (Heatmap)
- **Chart type:** Heatmap
- **Dataset:** `v_dash_sales_year_county`
- **X-axis:** `sale_year`
- **Y-axis:** `county_name`
- **Metric:** `sale_count` → Aggregation: **SUM**
- **Normalize across:** All values
- **Sort Y-axis:** Alphabetically
- **Show values:** OFF
- **Linear color scheme:** `Sunset` (or `Blues`)
- **Save as:** `Sales Heatmap – Year × County`

---

### CHART 2-L — Sale Price Distribution Histogram (Bar Chart)
- **Chart type:** Bar Chart
- **Dataset:** `v_dash_sale_price_distribution`
- **Orientation:** Vertical
- **X-axis (Dimensions):** `price_bucket`
- **Y-axis (Metrics):** `sale_count` → Aggregation: **SUM** → Label: `Sales`
- **Sort by:** `bucket_order` ascending *(add as sort column)*
- **Show data labels:** OFF
- **X-axis label:** `Sale Price Range`
- **Y-axis label:** `Number of Sales`
- **Number format:** `,d`
- **Save as:** `Sale Price Distribution Histogram`

---

### CHART 2-M — Qualification Code Breakdown (Pie Chart)
- **Chart type:** Pie Chart
- **Dataset:** `v_dash_sales_qualification`
- **Dimensions:** `qualification_code`
- **Metric:** `sale_count` → Aggregation: **SUM**
- **Show labels:** ON
- **Label type:** `Category and percentage`
- **Donut:** ON
- **Show legend:** ON
- **Save as:** `Sales by Qualification Code – Pie`

### CHART 2-N — Qualification Code Detail (Table)
- **Chart type:** Table
- **Dataset:** `v_dash_sales_qualification`
- **Columns:**
  1. `qualification_code` → Label: `Qualification Code`
  2. `sale_count` → Label: `Sales` → Format: `,d`
  3. `pct_of_total` → Label: `% of Total` → Format: `,.2f`
  4. `avg_price` → Label: `Avg Price` → Format: `$,.0f`
  5. `median_price` → Label: `Median Price` → Format: `$,.0f`
- **Sort by:** `sale_count` descending
- **Save as:** `Qualification Code Table`

---

### CHART 2-O — Multi-Parcel Sales Split (Pie Chart)
- **Chart type:** Pie Chart
- **Dataset:** `v_dash_multi_parcel_sales`
- **Dimensions:** `multi_parcel_sale`
- **Metric:** `sale_count` → Aggregation: **SUM**
- **Show labels:** ON
- **Label type:** `Category and percentage`
- **Donut:** ON
- **Save as:** `Multi-Parcel vs Single-Parcel Sales`

---

### Assemble Dashboard 2

```
Row 1 (5 KPI cards):
  [2-A Total Sales] [2-B Unique Parcels] [2-C Avg Price] [2-D Median Price] [2-E Volume $B]

Row 2 (2 columns):
  Left:  [2-H Annual Sales Volume Trend]
  Right: [2-J Sale Price Trend Over Time]

Row 3 (full width):
  [2-I Annual Sale Count Trend]

Row 4 (2 columns):
  Left:  [2-F Sales Volume by County]
  Right: [2-G Avg vs Median Price by County]

Row 5 (full width):
  [2-K Sales Heatmap – Year × County]

Row 6 (3 columns):
  Left:  [2-L Sale Price Distribution Histogram]
  Mid:   [2-M Sales by Qualification Code – Pie]
  Right: [2-O Multi-Parcel vs Single-Parcel Sales]

Row 7 (full width):
  [2-N Qualification Code Table]
```

---

## DASHBOARD 3 — COUNTY COMPARISON

### Create the dashboard
1. **Dashboards → + Dashboard**
2. Title: `County Comparison`
3. Click **Save**

---

### CHART 3-A — County Scorecard Table (Pivot Table)
- **Chart type:** Table
- **Dataset:** `v_dash_county_scorecard`
- **Columns (in order):**
  1. `county_name` → Label: `County`
  2. `parcel_count` → Label: `Parcels` → Format: `,d`
  3. `pct_of_state_parcels` → Label: `% of State` → Format: `,.2f`
  4. `total_jv_billions` → Label: `Total JV ($B)` → Format: `,.2f`
  5. `avg_jv` → Label: `Avg JV` → Format: `$,.0f`
  6. `median_jv` → Label: `Median JV` → Format: `$,.0f`
  7. `avg_taxable_value` → Label: `Avg Taxable Val` → Format: `$,.0f`
  8. `avg_land_value` → Label: `Avg Land Val` → Format: `$,.0f`
  9. `avg_value_per_sqft` → Label: `$/sqft` → Format: `$,.2f`
  10. `sale_count` → Label: `Sales` → Format: `,d`
  11. `avg_sale_price` → Label: `Avg Sale $` → Format: `$,.0f`
  12. `median_sale_price` → Label: `Median Sale $` → Format: `$,.0f`
  13. `sales_volume_billions` → Label: `Sales Vol ($B)` → Format: `,.2f`
- **Page size:** 30
- **Sort by:** `total_jv_billions` descending
- **Conditional formatting:**  
  - Column `total_jv_billions`: Color scale blue (min→max)  
  - Column `avg_jv`: Color scale green  
- **Search bar:** ON
- **Save as:** `County Scorecard Table`

---

### CHART 3-B — JV per County vs Sales Volume (Scatter Plot)
- **Chart type:** Scatter Plot
- **Dataset:** `v_dash_county_scorecard`
- **X-axis:** `avg_jv` → Aggregation: **SUM** → Label: `Avg Just Value`
- **Y-axis:** `avg_sale_price` → Aggregation: **SUM** → Label: `Avg Sale Price`
- **Entity (label):** `county_name`
- **Bubble size:** `parcel_count`
- **X-axis format:** `$,.0f`
- **Y-axis format:** `$,.0f`
- **Show data labels:** ON
- **Save as:** `Avg JV vs Avg Sale Price – Scatter`

---

### CHART 3-C — County Map (Deck.gl Scatter Plot)
- **Chart type:** Deck.gl Scatter Plot
- **Dataset:** `v_dash_county_map`
- **Longitude:** `longitude`
- **Latitude:** `latitude`
- **Size:** `parcel_count`
- **Color by:** `total_jv_billions`
- **Color scheme:** `Sunset` sequential scale
- **Point radius:** 30000 (meters)
- **Point radius fixed:** OFF (let size column control it)
- **Tooltip:** `county_name`, `parcel_count`, `total_jv_billions`, `avg_jv`
- **Viewport center:** lat `27.8`, lon `-81.8` (Florida center)
- **Viewport zoom:** 6
- **Save as:** `County Map – Bubble`

---

### CHART 3-D — % of State Parcels by County (Horizontal Bar)
- **Chart type:** Bar Chart
- **Dataset:** `v_dash_county_scorecard`
- **Orientation:** Horizontal
- **Y-axis (Dimensions):** `county_name`
- **X-axis (Metrics):** `pct_of_state_parcels` → Aggregation: **SUM** → Label: `% of State Parcels`
- **Sort by:** `pct_of_state_parcels` descending
- **Show data labels:** ON
- **Number format:** `,.2f`
- **Save as:** `County Share of State Parcels`

---

### Assemble Dashboard 3

```
Row 1 (full width):
  [3-C County Map – Bubble]

Row 2 (2 columns):
  Left:  [3-D County Share of State Parcels]
  Right: [3-B Avg JV vs Avg Sale Price – Scatter]

Row 3 (full width):
  [3-A County Scorecard Table]
```

---

## DASHBOARD 4 — LAND USE DEEP DIVE

### Create the dashboard
1. **Dashboards → + Dashboard**
2. Title: `Land Use Deep Dive`
3. Click **Save**

---

### CHART 4-A — Parcel Count by Land Use and County (Stacked Bar)
- **Chart type:** Bar Chart
- **Dataset:** `v_dash_land_use_by_county`
- **Orientation:** Vertical
- **X-axis (Dimensions):** `county_name`
- **Y-axis (Metrics):** `parcel_count` → Aggregation: **SUM**
- **Groupby (color series):** `land_use_category`
- **Bar mode:** Stacked
- **Show legend:** ON
- **X-axis label:** `County`
- **Y-axis label:** `Parcel Count`
- **Number format:** `,d`
- **Save as:** `Parcels by Land Use & County – Stacked Bar`

### CHART 4-B — Avg JV by Land Use and County (Heatmap)
- **Chart type:** Heatmap
- **Dataset:** `v_dash_land_use_by_county`
- **X-axis:** `county_name`
- **Y-axis:** `land_use_category`
- **Metric:** `avg_jv` → Aggregation: **SUM**
- **Normalize across:** All values
- **Show values:** OFF
- **Sort X:** Alphabetical
- **Sort Y:** by value descending
- **Color scheme:** `RdYlGn`
- **Save as:** `Avg JV Heatmap – Land Use × County`

### CHART 4-C — Top Land Use Codes Table
- **Chart type:** Table
- **Dataset:** `v_dash_top_land_use_codes`
- **Columns (in order):**
  1. `DOR_UC` → Label: `DOR Code`
  2. `land_use_description` → Label: `Description`
  3. `land_use_category` → Label: `Category`
  4. `parcel_count` → Label: `Parcels` → Format: `,d`
  5. `pct_of_total` → Label: `% of Total` → Format: `,.2f`
  6. `avg_jv` → Label: `Avg JV` → Format: `$,.0f`
  7. `total_jv_billions` → Label: `Total JV ($B)` → Format: `,.2f`
- **Page size:** 25
- **Sort by:** `parcel_count` descending
- **Search bar:** ON
- **Conditional formatting:** `parcel_count` — color scale green
- **Save as:** `Top Land Use Codes Table`

### CHART 4-D — Top Land Use Codes (Horizontal Bar)
- **Chart type:** Bar Chart
- **Dataset:** `v_dash_top_land_use_codes`
- **Orientation:** Horizontal
- **Y-axis (Dimensions):** `land_use_description`
- **X-axis (Metrics):** `parcel_count` → Aggregation: **SUM** → Label: `Parcels`
- **Sort by:** `parcel_count` descending
- **Row limit:** 20
- **Show data labels:** ON
- **Number format:** `,d`
- **Save as:** `Top 20 Land Use Codes by Parcel Count`

### CHART 4-E — Total JV by Land Use Category (Horizontal Bar)
- **Chart type:** Bar Chart
- **Dataset:** `v_dash_top_land_use_codes`
- **Orientation:** Horizontal
- **Y-axis (Dimensions):** `land_use_category`
- **X-axis (Metrics):** `total_jv_billions` → Aggregation: **SUM** → Label: `Total JV ($B)`
- **Sort by:** `total_jv_billions` descending
- **Show data labels:** ON
- **Number format:** `,.2f`
- **Save as:** `Total JV by Land Use Category`

---

### Assemble Dashboard 4

```
Row 1 (2 columns):
  Left:  [4-E Total JV by Land Use Category]
  Right: [4-D Top 20 Land Use Codes by Parcel Count]

Row 2 (full width):
  [4-A Parcels by Land Use & County – Stacked Bar]

Row 3 (full width):
  [4-B Avg JV Heatmap – Land Use × County]

Row 4 (full width):
  [4-C Top Land Use Codes Table]
```

---

## DASHBOARD 5 — BUILDING CHARACTERISTICS

### Create the dashboard
1. **Dashboards → + Dashboard**
2. Title: `Building Characteristics`
3. Click **Save**

---

### CHART 5-A — Homesteaded vs Non-Homesteaded KPI (Big Number)
- **Chart type:** Big Number with Trendline  
  *(or use two Big Number charts)*
- For **Homesteaded %**: use `v_dash_homestead_analysis`, metric `pct_of_total`, filter `homestead_status = 'Homesteaded'`
  - **Subheader:** `Homesteaded Parcels`
  - **Number format:** `,.1f`
  - **Save as:** `KPI – Homestead Rate %`

### CHART 5-B — Homestead Status Comparison (Bar Chart)
- **Chart type:** Bar Chart
- **Dataset:** `v_dash_homestead_analysis`
- **Orientation:** Vertical
- **X-axis (Dimensions):** `homestead_status`
- **Y-axis (Metrics):**
  - `parcel_count` → Label: `Parcels`
  - `avg_jv` → Label: `Avg Just Value` (secondary axis)
- **Bar style:** Grouped
- **Show data labels:** ON
- **Save as:** `Homestead Status – Parcels & Avg JV`

### CHART 5-C — Homestead Status Detail (Table)
- **Chart type:** Table
- **Dataset:** `v_dash_homestead_analysis`
- **Columns:**
  1. `homestead_status` → Label: `Status`
  2. `parcel_count` → Label: `Parcels` → Format: `,d`
  3. `pct_of_total` → Label: `%` → Format: `,.2f`
  4. `avg_jv` → Label: `Avg JV` → Format: `$,.0f`
  5. `median_jv` → Label: `Median JV` → Format: `$,.0f`
  6. `avg_taxable_value` → Label: `Avg Taxable Val` → Format: `$,.0f`
  7. `avg_living_area` → Label: `Avg Sq Ft` → Format: `,.0f`
- **Save as:** `Homestead Status Table`

---

### CHART 5-D — Year Built Decades (Vertical Bar)
- **Chart type:** Bar Chart
- **Dataset:** `v_dash_year_built_decades`
- **Orientation:** Vertical
- **X-axis (Dimensions):** `decade`
- **Y-axis (Metrics):** `parcel_count` → Aggregation: **SUM** → Label: `Parcels`
- **Sort by:** `decade_sort` ascending *(add as custom sort)*
- **Show data labels:** OFF
- **X-axis label:** `Decade Built`
- **Y-axis label:** `Number of Parcels`
- **Number format:** `,d`
- **Save as:** `Parcels by Decade Built`

### CHART 5-E — Avg JV by Decade (Line overlay on Bar)
- **Chart type:** Mixed Chart (or separate Bar Chart)
- **Dataset:** `v_dash_year_built_decades`
- **X-axis (Dimensions):** `decade`
- **Metrics:**
  - `avg_just_value` → Bar → Label: `Avg Just Value`
  - `avg_value_per_sqft` → Line → Label: `Avg $/sqft` (right axis)
- **Sort by:** `decade_sort` ascending
- **Y-axis format (left):** `$,.0f`
- **Y-axis format (right):** `$,.2f`
- **Save as:** `Avg Value by Decade Built`

---

### CHART 5-F — Construction Class (Pie Chart)
- **Chart type:** Pie Chart
- **Dataset:** `v_dash_construction_class`
- **Dimensions:** `construction_class`
- **Metric:** `parcel_count` → Aggregation: **SUM**
- **Show labels:** ON
- **Label type:** `Category and percentage`
- **Donut:** ON
- **Save as:** `Construction Class – Pie`

### CHART 5-G — Construction Class Detail (Table)
- **Chart type:** Table
- **Dataset:** `v_dash_construction_class`
- **Columns:**
  1. `construction_class` → Label: `Class`
  2. `parcel_count` → Label: `Parcels` → Format: `,d`
  3. `pct_of_total` → Label: `%` → Format: `,.2f`
  4. `avg_jv` → Label: `Avg JV` → Format: `$,.0f`
  5. `avg_living_area` → Label: `Avg Sq Ft` → Format: `,.0f`
- **Sort by:** `parcel_count` descending
- **Save as:** `Construction Class Table`

---

### CHART 5-H — Improvement Quality (Pie Chart)
- **Chart type:** Pie Chart
- **Dataset:** `v_dash_improvement_quality`
- **Dimensions:** `improvement_quality`
- **Metric:** `parcel_count` → Aggregation: **SUM**
- **Show labels:** ON
- **Label type:** `Category and percentage`
- **Donut:** ON
- **Save as:** `Improvement Quality – Pie`

### CHART 5-I — Improvement Quality Detail (Table)
- **Chart type:** Table
- **Dataset:** `v_dash_improvement_quality`
- **Columns:**
  1. `improvement_quality` → Label: `Quality`
  2. `parcel_count` → Label: `Parcels` → Format: `,d`
  3. `pct_of_total` → Label: `%` → Format: `,.2f`
  4. `avg_jv` → Label: `Avg JV` → Format: `$,.0f`
  5. `avg_living_area` → Label: `Avg Sq Ft` → Format: `,.0f`
- **Sort by:** `parcel_count` descending
- **Save as:** `Improvement Quality Table`

---

### CHART 5-J — Living Area Distribution (Bar Chart)
- **Chart type:** Bar Chart
- **Dataset:** `v_dash_living_area_distribution`
- **Orientation:** Vertical
- **X-axis (Dimensions):** `area_bucket`
- **Y-axis (Metrics):** `parcel_count` → Aggregation: **SUM** → Label: `Parcels`
- **Sort by:** `bucket_order` ascending *(custom sort column)*
- **Show data labels:** OFF
- **X-axis label:** `Living Area Range`
- **Y-axis label:** `Parcel Count`
- **Number format:** `,d`
- **Save as:** `Living Area Distribution`

### CHART 5-K — Avg JV by Living Area Bucket (Horizontal Bar)
- **Chart type:** Bar Chart
- **Dataset:** `v_dash_living_area_distribution`
- **Orientation:** Horizontal
- **Y-axis (Dimensions):** `area_bucket`
- **X-axis (Metrics):**
  - `avg_jv` → Aggregation: **SUM** → Label: `Avg JV`
  - `avg_value_per_sqft` → Aggregation: **SUM** → Label: `Avg $/sqft`
- **Bar style:** Grouped
- **Sort by:** `bucket_order` ascending
- **Number format:** `$,.0f`
- **Save as:** `Avg Value by Living Area Bucket`

---

### Assemble Dashboard 5

```
Row 1 (3 columns):
  Left:  [5-A KPI – Homestead Rate %]
  Mid:   [5-B Homestead Status – Parcels & Avg JV]
  Right: [5-C Homestead Status Table]

Row 2 (2 columns):
  Left:  [5-D Parcels by Decade Built]
  Right: [5-E Avg Value by Decade Built]

Row 3 (3 columns):
  Left:  [5-F Construction Class – Pie]
  Mid:   [5-H Improvement Quality – Pie]
  Right: [5-J Living Area Distribution]

Row 4 (2 columns):
  Left:  [5-G Construction Class Table]
  Right: [5-I Improvement Quality Table]

Row 5 (full width):
  [5-K Avg Value by Living Area Bucket]
```

---

## DASHBOARD 6 — SPATIAL / MAPS

### Create the dashboard
1. **Dashboards → + Dashboard**
2. Title: `Spatial Analysis`
3. Click **Save**

---

### CHART 6-A — County Bubble Map (Deck.gl Scatter)
*(Same as Chart 3-C — you can reuse it; just add it to this dashboard too)*
- **Chart type:** Deck.gl Scatter Plot
- **Dataset:** `v_dash_county_map`
- **Longitude:** `longitude`
- **Latitude:** `latitude`
- **Point size:** `parcel_count`
- **Color metric:** `total_jv_billions`
- **Color scheme:** `Sunset`
- **Point radius multiplier:** 5
- **Tooltip fields:** `county_name`, `parcel_count`, `total_jv_billions`, `avg_jv`, `median_jv`
- **Viewport:** lat `27.8`, lon `-81.8`, zoom `6`
- **Save as:** `Florida County Bubble Map`

### CHART 6-B — Avg JV per County on Map (alternate color = avg_jv)
- **Chart type:** Deck.gl Scatter Plot
- **Dataset:** `v_dash_county_map`
- **Longitude:** `longitude`
- **Latitude:** `latitude`
- **Point size:** `parcel_count`
- **Color metric:** `avg_jv`
- **Color scheme:** `RdYlGn` reversed (high = green)
- **Tooltip fields:** `county_name`, `avg_jv`, `median_jv`, `parcel_count`
- **Viewport:** lat `27.8`, lon `-81.8`, zoom `6`
- **Save as:** `Florida Avg JV Map`

---

### CHART 6-C — Parcels by Latitude Band (Horizontal Bar)
- **Chart type:** Bar Chart
- **Dataset:** `v_dash_latitude_bands`
- **Orientation:** Horizontal
- **Y-axis (Dimensions):** `lat_band`
- **X-axis (Metrics):** `parcel_count` → Aggregation: **SUM** → Label: `Parcels`
- **Sort by:** `lat_band` ascending
- **Show data labels:** ON
- **X-axis label:** `Parcel Count`
- **Y-axis label:** `Latitude Band (degrees N)`
- **Number format:** `,d`
- **Save as:** `Parcel Count by Latitude Band`

### CHART 6-D — Total JV by Latitude Band (Bar Chart)
- **Chart type:** Bar Chart
- **Dataset:** `v_dash_latitude_bands`
- **Orientation:** Horizontal
- **Y-axis (Dimensions):** `lat_band`
- **X-axis (Metrics):** `total_jv_billions` → Aggregation: **SUM** → Label: `Total JV ($B)`
- **Sort by:** `lat_band` ascending
- **Show data labels:** ON
- **Number format:** `,.2f`
- **Save as:** `Total JV by Latitude Band`

---

### Assemble Dashboard 6

```
Row 1 (full width, tall):
  [6-A Florida County Bubble Map]

Row 2 (full width, tall):
  [6-B Florida Avg JV Map]

Row 3 (2 columns):
  Left:  [6-C Parcel Count by Latitude Band]
  Right: [6-D Total JV by Latitude Band]
```

---

## DASHBOARD 7 — ASSESSMENT ANALYSIS

### Create the dashboard
1. **Dashboards → + Dashboard**
2. Title: `Assessment Analysis`
3. Click **Save**

---

### CHART 7-A — Assessment Ratio by County (Horizontal Bar)
- **Chart type:** Bar Chart
- **Dataset:** `v_dash_assessment_ratio`
- **Orientation:** Horizontal
- **Y-axis (Dimensions):** `county_name`
- **X-axis (Metrics):**
  - `avg_assessment_ratio_sd` → Aggregation: **SUM** → Label: `Assessed/JV (School District)`
  - `avg_taxable_ratio` → Aggregation: **SUM** → Label: `Taxable/JV`
- **Bar style:** Grouped
- **Sort by:** `avg_assessment_ratio_sd` ascending
- **Reference line:** Add at x=1.0, label "100% = JV"
- **Number format:** `,.2%` *(or `,.4f`)*
- **Save as:** `Assessment Ratio by County`

### CHART 7-B — Assessment Ratio Table
- **Chart type:** Table
- **Dataset:** `v_dash_assessment_ratio`
- **Columns:**
  1. `county_name` → Label: `County`
  2. `avg_assessment_ratio_sd` → Label: `Assess Ratio (SD)` → Format: `,.4f`
  3. `avg_assessment_ratio_nsd` → Label: `Assess Ratio (NSD)` → Format: `,.4f`
  4. `avg_taxable_ratio` → Label: `Taxable Ratio` → Format: `,.4f`
  5. `parcel_count` → Label: `Parcels` → Format: `,d`
- **Sort by:** `avg_assessment_ratio_sd` ascending
- **Conditional formatting:**
  - `avg_assessment_ratio_sd`: Color scale blue
  - `avg_taxable_ratio`: Color scale green
- **Save as:** `Assessment Ratio Table`

---

### CHART 7-C — Land Value as % of JV – Heatmap
- **Chart type:** Heatmap
- **Dataset:** `v_dash_land_value_share`
- **X-axis:** `county_name`
- **Y-axis:** `land_use_category`
- **Metric:** `avg_land_pct_of_jv` → Aggregation: **SUM**
- **Normalize across:** All values
- **Show values:** OFF
- **Color scheme:** `RdYlGn`
- **Save as:** `Land Value % of JV Heatmap`

### CHART 7-D — Land Value Share Table
- **Chart type:** Table
- **Dataset:** `v_dash_land_value_share`
- **Columns:**
  1. `land_use_category` → Label: `Land Use`
  2. `county_name` → Label: `County`
  3. `avg_land_pct_of_jv` → Label: `Land % of JV` → Format: `,.2f`
  4. `avg_jv` → Label: `Avg JV` → Format: `$,.0f`
  5. `parcel_count` → Label: `Parcels` → Format: `,d`
- **Sort by:** `avg_land_pct_of_jv` descending
- **Page size:** 25
- **Save as:** `Land Value Share Table`

---

### CHART 7-E — Zero Just Value % by Land Use (Horizontal Bar)
- **Chart type:** Bar Chart
- **Dataset:** `v_dash_zero_value_analysis`
- **Orientation:** Horizontal
- **Y-axis (Dimensions):** `land_use_category`
- **X-axis (Metrics):** `zero_jv_pct` → Aggregation: **SUM** → Label: `% Zero JV`
- **Sort by:** `zero_jv_pct` descending
- **Show data labels:** ON
- **Number format:** `,.2f`
- **Save as:** `Zero JV % by Land Use`

### CHART 7-F — Zero Value Analysis Table
- **Chart type:** Table
- **Dataset:** `v_dash_zero_value_analysis`
- **Columns:**
  1. `land_use_category` → Label: `Land Use`
  2. `total_parcels` → Label: `Total Parcels` → Format: `,d`
  3. `zero_jv_count` → Label: `Zero JV Count` → Format: `,d`
  4. `zero_jv_pct` → Label: `% Zero JV` → Format: `,.2f`
  5. `zero_tv_count` → Label: `Zero TV Count` → Format: `,d`
  6. `zero_tv_pct` → Label: `% Zero TV` → Format: `,.2f`
- **Sort by:** `zero_jv_pct` descending
- **Conditional formatting:**
  - `zero_jv_pct`: Color scale red (high = dark red = problem)
- **Save as:** `Zero Value Analysis Table`

---

### Assemble Dashboard 7

```
Row 1 (full width):
  [7-A Assessment Ratio by County]

Row 2 (full width):
  [7-B Assessment Ratio Table]

Row 3 (full width):
  [7-C Land Value % of JV Heatmap]

Row 4 (2 columns):
  Left:  [7-E Zero JV % by Land Use]
  Right: [7-D Land Value Share Table]

Row 5 (full width):
  [7-F Zero Value Analysis Table]
```

---

## DASHBOARD 8 — OWNER ANALYSIS

### Create the dashboard
1. **Dashboards → + Dashboard**
2. Title: `Owner Analysis`
3. Click **Save**

---

### CHART 8-A — In-State vs Out-of-State Ownership (Pie)
- **Chart type:** Pie Chart
- **Dataset:** `v_dash_owner_state`
- **Custom SQL filter** (to group non-FL states):  
  Go to **Filters** → Add Custom SQL:  
  ```sql
  owner_state IN ('FL', 'Unknown') OR owner_state NOT IN ('FL', 'Unknown')
  ```
  *(No filter needed — show all; the pie will be dominated by FL)*
- **Dimensions:** `owner_state`
- **Metric:** `parcel_count` → Aggregation: **SUM**
- **Row limit:** 15
- **Show labels:** ON
- **Label type:** `Category and percentage`
- **Donut:** ON
- **Save as:** `Owner State Distribution – Pie`

### CHART 8-B — Top Owner States by Parcel Count (Horizontal Bar)
- **Chart type:** Bar Chart
- **Dataset:** `v_dash_owner_state`
- **Orientation:** Horizontal
- **Y-axis (Dimensions):** `owner_state`
- **X-axis (Metrics):** `parcel_count` → Aggregation: **SUM** → Label: `Parcels Owned`
- **Sort by:** `parcel_count` descending
- **Row limit:** 20
- **Show data labels:** ON
- **Number format:** `,d`
- **Save as:** `Top Owner States by Parcel Count`

### CHART 8-C — Top Owner States by Total JV (Horizontal Bar)
- **Chart type:** Bar Chart
- **Dataset:** `v_dash_owner_state`
- **Orientation:** Horizontal
- **Y-axis (Dimensions):** `owner_state`
- **X-axis (Metrics):** `total_jv_billions` → Aggregation: **SUM** → Label: `Total JV ($B)`
- **Sort by:** `total_jv_billions` descending
- **Row limit:** 20
- **Show data labels:** ON
- **Number format:** `,.2f`
- **Save as:** `Top Owner States by Total JV`

### CHART 8-D — Avg JV by Owner State (Horizontal Bar)
- **Chart type:** Bar Chart
- **Dataset:** `v_dash_owner_state`
- **Orientation:** Horizontal
- **Y-axis (Dimensions):** `owner_state`
- **X-axis (Metrics):** `avg_jv` → Aggregation: **SUM** → Label: `Avg Just Value`
- **Filter:** `parcel_count > 100` *(add in Filters section)*  
  Custom SQL: `parcel_count > 100`
- **Sort by:** `avg_jv` descending
- **Row limit:** 20
- **Number format:** `$,.0f`
- **Save as:** `Avg JV by Owner State`

### CHART 8-E — Owner State Full Table
- **Chart type:** Table
- **Dataset:** `v_dash_owner_state`
- **Columns:**
  1. `owner_state` → Label: `State`
  2. `parcel_count` → Label: `Parcels` → Format: `,d`
  3. `pct_of_total` → Label: `% of Total` → Format: `,.2f`
  4. `avg_jv` → Label: `Avg JV` → Format: `$,.0f`
  5. `total_jv_billions` → Label: `Total JV ($B)` → Format: `,.2f`
- **Sort by:** `parcel_count` descending
- **Page size:** 30
- **Search bar:** ON
- **Conditional formatting:**
  - `parcel_count`: Color scale blue
- **Save as:** `Owner State Full Table`

---

### CHART 8-F — Top 100 Parcels by Just Value (Table)
- **Chart type:** Table
- **Dataset:** `v_dash_top_parcels_by_jv`
- **Columns (in order):**
  1. `PARCEL_ID` → Label: `Parcel ID`
  2. `county_name` → Label: `County`
  3. `land_use_description` → Label: `Land Use`
  4. `land_use_category` → Label: `Category`
  5. `JV` → Label: `Just Value` → Format: `$,.0f`
  6. `TV_SD` → Label: `Taxable Value` → Format: `$,.0f`
  7. `LND_VAL` → Label: `Land Value` → Format: `$,.0f`
  8. `TOT_LVG_AR` → Label: `Living Area (sqft)` → Format: `,.0f`
  9. `EFF_YR_BLT` → Label: `Year Built`
  10. `PHY_ADDR1` → Label: `Address`
  11. `PHY_CITY` → Label: `City`
- **Page size:** 25
- **Sort by:** `JV` descending
- **Search bar:** ON
- **Conditional formatting:**
  - `JV`: Color scale (red for highest values)
- **Save as:** `Top 100 Parcels by Just Value`

---

### Assemble Dashboard 8

```
Row 1 (3 columns):
  Left:  [8-A Owner State Distribution – Pie]
  Mid:   [8-B Top Owner States by Parcel Count]
  Right: [8-C Top Owner States by Total JV]

Row 2 (full width):
  [8-D Avg JV by Owner State]

Row 3 (full width):
  [8-E Owner State Full Table]

Row 4 (full width):
  [8-F Top 100 Parcels by Just Value]
```

---

## PART 3 — CROSS-FILTERS (Connect charts within each dashboard)

After saving each dashboard, enable cross-filtering so clicking a bar/slice filters the other charts.

1. Open a dashboard → **Edit Dashboard**
2. Click the **...** menu on any chart → **Enable cross-filtering**
3. Enable cross-filtering on all charts in the dashboard that share a dimension (e.g., `county_name`)

**Key cross-filter pairs per dashboard:**
| Dashboard | Click on | Filters |
|-----------|----------|---------|
| D1 | County bar → filters land use pie and JV histogram | `county_name` |
| D2 | Year line → filters county bar and heatmap | `sale_year` |
| D3 | Map bubble → filters scorecard table | `county_name` |
| D4 | Land use category → filters county stacked bar | `land_use_category` |
| D8 | Owner state → filters top parcels table | `owner_state` |

---

## PART 4 — CUSTOM SQL METRICS IN CHART EDITOR

For charts where Superset's aggregation options are insufficient, use **Custom SQL** in the metric builder:

### Assessment Ratio (in v_dash_assessment_ratio charts)
The ratio is already pre-computed in the view. Use SUM directly.

### Value Per Sqft (custom if needed in any chart)
If you need it as a live metric (not from a view):
```sql
AVG(CASE WHEN TOT_LVG_AR > 0 THEN JV * 1.0 / TOT_LVG_AR END)
```

### Land Value as % of JV (custom)
```sql
AVG(CASE WHEN JV > 0 THEN LND_VAL * 100.0 / JV END)
```

### Taxable Ratio (custom)
```sql
AVG(CASE WHEN JV > 0 THEN TV_SD * 1.0 / JV END)
```

To use custom SQL in a metric:
1. In any chart editor, click **+ Add Metric**
2. Click the pencil icon → switch to **Custom SQL**
3. Paste the expression above
4. Set Label and Format

---

## PART 5 — NUMBER FORMAT REFERENCE

| Format string | Example output | Use for |
|--------------|---------------|---------|
| `,d` | 1,234,567 | Parcel counts, sale counts |
| `,.0f` | 1,234,568 | Rounded numbers |
| `$,.0f` | $234,568 | Dollar values (no cents) |
| `$,.2f` | $234,567.89 | Dollar values with cents |
| `,.2f` | 1,234.56 | Billions, ratios |
| `,.2%` | 12.34% | Percentages (multiply by 100 auto) |
| `,.4f` | 0.9876 | Assessment ratios |

---

## PART 6 — DASHBOARD TITLES AND DESCRIPTIONS

After saving each dashboard, add a description:
1. Open dashboard → **Edit Dashboard** → click title area
2. Add description text:

| Dashboard | Description |
|-----------|-------------|
| Property Valuation Overview | Statewide just value, taxable value, and land value summary by county and land use |
| Sales Analysis | Transaction volumes, price trends, and qualification analysis across all counties |
| County Comparison | Side-by-side county metrics combining valuation and sales data with map view |
| Land Use Deep Dive | Parcel distribution and valuation across DOR land use categories and codes |
| Building Characteristics | Year built, construction class, improvement quality, and living area analysis |
| Spatial Analysis | Geographic distribution of parcels and values across Florida |
| Assessment Analysis | Assessment ratios, land value share, and zero-value parcel quality analysis |
| Owner Analysis | Owner state residency patterns and top parcels by just value |

---

## TIPS FOR FASTER BUILDING

1. **Build KPI big numbers first** — they are quick (30 sec each) and give confidence the dataset connected correctly
2. **Duplicate charts** — after creating one bar chart, click the `...` menu in Charts list → **Duplicate**. Change only the metric/dimension for the next chart
3. **Save chart to multiple dashboards** — when saving a chart, in the "Add to Dashboard" field you can select multiple dashboards
4. **Use SQL Lab to verify data** — go to **SQL Lab**, select `Florida Parcels DuckDB`, run `SELECT * FROM v_dash_statewide_kpi` to confirm numbers before building charts
5. **Set default filters** — in each dashboard's **Edit Dashboard** mode, add a filter bar with `county_name` as a dropdown filter to let users slice all charts at once
