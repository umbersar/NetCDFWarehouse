# -*- coding: utf-8 -*-
"""
Created on Fri Nov 19 14:39:22 2021

@author: sor035
"""


import pyodbc
import os
from datetime import datetime as dt

InputFolder = "C:\AWRA_nc_dataset\AWRA-L_historical_data\e0\CSV FILES"


CONNECT = pyodbc.connect('DRIVER={SQL Server};\
                        SERVER=MAGICAL-BM;\
                        DATABASE=CLIMATE_DATA_V1;\
                        Trusted_Connection=yes')
cursor = CONNECT.cursor()


NClist = []
for FileName in os.listdir(InputFolder):
    if (FileName[-4:] == '.csv') and (FileName[-8:-4].isnumeric()):
        NClist.append(FileName)

NClist = NClist[0:2]
        
FolderStartTime = dt.now()

for FileName in NClist:
    
    Year = FileName[-8:-4]
    VariableName = (FileName.split("_")[0])
    SchemaName = VariableName.upper()
    TableName = "Y"+Year
    TableName_Full = "[{}].[{}]".format(SchemaName, TableName)     
    ViewName = SchemaName+"_"+TableName
    FilePath = InputFolder+"\\"+FileName

    cursor.execute("DROP TABLE IF EXISTS {};".format(TableName_Full))
    cursor.execute("DROP VIEW IF EXISTS {};".format(ViewName))
    CONNECT.commit()
    
    cursor.execute("CREATE TABLE {} (\
                    [DataID] INT IDENTITY(1,1), \
                    [Variable] FLOAT \
                    );".format(TableName_Full))
    CONNECT.commit()
    
    cursor.execute("CREATE VIEW {} (\
                    [Variable]) AS \
                        (SELECT [Variable] FROM {});".format(ViewName, TableName_Full))
    CONNECT.commit()
    
    ST = dt.now()
    print(ST, "EXECUTING")
    cursor.execute("BULK INSERT {} \
                    FROM '{}' \
                    WITH( \
                        FIRSTROW = 2, \
                        FIELDTERMINATOR = ',', \
                        ROWTERMINATOR = '\n', \
                        KEEPNULLS \
                        )".format(ViewName, FilePath))
    
    print(dt.now()-ST)
    ST = dt.now()
    print(ST, "COMMITTING")
    CONNECT.commit()
    print(dt.now()-ST)
    
    cursor.execute("DROP VIEW IF EXISTS {};".format(ViewName))
    CONNECT.commit()

ST = dt.now()
print(ST, "CLOSING CURSOR")
cursor.close()
print(dt.now()-ST)

ST = dt.now()
print(ST, "CLOSING CONNECT")
CONNECT.close()
print(dt.now()-ST)