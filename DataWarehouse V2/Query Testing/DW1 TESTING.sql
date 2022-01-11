PRINT 'QUERY TESTING FOR DataWarehouse Structure 1 (DW1): STAR-schema with a clustered rowstore index, datetime format.'
PRINT 'COMMENT Expected to have the weakest performance - but act as a baseline for all other variations.'

USE [CLIMATE_DATA_V1]
GO

EXEC sp_configure 'show advanced options', 1
RECONFIGURE
GO
EXEC sp_configure 'affinity mask', 255 
RECONFIGURE
GO
EXEC sp_configure 'affinity I/O mask', 3840
RECONFIGURE
GO
--Reserving 8 cores for CPU, and 4 cores for I/O
--https://sqltimes.wordpress.com/2015/01/31/sql-server-cpu-affinity-mask-or-how-to-limit-sql-server-to-selected-cpus-or-processors-or-numa-set/
 
DBCC TRACEON (8002) 
-- Avoids restricting the schedulers as advised by:
--https://www.sqlpassion.at/archive/2017/10/02/setting-a-processor-affinity-in-sql-server-the-unwanted-side-effects/ 

SET STATISTICS IO ON
SET STATISTICS TIME ON
GO




-- --STANDARD QUERY 1: RAW DATA FOR A GIVEN TIMESTEP
PRINT CHAR(13) + CHAR(10) + N'STANDARD QUERY 1: RAW DATA FOR A GIVEN TIMESTEP -----------------------------------------------------------' + CHAR(13) + CHAR(10);
DBCC DROPCLEANBUFFERS
GO

SELECT [Latitude], [Longitude], [E0]
FROM (
		(SELECT * FROM [DW1].[TIME1] WHERE [DateTime] = '19300730') AS DW1_TIME  -- SPECIFY TIMESTEP HERE

		LEFT JOIN 
		[DW1].[FACT] AS DW1_FACT
		ON [DW1_TIME].[DateID] = [DW1_FACT].[DateID]

		LEFT JOIN 
		[DW1].[GRID] AS DW1_GRID
		ON [DW1_GRID].[GridID] = [DW1_FACT].[GridID]
		)
ORDER BY [DW1_FACT].[GridID]


-- -- STANDARD QUERY 2: ABSOLUTE MAXIMUM OVER A SPECIFIED YEAR
PRINT CHAR(13) + CHAR(10) + N'STANDARD QUERY 2: ABSOLUTE MAXIMUM OVER A SPECIFIED YEAR ---------------------------------------------------' + CHAR(13) + CHAR(10);
DBCC DROPCLEANBUFFERS
GO

SELECT [Latitude], [Longitude], MAX([E0]) AS Max_E0
FROM (
		(SELECT * FROM [DW1].[TIME1] WHERE Year([DateTime]) = 1930) AS DW1_TIME  -- SPECIFY TEMPORAL RANGE HERE

		LEFT JOIN 
		[DW1].[FACT] AS DW1_FACT
		ON [DW1_TIME].[DateID] = [DW1_FACT].[DateID]

		LEFT JOIN 
		[DW1].[GRID] AS DW1_GRID
		ON [DW1_GRID].[GridID] = [DW1_FACT].[GridID]
		)
GROUP BY [DW1_FACT].[GridID], [Latitude], [Longitude]
ORDER BY [DW1_FACT].[GridID]


-- -- STANDARD QUERY 3: MONTHLY DECILE
PRINT CHAR(13) + CHAR(10) + N'STANDARD QUERY 3: MONTHLY DECILE --------------------------------------------------------------------------' + CHAR(13) + CHAR(10);
DBCC DROPCLEANBUFFERS
GO

PRINT CHAR(13) + CHAR(10) + N'TEST 3.1: 10 YEARS ----------------------------' + CHAR(13) + CHAR(10);
DBCC DROPCLEANBUFFERS
GO
WITH [SAMPLE_PERIOD] AS(
	SELECT [Grid].[GridID], YEAR([DateTime]) AS [Year], MONTH([DateTime]) AS [Month], [E0]
	FROM (
		(SELECT * FROM [DW1].[TIME1]
		WHERE YEAR([DateTime]) BETWEEN 1911 AND 1920) AS [Time]  -- SPECIFY TEMPORAL RANGE HERE

		LEFT JOIN 
		[DW1].[FACT] AS [Fact]
		ON [Time].[DateID] = [Fact].[DateID]

		LEFT JOIN 
		[DW1].[GRID] AS [Grid]
		ON [Grid].[GridID] = [Fact].[GridID]
		)
	),

