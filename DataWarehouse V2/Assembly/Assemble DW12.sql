

USE CLIMATE_DATA_V1
GO

--CREATE SCHEMA DW12

-- -- GRID TABLE
DROP TABLE IF EXISTS [DW12].[GRID]
CREATE TABLE  [DW12].[GRID](
		[GridID] INT,
		[Latitude] DECIMAL(5,2),
		[Longitude] DECIMAL(5,2), 
		INDEX DW12_COLUMNSTORE_GRID CLUSTERED COLUMNSTORE 
        );
BULK INSERT [DW12].[GRID]
FROM 'D:\CSIRO\STAR-SCHEMA V1\DIMENSION_GRID.csv'
WITH( 
    FIRSTROW = 2, 
    FIELDTERMINATOR = ',', 
    ROWTERMINATOR = '\n', 
    KEEPNULLS 
    )
GO

-- -- TIME TABLE
DROP TABLE IF EXISTS [DW12].[TIME]
CREATE TABLE  [DW12].[TIME](
		[DateID] INT,
		[Year] SMALLINT,
		[Month] TINYINT,
		[Day] TINYINT,
		INDEX DW12_COLUMNSTORE_TIME CLUSTERED COLUMNSTORE 
        );
BULK INSERT [DW12].[TIME]
FROM 'D:\CSIRO\STAR-SCHEMA V2\DIMENSION_TIME2.csv'
WITH( 
    FIRSTROW = 2, 
    FIELDTERMINATOR = ',', 
    ROWTERMINATOR = '\n', 
    KEEPNULLS 
    )
GO


DROP TABLE IF EXISTS [DW12].[OBT]
CREATE TABLE  [DW12].[OBT](
		[ID] BIGINT IDENTITY(1,1), -- 
		[Year] SMALLINT,
		[Month] TINYINT,
		[Day] TINYINT,
		[Latitude] DECIMAL(5,2), 
		[Longitude] DECIMAL(5,2), 
		[E0] FLOAT,
		INDEX DW12_COLUMNSTORE_OBT CLUSTERED COLUMNSTORE 
        );

DROP VIEW IF EXISTS [DW12_OBT]
GO
CREATE VIEW DW12_OBT ([Year], [Month], [Day], [Latitude], [Longitude], [E0]) AS
	SELECT [Year], [Month], [Day], [Latitude], [Longitude], [E0] FROM [DW12].[OBT];
GO


DBCC SHRINKFILE (N'CLIMATE_DATA_V1_log' , 0, TRUNCATEONLY)
GO
DECLARE 
		@Year INT,
		@YearStart INT,
		@YearEnd INT,
		@YearIncrement INT,
		@ProgressPercent DECIMAL(5,2),
		@FilePath NVARCHAR(30),
		@FileName NVARCHAR(20),
		@Bulk_Insert_Command NVARCHAR(200),
		@CreateView_LoadingTable NVARCHAR(200);

SET @YearStart	= 1911;
SET @YearEnd	= 1950;
SET @Year		= @YearStart;
SET @YearIncrement = 1;
SET @FilePath = 'D:\CSIRO\STAR-SCHEMA V1\'
SET @CreateView_LoadingTable =
'	CREATE VIEW DW12_LOAD ([DateID], [GridID], [E0]) AS
	SELECT [DateID], [GridID], [E0] FROM [DW12].[LOAD];'


