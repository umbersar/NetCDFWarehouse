USE CLIMATE_DATA_V1
GO

--CREATE SCHEMA DW2


---- -- GRID TABLE
--DROP TABLE IF EXISTS [DW2].[GRID]

--CREATE TABLE  [DW2].[GRID](
--		[GridID] INT PRIMARY KEY CLUSTERED,
--		[Latitude] DECIMAL(5,2),
--		[Longitude] DECIMAL(5,2) 
--        );

--BULK INSERT [DW2].[GRID]
--FROM 'C:\AWRA_nc_dataset\AWRA-L_historical_data\DW_V2\DIMENSION_GRID.csv'
--WITH( 
--    FIRSTROW = 2, 
--    FIELDTERMINATOR = ',', 
--    ROWTERMINATOR = '\n', 
--    KEEPNULLS 
--    )


---- -- TIME1 DIMENSION TABLE (with datetime format)
--DROP TABLE IF EXISTS [DW2].[TIME1]

--CREATE TABLE  [DW2].[TIME1](
--		[DateID] INT PRIMARY KEY CLUSTERED,
--		[DateTime] DATETIME,
--        );

--BULK INSERT [DW2].[TIME1]
--FROM 'C:\AWRA_nc_dataset\AWRA-L_historical_data\DW_V2\DIMENSION_TIME1.csv'
--WITH( 
--    FIRSTROW = 2, 
--    FIELDTERMINATOR = ',', 
--    ROWTERMINATOR = '\n', 
--    KEEPNULLS 
--    )

---- -- TIME2 DIMENSION TABLE (with split integer format)
--DROP TABLE IF EXISTS [DW2].[TIME2]

--CREATE TABLE  [DW2].[TIME2](
--		[DateID] INT PRIMARY KEY CLUSTERED,
--		[Year] SMALLINT,
--		[Month] TINYINT,
--		[Day] TINYINT
--        );

--BULK INSERT [DW2].[TIME2]
--FROM 'C:\AWRA_nc_dataset\AWRA-L_historical_data\DW_V2\DIMENSION_TIME2.csv'
--WITH( 
--    FIRSTROW = 2, 
--    FIELDTERMINATOR = ',', 
--    ROWTERMINATOR = '\n', 
--    KEEPNULLS 
--    )

--SELECT * 
--FROM (
--	(SELECT [DateID] FROM [DW2].[TIME2]) AS [DateTime]
--	CROSS JOIN 
--	(SELECT [GridID] FROM [DW2].[GRID]) AS [Grid]
--	)

-- -- FACT TABLE
DROP TABLE IF EXISTS [DW2].[FACT]
DROP VIEW IF EXISTS [DW2_DIMENSION]

CREATE TABLE  [DW2].[FACT](
		[ID] BIGINT IDENTITY(1,1), -- 
		[DateID] SMALLINT, 
		[GridID] INT, 
		[E0] FLOAT,
		INDEX DW2_CL_COLUMNSTORE  CLUSTERED COLUMNSTORE 
        );

--CREATE VIEW DW2_DIMENSION ([DateID], [GridID]) AS
--	SELECT [DateID], [GridID] FROM [DW2].[FACT];

--INSERT INTO [DW2_DIMENSION]
--SELECT * 
--FROM (
--	(SELECT [DateID] FROM [DW2].[TIME2]) AS [DateTime]
--	CROSS JOIN 
--	(SELECT [GridID] FROM [DW2].[GRID]) AS [Grid]
--	)

SELECT TOP(10000) * FROM [DW2].[FACT]
WHERE [GridID] is null
--WHERE [DateID] = 1

--CREATE VIEW DW2_FACT ([E0]) AS
--	SELECT [E0] FROM [DW2].[FACT];


--BULK INSERT [DW2_FACT]
--FROM 'C:\AWRA_nc_dataset\AWRA-L_historical_data\DW_V2\FACT 1911 - 1920.csv'
--WITH (
--	FIRSTROW = 2, 
--    FIELDTERMINATOR = ',', 
--    ROWTERMINATOR = '\n', 
--    KEEPNULLS )

BULK INSERT [DW2_FACT]
FROM 'C:\AWRA_nc_dataset\AWRA-L_historical_data\DW_V2\FACT 1921 - 1930.csv'
WITH (
	FIRSTROW = 2, 
    FIELDTERMINATOR = ',', 
    ROWTERMINATOR = '\n', 
    KEEPNULLS )

BULK INSERT [DW2_FACT]
FROM 'C:\AWRA_nc_dataset\AWRA-L_historical_data\DW_V2\FACT 1931 - 1940.csv'
WITH (
	FIRSTROW = 2, 
    FIELDTERMINATOR = ',', 
    ROWTERMINATOR = '\n', 
    KEEPNULLS )

BULK INSERT [DW2_FACT]
FROM 'C:\AWRA_nc_dataset\AWRA-L_historical_data\DW_V2\FACT 1941 - 1950.csv'
WITH (
	FIRSTROW = 2, 
    FIELDTERMINATOR = ',', 
    ROWTERMINATOR = '\n', 
    KEEPNULLS )

BULK INSERT [DW2_FACT]
FROM 'C:\AWRA_nc_dataset\AWRA-L_historical_data\DW_V2\FACT 1951 - 1960.csv'
WITH (
	FIRSTROW = 2, 
    FIELDTERMINATOR = ',', 
    ROWTERMINATOR = '\n', 
    KEEPNULLS )
