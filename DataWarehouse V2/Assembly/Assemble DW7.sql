-- -- ADDING A NON-CLUSTERED POC INDEX ON [DW6]
-- -- NOT INGESTING THE TABLE ALL OVER AGAIN.

CHECKPOINT
DBCC SHRINKFILE (N'CLIMATE_DATA_V1_log' , 0, TRUNCATEONLY)

CREATE  INDEX [DW7_POC_INDEX]
ON [DW6].[OBT] ([GridID], [E0]) INCLUDE ([Year], [Month], [Day])

CHECKPOINT
DBCC SHRINKFILE (N'CLIMATE_DATA_V1_log' , 0, TRUNCATEONLY)