WHILE (@Year <= @YearEnd)
BEGIN;
	SET @FileName = N'FACT ' + CAST(@Year AS NVARCHAR(4)) + '.csv';

	DROP TABLE IF EXISTS [DW12].[LOAD]
	DROP VIEW IF EXISTS DW12_LOAD

	CREATE TABLE  [DW12].[LOAD](
		[ID] BIGINT IDENTITY(1,1), -- 
		[DateID] SMALLINT,
		[GridID] INT, 
		[E0] FLOAT,
		INDEX DW12_COLUMNSTORE_LOAD CLUSTERED COLUMNSTORE )

	EXEC(@CreateView_LoadingTable)

	SET @Bulk_Insert_Command = '
	BULK INSERT [DW12_LOAD]
	FROM ''' + @FilePath + @FileName + '''
	WITH( 
		FIRSTROW = 2, 
		FIELDTERMINATOR = '','', 
		ROWTERMINATOR = ''\n'',
		KEEPNULLS 
		)'

	PRINT  CAST(CURRENT_TIMESTAMP AS NVARCHAR(40)) + N': LOADING FILE "' + @FileName + '"'
	EXEC(@Bulk_Insert_Command)

	CHECKPOINT
	--DBCC SHRINKFILE (N'CLIMATE_DATA_V1_log' , 0, TRUNCATEONLY)

	PRINT  CAST(CURRENT_TIMESTAMP AS NVARCHAR(40)) + N': TRANSFORMING TO OBT'
	INSERT INTO [DW12_OBT]
	SELECT [Year], [Month], [Day], [Latitude], [Longitude], [E0]
	FROM (
		[DW12].[LOAD] AS [Fact]

		JOIN  [DW12].[TIME] AS [Time]
		ON [Fact].[DateID] = [Time].[DateID]

		JOIN  [DW12].[GRID] AS [Grid]
		ON [Fact].[GridID] = [Grid].[GridID]
		)

	CHECKPOINT
	--DBCC SHRINKFILE (N'CLIMATE_DATA_V1_log' , 0, TRUNCATEONLY)

	SET @Year = @Year + @YearIncrement;
	SET @ProgressPercent = 100 * (CAST(@Year - @YearStart AS FLOAT) / CAST(@YearEnd - @YearStart + 1 AS FLOAT));
	PRINT  CAST(CURRENT_TIMESTAMP AS NVARCHAR(40)) + N': ' + CAST(@ProgressPercent AS NVARCHAR(6)) +'% COMPLETE'
END

DROP TABLE IF EXISTS [DW12].[LOAD]
DROP VIEW IF EXISTS DW12_LOAD
DROP VIEW IF EXISTS DW12_OBT




























-- MODIFYING THE STRUCTURE OF DW3 TO ADD SPLIT INTEGER DATES, RATHER THAN RE-INGESTING. -
-- OUTCOME: didn't work. first column took 3 hours then blew out the transaction log

--ALTER TABLE [DW3].[OBT]
--DROP COLUMN [Year], [Month], [Day]

----ALTER TABLE [DW3].[OBT]
----ADD [Year] SMALLINT NULL,
----	[Month] TINYINT NULL,
----	[Day] TINYINT NULL;

--DBCC SHRINKFILE (N'CLIMATE_DATA_V1_log' , 0, TRUNCATEONLY)

--UPDATE [DW3].[OBT]
--SET [Year] =	YEAR([DateTime]);
--CHECKPOINT
--DBCC SHRINKFILE (N'CLIMATE_DATA_V1_log' , 0, TRUNCATEONLY)

--UPDATE [DW3].[OBT]
--SET [Month] =	MONTH([DateTime]);
--CHECKPOINT
--DBCC SHRINKFILE (N'CLIMATE_DATA_V1_log' , 0, TRUNCATEONLY)

--UPDATE [DW3].[OBT]
--SET [Day] =		DAY([DateTime]);
--CHECKPOINT
--DBCC SHRINKFILE (N'CLIMATE_DATA_V1_log' , 0, TRUNCATEONLY)

--ALTER TABLE [DW3].[OBT]
--DROP COLUMN [DateTime]
--CHECKPOINT
--DBCC SHRINKFILE (N'CLIMATE_DATA_V1_log' , 0, TRUNCATEONLY)

---- NEED TO FIGURE OUT WHAT TO DO ABOUT THE INDEX

--SELECT TOP(100) * FROM [DW3].[OBT]