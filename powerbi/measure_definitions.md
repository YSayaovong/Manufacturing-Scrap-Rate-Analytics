# Power BI – Suggested DAX Measures

**Tables**: Import `dim_*`, `fact_production`, `fact_scrap_detail`, and optionally views as tables if desired.

```DAX
Produced Qty := SUM(fact_production[produced_qty])
Scrap Qty    := SUM(fact_production[scrap_qty])
Rework Qty   := SUM(fact_production[rework_qty])

Scrap Rate := DIVIDE([Scrap Qty], [Produced Qty])

-- Rolling 28d Scrap Rate (assumes a Calendar table mapped to dim_date)
Scrap Qty 28d := CALCULATE([Scrap Qty], DATESINPERIOD(dim_date[calendar_date], MAX(dim_date[calendar_date]), -28, DAY))
Prod Qty 28d  := CALCULATE([Produced Qty], DATESINPERIOD(dim_date[calendar_date], MAX(dim_date[calendar_date]), -28, DAY))
Scrap Rate 28d := DIVIDE([Scrap Qty 28d], [Prod Qty 28d])

-- YTD Scrap Rate
Scrap Qty YTD := TOTALYTD([Scrap Qty], dim_date[calendar_date])
Prod Qty YTD  := TOTALYTD([Produced Qty], dim_date[calendar_date])
Scrap Rate YTD := DIVIDE([Scrap Qty YTD], [Prod Qty YTD])

-- Pareto cumulative % by defect (requires a defects table)
Defect Scrap Qty := SUM(fact_scrap_detail[scrap_qty])
Total Scrap (Context) := CALCULATE([Defect Scrap Qty], ALL(dim_defect))
Pareto Cum % :=
VAR ThisDefectQty = [Defect Scrap Qty]
VAR RankByQty =
    RANKX(
        ALL(dim_defect[defect_code]),
        [Defect Scrap Qty],
        ,
        DESC,
        Dense
    )
VAR CumQty =
    SUMX(
        TOPN(RankByQty, ALL(dim_defect[defect_code]), [Defect Scrap Qty], DESC),
        [Defect Scrap Qty]
    )
RETURN DIVIDE(CumQty, [Total Scrap (Context)])
```

**Visuals**  
- Line: `Scrap Rate` by `calendar_date` (with 28d line overlay)  
- Bar: `Defect Scrap Qty` by `defect_code`, color by `Pareto Cum %` (show 80% line)  
- Matrix: `plant_name` → `line_name` → `part_name` with `[Scrap Rate]`  
