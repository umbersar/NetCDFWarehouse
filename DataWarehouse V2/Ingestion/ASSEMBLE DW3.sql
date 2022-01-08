USE CLIMATE_DATA_V1
GO

DROP TABLE IF EXISTS [DW3].[OBT]
CREATE TABLE  [DW3].[OBT](
		[ID] BIGINT IDENTITY(1,1), -- 
		[DateTime] SMALLDATETIME, 
		[Latitude] DECIMAL(5,2), 
		[Longitude] DECIMAL(5,2), 
		[E0] FLOAT,
		CONSTRAINT CL_ROWSTORE_DW3FACT PRIMARY KEY ([DateTime], [Latitude], [Longitude]) -- or for columnstore use: INDEX <index_name>  CLUSTERED COLUMNSTORE 
        );


DROP VIEW IF EXISTS [DW3_OBT]
GO
CREATE VIEW DW3_OBT ([DateTime], [Latitude], [Longitude], [E0]) AS
	SELECT [DateTime], [Latitude], [Longitude], [E0] FROM [DW3].[OBT];
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
	SET @Bulk_Insert_Command = '
	BULK INSERT [DW3_OBT]
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