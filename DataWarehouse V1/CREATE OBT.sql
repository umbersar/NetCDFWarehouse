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

------DEFINING DIMENSION TABLE 
--;WITH [COORDINATE_TABLE] ([DataID], [Month], [Day], [SpaceID], [Latitude], [Longitude])  AS (
--	SELECT [DS].[DataID], [Month], [Day], [SpaceID], [Latitude], [Longitude] 
--	FROM 
--		[DIMENSION].[SPACE] AS [DS]
--		JOIN
--		[DIMENSION].[TIME] AS [DT]
--		ON [DS].[DataID] = [DT].[DataID]
--	)

--SELECT * INTO [DIMENSION].[ALL]
--FROM [COORDINATE_TABLE];
	


-------METHODS TO FILL 'Year' COLUMN
--UPDATE [DIMENSION].[ALL] SET [Year] = 1911;
--ALTER TABLE [DIMENSION].[ALL] ADD [Year] SMALLINT DEFAULT 1911 NOT NULL;



--SELECT TOP(100) * FROM [DIMENSION].[ALL]
--;WITH jeff AS (
--SELECT TOP(9860)[DIM].[DataID], [E0].[Y1911].[Year] AS [Year], [Month], [Day], [SpaceID], [Latitude], [Longitude], [E0].[Y1911].[Variable] AS [E011], [E0].[Y1912].[Variable] AS [E012] FROM (
--	[DIMENSION].[ALL] AS [DIM]
--	JOIN [E0].[Y1911] ON [DIM].[DataID] = [E0].[Y1911].[DataID]
--	JOIN [E0].[Y1912] ON [DIM].[DataID] = [E0].[Y1912].[DataID])
--	ORDER BY [DIM].[DataID]


--SELECT * FROM [E0].[Y1911]
--UNION ALL
--SELECT * FROM [E0].[Y1912]

--ALTER TABLE [E0].[Y1911] ADD [Year] SMALLINT DEFAULT 1911 NOT NULL
--ALTER TABLE [E0].[Y1912] ADD [Year] SMALLINT DEFAULT 1912 NOT NULL

--WITH TEMP AS 
--	SELECT * FROM [E0].[Y1911]
--	UNION ALL
--	SELECT * FROM [E0].[Y1912]

--SELECT TOP(100) * FROM TEMP
--	--ORDER BY [Variable] DESC


--SELECT * FROM(
--E0.Y1911 JOIN DIMENSION.[ALL]
--on E0.Y1911.DataID = DIMENSION.[ALL].DataID)
 --EXEC('CREATE SCHEMA OBT')

DROP TABLE [OBT].[V1]

CREATE TABLE [OBT].[V1] (
	[DataID] INT,
	[Year] SMALLINT,
	[Month] TINYINT,
	[Day] TINYINT,
	[SpaceID] INT,
	[Longitude] DECIMAL(5,2),
	[Latitude] DECIMAL(5,2),
	[E0] FLOAT,
	[QTOT] FLOAT,
	INDEX COLUMNSTORE_OBT_V1 CLUSTERED COLUMNSTORE );

INSERT INTO [OBT].[V1]
SELECT [DIM].[DataID], [E0].[Y1911].[Year] AS [Year], [Month], [Day], [SpaceID], [Latitude], [Longitude], [E0].[Y1911].[Variable] AS [E0], [E0].[Y1912].[Variable] AS [QTOT]
FROM (
	[DIMENSION].[ALL] AS [DIM]
	JOIN [E0].[Y1911] ON [DIM].[DataID] = [E0].[Y1911].[DataID]
	JOIN [E0].[Y1912] ON [DIM].[DataID] = [E0].[Y1912].[DataID])

SELECT TOP(10000) * FROM [OBT].[V4]