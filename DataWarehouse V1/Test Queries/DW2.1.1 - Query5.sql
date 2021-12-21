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
	SELECT [SpaceID], AVG([E0])[Base_E0]
	FROM [DW4].[OBT]
	WHERE [Year] BETWEEN 1911 AND 1941 -- DEFINE BASE PERIOD HERE
	GROUP BY [SpaceID]
	),

	SAMPLE_PERIOD AS
	(
	SELECT [SpaceID], [Latitude], [Longitude], AVG([E0])[Sample_E0]
	FROM [DW4].[OBT]
	WHERE [Year] = 1930 AND [Month] = 3 AND [Day] = 3 -- DEFINE SAMPLE PERIOD HERE
	GROUP BY [SpaceID],[Latitude], [Longitude]
	)

SELECT [Latitude], [Longitude], [Sample_E0] - [Base_E0] AS Anomaly
FROM (
		[SAMPLE_PERIOD] AS S 
		JOIN 
		[BASE_PERIOD] AS B
		ON [S].[SpaceID] = [B].[SpaceID])
ORDER BY [S].[SpaceID]

---- DAY
--SELECT [Latitude], [Longitude], [E0] - [Base_E0] AS Anomaly
--FROM (
--	SELECT [Latitude], [Longitude], [SpaceID], [E0]
--	FROM [OBT].[V4]
--	WHERE [Year] = 1930 AND [Month] = 3 AND [Day] = 3
--	) AS X
--	JOIN
--	Base_Period AS B
--	ON X.[SpaceID] = B.[SpaceID] 
--ORDER BY X.[SpaceID]


---- MONTH
--SELECT [Latitude], [Longitude], [Avg_E0] - [Base_E0] AS Anomaly
--FROM (
--		SELECT  [Latitude], [Longitude], [SpaceID], AVG([E0]) AS Avg_E0
--		FROM [OBT].[V4]
--		WHERE [Year] = 1930 AND [Month] = 2
--		GROUP BY [SpaceID], [Latitude], [Longitude]
--		) AS B
--		JOIN
--		Base_Period AS C
--		ON B.[SpaceID] = C.[SpaceID] 
--	ORDER BY B.[SpaceID]

-- YEAR
--SELECT [Latitude], [Longitude], [Avg_E0] - [Base_E0] AS Anomaly
--FROM (
--		SELECT  [Latitude], [Longitude], [SpaceID], AVG([E0]) AS Avg_E0
--		FROM (
--			SELECT * FROM [OBT].[V4]
--			WHERE [Year] = 1930) AS A 
--		GROUP BY [SpaceID], [Latitude], [Longitude]
--		) AS B
--		JOIN
--		Base_Period AS C
--		ON B.[SpaceID] = C.[SpaceID] 
--	ORDER BY B.[SpaceID]



SET STATISTICS IO OFF
SET STATISTICS TIME OFF
GO