DECILES AS (
	SELECT  [GridID], [Year], [Month],
		   (CASE WHEN SUM([E0]) IS NOT NULL
				 THEN NTILE(10) OVER (PARTITION BY (CASE WHEN SUM([E0]) IS NOT NULL THEN [GridID] ELSE NULL END)
									 ORDER BY SUM([E0])
									)
			END) as Decile
	FROM [SAMPLE_PERIOD]
	GROUP BY [GridID], [Year], [Month]
	)

SELECT [Latitude], [Longitude], [Decile]
FROM (
	DECILES AS DECILE
	LEFT JOIN
	[DW1].[GRID] AS DW1_GRID
	ON [DW1_GRID].[GridID] = [DECILE].[GridID]
	)
WHERE [Year] = 1915 AND [Month] = 7 -- SPECIFY TIMESTEP TO BE QUERIED
ORDER BY [DW1_GRID].[GridID]


PRINT CHAR(13) + CHAR(10) + N'TEST 3.2: 20 YEARS ----------------------------' + CHAR(13) + CHAR(10);
DBCC DROPCLEANBUFFERS
GO
WITH [SAMPLE_PERIOD] AS(
	SELECT [Grid].[GridID], YEAR([DateTime]) AS [Year], MONTH([DateTime]) AS [Month], [E0]
	FROM (
		(SELECT * FROM [DW1].[TIME1]
		WHERE YEAR([DateTime]) BETWEEN 1911 AND 1930) AS [Time]  -- SPECIFY TEMPORAL RANGE HERE

		LEFT JOIN 
		[DW1].[FACT] AS [Fact]
		ON [Time].[DateID] = [Fact].[DateID]

		LEFT JOIN 
		[DW1].[GRID] AS [Grid]
		ON [Grid].[GridID] = [Fact].[GridID]
		)
	),

DECILES AS (
	SELECT  [GridID], [Year], [Month],
		   (CASE WHEN SUM([E0]) IS NOT NULL
				 THEN NTILE(10) OVER (PARTITION BY (CASE WHEN SUM([E0]) IS NOT NULL THEN [GridID] ELSE NULL END)
									 ORDER BY SUM([E0])
									)
			END) as Decile
	FROM [SAMPLE_PERIOD]
	GROUP BY [GridID], [Year], [Month]
	)

SELECT [Latitude], [Longitude], [Decile]
FROM (
	DECILES AS DECILE
	LEFT JOIN
	[DW1].[GRID] AS DW1_GRID
	ON [DW1_GRID].[GridID] = [DECILE].[GridID]
	)
WHERE [Year] = 1915 AND [Month] = 7 -- SPECIFY TIMESTEP TO BE QUERIED
ORDER BY [DW1_GRID].[GridID]


PRINT CHAR(13) + CHAR(10) + N'TEST 3.3: 30 YEARS ----------------------------' + CHAR(13) + CHAR(10);
DBCC DROPCLEANBUFFERS
GO
WITH [SAMPLE_PERIOD] AS(
	SELECT [Grid].[GridID], YEAR([DateTime]) AS [Year], MONTH([DateTime]) AS [Month], [E0]
	FROM (
		(SELECT * FROM [DW1].[TIME1]
		WHERE YEAR([DateTime]) BETWEEN 1911 AND 1940) AS [Time]  -- SPECIFY TEMPORAL RANGE HERE

		LEFT JOIN 
		[DW1].[FACT] AS [Fact]
		ON [Time].[DateID] = [Fact].[DateID]

		LEFT JOIN 
		[DW1].[GRID] AS [Grid]
		ON [Grid].[GridID] = [Fact].[GridID]
		)
	),

