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

InputFolder = "C:\AWRA_nc_dataset\AWRA-L_historical_data\e0\RAW NETCDF\TEST"
OutputFolder = "C:\AWRA_nc_dataset\AWRA-L_historical_data\e0\E0 CSV"
        
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
    Year = int(FileName[-7:-3])
    LeapYear = (Year % 4 == 0)
    Unit = getattr(getattr(DS, (DS.var_name)), "units")
        
    # Determine spatial dimensions from the first .nc file.
    if FileName == NClist[0]:
        DimLon = DS.longitude.values
        DimLat = DS.latitude.values
        DimSpace = len(DimLon) * len(DimLat)
        DimTimeStep = np.unique(np.diff(DS.time.values).astype('timedelta64[s]'))
        
        # Check that timesteps are the same size throughout the file.
        if len(DimTimeStep) !=1:
            print("FILE SKIPPED: Inconsistent Timesteps")
            continue
        StartTime1 = dt.now()
        print(StartTime1, " EXTRACTION STARTED ---------------------------")
    
    
    # Check that the spatial dimensions and timestep are consistent with the other files
    if FileName != NClist[0]:
        if not(np.array_equal(DimLon, DS.longitude.values) or np.array_equal(DimLat, DS.latitude.values)):
            print("FILE SKIPPED: different spatial dimensions from other files")
            continue
        
        if len(np.unique(np.diff(DS.time.values).astype('timedelta64[s]'))) != 1:
            print("FILE SKIPPED: inconsistent timesteps")
            continue
        
        elif DimTimeStep != np.unique(np.diff(DS.time.values).astype('timedelta64[s]')):
            print("FILE SKIPPED: different timestep from other files")
            continue


    # Check if the file has already been extracted
    if (OutputName + ".csv") in os.listdir(OutputFolder):
        print("\n\tFILE", FileName, "ALREADY EXTRACTED\n")
        continue
        
        
    else:
        Print_Duration(FolderStartTime, ("EXTRACTING: " + FileName + " INTO CSV"))
        
        ST1 = dt.now()
        print("\t STARTED: ", ST1.strftime("%H:%M:%S %p"))
        DimTime = len(DS.time.values) 
        
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
                
        # For non-leap years, this block inserts a days worth of NaN values just before March 1st, so that all outputs have the same dimensions.
        # This simplifies many of the queries in SQL server.
        if LeapYear == False: 
            DayLength = int(np.timedelta64(1, 'D').astype('timedelta64[s]') / DimTimeStep.astype('timedelta64[s]')) * DimSpace
            Feb29 = np.empty( DayLength)
            Feb29[:] = np.nan
            Full = np.insert(Full, (DayLength * (31+28)), Feb29)
        
        # Convert to pandas DataFrame
        DF = pd.DataFrame({"VARIABLE":Full})
        Print_Duration(ST1, "NetCDF to DataFrame")

        # Write to CSV using built in function 
        ST2 = dt.now() 
        DF.to_csv(((OutputFolder+"\\"+OutputName+".csv")), index = False, chunksize=100000, compression=None )
        Print_Duration(ST2, "DataFrame to CSV")

        # Correct NULL value format, for input to SQL server:
        # By default NaN is written to CSV as "", this block replaces them with a blank space
        ST3 = dt.now() 
        CSV = open((OutputFolder+"\\"+OutputName+".csv"), 'r')
        TXT = CSV.read()
        CSV.close()
        TXT = TXT.replace("\"\"","")
        CSV = open((OutputFolder+"\\"+OutputName+".csv"), 'w')
        CSV.write(TXT)
        CSV.close()
        Print_Duration(ST3, "CSV cleaning")
        Print_Duration(ST1, "Total Duration\n")
        DS.close()
  
    


# Check if the Spatial Dimensions have already been extracted
if ("DIM_SPACE.csv") in os.listdir(OutputFolder):
    print("\n\t DIMENSIONS ALREADY EXTRACTED\n")
    Print_Duration(FolderStartTime, ("\t EXTRACTION COMPLETED ---------------------------"))
    exit()

# Find a file from a leap year
for FileName in NClist:
    Year = int(FileName[-7:-3])
    if (Year % 4 == 0):
        break
    
# Repeat steps above to extract a single CSV for longitude and latitude positions corresponding to the data  
DS = xr.open_dataset(InputFolder+"\\"+FileName) 

Lon,Lat = np.meshgrid(DS.longitude.values, DS.latitude.values)
Lon = Lon.flatten()
Lat = Lat.flatten()
SpaceID = np.arange(len(Lon)) + 1
Print_Duration(FolderStartTime, ("EXTRACTING LAT & LON INTO CSV"))
        
ST1 = dt.now()
print("\t STARTED: ", ST1.strftime("%H:%M:%S %p"))
DimTime = len(DS.time.values) 
Lon = np.tile(Lon, DimTime)
Lat = np.tile(Lat, DimTime)
SpaceID = np.tile(SpaceID, DimTime)

# Convert to pandas DataFrame
DF = pd.DataFrame({"SPACEID":SpaceID, "LONGITUDE":Lon, "LATITUDE":Lat})
Print_Duration(ST1, "NetCDF to DataFrame")

# Write to CSV using built in function 
ST2 = dt.now() 
DF.to_csv(((OutputFolder+"\\DIM_SPACE.csv")), index = False, chunksize=100000, compression=None )
Print_Duration(ST2, "DataFrame to CSV")
Print_Duration(ST1, "Total Duration")

Print_Duration(FolderStartTime, ("EXTRACTION COMPLETED ---------------------------"))
