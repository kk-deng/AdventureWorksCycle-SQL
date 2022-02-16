-- PRODUCTS SALES

-- Q1
-- Get the top 10 popular products based on the sales quantity
WITH sale AS (
	SELECT ProductID
		, SUM(OrderQty) AS SalesVolume
		, SUM(LineTotal) AS Revenue
		, ROUND(AVG(UnitPrice * (1 - UnitPriceDiscount)), 2) AS AvgUnitPriceAfterDiscount
	FROM Sales.SalesOrderDetail
	GROUP BY ProductID
),
products AS (
	SELECT p.ProductID
		, p.Name AS ProductName
		, s.ProductSubcategoryID
		, s.Name AS SubcatName
		, c.ProductCategoryID
		, c.Name AS CatName
	FROM Production.Product p
		LEFT JOIN Production.ProductSubcategory s
			ON p.ProductSubcategoryID = s.ProductSubcategoryID
		LEFT JOIN Production.ProductCategory c
			ON s.ProductCategoryID = c.ProductCategoryID
)
SELECT TOP 10 
	s.*
	, p.ProductName
	, p.SubcatName
	, p.CatName
FROM sale s
	LEFT JOIN products p
		ON s.ProductID = p.ProductID
ORDER BY SalesVolume DESC;
GO

--Analysis:
--The most popular product_ID by quantity is 712 and its name is "AWC Logo Cap" with 8311 units sold
--which brought $51,229 gross revenue to the company. Although it has the highest sales volume, it has a relatively 
--lower unit price, which generated less than 30% of revenue of other products, such as 
--Long-Sleeve Logo Jersey (~$200k) and Sport-100 Helmet (~$165k).

-- Q2
-- Get the top 10 popular products based on the gross revenue
SELECT TOP 10
	ProductID
	, SUM(OrderQty) AS SalesVolume
	, SUM(LineTotal) AS Revenue
	, ProductName
	, SubcatName
	, CatName
FROM vProductSalesSummary
GROUP BY ProductID
	, ProductName
	, SubcatName
	, CatName
ORDER BY Revenue DESC

--Analysis:
--The most popular product_ID by revenue is 782 with revenue of $4.4 million. 
--In the top 10 best selling items, all of them are bikes, and the top 6 items are mountain bikes. 
--Because bikes have a higher unit price, although the Mountain-200 Black bike has only around three thousand units sold, 
--the unit price of this model is $1229.

-- Q3
-- The most popular subcategory by order numbers
SELECT TOP 10
	SubcatName
	, COUNT(DISTINCT(SalesOrderID)) AS TotalOrders
	, SUM(OrderQty) AS SalesVolume
	, SUM(LineTotal) AS Revenue
	, CatName
FROM vProductSalesSummary
GROUP BY SubcatName
	, CatName
ORDER BY TotalOrders DESC

SELECT CatName
	, COUNT(DISTINCT(SalesOrderID)) AS TotalOrders
	, SUM(OrderQty) AS SalesVolume
	, SUM(LineTotal) AS Revenue
FROM vProductSalesSummary
GROUP BY CatName
ORDER BY TotalOrders DESC

--Analysis:
--In the top 10 subcategories, tires and tubes are the most demanding products with more than 10,000 orders.
--However, road bikes has the most units sold in the top 10, having 47,196 items with around 9,500 orders.
--In terms of the categories, accessories have the highest sales orders (19,524) amongst these four main categories,
--followed by bikes (18,368).

--PEOPLE
--Q4 
--Get the Top Salesperson by Sales Volume
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
	, ROW_NUMBER() OVER (PARTITION BY SalesRegion ORDER BY SalesYTD DESC) AS Ranking
FROM sp
ORDER BY SalesRegion DESC

--Analysis:
--14 salespersons have a sales target in 2014. All of them have met and exceeded the target.
--North America has the most salesperson amongst all sales regions (10 salespersons). Lynn Tsoflia is responsible for 
--sales in the Pacific region, generating around $1.42 million in sales. While in North America, Linda Mitchell won
--the best salesperson who brought about $4.25 million in sales to the company, followed by Michael Blythe and 
--Jillian Carson with $3.76 million and $3.19 million, respectively. In Europe region, Jae Pak has the highest sales ($4.12 million)

-- CUSTOMER SALES
-- Q5 - Create a view for RFM model: vCustomerSalesSummary
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

-- Q6 Customer Segmentation with RFM Model
WITH CusSales AS (
SELECT CustomerID
	, FullName
	, CAST(NumOfTxn / ActiveWeeks AS FLOAT) AS WeeklyTxnNum
	, TotalSpending / ActiveWeeks AS WeeklySpending
	, DaysSinceLastTxn
FROM vCustomerSalesSummary
),
CusRank AS (
	SELECT CusSales.*
--CustomerID
--	, FullName
	, NTILE(4) OVER (ORDER BY DaysSinceLastTxn) AS RankRecency
	, NTILE(4) OVER (ORDER BY WeeklyTxnNum DESC) AS RankWeeklyTxnNum
	, NTILE(4) OVER (ORDER BY WeeklySpending DESC) AS RankWeeklySpending
FROM CusSales
),
CusRFM AS (
SELECT CusRank.*
	, CONCAT(RankRecency, RankWeeklyTxnNum, RankWeeklySpending) AS RFM
	, RankRecency + RankWeeklyTxnNum + RankWeeklySpending AS RFMSum
FROM CusRank
)
SELECT RFMSum
	, COUNT(DISTINCT(CustomerID)) AS CustomerCount
	, COUNT(*) * 100.0 / SUM(COUNT(*)) OVER() AS PercentageTotal
FROM CusRFM
GROUP BY RFMSum
ORDER BY RFMSum
GO

--Analysis:
--RFMSum is the sum of each segment of R, F, and M. The lower the value, the higher tier the customer is.
--The RFMSum of 3 means the most valuable customers. In the result, it has 796 customers ranked as the top tier (4.2%).
--While the RFMSum of 9 has the most population (21.9%).