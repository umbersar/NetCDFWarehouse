USE CLIMATE_DATA_V1
GO

---- MONTHLY TABLE
--DROP TABLE IF EXISTS [OBT].[MONTHLY_V1]
--CREATE TABLE  [OBT].[MONTHLY_V1](
--        [SpaceID] INT, 
--		[Year] SMALLINT, 
--        [Month] TINYINT, 
--		[Total_E0] FLOAT,
--		[Avg_E0] FLOAT,
--		[Abs_Max_E0] FLOAT,
--		[Abs_Min_E0] FLOAT,
--		[STD_E0] FLOAT,
--		INDEX COLUMNSTORE_OBT_MONTHLY_V1  CLUSTERED COLUMNSTORE 
--        )


--INSERT INTO [OBT].[MONTHLY_V1]
--SELECT  [SpaceID],[Year], [Month],  SUM([E0]) AS Total_E0, AVG([E0]) AS Avg_E0, MAX([E0]) AS Abs_Max_E0, MIN([E0]) AS Abs_Min_E0, STDEV([E0]) AS STD_E0
--FROM [OBT].[V4]
--GROUP BY [SpaceID], [Year], [Month]
--ORDER BY [SpaceID], [Year], [Month]

--SELECT * FROM [OBT].[MONTHLY_V1]
--ORDER BY [SpaceID], [Year], [Month]


---- ANNUAL TABLE
--DROP TABLE IF EXISTS [OBT].[ANNUAL_V1]
--CREATE TABLE  [OBT].[ANNUAL_V1](
--        [SpaceID] INT, 
--		[Year] SMALLINT, 
--		[Total_E0] FLOAT,
--		[Avg_E0] FLOAT,
--		[Abs_Max_E0] FLOAT,
--		[Abs_Min_E0] FLOAT,
--		[STD_E0] FLOAT,
--		INDEX COLUMNSTORE_OBT_ANNUAL_V1  CLUSTERED COLUMNSTORE 
--        )

--INSERT INTO [OBT].[ANNUAL_V1]
--SELECT  [SpaceID], [Year], SUM([E0]) AS Total_E0, AVG([E0]) AS Avg_E0, MAX([E0]) AS Max_E0, MIN([E0]) AS Min_E0, STDEV([E0]) AS STD_E0
--FROM [OBT].[V4]
--GROUP BY [SpaceID], [Year]
--ORDER BY [SpaceID], [Year]

----SELECT * FROM [OBT].[ANNUAL_V1]
----ORDER BY [SpaceID], [Year]



DROP TABLE IF EXISTS [DIMENSION].[SPACE_OUTPUT]
CREATE TABLE  [DIMENSION].[SPACE_OUTPUT](
        [SpaceID] INT, 
		[Longitude] DECIMAL(5,2),
		[Latitude] DECIMAL(5,2),
		INDEX COLUMNSTORE_DIMENSION_SPACEOUTPUT  CLUSTERED COLUMNSTORE 
		)

INSERT INTO [DIMENSION].[SPACE_OUTPUT]
SELECT DISTINCT [SpaceID], [Longitude], [Latitude] 	FROM [DIMENSION].[SPACE]