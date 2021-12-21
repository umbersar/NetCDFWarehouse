USE CLIMATE_DATA_V1
GO

--CREATE SCHEMA [DW1]

-- FACT TABLE ------------------------------------------------------- (105 minutes)
DROP TABLE IF EXISTS [DW1].[FACT]
CREATE TABLE  [DW1].[FACT](
		[TimeID] INT,
		[SpaceID] INT, 
		[E0] FLOAT
		)

--CREATE INDEX POC_DW1_FACT
--ON [DW1].[FACT] ([TimeID], [SpaceID])
--INCLUDE([E0]);

CREATE INDEX POC_DW1_FACT
	ON [DW1].[FACT] ([TimeID], [SpaceID])
    INCLUDE([E0]);

INSERT INTO [DW1].[FACT]
	SELECT *
	FROM [DW3].[FACT]


	
SELECT TOP(10000) * FROM [DW1].[FACT]