DECILES AS (
	SELECT  [GridID], [Year], [Month],
		   (CASE WHEN SUM([E0]) IS NOT NULL
				 THEN NTILE(10) OVER (PARTITION BY (CASE WHEN SUM([E0]) IS NOT NULL THEN [GridID] ELSE NULL END)
									 ORDER BY SUM([E0])
									)
			END) as Decile
	FROM [SAMPLE_PERIOD]
	GROUP BY [GridID], [Year], [Month]
	)

SELECT [Latitude], [Longitude], [Decile]
FROM (
	DECILES AS DECILE
	LEFT JOIN
	[DW1].[GRID] AS DW1_GRID
	ON [DW1_GRID].[GridID] = [DECILE].[GridID]
	)
WHERE [Year] = 1915 AND [Month] = 7 -- SPECIFY TIMESTEP TO BE QUERIED
ORDER BY [DW1_GRID].[GridID]


PRINT CHAR(13) + CHAR(10) + N'TEST 3.4: 40 YEARS ----------------------------' + CHAR(13) + CHAR(10);
DBCC DROPCLEANBUFFERS
GO
WITH [SAMPLE_PERIOD] AS(
	SELECT [Grid].[GridID], YEAR([DateTime]) AS [Year], MONTH([DateTime]) AS [Month], [E0]
	FROM (
		(SELECT * FROM [DW1].[TIME1]
		WHERE YEAR([DateTime]) BETWEEN 1911 AND 1950) AS [Time]  -- SPECIFY TEMPORAL RANGE HERE

		LEFT JOIN 
		[DW1].[FACT] AS [Fact]
		ON [Time].[DateID] = [Fact].[DateID]

		LEFT JOIN 
		[DW1].[GRID] AS [Grid]
		ON [Grid].[GridID] = [Fact].[GridID]
		)
	),

DECILES AS (
	SELECT  [GridID], [Year], [Month],
		   (CASE WHEN SUM([E0]) IS NOT NULL
				 THEN NTILE(10) OVER (PARTITION BY (CASE WHEN SUM([E0]) IS NOT NULL THEN [GridID] ELSE NULL END)
									 ORDER BY SUM([E0])
									)
			END) as Decile
	FROM [SAMPLE_PERIOD]
	GROUP BY [GridID], [Year], [Month]
	)

SELECT [Latitude], [Longitude], [Decile]
FROM (
	DECILES AS DECILE
	LEFT JOIN
	[DW1].[GRID] AS DW1_GRID
	ON [DW1_GRID].[GridID] = [DECILE].[GridID]
	)
WHERE [Year] = 1915 AND [Month] = 7 -- SPECIFY TIMESTEP TO BE QUERIED
ORDER BY [DW1_GRID].[GridID]



-- Slightly different version of the same query.
--DBCC DROPCLEANBUFFERS
--GO

--WITH [SAMPLE_PERIOD] AS(
--	SELECT [Grid].[GridID], YEAR([DateTime]) AS [Year], MONTH([DateTime]) AS [Month], SUM([E0]) AS [Sum_E0]
--	FROM (
--		(SELECT * FROM [DW1].[TIME1]
--		WHERE YEAR([DateTime]) BETWEEN 1911 AND 1920) AS [Time]  -- SPECIFY TEMPORAL RANGE HERE
--		LEFT JOIN 
--		[DW1].[FACT] AS [Fact]
--		ON [Time].[DateID] = [Fact].[DateID]
--		LEFT JOIN 
--		[DW1].[GRID] AS [Grid]
--		ON [Grid].[GridID] = [Fact].[GridID]
--		)
--	GROUP BY [Grid].[GridID], YEAR([DateTime]), MONTH([DateTime])
--	),

--DECILES AS (
--	SELECT  [GridID], [Year], [Month],
--		   (CASE WHEN Sum_E0 IS NOT NULL
--				 THEN NTILE(10) OVER (PARTITION BY (CASE WHEN Sum_E0 IS NOT NULL THEN [GridID] ELSE NULL END)
--									 ORDER BY Sum_E0
--									)
--			END) as Decile
--	FROM [SAMPLE_PERIOD]
--	)

