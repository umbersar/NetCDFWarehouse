USE CLIMATE_DATA_V1
GO

--CREATE CLUSTERED COLUMNSTORE INDEX TESTINDEX ON [E0].[Y1911]
	--WITH (DROP_EXISTING = ON);

--SELECT * FROM [DIMENSION].[ALL]
--SELECT * FROM [E0].[Y1911]

--DROP TABLE IF EXISTS[E0].[Y1911]
--CREATE TABLE [E0].[Y1911] (
--                                [DataID] INT IDENTITY(1,1), 
--                                [Year] SMALLINT, 
--                                [Month] TINYINT, 
--                                [Day] TINYINT, 
--                                [Hour] TINYINT, 
--                                [Minute] TINYINT, 
--                                [Second] TINYINT, 
--                                INDEX COLUMNSTORE_E0_Y1911 CLUSTERED COLUMNSTORE 
--                                );


SELECT TOP(9860) * FROM [E0].[Y1931]


--DROP TABLE [DIMENSION].[ALL]
--DROP TABLE [DIMENSION].[SPACE]
--DROP VIEW [DIMENSION_SPACE]
--DROP TABLE [DIMENSION].[TIME]
--DROP VIEW [DIMENSION_TIME]
--DROP VIEW [E0_Y1911]
DROP TABLE [E0].[Y1911]
DROP TABLE [E0].[Y1912]
DROP TABLE [E0].[Y1913]
DROP TABLE [E0].[Y1914]
DROP TABLE [E0].[Y1915]
DROP TABLE [E0].[Y1916]
DROP TABLE [E0].[Y1917]
DROP TABLE [E0].[Y1918]
DROP TABLE [E0].[Y1919]
DROP TABLE [E0].[Y1920]
DROP TABLE [E0].[Y1921]
DROP TABLE [E0].[Y1922]
DROP TABLE [E0].[Y1923]
DROP TABLE [E0].[Y1924]
DROP TABLE [E0].[Y1925]
DROP TABLE [E0].[Y1926]
DROP TABLE [E0].[Y1927]
DROP TABLE [E0].[Y1928]
DROP TABLE [E0].[Y1929]
DROP TABLE [E0].[Y1930]
DROP TABLE [E0].[Y1931]
DROP TABLE [E0].[Y1932]
DROP TABLE [E0].[Y1933]
DROP TABLE [E0].[Y1934]
DROP TABLE [E0].[Y1935]
DROP TABLE [E0].[Y1936]
DROP TABLE [E0].[Y1937]
DROP TABLE [E0].[Y1938]
DROP TABLE [E0].[Y1939]
DROP TABLE [E0].[Y1940]
DROP TABLE [E0].[Y1941]
DROP TABLE [E0].[Y1942]
DROP TABLE [E0].[Y1943]
DROP TABLE [E0].[Y1944]
DROP TABLE [E0].[Y1945]
DROP TABLE [E0].[Y1946]
DROP TABLE [E0].[Y1947]
DROP TABLE [E0].[Y1948]
DROP TABLE [E0].[Y1949]
DROP TABLE [E0].[Y1950]
DROP TABLE [E0].[Y1951]
DROP TABLE [E0].[Y1952]
DROP TABLE [E0].[Y1953]
DROP TABLE [E0].[Y1954]
DROP TABLE [E0].[Y1955]
DROP TABLE [E0].[Y1956]
DROP TABLE [E0].[Y1957]
DROP TABLE [E0].[Y1958]
DROP TABLE [E0].[Y1959]
DROP TABLE [E0].[Y1960]