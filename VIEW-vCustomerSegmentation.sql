-- =============================================
-- Create View for Customer Segmentation:
-- Recency, Frequency, Monetary
-- =============================================
USE AdventureWorks2019
GO

IF object_id(N'dbo.vCustomerRFMSegmentation', 'V') IS NOT NULL
	DROP VIEW dbo.vCustomerRFMSegmentation
GO

CREATE VIEW dbo.vCustomerRFMSegmentation AS
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
SELECT * 
FROM CusRFM
GO