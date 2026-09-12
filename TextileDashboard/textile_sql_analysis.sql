/* =====================================================================
   TEXTILE MANUFACTURING PERFORMANCE ANALYSIS
   Database: textile_manufacturing
   Tables: Departments, Employees, Machines, Production, Defects,
           Cost_Revenue, Orders
   Dialect: MySQL (works with minor tweaks in PostgreSQL/SQL Server too)
   ===================================================================== */

USE textile_manufacturing;

-- 1. WHICH DEPARTMENT PRODUCES THE MOST?
SELECT
    d.DeptName,
    SUM(p.QuantityProduced) AS total_production
FROM Production p
JOIN Departments d ON p.DeptID = d.DeptID
GROUP BY d.DeptName
ORDER BY total_production DESC;


-- 2. WHICH MACHINE HAS THE HIGHEST DEFECT RATE?
-- Note: Production and Defects are aggregated separately first
-- (each into its own subquery), then joined on MachineID. Joining the
-- two raw tables directly on MachineID would multiply rows and inflate
-- the numbers, since each machine has many Production rows AND many
-- Defects rows.
SELECT
    m.MachineID,
    m.MachineName,
    prod.total_production,
    def.total_defects,
    ROUND((def.total_defects / prod.total_production) * 100, 2) AS defect_rate_pct
FROM Machines m
JOIN (
    SELECT MachineID, SUM(QuantityProduced) AS total_production
    FROM Production
    GROUP BY MachineID
) prod ON m.MachineID = prod.MachineID
JOIN (
    SELECT MachineID, SUM(DefectQty) AS total_defects
    FROM Defects
    GROUP BY MachineID
) def ON m.MachineID = def.MachineID
ORDER BY defect_rate_pct DESC;

-- 3. WHICH MONTH HAD THE HIGHEST PRODUCTION?
SELECT
    DATE_FORMAT(Date, '%Y-%m') AS production_month,
    SUM(QuantityProduced) AS total_production
FROM Production
GROUP BY production_month
ORDER BY total_production DESC;

-- Just the single highest month:
SELECT
    DATE_FORMAT(Date, '%Y-%m') AS production_month,
    SUM(QuantityProduced) AS total_production
FROM Production
GROUP BY production_month
ORDER BY total_production DESC
LIMIT 1;


-- 4. cost by department
SELECT
    d.DeptName,
    ROUND(SUM(cr.ProductionCost), 2) AS total_cost,
    ROUND(SUM(cr.Revenue), 2)        AS total_revenue,
    ROUND(SUM(cr.Revenue) - SUM(cr.ProductionCost), 2) AS profit
FROM Cost_Revenue cr
JOIN Departments d ON cr.DeptID = d.DeptID
GROUP BY d.DeptName
ORDER BY total_cost DESC;

-- Cost trend by month (useful for a line chart)
SELECT
    DATE_FORMAT(Date, '%Y-%m') AS cost_month,
    ROUND(SUM(ProductionCost), 2) AS total_cost
FROM Cost_Revenue
GROUP BY cost_month
ORDER BY cost_month;


-- Overall defect %
SELECT
    ROUND(
        (SELECT SUM(DefectQty) FROM Defects) /
        (SELECT SUM(QuantityProduced) FROM Production) * 100, 2
    ) AS overall_defect_pct;

-- Defect % by department
SELECT
    d.DeptName,
    prod.total_production,
    def.total_defects,
    ROUND((def.total_defects / prod.total_production) * 100, 2) AS defect_rate_pct
FROM Departments d
JOIN (
    SELECT DeptID, SUM(QuantityProduced) AS total_production
    FROM Production
    GROUP BY DeptID
) prod ON d.DeptID = prod.DeptID
JOIN (
    SELECT DeptID, SUM(DefectQty) AS total_defects
    FROM Defects
    GROUP BY DeptID
) def ON d.DeptID = def.DeptID
ORDER BY defect_rate_pct DESC;


SELECT
    DefectType,
    COUNT(*) AS occurrences,
    SUM(DefectQty) AS total_defect_units
FROM Defects
GROUP BY DefectType
ORDER BY total_defect_units DESC;


-- 6. TARGET VS ACTUAL PRODUCTION 
SELECT
    SUM(QuantityProduced) AS total_actual,
    SUM(TargetQuantity)   AS total_target,
    ROUND(SUM(QuantityProduced) / SUM(TargetQuantity) * 100, 2) AS achievement_pct
FROM Production;

-- By department
SELECT
    d.DeptName,
    SUM(p.QuantityProduced) AS actual_production,
    SUM(p.TargetQuantity)   AS target_production,
    ROUND(SUM(p.QuantityProduced) / SUM(p.TargetQuantity) * 100, 2) AS achievement_pct
FROM Production p
JOIN Departments d ON p.DeptID = d.DeptID
GROUP BY d.DeptName
ORDER BY achievement_pct DESC;

-- By month (for a Target vs Actual trend chart)
SELECT
    DATE_FORMAT(Date, '%Y-%m') AS production_month,
    SUM(QuantityProduced) AS actual_production,
    SUM(TargetQuantity)   AS target_production,
    ROUND(SUM(QuantityProduced) / SUM(TargetQuantity) * 100, 2) AS achievement_pct
FROM Production
GROUP BY production_month
ORDER BY production_month;


SELECT
    d.DeptName,
    COUNT(DISTINCT e.EmpID) AS employee_count
FROM Employees e
JOIN Departments d ON e.DeptID = d.DeptID
GROUP BY d.DeptName
ORDER BY employee_count DESC;


SELECT
    m.MachineID,
    m.MachineName,
    d.DeptName,
    m.Status,
    m.InstallDate
FROM Machines m
JOIN Departments d ON m.DeptID = d.DeptID
WHERE m.Status = 'Under Maintenance';


--  Order fulfilment status breakdown (on-time vs delayed vs cancelled)
SELECT
    Status,
    COUNT(*) AS order_count,
    SUM(QuantityOrdered) AS total_units_ordered
FROM Orders
GROUP BY Status
ORDER BY order_count DESC;

-- BONUS: KPI summary
SELECT
    (SELECT SUM(QuantityProduced) FROM Production)                          AS total_production,
    (SELECT SUM(TargetQuantity) FROM Production)                            AS production_target,
    ROUND((SELECT SUM(QuantityProduced) FROM Production) /
          (SELECT SUM(TargetQuantity) FROM Production) * 100, 2)            AS achievement_pct,
    (SELECT SUM(DefectQty) FROM Defects)                                    AS total_defects,
    ROUND((SELECT SUM(DefectQty) FROM Defects) /
          (SELECT SUM(QuantityProduced) FROM Production) * 100, 2)          AS defect_rate_pct,
    (SELECT ROUND(SUM(Revenue), 2) FROM Cost_Revenue)                       AS total_revenue,
    (SELECT ROUND(SUM(ProductionCost), 2) FROM Cost_Revenue)                AS total_cost;
