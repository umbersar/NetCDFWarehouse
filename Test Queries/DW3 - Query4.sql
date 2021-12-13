-- STANDARD QUERY 4: LONG-TERM AVERAGE (Spatial)

USE [CLIMATE_DATA_V1]
GO

DBCC DROPCLEANBUFFERS
GO

SET STATISTICS IO ON
SET STATISTICS TIME ON
GO

SELECT [Latitude], [Longitude], AVG([E0]) AS Avg_E0
FROM (
		(SELECT * FROM [DW3].[Time]
		WHERE [Year] BETWEEN 1911 AND 1920  -- DEFINE TIME PERIOD HERE
		) AS T
		LEFT JOIN 
		[DW3].[FACT] AS F
		ON [T].[TimeID] = [F].[TimeID]
		LEFT JOIN 
		[DW3].[Space] AS S
		ON [S].[SpaceID] = [F].[SpaceID]
		)
GROUP BY [S].[SpaceID], [Latitude], [Longitude]
ORDER BY [S].[SpaceID]



SET STATISTICS IO OFF
SET STATISTICS TIME OFF
GO