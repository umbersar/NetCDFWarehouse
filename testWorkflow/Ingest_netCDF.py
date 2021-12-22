# -*- coding: utf-8 -*-
"""
Created on Wed Nov 10 16:37:34 2021

@author: sor035
"""

# netCDF_to_table()
import xarray as xr
import pandas as pd
from datetime import datetime as dt
DS = xr.open_dataset("e0_avg_1911.nc")

DS = DS.sel(latitude=slice(-30, -35))
DS = DS.sel(longitude=slice(145, 150))

# CREATE PYTHON LIST ARRAY FROM DATA SET
DA = []
DA_size = len(DS.time.values) * len(DS.longitude.values) * len(DS.latitude.values)
DA_step = 0
start_time = dt.now()

print("\n EXTRACTING NETCDF")
for time in range(len(DS.time.values)):
    for long in range(len(DS.longitude.values)):
        for lat in range(len(DS.latitude.values)):
            DA.append( 
                [DS.time.values[time], DS.longitude.values[long], DS.latitude.values[lat], DS.e0_avg.values[time][lat][long]])
            DA_step = DA_step + 1
            
            # PRINT UPDATES THROUGHOUT
            if ((DA_step % 200000) == 0) or (DA_step == DA_size ):
                
                elapsed_seconds = (dt.now() - start_time).seconds
                
                elapsed_hours = elapsed_seconds // 3600
                elapsed_seconds = elapsed_seconds - (elapsed_hours * 3600)
                
                elapsed_minutes = elapsed_seconds // 60
                elapsed_seconds = elapsed_seconds - (elapsed_minutes * 60)
                
                print("{:02}:{:02}:{:02} - {:5.2f}% extracted".format(elapsed_hours, elapsed_minutes, elapsed_seconds, (DA_step/ DA_size) * 100))
                
              
# CREATE PANDAS DATAFRAME FROM PYTHON LIST
DF = pd.DataFrame(DA, columns=["TIME", "LONGITUDE", "LATITUDE", "VARIABLE"])
              

## LOAD DATAFRAMES INTO SQL SERVER TABLE
import pyodbc
connStr = pyodbc.connect('DRIVER={SQL Server};\
                        SERVER=MAGICAL-BM;\
                        DATABASE=AdventureWorks2019;\
                        Trusted_Connection=yes')
cursor = connStr.cursor()

DA_step = 0
start_time = dt.now()
print("\n LOADING INTO SQL SERVER")
for index,row in DF.iterrows():
    cursor.execute("INSERT INTO dbo.e0_avg_1911([Time],[Longitude],[Latitude],[Variable]) values (?, ?, ?, ?)",
                   row['TIME'],
                   row['LONGITUDE'],
                   row['LATITUDE'],
                   row['VARIABLE']) 
    connStr.commit()
    
    # PRINT UPDATES THROUGHOUT
    DA_step = DA_step + 1
    if ((DA_step % 200000) == 0) or (DA_step == DA_size ):
                
                elapsed_seconds = (dt.now() - start_time).seconds
                
                elapsed_hours = elapsed_seconds // 3600
                elapsed_seconds = elapsed_seconds - (elapsed_hours * 3600)
                
                elapsed_minutes = elapsed_seconds // 60
                elapsed_seconds = elapsed_seconds - (elapsed_minutes * 60)
                
                print("{:02}:{:02}:{:02} - {:5.2f}% loaded".format(elapsed_hours, elapsed_minutes, elapsed_seconds, (DA_step/ DA_size) * 100))
    
    
cursor.close()
connStr.close()
                    