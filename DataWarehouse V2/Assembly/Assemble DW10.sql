-- -- [DW10] is identical to [DW9] with the exception of the time dimension table.
-- -- Run 'Assemble DW9' first to build the space dimension table and fact table
-- -- The run this script to modify the time dimension table.

USE CLIMATE_DATA_V1
GO

-- TIME TABLE: should be small enough that it doesn't actually use columnstore
DROP TABLE IF EXISTS [DW9].[TIME]
CREATE TABLE  [DW9].[TIME](
		[DateID] SMALLINT,
		--[DateTime] SMALLDATETIME,
		[Year] SMALLINT,
		[Month] TINYINT,
		[Day] TINYINT,
		INDEX COLUMNSTORE_TIME CLUSTERED COLUMNSTORE
        );
BULK INSERT [DW9].[TIME]
FROM 'D:\CSIRO\STAR-SCHEMA V2\DIMENSION_TIME2.csv'
WITH( 
    FIRSTROW = 2, 
    FIELDTERMINATOR = ',', 
    ROWTERMINATOR = '\n', 
    KEEPNULLS 
    )
GO




























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