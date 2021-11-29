--SELECT DATEADD(
--SELECT * FROM [CLIMATE_DATA_V1].[DIMENSION].[TIME]

--USE [CLIMATE_DATA_V1]
--GO

--DROP TABLE IF EXISTS [DIMENSION].[TIME]
--DROP VIEW IF EXISTS DIM_TIME

--CREATE TABLE [DIMENSION].[TIME] (
--            [DataID] INT IDENTITY(1,1), 
--            [Year] INT, 
--            [Month] INT, 
--            [Day] INT, 
--            [Hour] INT, 
--			  [Minute] INT, 
--            [Second] INT)

--CREATE VIEW DIM_TIME (
--                    [Month], [Day], [Hour], [Minute], [Second]) AS 
--                    (SELECT [Month], [Day], [Hour], [Minute], [Second] FROM [DIMENSION].[TIME])

--BULK INSERT DIM_TIME 
--                        FROM 'C:\\AWRA_nc_dataset\\AWRA-L_historical_data\\e0\\E0 CSV\\DIM_TIME.csv' 
--                        WITH( 
--                            FIRSTROW = 2, 
--                            FIELDTERMINATOR = ',', 
--                            ROWTERMINATOR = '\n', 
--                            KEEPNULLS 
--                            )
--31
;WITH [COORDINATE_TABLE] ([DataID], [Year], [Month], [Day], [SpaceID], [Latitude], [Longitude])  AS (
	SELECT [DS].[DataID], [Year], [Month], [Day], [SpaceID], [Latitude], [Longitude] 
	FROM 
		[DIMENSION].[SPACE] AS [DS]
		JOIN
		[DIMENSION].[TIME] AS [DT]
		ON [DS].[DataID] = [DT].[DataID]
	)

SELECT * FROM [COORDINATE_TABLE]

-- AS [DS] JOIN [DIMENSION].[TIME] AS [DT]	ON [DS].[DataID] = [DT].[DataID]))

--SELECT * INTO [DIMENSION].[ALL]
--FROM 
	--SELECT [DataID], [Year], [Month], [Day] INTO [DIMENSION].[ALL]
	--FROM [DIMENSION].[TIME]

	--(SELECT [DS].[DataID], [Year], [Month], [Day], [SpaceID], [Latitude], [Longitude] 
	--FROM 
	--	[DIMENSION].[SPACE] AS [DS]
	--	JOIN
	--	[DIMENSION].[TIME] AS [DT]
	--	ON [DS].[DataID] = [DT].[DataID])
	


--SELECT * FROM [COORDINATE_TABLE]