---- STANDARD QUERY 3: MONTHLY DECILE

USE [CLIMATE_DATA_V1]
GO

DBCC DROPCLEANBUFFERS
GO

SET STATISTICS IO ON
SET STATISTICS TIME ON
GO

--;WITH Time_Range AS (
--	SELECT * 
--	FROM [OBT].[V4]
--	WHERE [Year] = 1930
--	)

--SELECT [Year], [month], [day], [SpaceID], [E0], NTILE(10) OVER(PARTITION BY [SpaceID] ORDER BY E0) AS Decile
--FROM Time_Range
--ORDER BY [Year], [Month], [Day], [SpaceID]


-- VERSION 1:
--WITH CTE AS (
--	SELECT * 
--	FROM [OBT].[V4]
--	WHERE [Year] BETWEEN 1921 AND 1923
--	)

--SELECT  [Year], [Month], [SpaceID], SUM([E0]) AS sum, NTILE(10) OVER(PARTITION BY [SpaceID] ORDER BY SUM(E0)) AS Decile
--FROM CTE
--GROUP BY [SpaceID], [Year], [Month]
--ORDER BY [SpaceID], [sum]


--SET STATISTICS IO OFF
--SET STATISTICS TIME OFF
--GO

---- VERSION 2:
--WITH CTE AS (
--	SELECT * 
--	FROM [OBT].[V4]
--	WHERE [Year] BETWEEN 1921 AND 1923
--	)

WITH DECILES AS (
	SELECT  [Year], [Month], [SpaceID], [Latitude], [Longitude],  
		   (CASE WHEN SUM([E0]) IS NOT NULL
				 THEN NTILE(10) OVER (PARTITION BY (CASE WHEN SUM([E0]) IS NOT NULL THEN [SpaceID] ELSE NULL END)
									 ORDER BY SUM([E0])
									)
			END) as Decile
	FROM [OBT].[V4]
	WHERE [Year] BETWEEN 1911 AND 1920 -- SPECIFY TEMPORAL RANGE HERE
	GROUP BY [SpaceID], [Latitude], [Longitude], [Year], [Month]
	)

SELECT [Latitude], [Longitude], [Decile] FROM DECILES
WHERE [Year] = 1911 AND [Month] = 1 -- SPECIFY TIMESTEP TO BE QUERIED
ORDER BY [SpaceID]

-- VERSION 3:
-- The condition "WHERE [E0] IS NULL" in this version produces incorrect results due to the NULL values inserted over february 29th.
-- It is not worth ammending as, this method does not offer notable improvements over V2. 

--WITH CTE AS (
--	SELECT * 
--	FROM [OBT].[V4]
--	--WHERE [Year] BETWEEN 1921 AND 1923
--	)

--SELECT  [Year], [Month], [SpaceID], SUM([E0]) AS Sum, NTILE(10) OVER(PARTITION BY [SpaceID] ORDER BY SUM(E0)) AS Decile
--FROM CTE
--WHERE [E0] IS NOT NULL
--GROUP BY [SpaceID], [Year], [Month]
--UNION ALL 
--SELECT  [Year], [Month], [SpaceID], SUM([E0]) AS Sum, NULL AS Decile
--FROM CTE
--WHERE [E0] IS NULL
--GROUP BY [SpaceID], [Year], [Month]
--ORDER BY [SpaceID], [sum]


SET STATISTICS IO OFF
SET STATISTICS TIME OFF
GO