-- STANDARD QUERY 3: MONTHLY DECILE

USE [CLIMATE_DATA_V1]
GO

DBCC DROPCLEANBUFFERS
GO

SET STATISTICS IO ON
SET STATISTICS TIME ON
GO


WITH CTE AS(
	SELECT [S].[SpaceID], [Latitude], [Longitude], [Year], [Month], [E0]
	FROM (
		(SELECT * FROM [DW3].[Time]
		WHERE [Year] BETWEEN 1911 AND 1920) AS T  -- SPECIFY TEMPORAL RANGE HERE
		LEFT JOIN 
		[DW3].[FACT] AS F
		ON [T].[TimeID] = [F].[TimeID]
		LEFT JOIN 
		[DW3].[Space] AS S
		ON [S].[SpaceID] = [F].[SpaceID]
		)
	),

DECILES AS (
	SELECT  [Year], [Month], [Latitude], [Longitude], 
		   (CASE WHEN SUM([E0]) IS NOT NULL
				 THEN NTILE(10) OVER (PARTITION BY (CASE WHEN SUM([E0]) IS NOT NULL THEN [SpaceID] ELSE NULL END)
									 ORDER BY SUM([E0])
									)
			END) as Decile
	FROM CTE
	GROUP BY [SpaceID], [Latitude], [Longitude], [Year], [Month]
	)

SELECT [Latitude], [Longitude], [Decile]
FROM DECILES
WHERE [Year] = 1911 AND [Month] = 1 -- SPECIFY TIMESTEP TO BE QUERIED
ORDER BY [Latitude], [Longitude]



SET STATISTICS IO OFF
SET STATISTICS TIME OFF
GO