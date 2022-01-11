# -*- coding: utf-8 -*-
"""
Created on Mon Dec 20 09:54:48 2021

@author: sor035
"""

# netCDF_to_table()
import xarray as xr
import pandas as pd
import numpy as np
import os
from datetime import datetime as dt

InputFolder = "C:\AWRA_nc_dataset\AWRA-L_historical_data\e0\RAW NETCDF\TEST"
OutputFolder = "D:\CSIRO\ONE BIG TABLE"
        
def Print_Duration(start_time, update):
    ''' Report the duration and progess throughout an iteration'''
    elapsed_seconds = (dt.now() - start_time).seconds
    elapsed_hours = elapsed_seconds // 3600
    elapsed_seconds = elapsed_seconds - (elapsed_hours * 3600)
    elapsed_minutes = elapsed_seconds // 60
    elapsed_seconds = elapsed_seconds - (elapsed_minutes * 60)
    print("\t{:02}:{:02}:{:02} - {}".format(elapsed_hours, elapsed_minutes, elapsed_seconds, update))
    
    
## ## CHECK FOR CONSISTENCY BETWEEN .NC FILES IN THE INPUT FOLDER ------------

# Assumes the NetCDF files are named in the format '<variable_name>_YYYY.nc'
# Check that consecutive years are presented.
# check that for each year, all variables are present
# check that spatial dimensions are consistent
# check that the timestep is consistent
# check that files from the same year have consistent time dimensions 
# NClist = []
# for FileName in os.listdir(InputFolder):
#     if FileName[-3:] == '.nc':
#         NClist.append(FileName)
        
NClist = [FileName for FileName in os.listdir(InputFolder) if FileName[-3:] == '.nc']
YearList = list(set([int(FileName[-7:-3]) for FileName in NClist]))
YearList.sort()
VarList = list(set([FileName[:-8] for FileName in NClist]))
VarList.sort()

# Check that data for all variables is available in each year.
MissingYearList = []
for Year in YearList:
    FilesFromYear = [FileName for FileName in NClist if str(Year) in FileName]
    if len(FilesFromYear) != len(VarList):
        VarMissing = [Variable for Variable in VarList if (Variable not in FilesFromYear)]
        print("Year {} is missing files for {}".format(Year, VarMissing))
        MissingYearList.append(Year)

# Check that complete data is available for consecutive years.
YearList = [YearList.remove(MissingYear) for MissingYear in MissingYearList]
if len(np.unique(np.diff(np.array(YearList)))) != 1:
    print("")
    print(YearList)
        
## ## CREATE AND EXPORT DIMENSION TABLES -------------------------------------

# SPATIAL DIMENSION TABLE:
# Creating and exporting the space dimension table to csv. 
# The DataFrame index is included as the GridID to be used in joining tables.
FileName = NClist[0]
DS = xr.open_dataset(InputFolder+"\\"+FileName) 
Lon,Lat = np.meshgrid(DS.longitude.values, DS.latitude.values)
Lon = Lon.flatten()
Lat = Lat.flatten()
DF_Grid = pd.DataFrame({ "LATITUDE":Lat, "LONGITUDE":Lon})
DF_Grid.index = DF_Grid.index + 1
DF_Grid.to_csv(((OutputFolder+"\\DIMENSION_GRID.csv")), index = True, header=True)


# TEMPORAL DIMENSION TABLE (datetime format):
# Creating and exporting the datetime dimension table to csv.
# the DataFrame index is included as the DateID to be used in joining tables.
# Note: the smalldatetime datatype (YYYY-MM-DD hh:mm:ss) in t-sql is 4 bytes, but dates prior to 1900 aren't allowed.
DateTime = np.array([], dtype='datetime64')
for FileName in NClist:
    DS = xr.open_dataset(InputFolder+"\\"+FileName)
    DateTime = np.append( DateTime, DS.time.values)
    DS.close()
DF_Time1 = pd.DataFrame({"DateTime":DateTime})
DF_Time1.index = DF_Time1.index + 1
DF_Time1.to_csv(((OutputFolder+"\\DIMENSION_TIME1.csv")), index = True, header=True)


# TIME DIMENSION TABLE (split integer format):
# Creating and exporting the datetime dimension table to csv as seperate
# tinyint (1 byte) columns for month and day, and a smallint (2 byte) column for year.
# This is less efficient for space and limits the scope of some queries (i.e. setting a predicate between two dates),
# however it is thought that it has potential to be faster on other queries.
# The DataFrame index is included as the DateID to be used in joining tables.
DateTime = np.array([], dtype='datetime64')
for FileName in NClist:
    DS = xr.open_dataset(InputFolder+"\\"+FileName)
    DateTime = np.append( DateTime, DS.time.values)
DS.close()
DF_Time2 = pd.DataFrame({"DateTime":DateTime})
DF_Time2["YEAR"] = DF_Time2["DateTime"].dt.year
DF_Time2["MONTH"] = DF_Time2["DateTime"].dt.month
DF_Time2["DAY"] = DF_Time2["DateTime"].dt.day
DF_Time2 = DF_Time2.drop(columns = ["DateTime"])
DF_Time2.index = DF_Time2.index + 1
YearList = DF_Time2["YEAR"].unique()
DF_Time2.to_csv(((OutputFolder+"\\DIMENSION_TIME2.csv")), index = True, header=True)
 


## ## EXPORT GRIDDED CLIMATE DATA TO CSV IN BATCHES --------------------------


# This appears to be optimum for daily files
BatchSize_Years = 10
BatchCount = 1
FolderStartTime = dt.now()
print("\t{} INGESTION STARTED ----------------------------- \n".format(FolderStartTime.strftime("%H:%M:%S %p")))


