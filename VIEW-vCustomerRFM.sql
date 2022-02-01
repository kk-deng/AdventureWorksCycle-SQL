-- =============================================
-- Create View for Customer Segmentation:
-- Recency, Frequency, Monetary
-- =============================================
USE AdventureWorks2019
GO

IF object_id(N'dbo.vCustomerRFM', 'V') IS NOT NULL
	DROP VIEW dbo.vCustomerRFM
GO

CREATE VIEW dbo.vCustomerRFM AS
WITH Sales AS (
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
SELECT Sales.*
	, CAST(Sales.ActiveDays / 7 AS INT) AS ActiveWeeks
	, Customers.FullName
FROM Sales
	INNER JOIN Customers
		ON Sales.CustomerID = Customers.CustomerID;
GO