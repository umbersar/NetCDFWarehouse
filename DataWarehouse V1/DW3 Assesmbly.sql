USE CLIMATE_DATA_V1
GO

--CREATE SCHEMA DW3

---- TIME DIMENSION TABLE -------------------------------------------------------
--DROP TABLE IF EXISTS [DW3].[Time];
--DROP VIEW IF EXISTS [DW3_Time];

--CREATE TABLE  [DW3].[Time](
--        [TimeID] INT IDENTITY (1,1), 
--		[Year] SMALLINT, 
--		[Month] SMALLINT, 
--		[Day] SMALLINT, 
--		INDEX COLUMNSTORE_DW3_TIME  CLUSTERED COLUMNSTORE 
--        );

--CREATE VIEW [DW3_Time] AS
--SELECT [Year], [Month], [Day]
--FROM [DW3].[Time];

--;WITH YYYY AS (
--SELECT DISTINCT [Year] FROM [OBT].[ANNUAL_V1]),
--MM_DD AS (
--SELECT DISTINCT [Month], [Day] FROM [DIMENSION].[TIME])

--INSERT INTO [DW3_Time]
--SELECT * 
--FROM(
--	YYYY CROSS JOIN MM_DD)
--ORDER BY [Year], [Month], [Day]

--DROP VIEW IF EXISTS [DW3_Time];
--SELECT * FROM [DW3].[Space]




---- SPACE DIMENSION TABLE -------------------------------------------------------
--DROP TABLE IF EXISTS [DW3].[Space]
--CREATE TABLE  [DW3].[Space](
--        [SpaceID] INT, 
--		[Latitude] DECIMAL(5,2), 
--		[Longitude] DECIMAL(5,2), 
--		INDEX COLUMNSTORE_DW3_SPACE  CLUSTERED COLUMNSTORE 
--        );

--INSERT INTO [DW3].[Space] 
--SELECT DISTINCT [SpaceID], [Latitude], [Longitude] FROM [DIMENSION].[SPACE]

--SELECT * FROM [DW3].[Space]
--ORDER BY [SpaceID], [Latitude], [Longitude]




---- FACT TABLE ------------------------------------------------------- (105 minutes)
--DROP TABLE IF EXISTS [DW3].[FACT]
--CREATE TABLE  [DW3].[FACT](
--      [TimeID] INT,
--		[SpaceID] INT, 
--		[E0] FLOAT, 
--		INDEX COLUMNSTORE_DW3_FACT  CLUSTERED COLUMNSTORE 
--        )

--INSERT INTO [DW3].[FACT]
--	SELECT [TimeID], [SpaceID],	[E0] 
--	FROM (
--		[DW3].[Time] AS A
--		JOIN
--		[OBT].[V4] AS B
--		ON A.[Year] = B.[Year] AND A.[Month] = B.[Month] AND A.[Day] = B.[Day]
--		)
--	ORDER BY [TimeID], [SpaceID]

--SELECT TOP(10000) * FROM [DW3].[FACT]
