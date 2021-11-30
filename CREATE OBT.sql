--SELECT DATEADD(
--SELECT * FROM [CLIMATE_DATA_V1].[DIMENSION].[TIME]

USE [CLIMATE_DATA_V1]
GO

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

--DROP TABLE IF EXISTS [DIMENSION].[ALL]

----DEFINING CTE HAS WORKED 
--;WITH [COORDINATE_TABLE] ([DataID], [Month], [Day], [SpaceID], [Latitude], [Longitude])  AS (
--	SELECT [DS].[DataID], [Month], [Day], [SpaceID], [Latitude], [Longitude] 
--	FROM 
--		[DIMENSION].[SPACE] AS [DS]
--		JOIN
--		[DIMENSION].[TIME] AS [DT]
--		ON [DS].[DataID] = [DT].[DataID]
--	)

----SELECT * FROM [COORDINATE_TABLE]

----UPDATE [COORDINATE_TABLE] SET [Year] = 1911;

----DEFINING WITH SELECT INTO
--SELECT * INTO [DIMENSION].[ALL]
--FROM [COORDINATE_TABLE];
	
----UPDATE [DIMENSION].[ALL] SET [Year] = 1911;
--ALTER TABLE [DIMENSION].[ALL] ADD [Year] SMALLINT DEFAULT 1911 NOT NULL;
--SELECT TOP(100) * FROM [DIMENSION].[ALL]

--SELECT TOP(100) * FROM (
--	[DIMENSION].[ALL] AS [DIM]
--	JOIN
--	[E0].[Y1911] 
--	ON [DIM].[DataID] = [E0].[Y1911].[DataID])
--	ORDER BY [E0].[Y1911].[Variable] DESC


--SELECT * FROM [E0].[Y1911]
--UNION ALL
--SELECT * FROM [E0].[Y1912]

ALTER TABLE [E0].[Y1911] ADD [Year] SMALLINT DEFAULT 1911 NOT NULL
ALTER TABLE [E0].[Y1912] ADD [Year] SMALLINT DEFAULT 1912 NOT NULL

SELECT * FROM [E0].[Y1911]
UNION ALL
SELECT * FROM [E0].[Y1912]