--SELECT [Latitude], [Longitude], [Decile]
--FROM (
--	DECILES AS DECILE
--	LEFT JOIN
--	[DW1].[GRID] AS DW1_GRID
--	ON [DW1_GRID].[GridID] = [DECILE].[GridID]
--	)
--WHERE [Year] = 1911 AND [Month] = 1 -- SPECIFY TIMESTEP TO BE QUERIED
--ORDER BY [DW1_GRID].[GridID]


-- -- STANDARD QUERY 4 : LONG-TERM AVERAGE (Spatial)
PRINT CHAR(13) + CHAR(10) + N'STANDARD QUERY 4: LONG-TERM AVERAGE (Spatial) -------------------------------------------------------------' + CHAR(13) + CHAR(10);
DBCC DROPCLEANBUFFERS
GO
PRINT CHAR(13) + CHAR(10) + N'TEST 4.1: 10 YEARS ----------------------------' + CHAR(13) + CHAR(10);
DBCC DROPCLEANBUFFERS
GO
SELECT [Latitude], [Longitude], AVG([E0]) AS Avg_E0
FROM (
		(SELECT * FROM [DW1].[TIME1]
		WHERE YEAR([DateTime]) BETWEEN 1911 AND 1920  -- DEFINE TIME PERIOD HERE
		) AS [Time]

		LEFT JOIN 
		[DW1].[FACT] AS [Fact]
		ON [Time].[DateID] = [Fact].[DateID]

		LEFT JOIN 
		[DW1].[Grid] AS [Grid]
		ON [Grid].[GridID] = [Fact].[GridID]
		)
GROUP BY [Grid].[GridID], [Latitude], [Longitude]
ORDER BY [Grid].[GridID]


PRINT CHAR(13) + CHAR(10) + N'TEST 4.2: 20 YEARS ----------------------------' + CHAR(13) + CHAR(10);
DBCC DROPCLEANBUFFERS
GO
SELECT [Latitude], [Longitude], AVG([E0]) AS Avg_E0
FROM (
		(SELECT * FROM [DW1].[TIME1]
		WHERE YEAR([DateTime]) BETWEEN 1911 AND 1930  -- DEFINE TIME PERIOD HERE
		) AS [Time]

		LEFT JOIN 
		[DW1].[FACT] AS [Fact]
		ON [Time].[DateID] = [Fact].[DateID]

		LEFT JOIN 
		[DW1].[Grid] AS [Grid]
		ON [Grid].[GridID] = [Fact].[GridID]
		)
GROUP BY [Grid].[GridID], [Latitude], [Longitude]
ORDER BY [Grid].[GridID]


PRINT CHAR(13) + CHAR(10) + N'TEST 4.3: 30 YEARS ----------------------------' + CHAR(13) + CHAR(10);
DBCC DROPCLEANBUFFERS
GO
SELECT [Latitude], [Longitude], AVG([E0]) AS Avg_E0
FROM (
		(SELECT * FROM [DW1].[TIME1]
		WHERE YEAR([DateTime]) BETWEEN 1911 AND 1940  -- DEFINE TIME PERIOD HERE
		) AS [Time]

		LEFT JOIN 
		[DW1].[FACT] AS [Fact]
		ON [Time].[DateID] = [Fact].[DateID]

		LEFT JOIN 
		[DW1].[Grid] AS [Grid]
		ON [Grid].[GridID] = [Fact].[GridID]
		)
GROUP BY [Grid].[GridID], [Latitude], [Longitude]
ORDER BY [Grid].[GridID]


PRINT CHAR(13) + CHAR(10) + N'TEST 4.4: 40 YEARS ----------------------------' + CHAR(13) + CHAR(10);
DBCC DROPCLEANBUFFERS
GO
SELECT [Latitude], [Longitude], AVG([E0]) AS Avg_E0
FROM (
		(SELECT * FROM [DW1].[TIME1]
		WHERE YEAR([DateTime]) BETWEEN 1911 AND 1950  -- DEFINE TIME PERIOD HERE
		) AS [Time]

		LEFT JOIN 
		[DW1].[FACT] AS [Fact]
		ON [Time].[DateID] = [Fact].[DateID]

		LEFT JOIN 
		[DW1].[Grid] AS [Grid]
		ON [Grid].[GridID] = [Fact].[GridID]
		)
