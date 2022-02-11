-- =============================================
-- Create View for Customer Segmentation:
-- Recency, Frequency, Monetary
-- =============================================
USE AdventureWorks2019
GO

IF object_id(N'dbo.vProductSalesSummary', 'V') IS NOT NULL
	DROP VIEW dbo.vProductSalesSummary
GO

CREATE VIEW dbo.vProductSalesSummary AS
WITH sale AS (
	SELECT SalesOrderID 
		, ProductID
		, OrderQty
		, UnitPrice * (1 - UnitPriceDiscount) AS FinalUnitPrice
		, LineTotal
	FROM Sales.SalesOrderDetail
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
SELECT s.*
	, p.ProductName
	, p.SubcatName
	, p.CatName
FROM sale s
	LEFT JOIN products p
		ON s.ProductID = p.ProductID
GO