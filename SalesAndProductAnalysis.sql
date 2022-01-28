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
FROM Sales.SalesOrderDetail
--FROM Production.Product