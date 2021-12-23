---- STANDARD QUERY 4: LONG-TERM AVERAGE (Spatial)

USE [CLIMATE_DATA_V1]
GO

DBCC DROPCLEANBUFFERS
GO

SET STATISTICS IO ON
SET STATISTICS TIME ON
GO


SELECT [Latitude], [Longitude], [Avg_E0]
FROM 
	(SELECT  [SpaceID], AVG([E0]) AS Avg_E0
	FROM (
		SELECT * 
		FROM [OBT].[V4]
		WHERE [Year] BETWEEN 1931 AND 1940 -- DEFINE TIME PERIOD HERE
		) AS X
	GROUP BY [SpaceID]) AS S
	JOIN 
	(SELECT DISTINCT [SpaceID], [Longitude], [Latitude] 	FROM [DIMENSION].[SPACE]) AS dim
	ON dim.[SpaceID] = S.[SpaceID] 
ORDER BY dim.[SpaceID]


SET STATISTICS IO OFF
SET STATISTICS TIME OFF
GO