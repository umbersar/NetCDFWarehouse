# -*- coding: utf-8 -*-
"""
Created on Tue Nov 30 12:36:05 2021

@author: sor035
"""

import pyodbc
import numpy as np
import pandas as pd
from datetime import datetime as dt
import sys

def Print_Duration(start_time, update):
    ''' Report the duration and progess throughout an iteration'''
    elapsed_seconds = (dt.now() - start_time).seconds
    elapsed_hours = elapsed_seconds // 3600
    elapsed_seconds = elapsed_seconds - (elapsed_hours * 3600)
    elapsed_minutes = elapsed_seconds // 60
    elapsed_seconds = elapsed_seconds - (elapsed_minutes * 60)
    print("\t{:02}:{:02}:{:02} - {}".format(elapsed_hours, elapsed_minutes, elapsed_seconds, update))
    
def Table_Exists(SchemaName, TableName):
    ''' Return a boolean value indicating whether a table with the specified schema and name exists in the database'''
    cursor.execute("\
        SELECT * FROM [information_schema].[tables] \
        WHERE TABLE_SCHEMA = '{}' AND TABLE_NAME = '{}'".format(SchemaName, TableName))
    if cursor.fetchone() == None:
        return False
    else:
        return True


# Connect to SQL Server
CONNECT = pyodbc.connect('DRIVER={SQL Server};\
                        SERVER=MAGICAL-BM;\
                        DATABASE=CLIMATE_DATA_V1;\
                        Trusted_Connection=yes')
cursor = CONNECT.cursor()

TargetSchema = ['E0']
BatchSize = 1


# Check whether the dimensions table exists
if not Table_Exists("DIMENSION", "ALL"):
    
    # If the constituent space and time dimension tables exist, join them
    if (Table_Exists("DIMENSION", "TIME") and Table_Exists("DIMENSION", "SPACE")):
        T1 = dt.now()
        cursor.execute("\
                       ;WITH [COORDINATE_TABLE] ([DataID], [Month], [Day], [SpaceID], [Latitude], [Longitude])  AS ( \
                           SELECT [DS].[DataID], [Month], [Day], [SpaceID], [Latitude], [Longitude] \
                           FROM \
                               [DIMENSION].[SPACE] AS [DS] \
                               JOIN \
                               [DIMENSION].[TIME] AS [DT] \
                               ON [DS].[DataID] = [DT].[DataID] \
                           )\
                        \
                        SELECT * INTO [DIMENSION].[ALL] \
                        FROM [COORDINATE_TABLE];\
                        ")
        CONNECT.commit()
        Print_Duration(T1, "\t[DIMENSION].[ALL] created")
        
    # Otherwise end the script and return an error
    else:
        if not Table_Exists("DIMENSION", "TIME"):
            print("\tRequired table [DIMENSION].[TIME] does not exist in the database")
            
        if not Table_Exists("DIMENSION", "SPACE"):
            print("\tRequired table [DIMENSION].[SPACE] does not exist in the database")
            
        print("\n\tTry again after ingesting all dimension tables")
        sys.exit()


# Create chronologically ordered list of Table Names, for the years that are consistent across all variables/schema
DBTables = []
#Extract a list of all tables within each schema
for SchemaName in TargetSchema:
    print(SchemaName)
    cursor.execute("\
            SELECT * FROM [information_schema].[tables] \
            WHERE TABLE_SCHEMA = '{}'".format(SchemaName))
    DBTables.append(cursor.fetchall())

# Iterate through the annual table names in each schema, and combine them into a dataframe using an inner join
# so that only years for which each schema has a table are combined. 
for SchemaIndex in range(len(DBTables)): 
    TableName = np.array([], dtype='str')
    Year = np.array([], dtype='int')
    
    for Table in DBTables[SchemaIndex]:
        TableName = np.append(TableName,  "[{}].[{}]".format(Table[1], Table[2]))
        Year = np.append(Year,  int(Table[2][1:]))
    
    if SchemaIndex == 0:
        DF = pd.DataFrame({"Year":Year, TargetSchema[SchemaIndex]:TableName})
        
    else:
        DF2 = pd.DataFrame({"Year":Year, TargetSchema[SchemaIndex]:TableName})
        DF =  DF.join(DF2.set_index('YEAR'), on="YEAR", how="inner")
DF = DF.sort_values("Year", ignore_index=True)        


for index, row in DF.iterrows():
    # TableName = row['TableName']
    print(row)
    
#     # JOIN TO DIMENSION TABLE
    
#     # UNION TO EXISTING SET
        

# A = pd.DataFrame({"YEAR":[1, 2, 3, 4, 5], "TEXT1":['A1', 'B1', 'C1', 'D1', 'E1']})
# B = pd.DataFrame({"YEAR":[3, 4, 5, 6, 7], "TEXT2":['C2', 'D2', 'E2', 'F2', 'G2']})
        
    
        