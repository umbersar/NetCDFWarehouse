USE CLIMATE_DATA_V1
GO

--CREATE SCHEMA DW11

---- TIME DIMENSION (with datetime format)
--DROP TABLE IF EXISTS [DW11].[TIME]
--CREATE TABLE  [DW11].[TIME](
--		[DateID] SMALLINT,
--		[DateTime] SMALLDATETIME,
--		--[Year] SMALLINT,
--		--[Month] TINYINT,
--		--[Day] TINYINT,
--		INDEX COLUMNSTORE_TIME CLUSTERED COLUMNSTORE
--        );
--BULK INSERT [DW11].[TIME]
--FROM 'D:\CSIRO\STAR-SCHEMA V2\DIMENSION_TIME1.csv'
--WITH( 
--    FIRSTROW = 2, 
--    FIELDTERMINATOR = ',', 
--    ROWTERMINATOR = '\n', 
--    KEEPNULLS 
--    )

---- GRID DIMENSION TABLE
--DROP TABLE IF EXISTS [DW11].[GRID]
--CREATE TABLE  [DW11].[GRID](
--		[GridID] INT,
--		[Latitude] DECIMAL(5,2),
--		[Longitude] DECIMAL(5,2),
--		INDEX COLUMNSTORE_GRID CLUSTERED COLUMNSTORE
--        );
--BULK INSERT [DW11].[GRID]
--FROM 'D:\CSIRO\STAR-SCHEMA V2\DIMENSION_GRID.csv'
--WITH( 
--    FIRSTROW = 2, 
--    FIELDTERMINATOR = ',', 
--    ROWTERMINATOR = '\n', 
--    KEEPNULLS 
--    )
--GO

DROP TABLE IF EXISTS [DW11].[OBT]
CREATE TABLE  [DW11].[OBT](
		[ID] BIGINT IDENTITY(1,1), -- 
		[DateTime] SMALLDATETIME,
		[Latitude] DECIMAL(5,2),
		[Longitude] DECIMAL(5,2),
		[E0] FLOAT,
		INDEX DW11_COLUMNSTORE CLUSTERED COLUMNSTORE
        );
DROP VIEW IF EXISTS [DW11_OBT]
GO
CREATE VIEW DW11_OBT ([DateTime], [Latitude], [Longitude], [E0]) AS
	SELECT [DateTime], [Latitude], [Longitude], [E0] FROM [DW11].[OBT];
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
SET @FilePath = 'D:\CSIRO\ONE BIG TABLE V1\'

WHILE (@Year <= @YearEnd)
BEGIN;
	SET @FileName = N'FACT ' + CAST(@Year AS NVARCHAR(4)) + ' - ' + CAST(@Year + 1 AS NVARCHAR(4)) +'.csv';
	PRINT  CAST(CURRENT_TIMESTAMP AS NVARCHAR(40)) + N': LOADING FILE "' + @FileName + '"'
	
	SET @Bulk_Insert_Command = '
	BULK INSERT [DW11_OBT]
	FROM ''' + @FilePath + @FileName + '''
	WITH( 
		FIRSTROW = 2, 
		FIELDTERMINATOR = '','', 
		ROWTERMINATOR = ''\n'',
		KEEPNULLS 
		)'
	EXEC(@Bulk_Insert_Command)
	CHECKPOINT


	SET @Year = @Year + 2
	SET @ProgressPercent = 100 * (CAST(@Year - @YearStart AS FLOAT) / CAST(@YearEnd - @YearStart + 1 AS FLOAT));
	PRINT  CAST(CURRENT_TIMESTAMP AS NVARCHAR(40)) + N': ' + CAST(@ProgressPercent AS NVARCHAR(6)) +'% COMPLETE'
END