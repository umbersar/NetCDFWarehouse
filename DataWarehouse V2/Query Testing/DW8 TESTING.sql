SET STATISTICS IO OFF
SET STATISTICS TIME OFF
PRINT 'QUERY TESTING FOR DataWarehouse Structure 8 (DW8): STAR-schema v2 with a clustered rowstore index, split integer datetime format, and a POC indexed view'
PRINT 'COMMENT The OBT occupies 266,819.320 MB, with 1,259.336 MB MB for the index.'
PRINT 'COMMENT The INDEXED VIEW occupies 207,243.440 MB, with 720.408 MB for the index. Assembly took an additional 2:18:55 on top of the DW6 assembly time.'
PRINT 'COMMENT The GRID table occupies 12.719 MB, with 0.55 MB for the index.'
-- DW8 is just DW6 with an additional indexed view. The table has not been re-ingested, only an indexed view added

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
		(SELECT * FROM [DW8].[VOBT] 
		WHERE [Year] = 1930 AND [Month] = 7 AND [Day] = 30) AS DW6_FACT  -- SPECIFY TIMESTEP HERE
		LEFT JOIN 
		[DW6].[GRID] AS DW6_GRID
		ON [DW6_GRID].[GridID] = [DW6_FACT].[GridID]
		)
ORDER BY [DW6_FACT].[GridID]


-- -- STANDARD QUERY 2: ABSOLUTE MAXIMUM OVER A SPECIFIED YEAR
PRINT CHAR(13) + CHAR(10) + N'STANDARD QUERY 2: ABSOLUTE MAXIMUM OVER A SPECIFIED YEAR ---------------------------------------------------' + CHAR(13) + CHAR(10);
DBCC DROPCLEANBUFFERS
GO

SELECT [Latitude], [Longitude], MAX([E0]) AS Max_E0
FROM (
		(SELECT * FROM [DW8].[VOBT] 
		WHERE [Year] = 1930) AS DW6_FACT  -- SPECIFY TEMPORAL RANGE HERE

		LEFT JOIN 
		[DW6].[GRID] AS DW6_GRID
		ON [DW6_GRID].[GridID] = [DW6_FACT].[GridID]
		)
GROUP BY [DW6_FACT].[GridID], [Latitude], [Longitude]
ORDER BY [DW6_FACT].[GridID]


-- -- STANDARD QUERY 3: MONTHLY DECILE
PRINT CHAR(13) + CHAR(10) + N'STANDARD QUERY 3: MONTHLY DECILE --------------------------------------------------------------------------' + CHAR(13) + CHAR(10);
DBCC DROPCLEANBUFFERS
GO

PRINT CHAR(13) + CHAR(10) + N'TEST 3.1: 10 YEARS ----------------------------' + CHAR(13) + CHAR(10);
DBCC DROPCLEANBUFFERS
GO
WITH [SAMPLE_PERIOD] AS(
	SELECT [GridID], [Year], [Month], [E0]
	FROM [DW8].[VOBT]
	WHERE [Year] BETWEEN 1911 AND 1920  -- SPECIFY TEMPORAL RANGE HERE
	),
[DECILES] AS (
	SELECT  [GridID], [Year], [Month],
		   (CASE WHEN SUM([E0]) IS NOT NULL
				 THEN NTILE(10) OVER (PARTITION BY [GridID] ORDER BY SUM([E0]))
				 ELSE NULL
			END) as Decile
	FROM [SAMPLE_PERIOD]
	GROUP BY [GridID], [Year], [Month]
	)

SELECT [Latitude], [Longitude], [Decile]
FROM (
	DECILES AS DECILE
	LEFT JOIN
	[DW6].[GRID] AS DW6_GRID
	ON [DW6_GRID].[GridID] = [DECILE].[GridID]
	)
WHERE [Year] = 1915 AND [Month] = 7 -- SPECIFY TIMESTEP TO BE QUERIED
ORDER BY [DW6_GRID].[GridID]


PRINT CHAR(13) + CHAR(10) + N'TEST 3.2: 20 YEARS ----------------------------' + CHAR(13) + CHAR(10);
DBCC DROPCLEANBUFFERS
GO
WITH [SAMPLE_PERIOD] AS(
	SELECT [GridID], [Year], [Month], [E0]
	FROM [DW8].[VOBT]
	WHERE [Year] BETWEEN 1911 AND 1930  -- SPECIFY TEMPORAL RANGE HERE
	),