GROUP BY [Grid].[GridID], [Latitude], [Longitude]
ORDER BY [Grid].[GridID]



---- STANDARD QUERY 5: ANOMALY WRT 30 YEAR BASE (Spatial)
PRINT CHAR(13) + CHAR(10) + N'STANDARD QUERY 5: ANOMALY WRT 30 YEAR BASE (Spatial) ------------------------------------------------------' + CHAR(13) + CHAR(10);

PRINT CHAR(13) + CHAR(10) + N'TEST 1: ANNUAL AVERAGE ----------------------' + CHAR(13) + CHAR(10);
DBCC DROPCLEANBUFFERS
GO

WITH BASE_PERIOD AS 
	(
	SELECT [Grid].[GridID], AVG([E0]) AS[Base_E0]
	FROM (
		(SELECT * 
		FROM [DW1].[TIME1] 
		WHERE YEAR([DateTime]) BETWEEN 1911 AND 1940  -- DEFINE BASE PERIOD HERE
		) AS [Time]

		LEFT JOIN 
		[DW1].[FACT] AS [Fact]
		ON [Time].[DateID] = [Fact].[DateID]

		LEFT JOIN 
		[DW1].[GRID] AS [Grid]
		ON [Grid].[GridID] = [Fact].[GridID]
		)
	GROUP BY [Grid].[GridID], [Longitude], [Latitude]
	),

SAMPLE_PERIOD AS 
	(
	SELECT [Grid].[GridID], [Latitude], [Longitude], AVG([E0]) AS Sample_E0
	FROM (
		(SELECT * 
		FROM [DW1].[TIME1] 
		WHERE YEAR([DateTime]) = 1930 -- DEFINE SAMPLE PERIOD HERE
		) AS [Time]

		LEFT JOIN 
		[DW1].[FACT] AS [Fact]
		ON [Time].[DateID] = [Fact].[DateID]

		LEFT JOIN 
		[DW1].[GRID] AS [Grid]
		ON [Grid].[GridID] = [Fact].[GridID]
		)
	GROUP BY [Grid].[GridID], [Latitude], [Longitude]
	)

SELECT [Latitude], [Longitude], [Sample_E0] - [Base_E0] AS Anomaly
FROM (
		[SAMPLE_PERIOD] AS [Sample] 
		JOIN 
		[BASE_PERIOD] AS [Base]
		ON [Sample].[GridID] = [Base].[GridID])
ORDER BY [Sample].[GridID]



PRINT CHAR(13) + CHAR(10) + N'TEST 2: MONTHLY AVERAGE ---------------------' + CHAR(13) + CHAR(10);
DBCC DROPCLEANBUFFERS
GO

WITH BASE_PERIOD AS 
	(
	SELECT [Grid].[GridID], AVG([E0]) AS[Base_E0]
	FROM (
		(SELECT * 
		FROM [DW1].[TIME1] 
		WHERE YEAR([DateTime]) BETWEEN 1911 AND 1940  -- DEFINE BASE PERIOD HERE
		) AS [Time]

		LEFT JOIN 
		[DW1].[FACT] AS [Fact]
		ON [Time].[DateID] = [Fact].[DateID]

		LEFT JOIN 
		[DW1].[GRID] AS [Grid]
		ON [Grid].[GridID] = [Fact].[GridID]
		)
	GROUP BY [Grid].[GridID], [Longitude], [Latitude]
	),

SAMPLE_PERIOD AS 
	(
	SELECT [Grid].[GridID], [Latitude], [Longitude], AVG([E0]) AS Sample_E0
	FROM (
		(SELECT * 
		FROM [DW1].[TIME1] 
		WHERE YEAR([DateTime]) = 1930 AND MONTH([DateTime]) = 7 -- DEFINE SAMPLE PERIOD HERE
		) AS [Time]

		LEFT JOIN 
		[DW1].[FACT] AS [Fact]
		ON [Time].[DateID] = [Fact].[DateID]

		LEFT JOIN 
		[DW1].[GRID] AS [Grid]
		ON [Grid].[GridID] = [Fact].[GridID]
		)
	GROUP BY [Grid].[GridID], [Latitude], [Longitude]
	)

