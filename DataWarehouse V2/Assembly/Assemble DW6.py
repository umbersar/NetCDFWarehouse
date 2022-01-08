# DW6 is a STAR/OBT hybrid in rowstore. The OBT contains [Year], [Month], [Day] columns alongside a [GridID] column
# that joins to a dimension table containing latitudes and longitudes. A clustered index is defined over the 
# [Year], [Month], [Day], [GridID] columns.

import pyodbc
import numpy as np
import pandas as pd
from datetime import datetime as dt
import sys
import os

def Print_Duration(start_time, update):
    ''' Report the duration and progess throughout an iteration'''
    elapsed_seconds = (dt.now() - start_time).seconds
    elapsed_hours = elapsed_seconds // 3600
    elapsed_seconds = elapsed_seconds - (elapsed_hours * 3600)
    elapsed_minutes = elapsed_seconds // 60
    elapsed_seconds = elapsed_seconds - (elapsed_minutes * 60)
    print("\t{:02}:{:02}:{:02} : {}".format(elapsed_hours, elapsed_minutes, elapsed_seconds, update))
    

# CREATE A LIST OF RELEVANT FILENAMES
InputFolder = "D:\CSIRO\STAR-SCHEMA V1"
FileList = [FileName for FileName in os.listdir(InputFolder) if "FACT" in FileName]
FileList.sort()
    
T1 = dt.now()
print("\t{} : Assembly Started".format(dt.now()))

# CONNECT TO SQL SERVER
CONNECT = pyodbc.connect('DRIVER={SQL Server};\
                        SERVER=MAGICAL-BM;\
                        DATABASE=CLIMATE_DATA_V1;\
                        Trusted_Connection=yes')
cursor = CONNECT.cursor()
print("\t{} : Connected to Server".format(dt.now()))


# DEFINE OBT
cursor.execute(" \
    DROP TABLE IF EXISTS [DW6].[OBT] \
    CREATE TABLE  [DW6].[OBT]( \
    		[ID] BIGINT IDENTITY(1,1), -- \
    		[Year] SMALLINT,\
    		[Month] TINYINT,\
    		[Day] TINYINT,\
    		[GridID] INT,\
    		[E0] FLOAT, \
    		CONSTRAINT CL_ROWSTORE_DW6FACT PRIMARY KEY ([Year], [Month], [Day], [Latitude], [Longitude]) \
            ); \
    \
    DROP VIEW IF EXISTS [DW6_OBT] \
    ")
CONNECT.commit()

# CREATE VIEW ON OBT WITHOUT THE ID COLUMN SO THAT ORDER IS PRESERVED DURING INSERT
cursor.execute("\
    CREATE VIEW DW6_OBT ([Year], [Month], [Day], [GridID], [E0]) AS \
     	SELECT [Year], [Month], [Day], [GridID], [E0] FROM [DW6].[OBT]; \
    GO \
    ")
CONNECT.commit()
print("\t{} : OBT Created".format(dt.now()))
Print_Duration(T1, "ASSEMBLY DURATION =========================================")

for FileName in FileList:
    T2 = dt.now()
    print("\t{} : Starting on '{}'".format(dt.now(), InputFolder + "\\" + FileName))
    
    # DEFINE STAGING TABLE IN STAR-SCHEMA FACT TABLE FORMAT
    cursor.execute(" \
            CREATE TABLE  [DW6].[LOAD]( \
        		[ID] BIGINT IDENTITY(1,1), \
        		[DateID] SMALLINT, \
        		[GridID] INT,  \
        		[E0] FLOAT) \
            ")
    CONNECT.commit()
     
    # CREATE VIEW ON STAGING TABLE WITHOUT THE ID COLUMN SO THAT ORDER IS PRESERVED DURING BULK INSERT
    cursor.execute(" \
                CREATE VIEW DW6_LOAD ([DateID], [GridID], [E0]) AS \
                SELECT [DateID], [GridID], [E0] FROM [DW6].[LOAD]; \
            ")
    CONNECT.commit()
    
    
    # BULK INSERT FROM CSV FILE INTO VIEW ON STAGING TABLE
    cursor.execute(" \
        BULK INSERT [DW6_LOAD] \
         	FROM '{}' \
         	WITH(  \
        		FIRSTROW = 2, \
        		FIELDTERMINATOR = ',', \
        		ROWTERMINATOR = '\n', \
        		KEEPNULLS \
        		) \
            ".format(InputFolder + "\\" + FileName))
    CONNECT.commit()
    Print_Duration(T2, "BULK INSERT to staging table complete")
            
    # CLEAR TRANSACTION LOG
    cursor.execute(" \
        CHECKPOINT \
        DBCC SHRINKFILE (N'CLIMATE_DATA_V1_log' , 0, TRUNCATEONLY) \
            ")
    CONNECT.commit()
        
    
    # JOIN STAGING TABLE WITH TIME AND GRID DIMENSION COLUMNS AND INSERT TO OBT
    cursor.execute(" \
        INSERT INTO [DW6_OBT] \
     	SELECT [Year], [Month], [Day], [GridID], [E0] \
     	FROM ( \
    		[DW6].[LOAD] AS [Fact] \
            \
    		JOIN  [DW6].[TIME2] AS [Time] \
    		ON [Fact].[DateID] = [Time].[DateID] \
    		) \
            ")
    CONNECT.commit()
    Print_Duration(T2, "Star JOIN and INSERT to OBT Complete")
              
    
    # CLEAR STAGING TABLE AND VIEW
    cursor.execute(" \
        DROP TABLE IF EXISTS [DW6].[LOAD] \
     	DROP VIEW IF EXISTS DW6_LOAD \
            ")
    CONNECT.commit()
        
    # CLEAR TRANSACTION LOG
    cursor.execute(" \
        CHECKPOINT \
     	DBCC SHRINKFILE (N'CLIMATE_DATA_V1_log' , 0, TRUNCATEONLY) \
            ")
    CONNECT.commit()
    
    Print_Duration(T1, "ASSEMBLY DURATION =========================================")
        
    
    
    