[DECILES] AS (
	SELECT  [GridID], [Year], [Month],
		   (CASE WHEN SUM([E0]) IS NOT NULL
				 THEN NTILE(10) OVER (PARTITION BY [GridID] ORDER BY SUM([E0]))
				 ELSE NULL
			END) as Decile
	FROM [SAMPLE_PERIOD]
	GROUP BY [GridID], [Year], [Month]
	)

SELECT [Latitude], [Longitude], [Decile]
FROM (
	DECILES AS DECILE
	LEFT JOIN
	[DW6].[GRID] AS DW6_GRID
	ON [DW6_GRID].[GridID] = [DECILE].[GridID]
	)
WHERE [Year] = 1915 AND [Month] = 7 -- SPECIFY TIMESTEP TO BE QUERIED
ORDER BY [DW6_GRID].[GridID]


PRINT CHAR(13) + CHAR(10) + N'TEST 3.3: 30 YEARS ----------------------------' + CHAR(13) + CHAR(10);
DBCC DROPCLEANBUFFERS
GO
WITH [SAMPLE_PERIOD] AS(
	SELECT [GridID], [Year], [Month], [E0]
	FROM [DW8].[VOBT]
	WHERE [Year] BETWEEN 1911 AND 1940  -- SPECIFY TEMPORAL RANGE HERE
	),
[DECILES] AS (
	SELECT  [GridID], [Year], [Month],
		   (CASE WHEN SUM([E0]) IS NOT NULL
				 THEN NTILE(10) OVER (PARTITION BY [GridID] ORDER BY SUM([E0]))
				 ELSE NULL
			END) as Decile
	FROM [SAMPLE_PERIOD]
	GROUP BY [GridID], [Year], [Month]
	)

SELECT [Latitude], [Longitude], [Decile]
FROM (
	DECILES AS DECILE
	LEFT JOIN
	[DW6].[GRID] AS DW6_GRID
	ON [DW6_GRID].[GridID] = [DECILE].[GridID]
	)
WHERE [Year] = 1915 AND [Month] = 7 -- SPECIFY TIMESTEP TO BE QUERIED
ORDER BY [DW6_GRID].[GridID]


PRINT CHAR(13) + CHAR(10) + N'TEST 3.4: 40 YEARS ----------------------------' + CHAR(13) + CHAR(10);
DBCC DROPCLEANBUFFERS
GO
WITH [SAMPLE_PERIOD] AS(
	SELECT [GridID], [Year], [Month], [E0]
	FROM [DW8].[VOBT]
	WHERE [Year] BETWEEN 1911 AND 1950  -- SPECIFY TEMPORAL RANGE HERE
	),
[DECILES] AS (
	SELECT  [GridID], [Year], [Month],
		   (CASE WHEN SUM([E0]) IS NOT NULL
				 THEN NTILE(10) OVER (PARTITION BY [GridID] ORDER BY SUM([E0]))
				 ELSE NULL
			END) as Decile
	FROM [SAMPLE_PERIOD]
	GROUP BY [GridID], [Year], [Month]
	)

SELECT [Latitude], [Longitude], [Decile]
FROM (
	DECILES AS DECILE
	LEFT JOIN
	[DW6].[GRID] AS DW6_GRID
	ON [DW6_GRID].[GridID] = [DECILE].[GridID]
	)
WHERE [Year] = 1915 AND [Month] = 7 -- SPECIFY TIMESTEP TO BE QUERIED
ORDER BY [DW6_GRID].[GridID]



-- -- STANDARD QUERY 4 : LONG-TERM AVERAGE (Spatial)
PRINT CHAR(13) + CHAR(10) + N'STANDARD QUERY 4: LONG-TERM AVERAGE (Spatial) -------------------------------------------------------------' + CHAR(13) + CHAR(10);
DBCC DROPCLEANBUFFERS
GO
PRINT CHAR(13) + CHAR(10) + N'TEST 4.1: 10 YEARS ----------------------------' + CHAR(13) + CHAR(10);
DBCC DROPCLEANBUFFERS
GO
SELECT [Latitude], [Longitude], AVG([E0]) AS Avg_E0
FROM (
		(SELECT * FROM [DW8].[VOBT]
		WHERE [Year] BETWEEN 1911 AND 1920  -- DEFINE TIME PERIOD HERE
		) AS [Fact]

		LEFT JOIN 
		[DW6].[Grid] AS [Grid]
		ON [Grid].[GridID] = [Fact].[GridID]
		)
