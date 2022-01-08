# DW4 is a rowstore OBT with split integer dateformat. A clustered index in placed over the 
# [Year], [Month], [Day], [Latitude], [Longitude] columns

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
    DROP TABLE IF EXISTS [DW4].[OBT] \
    CREATE TABLE  [DW4].[OBT]( \
    		[ID] BIGINT IDENTITY(1,1), -- \
    		[Year] SMALLINT,\
    		[Month] TINYINT,\
    		[Day] TINYINT,\
    		[Latitude] DECIMAL(5,2),\
    		[Longitude] DECIMAL(5,2),\
    		[E0] FLOAT, \
    		CONSTRAINT CL_ROWSTORE_DW4FACT PRIMARY KEY ([Year], [Month], [Day], [Latitude], [Longitude]) \
            ); \
    \
    DROP VIEW IF EXISTS [DW4_OBT] \
    ")
CONNECT.commit()

# CREATE VIEW ON OBT WITHOUT THE ID COLUMN SO THAT ORDER IS PRESERVED DURING INSERT
cursor.execute("\
    CREATE VIEW DW4_OBT ([Year], [Month], [Day], [Latitude], [Longitude], [E0]) AS \
     	SELECT [Year], [Month], [Day], [Latitude], [Longitude], [E0] FROM [DW4].[OBT]; \
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
            CREATE TABLE  [DW4].[LOAD]( \
        		[ID] BIGINT IDENTITY(1,1), \
        		[DateID] SMALLINT, \
        		[GridID] INT,  \
        		[E0] FLOAT) \
            ")
    CONNECT.commit()
     
    # CREATE VIEW ON STAGING TABLE WITHOUT THE ID COLUMN SO THAT ORDER IS PRESERVED DURING BULK INSERT
    cursor.execute(" \
                CREATE VIEW DW4_LOAD ([DateID], [GridID], [E0]) AS \
                SELECT [DateID], [GridID], [E0] FROM [DW4].[LOAD]; \
            ")
    CONNECT.commit()
    
    
    # BULK INSERT FROM CSV FILE INTO VIEW ON STAGING TABLE
    cursor.execute(" \
        BULK INSERT [DW4_LOAD] \
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
        INSERT INTO [DW4_OBT] \
     	SELECT [Year], [Month], [Day], [Latitude], [Longitude], [E0] \
     	FROM ( \
    		[DW4].[LOAD] AS [Fact] \
            \
    		JOIN  [DW4].[TIME2] AS [Time] \
    		ON [Fact].[DateID] = [Time].[DateID] \
            \
    		JOIN  [DW4].[GRID] AS [Grid] \
    		ON [Fact].[GridID] = [Grid].[GridID] \
    		) \
            ")
    CONNECT.commit()
    Print_Duration(T2, "Star JOIN and INSERT to OBT Complete")
              
    
    # CLEAR STAGING TABLE AND VIEW
    cursor.execute(" \
        DROP TABLE IF EXISTS [DW4].[LOAD] \
     	DROP VIEW IF EXISTS DW4_LOAD \
            ")
    CONNECT.commit()
        
    # CLEAR TRANSACTION LOG
    cursor.execute(" \
        CHECKPOINT \
     	DBCC SHRINKFILE (N'CLIMATE_DATA_V1_log' , 0, TRUNCATEONLY) \
            ")
    CONNECT.commit()
    
    Print_Duration(T1, "ASSEMBLY DURATION =========================================")
        
    
    
    