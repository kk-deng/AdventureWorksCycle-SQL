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

--The most popular product ID is 712 and its name is "AWC Logo Cap" with 8311 sales number 
--and $51,229 gross revenue. Although it has the highest sales volume, it has a relatively 
--lower unit price, which generated less than 30% of revenue of other products, such as 
--Long-Sleeve Logo Jersey (~$200k) and Sport-100 Helmet (~$165k).


-- Q2 - Create a view for RFM model: vCustomerRFM
-- 2011-05-31 00:00:00.000 ~ 2014-06-30 00:00:00.000
WITH RawSales AS (
	SELECT CustomerID
		, SUM(TotalDue) AS TotalSpending
		, COUNT(DISTINCT SalesOrderID) AS NumOfTxn
		, MIN(OrderDate) AS FirstDate
		, MAX(OrderDate) AS LastDate
		, DATEDIFF(DAY, MIN(OrderDate), DATEADD(DAY, 1, MAX(OrderDate))) AS ActiveDays
		, CAST('2014-07-01T00:00:00.000' AS datetime) AS CurrentDate
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
	--, CAST(RawSales.ActiveDays / 7 AS INT) AS ActiveWeeks
	, DATEDIFF(DAY, RawSales.LastDate, RawSales.CurrentDate) AS DaysSinceLastTxn
	, Customers.FullName
FROM RawSales
	INNER JOIN Customers
		ON RawSales.CustomerID = Customers.CustomerID;
GO

-- Q3 - Individual Customer Segmentation
WITH CusSales AS (
SELECT CustomerID
	, FullName
	, NumOfTxn / ActiveWeeks AS WeeklyTxnNum
	, TotalSpending / ActiveWeeks AS WeeklySpending
FROM dbo.vCustomerRFM