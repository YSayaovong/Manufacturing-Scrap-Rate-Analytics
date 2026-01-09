# 🏭 Scrap Rate Analytics — Manufacturing Quality & Cost Risk Analysis (Python + SQL + CSV)

This project implements a repeatable analytics pipeline to evaluate scrap behavior, identify high-risk defect patterns, and quantify their operational and financial impact.  
Using Python, SQL, and structured CSV workflows, it transforms raw production scrap data into actionable insights for **engineering, quality, and manufacturing** teams.

---

## ⚙️ Engineering Problem — Scrap, Variability, and Hidden Cost

In manufacturing, scrap is more than a quality issue — it is a signal of process instability and uncontrolled variation that leads to rework, delays, and avoidable cost.

Without structured analytics, teams struggle to answer questions that affect reliability and decision-making:

- Which production lines generate the **highest scrap cost and instability**?
- Which defect modes create the **largest recurring losses**?
- When does scrap cost spike, and are spikes **special-cause variation** or noise?
- Are improvement actions reducing scrap **sustainably**, or shifting failure modes?

This project provides visibility into daily losses and helps teams prioritize the highest-impact corrective actions.

---

## 🔍 What This Project Does

- Cleans raw scrap + production CSV files into consistent datasets
- Computes operational + financial KPIs:
  - **Scrap Cost**
  - **Scrap Rate %**
  - **Cost by Defect Category**
  - **Cost by Production Line**
  - **Unit Cost Lost**
  - **Daily Financial Variance**
- Detects trends, spikes, and repeatable defect patterns
- Generates static PNG visuals for engineering reviews, CI meetings, and supervisor reports
- Produces repeatable outputs suitable for:
  - Daily production meetings
  - Lean/CI initiatives
  - CAPA validation
  - Monthly cost-reduction and quality reviews

> All data is synthetic and created for safe portfolio demonstration.

---

## 🧱 Pipeline Overview

**Inputs**
- `data/raw/` (raw scrap + production CSVs)

**Processing**
- Python ETL cleans and normalizes inputs
- SQL queries aggregate by defect, line, and day
- Python analysis produces KPI tables + charts

**Outputs**
- `outputs/img/` (PNG visuals)
- `outputs/` (summary tables / exports, if applicable)

---

## ▶️ How to Run

> Adjust paths/filenames below to match your repo structure.

1) Create a virtual environment (recommended)
```bash
python -m venv .venv
# Windows:
.venv\Scripts\activate
# macOS/Linux:
source .venv/bin/activate
