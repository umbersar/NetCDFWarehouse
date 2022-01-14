PRINT 'QUERY TESTING FOR DataWarehouse Structure 12 (DW12): One-Big-Table with a clustered columnstore index, and split integer date columns format.'
PRINT 'COMMENT The table occupies 49,184.906 MB, plus 0 MB for the index.' 
PRINT 'COMMENT Took 06:26:38 to assemble from CSV files.'

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
FROM [DW12].[OBT]		
WHERE [Year] = 1930 AND [Month] = 7 AND [Day] = 30 -- SPECIFY TIMESTEP HERE
ORDER BY [Latitude] DESC, [Longitude] ASC


-- -- STANDARD QUERY 2: ABSOLUTE MAXIMUM OVER A SPECIFIED YEAR
PRINT CHAR(13) + CHAR(10) + N'STANDARD QUERY 2: ABSOLUTE MAXIMUM OVER A SPECIFIED YEAR ---------------------------------------------------' + CHAR(13) + CHAR(10);
DBCC DROPCLEANBUFFERS
GO

SELECT [Latitude], [Longitude], MAX([E0]) AS Max_E0
FROM [DW12].[OBT]	
WHERE [Year] = 1930  -- SPECIFY TEMPORAL RANGE HERE
GROUP BY [Latitude], [Longitude]
ORDER BY [Latitude] DESC, [Longitude] ASC


-- -- STANDARD QUERY 3: MONTHLY DECILE
PRINT CHAR(13) + CHAR(10) + N'STANDARD QUERY 3: MONTHLY DECILE --------------------------------------------------------------------------' + CHAR(13) + CHAR(10);
DBCC DROPCLEANBUFFERS
GO

PRINT CHAR(13) + CHAR(10) + N'TEST 3.1: 10 YEARS ----------------------------' + CHAR(13) + CHAR(10);
DBCC DROPCLEANBUFFERS
GO
WITH [DECILES] AS (
	SELECT  [Latitude], [Longitude], [Year], [Month],
		   (CASE WHEN SUM([E0]) IS NOT NULL
				 THEN NTILE(10) OVER (PARTITION BY [Latitude], [Longitude] ORDER BY SUM([E0]))
				 ELSE NULL
			END) as Decile
	FROM [DW12].[OBT]
	WHERE [Year] BETWEEN 1911 AND 1920 -- SPECIFY DECILE RANGE
	GROUP BY [Latitude], [Longitude], [Year], [Month]
	)
SELECT [Latitude], [Longitude], [Decile]
FROM DECILES 
WHERE [Year] = 1915 AND [Month] = 7 -- SPECIFY TIMESTEP TO BE QUERIED
ORDER BY [Latitude] DESC, [Longitude] ASC

PRINT CHAR(13) + CHAR(10) + N'TEST 3.2: 20 YEARS ----------------------------' + CHAR(13) + CHAR(10);
DBCC DROPCLEANBUFFERS
GO
WITH [DECILES] AS (
	SELECT  [Latitude], [Longitude], [Year], [Month],
		   (CASE WHEN SUM([E0]) IS NOT NULL
				 THEN NTILE(10) OVER (PARTITION BY [Latitude], [Longitude] ORDER BY SUM([E0]))
				 ELSE NULL
			END) as Decile
	FROM [DW12].[OBT]
	WHERE [Year] BETWEEN 1911 AND 1930 -- SPECIFY DECILE RANGE
	GROUP BY [Latitude], [Longitude], [Year], [Month]
	)
SELECT [Latitude], [Longitude], [Decile]
FROM DECILES 
WHERE [Year] = 1915 AND [Month] = 7 -- SPECIFY TIMESTEP TO BE QUERIED
ORDER BY [Latitude] DESC, [Longitude] ASC

PRINT CHAR(13) + CHAR(10) + N'TEST 3.3: 30 YEARS ----------------------------' + CHAR(13) + CHAR(10);
DBCC DROPCLEANBUFFERS
GO
WITH [DECILES] AS (
	SELECT  [Latitude], [Longitude], [Year], [Month],
		   (CASE WHEN SUM([E0]) IS NOT NULL
				 THEN NTILE(10) OVER (PARTITION BY [Latitude], [Longitude] ORDER BY SUM([E0]))
				 ELSE NULL
			END) as Decile
	FROM [DW12].[OBT]
	WHERE [Year] BETWEEN 1911 AND 1940 -- SPECIFY DECILE RANGE
	GROUP BY [Latitude], [Longitude], [Year], [Month]
	)
