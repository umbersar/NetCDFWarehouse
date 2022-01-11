

USE CLIMATE_DATA_V1
GO

-- -- GRID TABLE
DROP TABLE IF EXISTS [DW4].[GRID]
CREATE TABLE  [DW4].[GRID](
		[GridID] INT PRIMARY KEY CLUSTERED,
		[Latitude] DECIMAL(5,2),
		[Longitude] DECIMAL(5,2) 
        );
BULK INSERT [DW4].[GRID]
FROM 'D:\CSIRO\STAR-SCHEMA V1\DIMENSION_GRID.csv'
WITH( 
    FIRSTROW = 2, 
    FIELDTERMINATOR = ',', 
    ROWTERMINATOR = '\n', 
    KEEPNULLS 
    )
GO

-- -- TIME TABLE
DROP TABLE IF EXISTS [DW4].[TIME]
CREATE TABLE  [DW4].[TIME](
		[DateID] INT PRIMARY KEY CLUSTERED,
		[Year] SMALLINT,
		[Month] TINYINT,
		[Day] TINYINT
        );
BULK INSERT [DW4].[TIME]
FROM 'D:\CSIRO\STAR-SCHEMA V2\DIMENSION_TIME2.csv'
WITH( 
    FIRSTROW = 2, 
    FIELDTERMINATOR = ',', 
    ROWTERMINATOR = '\n', 
    KEEPNULLS 
    )
GO


DROP TABLE IF EXISTS [DW4].[OBT]
CREATE TABLE  [DW4].[OBT](
		[ID] BIGINT IDENTITY(1,1), -- 
		[Year] SMALLINT,
		[Month] TINYINT,
		[Day] TINYINT,
		[Latitude] DECIMAL(5,2), 
		[Longitude] DECIMAL(5,2), 
		[E0] FLOAT,
		CONSTRAINT CL_ROWSTORE_DW4FACT PRIMARY KEY ([Year], [Month], [Day], [Latitude], [Longitude]) -- or for columnstore use: INDEX <index_name>  CLUSTERED COLUMNSTORE 
        );

DROP VIEW IF EXISTS [DW4_OBT]
GO
CREATE VIEW DW4_OBT ([Year], [Month], [Day], [Latitude], [Longitude], [E0]) AS
	SELECT [Year], [Month], [Day], [Latitude], [Longitude], [E0] FROM [DW4].[OBT];
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
'	CREATE VIEW DW4_LOAD ([DateID], [GridID], [E0]) AS
	SELECT [DateID], [GridID], [E0] FROM [DW4].[LOAD];'


WHILE (@Year <= @YearEnd)
BEGIN;
	SET @FileName = N'FACT ' + CAST(@Year AS NVARCHAR(4)) + '.csv';

	DROP TABLE IF EXISTS [DW4].[LOAD]
	DROP VIEW IF EXISTS DW4_LOAD

	CREATE TABLE  [DW4].[LOAD](
		[ID] BIGINT IDENTITY(1,1), -- 
		[DateID] SMALLINT,
		[GridID] INT, 
		[E0] FLOAT)

	EXEC(@CreateView_LoadingTable)

	SET @Bulk_Insert_Command = '
	BULK INSERT [DW4_LOAD]
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
	DBCC SHRINKFILE (N'CLIMATE_DATA_V1_log' , 0, TRUNCATEONLY)

	PRINT  CAST(CURRENT_TIMESTAMP AS NVARCHAR(40)) + N': TRANSFORMING TO OBT'
	INSERT INTO [DW4_OBT]
	SELECT [Year], [Month], [Day], [Latitude], [Longitude], [E0]
	FROM (
		[DW4].[LOAD] AS [Fact]

		JOIN  [DW4].[TIME] AS [Time]
		ON [Fact].[DateID] = [Time].[DateID]

		JOIN  [DW4].[GRID] AS [Grid]
		ON [Fact].[GridID] = [Grid].[GridID]
		)

	CHECKPOINT
	DBCC SHRINKFILE (N'CLIMATE_DATA_V1_log' , 0, TRUNCATEONLY)

	SET @Year = @Year + @YearIncrement;
	SET @ProgressPercent = 100 * (CAST(@Year - @YearStart AS FLOAT) / CAST(@YearEnd - @YearStart + 1 AS FLOAT));
	PRINT  CAST(CURRENT_TIMESTAMP AS NVARCHAR(40)) + N': ' + CAST(@ProgressPercent AS NVARCHAR(6)) +'% COMPLETE'
END

DROP TABLE IF EXISTS [DW4].[LOAD]
DROP VIEW IF EXISTS DW4_LOAD
DROP VIEW IF EXISTS DW4_OBT




























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