# Assuming that file list returned by os.listdir are chronologically ordered.
for Year in YearList:
    T1 = dt.now()
    
    # multiple different variable files from the same year
    FileList = [FileName for FileName in NClist if str(Year) in FileName]
    
    # Check that file formats are consistent.
    for FileName in FileList:
        DS = xr.open_dataset(InputFolder+"\\"+FileName)
        
        # MAKES MORE SENSE TO RE-ARRANGE THIS SO THEY'RE BEING CHECKED IN A LOOP BEFORE DATA IS ACTUALLY EXTRACTED
        # For each year group set the start and end date
        if FileName == FileList[0]:
            DateID_YearStart = int(DF_Time1[DF_Time1["DateTime"] == DS.time.values[0]].index.values)
            DateID_YearEnd = int(DF_Time1[DF_Time1["DateTime"] == DS.time.values[-1]].index.values)
            VariableCount = len(FileList)
            
            # Determine standard dimensions from the very first file to be read.
            if Year == YearList[0]:
                DimGrid = len(DS.latitude.values) * len(DS.longitude.values)
                DimLon = DS.latitude.values
                DimLat = DS.longitude.values
                DimTimeStep = np.unique(np.diff(DS.time.values).astype('timedelta64[s]'))
                
        # Check that all files in the year group match dimensions before proceeding, otherwise skip the year.
        else:
            if not (VariableCount == len(FileList)):
                print("YEAR SKIPPED: Inconsistent number of variables in year group")
                print(FileList)
            
            if not ( np.array_equal(DimLon, DS.longitude.values) 
                or  np.array_equal(DimLat, DS.latitude.values)):
                print("FILE SKIPPED: different spatial dimensions from other files")
                print("Standard Dimensions: \n Lat = {} \n{}: Lat =  \n {}".format(DimLat, FileName, DS.latitude.values))
                print("Standard Dimensions: \n Lon = {} \n{}: Lon =  \n {}".format(DimLon, FileName, DS.longitude.values))
                continue
            
            elif DimTimeStep != np.unique(np.diff(DS.time.values).astype('timedelta64[s]')):
                print("FILE SKIPPED: different timestep from other files")
                print("Standard Dimensions: \n TimeStep = {} \n{}: TimeStep =  \n {}".format(DimTimeStep, FileName, np.unique(np.diff(DS.time.values).astype('timedelta64[s]'))))
                continue
            
            elif not ( np.array_equal(DateID_YearStart, int(DF_Time1[DF_Time1["DateTime"] == DS.time.values[0]].index.values)) 
                or  np.array_equal(DateID_YearEnd, int(DF_Time1[DF_Time1["DateTime"] == DS.time.values[-1]].index.values))):
                print("FILE SKIPPED: different spatial dimensions from other files")
                print("Year Start Date:  = {}, {} Start Date: {}".format(str(DF_Time1["DateTime"][DateID_YearStart]), FileName, str(DS.time.values[0])))
                print("Year End Date:  = {}, {} End Date: {}".format(str(DF_Time1["DateTime"][DateID_YearEnd]), FileName, str(DS.time.values[-1])))
                continue
        DS.close()
        
T1 = dt.now()            
for Year in YearList:
    print(Year)
    FileList = [FileName for FileName in NClist if str(Year) in FileName]
        
    # Extract and assemble all the datasets from a given year into a single DataFrame:
    for FileName in FileList:
        print(FileName)
        
        # Extract dataset and variable name with xarray
        DS = xr.open_dataset(InputFolder+"\\"+FileName)
        ShortName = getattr(getattr(DS, (DS.var_name)), "name")
        DimTime = len(DS.time.values)
        
        # Create an annual DataFrame, and add columns for each variable.
        if FileName == FileList[0]:
            AnnualData = pd.DataFrame({
                'Date': np.repeat(DS.time.values, DimGrid),
                'Latitude': np.tile(Lat, DimTime),
                'Longitude': np.tile(Lon , DimTime),
                ShortName: getattr( getattr(DS, ShortName), "values").flatten()})
            
        else:
            AnnualData[ShortName] = getattr( getattr(DS, ShortName), "values").flatten()
        DS.close()
    Print_Duration(T1, ("{} Files Extracted".format(str(Year))))
    
    

    if BatchCount == 1:
        OutputName = "FACT {} - {}".format(str(Year), str(Year + BatchSize_Years - 1)) #has potential to mess things up when years are filtered out as above
        AnnualData.to_csv(((OutputFolder+"\\"+OutputName+".csv")), index = False, header=False)
    else:
        AnnualData.to_csv(((OutputFolder+"\\"+OutputName+".csv")), index = False, header=False, mode='a')# , mode='a', chunksize=100000, compression=None )
    Print_Duration(T1, ("Data written to {}.csv".format(OutputName)))
    
    
    # When the batch is full or after the last year of data has been extracted, export to CSV
    if ((BatchCount == BatchSize_Years) or (Year == YearList[-1])):
        
        BatchCount = 1
        
        # Correct NULL value format, for input to SQL server:
        # By default NaN is written to CSV as "", this block replaces them with a blank space
        CSV = open((OutputFolder+"\\"+OutputName+".csv"), 'r')
        Text = CSV.read()
        CSV.close()
        Text = Text.replace("\"\"","")
        CSV = open((OutputFolder+"\\"+OutputName+".csv"), 'w')
        CSV.write(Text)
        CSV.close()
        del CSV
        Print_Duration(T1, "CSV file NULL values cleaned /n")
        
        
        Print_Duration(FolderStartTime, "Ingestion Runtime")
        T4 = dt.now()
        print("\t{} NEXT BATCH ----------------------------- \n".format(T4.strftime("%H:%M:%S %p")))
        
    else:
        BatchCount = BatchCount + 1


        









