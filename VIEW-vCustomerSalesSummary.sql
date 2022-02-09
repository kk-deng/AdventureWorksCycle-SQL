-- =============================================
-- Create View for Customer Sales Summary:
-- Days Since Last Transaction, Number of Transactions, Total Spending
-- =============================================
USE AdventureWorks2019
GO

IF object_id(N'dbo.vCustomerSalesSummary', 'V') IS NOT NULL
	DROP VIEW dbo.vCustomerSalesSummary
GO

CREATE VIEW dbo.vCustomerSalesSummary AS
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