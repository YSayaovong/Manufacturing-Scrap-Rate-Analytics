# Entity-Relationship Design (ERD)

Star schema with two fact tables:

- **sra.fact_production** (units_produced by date, line, product)  
- **sra.fact_scrap** (units_scrapped by date, line, product, defect)

Dimensions:
- **sra.dim_date** (date, year, quarter, month, day, week, weekday, weekend flag)
- **sra.dim_line** (line_code, line_name)
- **sra.dim_product** (sku, product_name, unit_cost)
- **sra.dim_defect** (defect_code, defect_name)