SELECT [Latitude], [Longitude], [Sample_E0] - [Base_E0] AS Anomaly
FROM (
		[SAMPLE_PERIOD] AS [Sample] 
		JOIN 
		[BASE_PERIOD] AS [Base]
		ON [Sample].[GridID] = [Base].[GridID])
ORDER BY [Sample].[GridID]



PRINT CHAR(13) + CHAR(10) + N'TEST 3: DAILY AVERAGE -----------------------' + CHAR(13) + CHAR(10);
DBCC DROPCLEANBUFFERS
GO

WITH BASE_PERIOD AS 
	(
	SELECT [Grid].[GridID], AVG([E0]) AS[Base_E0]
	FROM (
		(SELECT * 
		FROM [DW1].[TIME1] 
		WHERE YEAR([DateTime]) BETWEEN 1911 AND 1940  -- DEFINE BASE PERIOD HERE
		) AS [Time]

		LEFT JOIN 
		[DW1].[FACT] AS [Fact]
		ON [Time].[DateID] = [Fact].[DateID]

		LEFT JOIN 
		[DW1].[GRID] AS [Grid]
		ON [Grid].[GridID] = [Fact].[GridID]
		)
	GROUP BY [Grid].[GridID], [Longitude], [Latitude]
	),

SAMPLE_PERIOD AS 
	(
	SELECT [Grid].[GridID], [Latitude], [Longitude], [E0] AS Sample_E0
	FROM (
		(SELECT * 
		FROM [DW1].[TIME1] 
		WHERE [DateTime] = '19300730' -- DEFINE SAMPLE PERIOD HERE
		) AS [Time]

		LEFT JOIN 
		[DW1].[FACT] AS [Fact]
		ON [Time].[DateID] = [Fact].[DateID]

		LEFT JOIN 
		[DW1].[GRID] AS [Grid]
		ON [Grid].[GridID] = [Fact].[GridID]
		)
	--GROUP BY [Grid].[GridID], [Latitude], [Longitude]
	)

SELECT [Latitude], [Longitude], [Sample_E0] - [Base_E0] AS Anomaly
FROM (
		[SAMPLE_PERIOD] AS [Sample] 
		JOIN 
		[BASE_PERIOD] AS [Base]
		ON [Sample].[GridID] = [Base].[GridID])
ORDER BY [Sample].[GridID]



SET STATISTICS IO OFF
SET STATISTICS TIME OFF
GO

PRINT CHAR(13) + CHAR(10) + N'TESTING COMPLETE' + CHAR(13) + CHAR(10)
PRINT CHAR(13) + CHAR(10) + N'REMEMBER TO RESET PROCESSOR AFFINITY' + CHAR(13) + CHAR(10)

------ STANDARD QUERY 6: COUNT AVERAGE ANNUAL DAYS ABOVE 7mm (Spatial)
--PRINT CHAR(13) + CHAR(10) + N'STANDARD QUERY 6: COUNT AVERAGE ANNUAL DAYS ABOVE 7mm (Spatial) -------------------------------------------' + CHAR(13) + CHAR(10);
--DBCC DROPCLEANBUFFERS
--GO

--WITH [COUNT_PERIOD] AS 
--	(
--	SELECT [Grid].[GridID], YEAR([DateTime]) AS [Year], COUNT([E0]) AS [Count] 
--	FROM (
--		(SELECT * 
--		FROM [DW1].[TIME1] 
--		WHERE YEAR([DateTime]) BETWEEN 1911 AND 1920  -- DEFINE BASE PERIOD HERE
--		) AS [Time]

--		LEFT JOIN 
--		[DW1].[FACT] AS [Fact]
--		ON [Time].[DateID] = [Fact].[DateID]

--		LEFT JOIN 
--		[DW1].[GRID] AS [Grid]
--		ON [Grid].[GridID] = [Fact].[GridID]
--		)
--	WHERE [Fact].[E0] > 7 
--	GROUP BY [Grid].[GridID], YEAR([DateTime])
--	--ORDER BY [Grid].[GridID], YEAR([DateTime])
--	)

--SELECT [GridID], AVG([Count])
--FROM COUNT_PERIOD
--GROUP BY [GridID]
--ORDER BY [GridID]