GROUP BY [Grid].[GridID], [Latitude], [Longitude]
ORDER BY [Grid].[GridID]


PRINT CHAR(13) + CHAR(10) + N'TEST 4.2: 20 YEARS ----------------------------' + CHAR(13) + CHAR(10);
DBCC DROPCLEANBUFFERS
GO
SELECT [Latitude], [Longitude], AVG([E0]) AS Avg_E0
FROM (
		(SELECT * FROM [DW8].[VOBT]
		WHERE [Year] BETWEEN 1911 AND 1930  -- DEFINE TIME PERIOD HERE
		) AS [Fact]

		LEFT JOIN 
		[DW6].[Grid] AS [Grid]
		ON [Grid].[GridID] = [Fact].[GridID]
		)
GROUP BY [Grid].[GridID], [Latitude], [Longitude]
ORDER BY [Grid].[GridID]


PRINT CHAR(13) + CHAR(10) + N'TEST 4.3: 30 YEARS ----------------------------' + CHAR(13) + CHAR(10);
DBCC DROPCLEANBUFFERS
GO
SELECT [Latitude], [Longitude], AVG([E0]) AS Avg_E0
FROM (
		(SELECT * FROM [DW8].[VOBT]
		WHERE [Year] BETWEEN 1911 AND 1940  -- DEFINE TIME PERIOD HERE
		) AS [Fact]

		LEFT JOIN 
		[DW6].[Grid] AS [Grid]
		ON [Grid].[GridID] = [Fact].[GridID]
		)
GROUP BY [Grid].[GridID], [Latitude], [Longitude]
ORDER BY [Grid].[GridID]


PRINT CHAR(13) + CHAR(10) + N'TEST 4.4: 40 YEARS ----------------------------' + CHAR(13) + CHAR(10);
DBCC DROPCLEANBUFFERS
GO
SELECT [Latitude], [Longitude], AVG([E0]) AS Avg_E0
FROM (
		(SELECT * FROM [DW8].[VOBT]
		WHERE [Year] BETWEEN 1911 AND 1950  -- DEFINE TIME PERIOD HERE
		) AS [Fact]

		LEFT JOIN 
		[DW6].[Grid] AS [Grid]
		ON [Grid].[GridID] = [Fact].[GridID]
		)
GROUP BY [Grid].[GridID], [Latitude], [Longitude]
ORDER BY [Grid].[GridID]



---- STANDARD QUERY 5: ANOMALY WRT 30 YEAR BASE (Spatial)
PRINT CHAR(13) + CHAR(10) + N'STANDARD QUERY 5: ANOMALY WRT 30 YEAR BASE (Spatial) ------------------------------------------------------' + CHAR(13) + CHAR(10);

PRINT CHAR(13) + CHAR(10) + N'TEST 5.1: ANNUAL AVERAGE ----------------------' + CHAR(13) + CHAR(10);
DBCC DROPCLEANBUFFERS
GO
WITH BASE_PERIOD AS 
	(
	SELECT [Grid].[GridID], AVG([E0]) AS[Base_E0]
	FROM (
		(SELECT * 
		FROM [DW8].[VOBT] 
		WHERE [Year] BETWEEN 1911 AND 1940  -- DEFINE BASE PERIOD HERE
		) AS [Fact]

		LEFT JOIN 
		[DW6].[GRID] AS [Grid]
		ON [Grid].[GridID] = [Fact].[GridID]
		)
	GROUP BY [Grid].[GridID]
	),

SAMPLE_PERIOD AS 
	(
	SELECT [Grid].[GridID],  AVG([E0]) AS Sample_E0
	FROM (
		(SELECT * 
		FROM [DW8].[VOBT] 
		WHERE [Year] = 1930 -- DEFINE SAMPLE PERIOD HERE
		) AS [Fact]

		LEFT JOIN 
		[DW6].[GRID] AS [Grid]
		ON [Grid].[GridID] = [Fact].[GridID]
		)
	GROUP BY [Grid].[GridID]
	)

