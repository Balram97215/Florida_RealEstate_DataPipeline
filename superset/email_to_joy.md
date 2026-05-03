# Follow-Up Email — Finance and Data Analyst (NF0009704)
**To:** jmonte@unc.edu  
**Subject:** Following Up — Finance and Data Analyst Application | Balram Bhanu Iyengar (NF0009704)

---

Dear Ms. Montemorano,

I hope you're having a great week. My name is Balram Bhanu Iyengar, and I submitted my application for the Finance and Data Analyst position (Vacancy ID: NF0009704) in the College of Arts and Sciences Dean's Office on April 25th. I wanted to reach out briefly to express my continued interest and share something concrete that might be useful as you evaluate candidates.

The role's description genuinely stood out to me — especially the framing around someone who "likes to dig into messy data and figure out what's actually going on." That describes how I've approached every project I've led. I am not a report-factory; I'm someone who gets curious when something doesn't add up and follows it until there's an explanation worth acting on.

**A relevant example of that work:**

I am currently serving as a pro bono Business Intelligence Developer for Community Dreams Foundation, a nonprofit working at the intersection of fair housing policy and data transparency. The Foundation had no analytical infrastructure — just raw Florida state parcel data with no way to ask questions of it at any meaningful scale.

I designed and built a production-grade ELT pipeline and analytics platform entirely from scratch:

- **Scope:** 10.8 million property parcel records across all 68 Florida counties
- **Pipeline:** Python-based Extract → Load → Transform → Validate framework, ingesting data from an Esri geodatabase format (`.gdb`), processing it through DuckDB with automated CRS transformation (EPSG:6439 → WGS84), and building a validated analytical warehouse
- **Analytics Layer:** 8 Apache Superset dashboards with 27+ pre-aggregated SQL views — covering property valuation, sales analysis, building characteristics, land use breakdowns, county comparisons, spatial mapping, assessment ratios, and owner-state analysis
- **Data Quality:** A built-in cross-validation framework (9 validation views) that automatically confirms dashboard numbers match independent EDA output — ensuring analysts and leadership can trust what they see
- **Business Impact:** Reduced policy analysis time from days to under an hour; produced the first-ever statewide baseline showing 21.4% corporate ownership concentration across Florida, directly supporting fair housing regulatory submissions

I've attached a project overview report and a sample dashboard screenshot as supplementary materials. If it would be helpful, I'm also happy to share the GitHub repository or schedule a brief live walkthrough.

I am excited about the prospect of bringing this same rigor — building from scratch, validating carefully, and making sure leadership can actually use what gets built — to the College's finance and data operations.

Thank you for your time, and I look forward to hearing from you.

Warm regards,

**Balram Bhanu Iyengar**  
(413) 612-8297 | iyengarbalram97@gmail.com  
[github.com/Balram97215](https://github.com/Balram97215) | [linkedin.com/in/balram-iyengar-97shree](https://linkedin.com/in/balram-iyengar-97shree)

---

> **Attachments to include:**
> - `Florida_Parcels_Project_Report.pdf` (see project_report.md in this folder)
> - Dashboard screenshot (export from Superset or use the screenshot already captured)
> - Resume (Balram_Bhanu_Iyengar_Resume.pdf)
