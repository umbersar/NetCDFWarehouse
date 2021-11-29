# -*- coding: utf-8 -*-
"""
Created on Thu Nov 18 15:09:18 2021

@author: sor035
"""
# netCDF_to_table()
import xarray as xr
import pandas as pd
import numpy as np
import os
from datetime import datetime as dt

InputFolder = "C:\AWRA_nc_dataset\AWRA-L_historical_data\e0\RAW NETCDF"
OutputFolder = "C:\AWRA_nc_dataset\AWRA-L_historical_data\e0\CSV FILES"
        
def Print_Duration(start_time, update):
    ''' Report the duration and progess throughout an iteration'''
    elapsed_seconds = (dt.now() - start_time).seconds
    elapsed_hours = elapsed_seconds // 3600
    elapsed_seconds = elapsed_seconds - (elapsed_hours * 3600)
    elapsed_minutes = elapsed_seconds // 60
    elapsed_seconds = elapsed_seconds - (elapsed_minutes * 60)
    print("\t{:02}:{:02}:{:02} - {}".format(elapsed_hours, elapsed_minutes, elapsed_seconds, update))
    

# Filter out any files that are not .nc
NClist = []
for FileName in os.listdir(InputFolder):
    if FileName[-3:] == '.nc':
        NClist.append(FileName)
        
# This appears to be optimum for daily files
BatchSize = 20
FolderStartTime = dt.now()
        
        
# Iterate through .nc files in input folder
for FileName in NClist:
        
    # Extract as xarray dataset
    DS = xr.open_dataset(InputFolder+"\\"+FileName)
        
    # Extract Metadata for naming etc.
    ShortName = getattr(getattr(DS, (DS.var_name)), "name")
    LongName = getattr(getattr(DS, (DS.var_name)), "long_name")
    OutputName = FileName.split('.')[0]
    Unit = getattr(getattr(DS, (DS.var_name)), "units")
    
    # Determine spatial dimensions from the first .nc file.
    if FileName == NClist[0]:
        DimLon = len(DS.longitude.values)
        DimLat = len(DS.latitude.values)
        DimSpace = DimLon * DimLat
        
        StartTime1 = dt.now()
        print(StartTime1, " EXTRACTION STARTED ---------------------------")
        
        
    # Check if the file has already been extracted
    if (OutputName + ".csv") in os.listdir(OutputFolder):
        print("FILE", FileName, "ALREADY EXTRACTED")
        
    else:
        # if not((DimLon = len(DS.longitude.values)) and \
        #         (DimLat = len(DS.latitude.values)) and \
        #          (DimTime = len(DS.time.values))):
        #     raise
        
        # Print metadata
        Print_Duration(FolderStartTime, ("\t EXTRACTING: " + FileName + " INTO CSV \n"))
        
        
        ST1 = dt.now()
        print("\t STARTED: ", ST1.strftime("%H:%M:%S %p"))
        DimTime = len(DS.time.values) #Due to leap years, this will not be consistent between files
        
        # Iterate through the file along the time dimension
        for step in range(DimTime):
            TimeStep = DS.time.values[step]
            
            # At each timestep, extract the 2D gridded data and flatten it into a 1D array.
            # This method appends each (latitude) row to the one above it, i.e. the 1D array is assembled from
            # East to West and then North to South. 
            DataStep = (getattr(DS, ShortName)).values[step,:,:]
            DataStep = np.reshape(DataStep, DimSpace).astype('float32')
            
        # In the first timestep, create arrays to store data from each step
            if step == 0:
                Batch = DataStep
                BatchStep = 1
                Full = np.array([], dtype='float32')
                   
        # At the last timestep, append the imcomplete batch to full set
            elif step+1 == DimTime:
                Batch = np.append(Batch, DataStep)
                Full = np.append(Full, Batch)
                        
        # When a batch is filled up, empty it into the full set. 
            elif BatchStep == BatchSize:
                Full = np.append(Full, Batch)
                Batch = DataStep
                BatchStep = 1

        # Otherwise, append timestep values to the current batch and repeat
            else:
                Batch = np.append(Batch, DataStep)
                BatchStep = BatchStep + 1
                
        # Convert to pandas DataFrame
        DF = pd.DataFrame({"VARIABLE":Full})
        Print_Duration(ST1, "NetCDF to DataFrame")

        # Write to CSV using built in function 
        ST2 = dt.now() 
        DF.to_csv(((OutputFolder+"\\"+OutputName+".csv")), index = False, chunksize=100000, compression=None )
        Print_Duration(ST2, "DataFrame to CSV")

        # Correct NULL value format, for input to SQL server
        ST3 = dt.now() 
        CSV = open((OutputFolder+"\\"+OutputName+".csv"), 'r')
        TXT = CSV.read()
        CSV.close()
        TXT = TXT.replace("\"\"","")
        CSV = open((OutputFolder+"\\"+OutputName+".csv"), 'w')
        CSV.write(TXT)
        CSV.close()
        Print_Duration(ST3, "CSV cleaning")
        Print_Duration(ST1, "Total Duration")
  
    
  
DS = xr.open_dataset("e0_avg_1911.nc")  
  
# Repeat steps above to extract a single CSV for longitude and latitude positions corresponding to the data
Lon,Lat = np.meshgrid(DS.longitude.values, DS.latitude.values)
Lon = Lon.flatten()
Lat = Lat.flatten()
# Print_Duration(FolderStartTime, ("\t EXTRACTING LAT & LON INTO CSV \n"))
        
# ST1 = dt.now()
# print("\t STARTED: ", ST1.strftime("%H:%M:%S %p"))
DimTime = len(DS.time.values) #Due to leap years, this will not be consistent between files

Lon = np.tile(Lon, DimTime)
Lat = np.tile(Lat, DimTime)

# Convert to pandas DataFrame
DF = pd.DataFrame({"LONGITUDE":Lon, "LATITUDE":Lat})

# Write to CSV using built in function 
ST2 = dt.now() 
DF.to_csv(((OutputFolder+"\\Spatial_Dimension.csv")), index = False, chunksize=100000, compression=None )
Print_Duration(ST2, "DataFrame to CSV")


# Print_Duration(ST1, "Total Duration")