SELECT [Latitude], [Longitude], [Sample_E0] - [Base_E0] AS Anomaly
FROM (
		[SAMPLE_PERIOD] AS [Sample] 
		JOIN 
		[BASE_PERIOD] AS [Base]
		ON [Sample].[GridID] = [Base].[GridID])
		LEFT JOIN
		[DW6].[GRID] AS [Grid]
		ON [Sample].[GridID] = [Grid].[GridID]
ORDER BY [Sample].[GridID]



PRINT CHAR(13) + CHAR(10) + N'TEST 5.2: MONTHLY AVERAGE ---------------------' + CHAR(13) + CHAR(10);
DBCC DROPCLEANBUFFERS
GO
WITH BASE_PERIOD AS 
	(
	SELECT [Grid].[GridID], AVG([E0]) AS[Base_E0]
	FROM (
		(SELECT * 
		FROM [DW8].[VOBT] 
		WHERE [Year] BETWEEN 1911 AND 1940  -- DEFINE BASE PERIOD HERE
		) AS [Fact]

		LEFT JOIN 
		[DW6].[GRID] AS [Grid]
		ON [Grid].[GridID] = [Fact].[GridID]
		)
	GROUP BY [Grid].[GridID]
	),

SAMPLE_PERIOD AS 
	(
	SELECT [Grid].[GridID],  AVG([E0]) AS Sample_E0
	FROM (
		(SELECT * 
		FROM [DW8].[VOBT] 
		WHERE [Year] = 1930 AND [Month] = 7-- DEFINE SAMPLE PERIOD HERE
		) AS [Fact]

		LEFT JOIN 
		[DW6].[GRID] AS [Grid]
		ON [Grid].[GridID] = [Fact].[GridID]
		)
	GROUP BY [Grid].[GridID]
	)

SELECT [Latitude], [Longitude], [Sample_E0] - [Base_E0] AS Anomaly
FROM (
		[SAMPLE_PERIOD] AS [Sample] 
		JOIN 
		[BASE_PERIOD] AS [Base]
		ON [Sample].[GridID] = [Base].[GridID])
		LEFT JOIN
		[DW6].[GRID] AS [Grid]
		ON [Sample].[GridID] = [Grid].[GridID]
ORDER BY [Sample].[GridID]


PRINT CHAR(13) + CHAR(10) + N'TEST 5.3: DAILY AVERAGE -----------------------' + CHAR(13) + CHAR(10);
DBCC DROPCLEANBUFFERS
GO
WITH BASE_PERIOD AS 
	(
	SELECT [Grid].[GridID], AVG([E0]) AS[Base_E0]
	FROM (
		(SELECT * 
		FROM [DW8].[VOBT] 
		WHERE [Year] BETWEEN 1911 AND 1940  -- DEFINE BASE PERIOD HERE
		) AS [Fact]

		LEFT JOIN 
		[DW6].[GRID] AS [Grid]
		ON [Grid].[GridID] = [Fact].[GridID]
		)
	GROUP BY [Grid].[GridID]
	),

SAMPLE_PERIOD AS 
	(
	SELECT [Grid].[GridID],  AVG([E0]) AS Sample_E0
	FROM (
		(SELECT * 
		FROM [DW8].[VOBT] 
		WHERE [Year] = 1930 AND [Month] = 7 AND [Day] = 30 --- DEFINE SAMPLE PERIOD HERE
		) AS [Fact]

		LEFT JOIN 
		[DW6].[GRID] AS [Grid]
		ON [Grid].[GridID] = [Fact].[GridID]
		)
	GROUP BY [Grid].[GridID]
	)

SELECT [Latitude], [Longitude], [Sample_E0] - [Base_E0] AS Anomaly
FROM (
		[SAMPLE_PERIOD] AS [Sample] 
		JOIN 
		[BASE_PERIOD] AS [Base]
		ON [Sample].[GridID] = [Base].[GridID])
		LEFT JOIN
		[DW6].[GRID] AS [Grid]
		ON [Sample].[GridID] = [Grid].[GridID]
ORDER BY [Sample].[GridID]



SET STATISTICS IO OFF
SET STATISTICS TIME OFF
GO

PRINT CHAR(13) + CHAR(10) + N'TESTING COMPLETE' + CHAR(13) + CHAR(10)
PRINT CHAR(13) + CHAR(10) + N'REMEMBER TO RESET PROCESSOR AFFINITY' + CHAR(13) + CHAR(10)