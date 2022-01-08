-- RUN THIS OUT OF PYTHON FOR BETTER CONTROL ISSUES

USE CLIMATE_DATA_V1
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
		@Bulk_Insert_Command NVARCHAR(200);

SET @YearStart	= 1911;
SET @YearEnd	= 1950;
SET @Year		= @YearStart;
SET @YearIncrement = 2;
SET @FilePath = 'D:\CSIRO\ONE BIG TABLE\'




WHILE (@Year < @YearEnd)
BEGIN;
	SET @FileName = N'FACT ' + CAST(@Year AS NVARCHAR(4)) + N' - ' + CAST((@Year + @YearIncrement - 1) AS NVARCHAR(4)) + '.csv';

	CREATE TABLE  [DW4].[LOAD](
		[ID] BIGINT IDENTITY(1,1), -- 
		[DateID] SMALLINT,
		[GridID] INT, 
		[E0] FLOAT)

	CREATE VIEW DW4_LOAD ([DateID], [GridID], [E0]) AS
	SELECT [DateID], [GridID], [E0] FROM [DW4].[LOAD];

	BULK INSERT [DW4_LOAD]
	FROM '<>'
	WITH( 
		FIRSTROW = 2, 
		FIELDTERMINATOR = ',', 
		ROWTERMINATOR = '\n',
		KEEPNULLS 
		)

	CHECKPOINT
	DBCC SHRINKFILE (N'CLIMATE_DATA_V1_log' , 0, TRUNCATEONLY)

	INSERT INTO [DW4_OBT]
	SELECT [Year], [Month], [Day], [Latitude], [Longitude], [E0]
	FROM (
		[DW4].[LOAD] AS [Fact]

		JOIN  [DW4].[TIME2] AS [Time]
		ON [Fact].[DateID] = [Time].[DateID]

		JOIN  [DW4].[GRID] AS [Grid]
		ON [Fact].[GridID] = [Grid].[GridID]
		)

	DROP TABLE IF EXISTS [DW4].[LOAD]
	DROP VIEW IF EXISTS DW4_LOAD

	CHECKPOINT
	DBCC SHRINKFILE (N'CLIMATE_DATA_V1_log' , 0, TRUNCATEONLY)
END






























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