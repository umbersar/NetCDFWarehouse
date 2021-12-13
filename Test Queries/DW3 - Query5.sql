---- STANDARD QUERY 5: ANOMALY WRT 30 YEAR BASE (Spatial)

USE [CLIMATE_DATA_V1]
GO

DBCC DROPCLEANBUFFERS
GO

SET STATISTICS IO ON
SET STATISTICS TIME ON
GO


WITH BASE_PERIOD AS 
	(
	SELECT [S].[SpaceID], AVG([E0]) AS[Base_E0]
	FROM (
		(SELECT * 
		FROM [DW3].[Time] 
		WHERE [Year] BETWEEN 1911 AND 1940  -- DEFINE BASE PERIOD HERE
		) AS T

		LEFT JOIN 
		[DW3].[FACT] AS F
		ON [T].[TimeID] = [F].[TimeID]

		LEFT JOIN 
		[DW3].[Space] AS S
		ON [S].[SpaceID] = [F].[SpaceID]
		)
	GROUP BY [S].[SpaceID], [Longitude], [Latitude]
	),

SAMPLE_PERIOD AS 
	(
	SELECT [S].[SpaceID], [Latitude], [Longitude], AVG([E0]) AS Sample_E0
	FROM (
		(SELECT * 
		FROM [DW3].[Time] 
		WHERE [Year] = 1920 AND [Month] = 7 AND [Day] = 30 -- DEFINE SAMPLE PERIOD HERE
		) AS T

		LEFT JOIN 
		[DW3].[FACT] AS F
		ON [T].[TimeID] = [F].[TimeID]

		LEFT JOIN 
		[DW3].[Space] AS S
		ON [S].[SpaceID] = [F].[SpaceID]
		)
	GROUP BY [S].[SpaceID], [Latitude], [Longitude]
	)

SELECT [Latitude], [Longitude], [Sample_E0] - [Base_E0] AS Anomaly
FROM (
		[SAMPLE_PERIOD] AS S 
		JOIN 
		[BASE_PERIOD] AS B
		ON [S].[SpaceID] = [B].[SpaceID])
ORDER BY [S].[SpaceID]

SET STATISTICS IO OFF
SET STATISTICS TIME OFF
GO