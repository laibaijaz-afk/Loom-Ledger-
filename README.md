# Loom & Ledger
Textile manufacturing KPI dashboard - SQL analysis + Power BI

# 🏭 Textile Manufacturing Performance Analysis

A SQL + Power BI project analyzing production, quality, and cost performance for a textile manufacturing operation modeled on Faisalabad's textile industry — one of Pakistan's largest textile manufacturing hubs.

## 📌 Project Overview

This project simulates a real textile mill's operational data across 6 departments (Spinning, Weaving, Dyeing, Finishing, Stitching, Quality Control) and answers key production, quality, and cost questions that plant managers and business owners actually ask.

**Dataset:** 2 years of daily operations (Jan 2024 – Dec 2025)
- 22,500+ production records
- 39 machines across 6 departments
- 180 employees
- 500 customer/export orders
- Daily cost & revenue tracking

## ❓ Business Questions Answered

1. Which department produces the most?
2. Which machine has the highest defect rate?
3. Which month had the highest production?
4. Where is production cost highest?
5. What is the overall and department-wise defect percentage?
6. How does actual production compare to target (achievement %)?

## 🛠️ Tools Used

| Tool | Purpose |
|---|---|
| **MySQL / MySQL Workbench** | Data storage, relational schema, SQL analysis |
| **Power BI Desktop** | Interactive KPI dashboard, DAX measures, data modeling |
| **Excel / CSV** | Raw dataset format |

## 🗄️ Database Schema

```
Departments (DeptID, DeptName)
Employees (EmpID, Name, DeptID, Shift, JoinDate)
Machines (MachineID, MachineName, DeptID, InstallDate, Status)
Production (ProdID, Date, DeptID, MachineID, EmployeeID, QuantityProduced, TargetQuantity)
Defects (DefectID, ProdID, MachineID, DeptID, Date, DefectQty, DefectType)
Cost_Revenue (Date, DeptID, ProductionCost, Revenue)
Orders (OrderID, Client, DeptID, OrderDate, DueDate, QuantityOrdered, Status)
```

All tables are linked by foreign keys (`DeptID`, `MachineID`, `EmployeeID`, `ProdID`), enabling multi-table JOINs for cross-departmental analysis.

## 📊 SQL Analysis Highlights

See [`textile_sql_analysis.sql`](./textile_sql_analysis.sql) for the full query set. A few examples:

**Machine defect rate** (aggregates Production and Defects independently before joining, to avoid row-multiplication errors from a direct many-to-many join):
```sql
SELECT m.MachineName, prod.total_production, def.total_defects,
       ROUND((def.total_defects / prod.total_production) * 100, 2) AS defect_rate_pct
FROM Machines m
JOIN (SELECT MachineID, SUM(QuantityProduced) AS total_production
      FROM Production GROUP BY MachineID) prod ON m.MachineID = prod.MachineID
JOIN (SELECT MachineID, SUM(DefectQty) AS total_defects
      FROM Defects GROUP BY MachineID) def ON m.MachineID = def.MachineID
ORDER BY defect_rate_pct DESC;
```

**Target vs Actual achievement %:**
```sql
SELECT d.DeptName,
       SUM(p.QuantityProduced) AS actual_production,
       SUM(p.TargetQuantity) AS target_production,
       ROUND(SUM(p.QuantityProduced) / SUM(p.TargetQuantity) * 100, 2) AS achievement_pct
FROM Production p
JOIN Departments d ON p.DeptID = d.DeptID
GROUP BY d.DeptName
ORDER BY achievement_pct DESC;
```

## 📈 Power BI Dashboard

The dashboard includes:

- **KPI Cards:** Total Production, Production Target, Achievement %, Defect Rate %, Total Revenue, Total Cost
- **Monthly Production Trend** — seasonal patterns across the year
- **Department Performance** — production output by department
- **Machine Performance** — defect rate ranked by machine, flagging maintenance-priority equipment
- **Target vs Actual Production** — combo chart tracking monthly performance against plan

### Key DAX Measures
```dax
Total Production = SUM(Production[QuantityProduced])
Production Target = SUM(Production[TargetQuantity])
Achievement % = DIVIDE([Total Production], [Production Target])
Total Defects = SUM(Defects[DefectQty])
Defect Rate % = DIVIDE([Total Defects], [Total Production])
Total Revenue = SUM(Cost_Revenue[Revenue])
Total Cost = SUM(Cost_Revenue[ProductionCost])
```

## 🔍 Key Insights

- **Spinning** is the highest-producing department, followed by Quality Control and Weaving.
- **Dyeing** department has the highest defect rate (~7%), driven largely by one underperforming machine.
- Production peaks in **September–November** (export/Eid season) and dips on Fridays/Sundays and during summer months.
- Overall plant achieves **~88% of production target**, with room to improve in Dyeing and Weaving.


## 📁 Repository Contents

| File | Description |
|---|---|
| `departments.csv`, `employees.csv`, `machines.csv`, `production.csv`, `defects.csv`, `cost_revenue.csv`, `orders.csv` | Raw dataset (7 related tables) |
| `textile_manufacturing_data.xlsx` | Same dataset, all sheets in one workbook |
| `textile_sql_analysis.sql` | Full SQL query set answering all business questions |
| `Textile_Manufacturing.pbix` | Power BI dashboard file |

## 🚀 How to Reproduce

1. Import the CSV files into MySQL (or any relational database) using the schema above.
2. Run the queries in `textile_sql_analysis.sql` to validate the analysis.
3. Open `Textile_Manufacturing.pbix` in Power BI Desktop, or connect Power BI directly to your database.

---

*This dataset is synthetically generated for portfolio/demonstration purposes and does not represent a real company's data.*
