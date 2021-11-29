# -*- coding: utf-8 -*-
"""
Created on Fri Nov 19 14:39:22 2021

@author: sor035
"""


import pyodbc
import os
from datetime import datetime as dt

InputFolder = "C:\AWRA_nc_dataset\AWRA-L_historical_data\e0\E0 CSV"

def Print_Duration(start_time, update):
    ''' Report the duration and progess throughout an iteration'''
    elapsed_seconds = (dt.now() - start_time).seconds
    elapsed_hours = elapsed_seconds // 3600
    elapsed_seconds = elapsed_seconds - (elapsed_hours * 3600)
    elapsed_minutes = elapsed_seconds // 60
    elapsed_seconds = elapsed_seconds - (elapsed_minutes * 60)
    print("\t{:02}:{:02}:{:02} - {}".format(elapsed_hours, elapsed_minutes, elapsed_seconds, update))

# Connect to SQL Server
CONNECT = pyodbc.connect('DRIVER={SQL Server};\
                        SERVER=MAGICAL-BM;\
                        DATABASE=CLIMATE_DATA_V1;\
                        Trusted_Connection=yes')
cursor = CONNECT.cursor()

# Build a list of data files to be pushed
CSVlist = []
for FileName in os.listdir(InputFolder):
    if (FileName[-4:] == '.csv') and (FileName[-8:-4].isnumeric()):
        CSVlist.append(FileName)


# Iterate through list of files and push them into SQL server one at a time 
FolderStartTime = dt.now()
print(FolderStartTime, " LOADING STARTED ---------------------------")
for FileName in CSVlist:
    
    # Derive relevant Schema and TableNames
    Year = FileName[-8:-4]
    VariableName = (FileName.split("_")[0])
    SchemaName = VariableName.upper()
    TableName = "Y"+Year
    TableName_Full = "[{}].[{}]".format(SchemaName, TableName)     
    ViewName = SchemaName+"_"+TableName
    FilePath = InputFolder+"\\"+FileName

    # Check if the table already exists
    cursor.execute("\
        SELECT * FROM [information_schema].[tables] \
        WHERE TABLE_SCHEMA = '{}' AND TABLE_NAME = '{}'".format(SchemaName, TableName))
    TableExists = cursor.fetchone()
    
    # Skip file if the corresponding table name already exists in SQL server
    if TableExists:
        Print_Duration(FolderStartTime, ("FILE "+ FileName + " SKIPPED: a table with name " +TableName_Full + " already exists in SQL server\n"))
        

    else:
        Print_Duration(FolderStartTime, ("LOADING " + FileName + " INTO SQL SERVER"))
        T1 = dt.now()
        print("\t STARTED: ", T1.strftime("%H:%M:%S %p"))

        cursor.execute("\
            IF NOT EXISTS ( \
            SELECT  * FROM    [information_schema].[schemata] \
            WHERE [SCHEMA_NAME] = '{}' ) \
            EXEC('CREATE SCHEMA [{}]');"\
                .format(SchemaName, SchemaName))
        
        cursor.execute("DROP VIEW IF EXISTS {};".format(ViewName))
        CONNECT.commit()
        
        # Create the empty table
        cursor.execute("CREATE TABLE {} (\
                        [DataID] INT IDENTITY(1,1), \
                        [Variable] FLOAT \
                        );".format(TableName_Full))
        CONNECT.commit()
        
        # Create the empty table view
        cursor.execute("CREATE VIEW {} (\
                        [Variable]) AS \
                            (SELECT [Variable] FROM {});".format(ViewName, TableName_Full))
        CONNECT.commit()
        T2 = dt.now()
        
        # Bulk insert the CSV data into the empty view
        cursor.execute("BULK INSERT {} \
                        FROM '{}' \
                        WITH( \
                            FIRSTROW = 2, \
                            FIELDTERMINATOR = ',', \
                            ROWTERMINATOR = '\n', \
                            KEEPNULLS \
                            )".format(ViewName, FilePath))
        CONNECT.commit()
        
        # Delete the view, as changed are automatically in the table now
        cursor.execute("DROP VIEW IF EXISTS {};".format(ViewName))
        CONNECT.commit()
        Print_Duration(T1, "Table Loaded\n")



CSVlist = []
for FileName in os.listdir(InputFolder):
    if (FileName[-4:] == '.csv') and (FileName[:3] == 'DIM'):
        CSVlist.append(FileName)

for FileName in CSVlist:
    
    SchemaName = "DIMENSION"
    TableName = (FileName.split(".")[0]).split("_")[1]
    TableName_Full = "[{}].[{}]".format(SchemaName, TableName)       
    ViewName = SchemaName+"_"+TableName
    FilePath = InputFolder+"\\"+FileName
    

    # Check if the table already exists
    cursor.execute("\
        SELECT * FROM [information_schema].[tables] \
        WHERE TABLE_SCHEMA = '{}' AND TABLE_NAME = '{}'".format(SchemaName, TableName))
    TableExists = cursor.fetchone()
    
    # Skip file if the corresponding table name already exists in SQL server
    if TableExists:
        Print_Duration(FolderStartTime, ("FILE " + FileName + " SKIPPED: a table with name " + TableName_Full + " already exists in SQL server\n"))
        
    else:
        Print_Duration(FolderStartTime, ("LOADING " + FileName + " INTO SQL SERVER"))
        T1 = dt.now()
        print("\t STARTED: ", T1.strftime("%H:%M:%S %p"))
        
        # Create the schema if it doesn't already exist
        cursor.execute("\
            IF NOT EXISTS ( \
            SELECT  * FROM    [information_schema].[schemata] \
            WHERE [SCHEMA_NAME] = '{}' ) \
            EXEC('CREATE SCHEMA [{}]');"\
                .format(SchemaName, SchemaName))
        
        # Specify table formats for either spatial or temporal dimensions
        if "SPACE" in TableName.upper():
            cursor.execute("CREATE TABLE {} (\
                            [DataID] INT IDENTITY(1,1), \
                            [SpaceID] INT, \
                            [Longitude] DECIMAL(5,2) ,\
                            [Latitude] DECIMAL(5,2) ,\
                            );".format(TableName_Full))
            CONNECT.commit()
            
            cursor.execute("CREATE VIEW {} (\
                            [SpaceID], [Longitude], [Latitude]) AS \
                            (SELECT [SpaceID], [Longitude], [Latitude] FROM {});".format(ViewName, TableName_Full))
                            
        elif "TIME" in TableName.upper():
            cursor.execute("CREATE TABLE {} (\
            [DataID] INT IDENTITY(1,1), \
            [Date] DATETIME \
            );".format(TableName_Full))
            CONNECT.commit()
    
            cursor.execute("CREATE VIEW {} (\
                    [Date]) AS \
                    (SELECT [Date] FROM {});".format(ViewName, TableName_Full))
        CONNECT.commit()
        
        cursor.execute("BULK INSERT {} \
                        FROM '{}' \
                        WITH( \
                            FIRSTROW = 2, \
                            FIELDTERMINATOR = ',', \
                            ROWTERMINATOR = '\n', \
                            KEEPNULLS \
                            )".format(ViewName, FilePath))
        CONNECT.commit()
        
        cursor.execute("DROP VIEW IF EXISTS {};".format(ViewName))
        CONNECT.commit()
        Print_Duration(T1, "Table Loaded\n")

# Close connection to SQL server
cursor.close()
CONNECT.close()
Print_Duration(FolderStartTime, ("\tLOADING COMPLETED ---------------------------"))