USE CLIMATE_DATA_V1
GO

--CREATE SCHEMA [DW5]

DROP TABLE IF EXISTS [DW5].[OBT]
CREATE TABLE  [DW5].[OBT](
		[ID] BIGINT IDENTITY(1,1), -- 
		[DateTime] SMALLDATETIME, 
		[GridID] INT, 
		[E0] FLOAT,
		CONSTRAINT CL_ROWSTORE_DW5FACT PRIMARY KEY ([DateTime], [GridID]) -- or for columnstore use: INDEX <index_name>  CLUSTERED COLUMNSTORE 
        );


DROP VIEW IF EXISTS [DW5_OBT]
GO
CREATE VIEW DW5_OBT ([DateTime], [GridID], [E0]) AS
	SELECT [DateTime], [GridID], [E0] FROM [DW5].[OBT];
GO

-- -- GRID TABLE
DROP TABLE IF EXISTS [DW5].[GRID]

CREATE TABLE  [DW5].[GRID](
		[GridID] INT PRIMARY KEY CLUSTERED,
		[Latitude] DECIMAL(5,2),
		[Longitude] DECIMAL(5,2) 
        );
BULK INSERT [DW5].[GRID]
FROM 'D:\CSIRO\STAR-SCHEMA V2\DIMENSION_GRID.csv'
WITH( 
    FIRSTROW = 2, 
    FIELDTERMINATOR = ',', 
    ROWTERMINATOR = '\n', 
    KEEPNULLS 
    )
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
SET @FilePath = 'D:\CSIRO\STAR-SCHEMA V2\'

WHILE (@Year < @YearEnd)
BEGIN;
	SET @FileName = N'FACT ' + CAST(@Year AS NVARCHAR(4)) + N' - ' + CAST((@Year + @YearIncrement - 1) AS NVARCHAR(4)) + '.csv';
	SET @Bulk_Insert_Command = '
	BULK INSERT [DW5_OBT]
	FROM ''' + @FilePath + @FileName + '''
	WITH( 
		FIRSTROW = 2, 
		FIELDTERMINATOR = '','', 
		ROWTERMINATOR = ''\n'',
		KEEPNULLS 
		)'

	PRINT  CAST(CURRENT_TIMESTAMP AS NVARCHAR(40)) + N': INSERTING FILE "' + @FileName + '"'
	--SET STATISTICS TIME ON
	EXEC(@Bulk_Insert_Command)
	--SET STATISTICS TIME OFF
	
	SET @Year = @Year + @YearIncrement;
	SET @ProgressPercent = 100 * (CAST(@Year - @YearStart AS FLOAT) / CAST(@YearEnd - @YearStart + 1 AS FLOAT));
	PRINT  CAST(CURRENT_TIMESTAMP AS NVARCHAR(40)) + N': ' + CAST(@ProgressPercent AS NVARCHAR(6)) +'% COMPLETE'

	CHECKPOINT
	DBCC SHRINKFILE (N'CLIMATE_DATA_V1_log' , 0, TRUNCATEONLY)
END