SELECT [Latitude], [Longitude], [Decile]
FROM DECILES 
WHERE [Year] = 1915 AND [Month] = 7 -- SPECIFY TIMESTEP TO BE QUERIED
ORDER BY [Latitude] DESC, [Longitude] ASC

PRINT CHAR(13) + CHAR(10) + N'TEST 3.4: 40 YEARS ----------------------------' + CHAR(13) + CHAR(10);
DBCC DROPCLEANBUFFERS
GO
WITH [DECILES] AS (
	SELECT  [Latitude], [Longitude], [Year], [Month],
		   (CASE WHEN SUM([E0]) IS NOT NULL
				 THEN NTILE(10) OVER (PARTITION BY [Latitude], [Longitude] ORDER BY SUM([E0]))
				 ELSE NULL
			END) as Decile
	FROM [DW12].[OBT]
	WHERE [Year] BETWEEN 1911 AND 1950 -- SPECIFY DECILE RANGE
	GROUP BY [Latitude], [Longitude], [Year], [Month]
	)
SELECT [Latitude], [Longitude], [Decile]
FROM DECILES 
WHERE [Year] = 1915 AND [Month] = 7 -- SPECIFY TIMESTEP TO BE QUERIED
ORDER BY [Latitude] DESC, [Longitude] ASC



PRINT CHAR(13) + CHAR(10) + N'STANDARD QUERY 4: LONG-TERM AVERAGE (Spatial) -------------------------------------------------------------' + CHAR(13) + CHAR(10);
DBCC DROPCLEANBUFFERS
GO
PRINT CHAR(13) + CHAR(10) + N'TEST 4.1: 10 YEARS ----------------------------' + CHAR(13) + CHAR(10);
DBCC DROPCLEANBUFFERS
GO
SELECT [Latitude], [Longitude], AVG([E0]) AS Avg_E0
FROM [DW12].[OBT]
WHERE [Year] BETWEEN 1911 AND 1920  -- DEFINE TIME PERIOD HERE
GROUP BY [Latitude], [Longitude]
ORDER BY [Latitude] DESC, [Longitude] ASC

PRINT CHAR(13) + CHAR(10) + N'TEST 4.2: 20 YEARS ----------------------------' + CHAR(13) + CHAR(10);
DBCC DROPCLEANBUFFERS
GO
SELECT [Latitude], [Longitude], AVG([E0]) AS Avg_E0
FROM [DW12].[OBT]
WHERE [Year] BETWEEN 1911 AND 1930  -- DEFINE TIME PERIOD HERE
GROUP BY [Latitude], [Longitude]
ORDER BY [Latitude] DESC, [Longitude] ASC

PRINT CHAR(13) + CHAR(10) + N'TEST 4.3: 30 YEARS ----------------------------' + CHAR(13) + CHAR(10);
DBCC DROPCLEANBUFFERS
GO
SELECT [Latitude], [Longitude], AVG([E0]) AS Avg_E0
FROM [DW12].[OBT]
WHERE [Year] BETWEEN 1911 AND 1940  -- DEFINE TIME PERIOD HERE
GROUP BY [Latitude], [Longitude]
ORDER BY [Latitude] DESC, [Longitude] ASC

PRINT CHAR(13) + CHAR(10) + N'TEST 4.4: 40 YEARS ----------------------------' + CHAR(13) + CHAR(10);
DBCC DROPCLEANBUFFERS
GO
SELECT [Latitude], [Longitude], AVG([E0]) AS Avg_E0
FROM [DW12].[OBT]
WHERE [Year] BETWEEN 1911 AND 1950  -- DEFINE TIME PERIOD HERE
GROUP BY [Latitude], [Longitude]
ORDER BY [Latitude] DESC, [Longitude] ASC



---- STANDARD QUERY 5: ANOMALY WRT 30 YEAR BASE (Spatial)
PRINT CHAR(13) + CHAR(10) + N'STANDARD QUERY 5: ANOMALY WRT 30 YEAR BASE (Spatial) ------------------------------------------------------' + CHAR(13) + CHAR(10);

