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
ORDER BY SalesVolume DESC
GO

--The most popular product ID is 712 and its name is "AWC Logo Cap" with 8311 sales number 
--and $51,229 gross revenue. Although it has the highest sales volume, it has a relatively 
--lower unit price, which generated less than 30% of revenue of other products, such as 
--Long-Sleeve Logo Jersey (~$200k) and Sport-100 Helmet (~$165k).

SELECT *
FROM Sales.SalesOrderHeader
--FROM Production.Product

SELECT *
FROM Production.Product 
GO


-- 2011-05-31 00:00:00.000 ~ 2014-06-30 00:00:00.000
WITH Sales AS (
SELECT CustomerID
	, SUM(TotalDue) AS TotalSpending
	, MIN(OrderDate) OVER (PARTITION BY CustomerID) AS FirstDate
	, MAX(OrderDate) OVER (PARTITION BY CustomerID) AS LastDate
	, DATEDIFF(DAY, 
		MIN(OrderDate) OVER (PARTITION BY CustomerID), 
		DATEADD(day, 1, MAX(OrderDate) OVER (PARTITION BY CustomerID))
	) AS ActiveDays
FROM Sales.SalesOrderHeader
--WHERE YEAR(OrderDate) IN (2013, 2014)
--GROUP BY CustomerID
),
Customers AS (
SELECT c.CustomerID
	, CONCAT(ISNULL(p.Title + ' ', ''), p.FirstName, ' ', p.LastName) AS FullName
FROM Sales.Customer c
	INNER JOIN Person.Person p
		ON c.PersonID = p.BusinessEntityID
)
SELECT Sales.*
	, Customers.FullName
FROM Sales
INNER JOIN Customers
ON Sales.CustomerID = Customers.CustomerID


SELECT soh.SalesOrderID, sod.ProductID, sod.OrderQty, soh.OrderDate,
    DATEDIFF(day, MIN(soh.OrderDate)   
        OVER(PARTITION BY soh.SalesOrderID), SYSDATETIME()) AS 'Total'  
FROM Sales.SalesOrderDetail sod  
    INNER JOIN Sales.SalesOrderHeader soh  
        ON sod.SalesOrderID = soh.SalesOrderID  