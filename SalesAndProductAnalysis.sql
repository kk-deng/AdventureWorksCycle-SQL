-- Get the top 10 popular products based on the sales quantity
WITH Sale AS (
SELECT ProductID
	, SUM(OrderQty) AS SalesVolume
	, SUM(UnitPrice) AS Revenue
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

SELECT *
FROM Production.Product