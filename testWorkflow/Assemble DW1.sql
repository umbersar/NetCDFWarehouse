USE NetCDFWarehouse
GO

IF NOT EXISTS ( SELECT  *
                FROM sys.schemas
                WHERE name = N'DW1')
    EXEC('CREATE SCHEMA [DW1]');
go


-- -- GRID TABLE
DROP TABLE IF EXISTS [DW1].[GRID]

CREATE TABLE  [DW1].[GRID](
		[GridID] INT PRIMARY KEY CLUSTERED,
		[Latitude] DECIMAL(5,2),
		[Longitude] DECIMAL(5,2) 
        )on [datawarehouse] ;

BULK INSERT [DW1].[GRID]
FROM 'C:\Temp\netcdfs\csv\DIMENSION_GRID.csv'
WITH( 
    FIRSTROW = 2, 
    FIELDTERMINATOR = ',', 
    ROWTERMINATOR = '\n', 
    KEEPNULLS 
    )


-- -- TIME1 DIMENSION TABLE (with datetime format)
DROP TABLE IF EXISTS [DW1].[TIME1]

CREATE TABLE  [DW1].[TIME1](
		[DateID] INT PRIMARY KEY CLUSTERED,
		[DateTime] DATETIME,
        )on [datawarehouse];

BULK INSERT [DW1].[TIME1]
FROM 'C:\Temp\netcdfs\csv\DIMENSION_TIME1.csv'
WITH( 
    FIRSTROW = 2, 
    FIELDTERMINATOR = ',', 
    ROWTERMINATOR = '\n', 
    KEEPNULLS 
    )

-- -- TIME2 DIMENSION TABLE (with split integer format)
DROP TABLE IF EXISTS [DW1].[TIME2]

CREATE TABLE  [DW1].[TIME2](
		[DateID] INT PRIMARY KEY CLUSTERED,
		[Year] SMALLINT,
		[Month] TINYINT,
		[Day] TINYINT
        )on [datawarehouse];

BULK INSERT [DW1].[TIME2]
FROM 'C:\Temp\netcdfs\csv\\DIMENSION_TIME2.csv'
WITH( 
    FIRSTROW = 2, 
    FIELDTERMINATOR = ',', 
    ROWTERMINATOR = '\n', 
    KEEPNULLS 
    )

-- -- FACT TABLE
DROP TABLE IF EXISTS [DW1].[FACT]
DROP VIEW IF EXISTS [DW1_FACT]

CREATE TABLE  [DW1].[FACT](
		[ID] INT IDENTITY(1,1), -- 
		[DateID] SMALLINT, 
		[GridID] INT, 
		[E0] FLOAT,
		CONSTRAINT CL_ROWSTORE_DW1FACT PRIMARY KEY ([DateID], [GridID]) -- or for columnstore use: INDEX <index_name>  CLUSTERED COLUMNSTORE 
        )on [datawarehouse];

go
 -- This needs to be executed on it's own
CREATE VIEW DW1_FACT ([DateID], [GridID], [E0]) AS
	SELECT [DateID], [GridID], [E0] FROM [DW1].[FACT];
go

BULK INSERT [DW1_FACT]
FROM 'C:\Temp\netcdfs\csv\FACT 2010 - 2014.csv'
WITH (
	FIRSTROW = 2, 
    FIELDTERMINATOR = ',', 
    ROWTERMINATOR = '\n', 
    KEEPNULLS )

SELECT TOP(1000) * FROM [DW1].[FACT]
ORDER BY ID DESC

--	BULK INSERT [DW1_FACT]
--FROM 'C:\AWRA_nc_dataset\AWRA-L_historical_data\DW_V2\FACT 1916 - 1920.csv'
--WITH (
--	FIRSTROW = 2, 
--    FIELDTERMINATOR = ',', 
--    ROWTERMINATOR = '\n', 
--    KEEPNULLS )

--BULK INSERT [DW1_FACT]
--FROM 'C:\AWRA_nc_dataset\AWRA-L_historical_data\DW_V2\FACT 1921 - 1925.csv'
--WITH (
--	FIRSTROW = 2, 
--    FIELDTERMINATOR = ',', 
--    ROWTERMINATOR = '\n', 
--    KEEPNULLS )

--BULK INSERT [DW1_FACT]
--FROM 'C:\AWRA_nc_dataset\AWRA-L_historical_data\DW_V2\FACT 1926 - 1930.csv'
--WITH (
--	FIRSTROW = 2, 
--    FIELDTERMINATOR = ',', 
--    ROWTERMINATOR = '\n', 
--    KEEPNULLS )

--BULK INSERT [DW1_FACT]
--FROM 'C:\AWRA_nc_dataset\AWRA-L_historical_data\DW_V2\FACT 1931 - 1935.csv'
--WITH (
--	FIRSTROW = 2, 
--    FIELDTERMINATOR = ',', 
--    ROWTERMINATOR = '\n', 
--    KEEPNULLS )

--BULK INSERT [DW1_FACT]
--FROM 'C:\AWRA_nc_dataset\AWRA-L_historical_data\DW_V2\FACT 1936 - 1940.csv'
--WITH (
--	FIRSTROW = 2, 
--    FIELDTERMINATOR = ',', 
--    ROWTERMINATOR = '\n', 
--    KEEPNULLS )

--BULK INSERT [DW1_FACT]
--FROM 'C:\AWRA_nc_dataset\AWRA-L_historical_data\DW_V2\FACT 1941 - 1945.csv'
--WITH (
--	FIRSTROW = 2, 
--    FIELDTERMINATOR = ',', 
--    ROWTERMINATOR = '\n', 
--    KEEPNULLS )

--BULK INSERT [DW1_FACT]
--FROM 'C:\AWRA_nc_dataset\AWRA-L_historical_data\DW_V2\FACT 1946 - 1950.csv'
--WITH (
--	FIRSTROW = 2, 
--    FIELDTERMINATOR = ',', 
--    ROWTERMINATOR = '\n', 
--    KEEPNULLS )
	
--BULK INSERT [DW1_FACT]
--FROM 'C:\AWRA_nc_dataset\AWRA-L_historical_data\DW_V2\FACT 1951 - 1955.csv'
--WITH (
--	FIRSTROW = 2, 
--    FIELDTERMINATOR = ',', 
--    ROWTERMINATOR = '\n', 
--    KEEPNULLS )

--BULK INSERT [DW1_FACT]
--FROM 'C:\AWRA_nc_dataset\AWRA-L_historical_data\DW_V2\FACT 1956 - 1960.csv'
--WITH (
--	FIRSTROW = 2, 
--    FIELDTERMINATOR = ',', 
--    ROWTERMINATOR = '\n', 
--    KEEPNULLS )
	