PRINT CHAR(13) + CHAR(10) + N'TEST 5.1: ANNUAL AVERAGE ----------------------' + CHAR(13) + CHAR(10);
DBCC DROPCLEANBUFFERS
GO
WITH BASE_PERIOD AS 
	(
	SELECT [Latitude], [Longitude], AVG([E0]) AS [Base_E0]
	FROM [DW12].[OBT]
	WHERE [Year] BETWEEN 1911 AND 1940  -- DEFINE BASE PERIOD HERE
	GROUP BY [Latitude], [Longitude]
	),
SAMPLE_PERIOD AS 
	(
	SELECT [Latitude], [Longitude], AVG([E0]) AS Sample_E0
	FROM [DW12].[OBT]
	WHERE [Year] = 1930  -- DEFINE SAMPLE PERIOD HERE
	GROUP BY [Latitude], [Longitude]
	)

SELECT [Sample].[Latitude], [Sample].[Longitude], [Sample_E0] - [Base_E0] AS Anomaly
FROM (
		[SAMPLE_PERIOD] AS [Sample] 
		JOIN 
		[BASE_PERIOD] AS [Base]
		ON [Sample].[Latitude] = [Base].[Latitude] AND [Sample].[Longitude] = [Base].[Longitude])
ORDER BY [Sample].[Latitude] DESC, [Sample].[Longitude] ASC;

PRINT CHAR(13) + CHAR(10) + N'TEST 5.2: MONTHLY AVERAGE ----------------------' + CHAR(13) + CHAR(10);
DBCC DROPCLEANBUFFERS
GO
WITH BASE_PERIOD AS 
	(
	SELECT [Latitude], [Longitude], AVG([E0]) AS [Base_E0]
	FROM [DW12].[OBT]
	WHERE [Year] BETWEEN 1911 AND 1940  -- DEFINE BASE PERIOD HERE
	GROUP BY [Latitude], [Longitude]
	),
SAMPLE_PERIOD AS 
	(
	SELECT [Latitude], [Longitude], AVG([E0]) AS Sample_E0
	FROM [DW12].[OBT]
	WHERE [Year] = 1930 AND  [Month] = 7 -- DEFINE SAMPLE PERIOD HERE
	GROUP BY [Latitude], [Longitude]
	)

SELECT [Sample].[Latitude], [Sample].[Longitude], [Sample_E0] - [Base_E0] AS Anomaly
FROM (
		[SAMPLE_PERIOD] AS [Sample] 
		JOIN 
		[BASE_PERIOD] AS [Base]
		ON [Sample].[Latitude] = [Base].[Latitude] AND [Sample].[Longitude] = [Base].[Longitude])
ORDER BY [Sample].[Latitude] DESC, [Sample].[Longitude] ASC;

PRINT CHAR(13) + CHAR(10) + N'TEST 5.3: DAILY AVERAGE ----------------------' + CHAR(13) + CHAR(10);
DBCC DROPCLEANBUFFERS
GO
WITH BASE_PERIOD AS 
	(
	SELECT [Latitude], [Longitude], AVG([E0]) AS [Base_E0]
	FROM [DW12].[OBT]
	WHERE [Year] BETWEEN 1911 AND 1940  -- DEFINE BASE PERIOD HERE
	GROUP BY [Latitude], [Longitude]
	),
SAMPLE_PERIOD AS 
	(
	SELECT [Latitude], [Longitude], AVG([E0]) AS Sample_E0
	FROM [DW12].[OBT]
	WHERE [Year] = 1930 AND  [Month] = 7 AND  [Day] = 30  -- DEFINE SAMPLE PERIOD HERE
	GROUP BY [Latitude], [Longitude]
	)

SELECT [Sample].[Latitude], [Sample].[Longitude], [Sample_E0] - [Base_E0] AS Anomaly
FROM (
		[SAMPLE_PERIOD] AS [Sample] 
		JOIN 
		[BASE_PERIOD] AS [Base]
		ON [Sample].[Latitude] = [Base].[Latitude] AND [Sample].[Longitude] = [Base].[Longitude])
ORDER BY [Sample].[Latitude] DESC, [Sample].[Longitude] ASC;

SET STATISTICS IO OFF
SET STATISTICS TIME OFF
GO

PRINT CHAR(13) + CHAR(10) + N'TESTING COMPLETE' + CHAR(13) + CHAR(10)
PRINT CHAR(13) + CHAR(10) + N'REMEMBER TO RESET PROCESSOR AFFINITY' + CHAR(13) + CHAR(10)