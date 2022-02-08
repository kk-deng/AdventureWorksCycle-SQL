-- Q1
-- Get the top 10 popular products based on the sales quantity
WITH Sale AS (
	SELECT ProductID
		, SUM(OrderQty) AS SalesVolume
		, SUM(LineTotal) AS Revenue
		, ROUND(AVG(UnitPrice - UnitPriceDiscount), 2) AS AvgUnitPriceAfterDiscount
	FROM Sales.SalesOrderDetail
	GROUP BY ProductID
)
SELECT TOP 10 
	s.*
	, p.Name
FROM Sale s
	LEFT JOIN Production.Product p
		ON s.ProductID = p.ProductID
ORDER BY SalesVolume DESC;
GO

--Analysis:
--The most popular product ID is 712 and its name is "AWC Logo Cap" with 8311 sales number 
--and $51,229 gross revenue. Although it has the highest sales volume, it has a relatively 
--lower unit price, which generated less than 30% of revenue of other products, such as 
--Long-Sleeve Logo Jersey (~$200k) and Sport-100 Helmet (~$165k).

--Q2 Top Salesperson
WITH sp AS (
	SELECT s.BusinessEntityID
		, CONCAT(ISNULL(p.Title + ' ', ''), p.FirstName, ' ', p.LastName) AS FullName
		, s.SalesQuota
		, s.Bonus
		, s.CommissionPct
		, s.SalesYTD
		, t.[Group] AS SalesRegion
		--, SalesLastYear
		--, CONVERT(NVARCHAR(20), SalesYTD, 1) AS SalesYTD
	FROM Sales.SalesPerson s
		INNER JOIN Person.Person p
			ON s.BusinessEntityID = p.BusinessEntityID
		INNER JOIN Sales.SalesTerritory t
			ON s.TerritoryID = t.TerritoryID
	WHERE s.SalesQuota IS NOT NULL
)
SELECT sp.*
	, CONVERT(NVARCHAR(20), sp.SalesYTD, 1) AS SalesYearToDay
	, ad.PostalCode
	, ROW_NUMBER() OVER (PARTITION BY SalesRegion ORDER BY SalesYTD DESC) AS Ranking
FROM sp
	INNER JOIN Person.Address AS ad
	    ON ad.AddressID = sp.BusinessEntityID 
ORDER BY SalesRegion DESC

-- Q2 - Create a view for RFM model: vCustomerRFM
-- 2011-05-31 00:00:00.000 ~ 2014-06-30 00:00:00.000
WITH RawSales AS (
	SELECT CustomerID
		, SUM(TotalDue) AS TotalSpending
		, COUNT(DISTINCT SalesOrderID) AS NumOfTxn
		, MIN(OrderDate) AS FirstDate
		, MAX(OrderDate) AS LastDate
		, DATEDIFF(DAY, MIN(OrderDate), DATEADD(DAY, 1, MAX(OrderDate))) AS ActiveDays
	FROM Sales.SalesOrderHeader
	GROUP BY CustomerID
),
Customers AS (
	SELECT c.CustomerID
		, CONCAT(ISNULL(p.Title + ' ', ''), p.FirstName, ' ', p.LastName) AS FullName
	FROM Sales.Customer c
		INNER JOIN Person.Person p
			ON c.PersonID = p.BusinessEntityID
)
SELECT RawSales.*
	, ActiveWeeks =
		CASE
			WHEN CAST(RawSales.ActiveDays / 7 AS INT) = 0 THEN 1
			ELSE CAST(RawSales.ActiveDays / 7 AS INT)
		END
	, DATEDIFF(DAY, RawSales.LastDate, '2014-07-01T00:00:00.000') AS DaysSinceLastTxn
	, Customers.FullName
FROM RawSales
	INNER JOIN Customers
		ON RawSales.CustomerID = Customers.CustomerID;
GO

-- Q3 - Individual Customer Segmentation with RFM Model
WITH CusSales AS (
SELECT CustomerID
	, FullName
	, CAST(NumOfTxn / ActiveWeeks AS FLOAT) AS WeeklyTxnNum
	, TotalSpending / ActiveWeeks AS WeeklySpending
	, DaysSinceLastTxn
FROM vCustomerRFM
),
CusRank AS (
SELECT CusSales.*
--CustomerID
--	, FullName
	, NTILE(5) OVER (ORDER BY DaysSinceLastTxn) AS RankRecency
	, NTILE(5) OVER (ORDER BY WeeklyTxnNum DESC) AS RankWeeklyTxnNum
	, NTILE(5) OVER (ORDER BY WeeklySpending DESC) AS RankWeeklySpending
FROM CusSales
),
CusRFM AS (
SELECT CusRank.*
	, CONCAT(RankRecency, RankWeeklyTxnNum, RankWeeklySpending) AS RFM
	, RankRecency + RankWeeklyTxnNum + RankWeeklySpending AS RFMSum
FROM CusRank
)
SELECT * 
FROM CusRFM
WHERE RFM = 111
ORDER BY RankWeeklySpending DESC;
GO

-- Q4 - 