USE CLIMATE_DATA_V1
GO

--CREATE SCHEMA DW3


 -- GRID TABLE
DROP TABLE IF EXISTS [DW3].[GRID]

CREATE TABLE  [DW3].[GRID](
		[GridID] INT PRIMARY KEY CLUSTERED,
		[Latitude] DECIMAL(5,2),
		[Longitude] DECIMAL(5,2) 
        );

BULK INSERT [DW3].[GRID]
FROM 'C:\AWRA_nc_dataset\AWRA-L_historical_data\DW_V2\DIMENSION_GRID.csv'
WITH( 
    FIRSTROW = 2, 
    FIELDTERMINATOR = ',', 
    ROWTERMINATOR = '\n', 
    KEEPNULLS 
    )


-- -- TIME1 DIMENSION TABLE (with datetime format)
DROP TABLE IF EXISTS [DW3].[TIME1]

CREATE TABLE  [DW3].[TIME1](
		[DateID] INT PRIMARY KEY CLUSTERED,
		[DateTime] SMALLDATETIME,
        );

BULK INSERT [DW3].[TIME1]
FROM 'C:\AWRA_nc_dataset\AWRA-L_historical_data\DW_V2\DIMENSION_TIME1.csv'
WITH( 
    FIRSTROW = 2, 
    FIELDTERMINATOR = ',', 
    ROWTERMINATOR = '\n', 
    KEEPNULLS 
    )

-- -- TIME2 DIMENSION TABLE (with split integer format)
DROP TABLE IF EXISTS [DW3].[TIME2]

CREATE TABLE  [DW3].[TIME2](
		[DateID] INT PRIMARY KEY CLUSTERED,
		[Year] SMALLINT,
		[Month] TINYINT,
		[Day] TINYINT
        );

BULK INSERT [DW3].[TIME2]
FROM 'C:\AWRA_nc_dataset\AWRA-L_historical_data\DW_V2\DIMENSION_TIME2.csv'
WITH( 
    FIRSTROW = 2, 
    FIELDTERMINATOR = ',', 
    ROWTERMINATOR = '\n', 
    KEEPNULLS 
    )

---- -- FACT TABLE
DROP TABLE IF EXISTS [DW3].[FACT]
DROP VIEW IF EXISTS [DW3_FACT]

CREATE TABLE  [DW3].[FACT](
		[ID] BIGINT IDENTITY(1,1), -- 
		[DateTime] SMALLDATETIME, 
		[Latitude] DECIMAL(5,2), 
		[Longitude] DECIMAL(5,2), 
		[E0] FLOAT,
		CONSTRAINT CL_ROWSTORE_DW3FACT PRIMARY KEY ([DateTime], [Latitude], [Longitude]) -- or for columnstore use: INDEX <index_name>  CLUSTERED COLUMNSTORE 
        );

-- -- This needs to be executed on it's own
--CREATE VIEW DW3_FACT ([DateTime], [Latitude], [Longitude], [E0]) AS
--	SELECT [DateTime], [Latitude], [Longitude], [E0] FROM [DW3].[FACT];

INSERT INTO DW3_FACT 
SELECT [DateTime], [Latitude], [Longitude], [E0]
FROM (
	[DW1].[FACT] AS [Fact]

	JOIN
	[DW3].[TIME1] AS [Time]
	ON [Fact].[DateID] = [Time].[DateID]
	
	JOIN
	[DW3].GRID AS [Grid]
	ON [Fact].[GridID] = [Grid].[GridID]
	)

	
	
	