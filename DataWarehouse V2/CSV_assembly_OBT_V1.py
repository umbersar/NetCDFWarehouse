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
# import sqlalchemy as sqla
# from sqlalchemy import event
# import urllib

InputFolder = "C:\AWRA_nc_dataset\AWRA-L_historical_data\e0\RAW NETCDF\TEST"
OutputFolder = "C:\AWRA_nc_dataset\AWRA-L_historical_data\DW_V2"


# Connection_String = ('DRIVER={SQL Server};'
#                      'SERVER=MAGICAL-BM;'
#                      'DATABASE=CLIMATE_DATA_V1;'
#                      'Trusted_Connection=yes')
# db_params = urllib.parse.quote_plus(Connection_String)
# engine = sqla.create_engine("mssql+pyodbc:///?odbc_connect={}".format(db_params))

# @event.listens_for(engine, "before_cursor_execute")
# def receive_before_cursor_execute(
#        conn, cursor, statement, params, context, executemany
#         ):
#             if executemany:
#                 cursor.fast_executemany = True
                
# connection_uri = f"mssql+pyodbc:///?odbc_connect={urllib.parse.quote_plus(Connection_String)}"
# engine = sqla.create_engine(connection_uri, fast_executemany=True)


        
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

## SPACE DIMENSION TABLE (simple)
DS = xr.open_dataset(InputFolder+"\\"+FileName) 
Lon,Lat = np.meshgrid(DS.longitude.values, DS.latitude.values)
Lon = Lon.flatten()
Lat = Lat.flatten()
DF_Grid = pd.DataFrame({ "LATITUDE":Lat, "LONGITUDE":Lon})
DF_Grid.index = DF_Grid.index + 1
DF_Grid.to_csv(((OutputFolder+"\\DIMENSION_GRID.csv")), index = True, header=True)


# ## TIME DIMENSION TABLE (datetime format)
DateTime = np.array([], dtype='datetime64')
for FileName in NClist:
    DS = xr.open_dataset(InputFolder+"\\"+FileName)
    DateTime = np.append( DateTime, DS.time.values)
    DS.close()
DF_Time1 = pd.DataFrame({"DateTime":DateTime})
DF_Time1.index = DF_Time1.index + 1
DF_Time1.to_csv(((OutputFolder+"\\DIMENSION_TIME1.csv")), index = True, header=True)


# ## TIME DIMENSION TABLE (split integer format) - 
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
 
# This appears to be optimum for daily files
BatchSize_Years = 5
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
            
        
    # Extract and assemble all the datasets from a given year into a single DataFrame:
    for FileName in FileList:
        
        # Extract dataset and variable name with xarray
        DS = xr.open_dataset(InputFolder+"\\"+FileName)
        ShortName = getattr(getattr(DS, (DS.var_name)), "name")
        DimTime = len(DS.time.values)
        
        # Create an annual DataFrame, and add columns for each variable.
        if FileName == FileList[0]:
            AnnualData = pd.DataFrame({
                "DateID": np.repeat(np.arange(DateID_YearStart, DateID_YearEnd + 1), DimGrid),
                "GridID": np.tile(np.arange(1, DimGrid+1), DimTime),
                ShortName: getattr( getattr(DS, ShortName), "values").flatten()})
            
        else:
            AnnualData[ShortName] = getattr( getattr(DS, ShortName), "values").flatten()
    
        DS.close()
        
    
    # if BatchCount == 1:
    #     Batch_StartYear = Year
    #     BatchData = AnnualData
    # else:
    #     BatchData = BatchData.append(AnnualData, ignore_index = True)
        
    
    Print_Duration(T1, ("{} Files Extracted".format(str(Year))))

    if BatchCount == 1:
        OutputName = "FACT {} - {}".format(str(Year), str(Year + BatchSize_Years - 1)) #has potential to mess things up when years are filtered out as above
        AnnualData.to_csv(((OutputFolder+"\\"+OutputName+".csv")), index = False, header=False)
    else:
        AnnualData.to_csv(((OutputFolder+"\\"+OutputName+".csv")), index = False, header=False, mode='a')# , mode='a', chunksize=100000, compression=None )
    Print_Duration(T1, ("Data written to {}.csv".format(OutputName)))
    
    
    # When the batch is full or after the last year of data has been extracted, export to CSV
    if ((BatchCount == BatchSize_Years) or (Year == YearList[-1])):
        
        
        
        # T2 = dt.now()
        # BatchData.to_sql("FACT", engine, schema="DW2", index=False, if_exists="append")
        # Print_Duration(T1, ("Batch Data written to SQL Server"))
        
         # T2 = dt.now()
        # BatchData.to_pickle(OutputFolder+"\\"+OutputName+".pkl")#, index=False)
        # Print_Duration(T1, ("Batch Data written to .pkl"))
        
        
        # print(BatchData)
        # T2 = dt.now()
        # BatchData.to_csv(((OutputFolder+"\\"+OutputName+".csv")), index = False, header=False)# , mode='a', chunksize=100000, compression=None )
        # Print_Duration(T1, ("Batch Data written to {}".format(OutputName)))
  
    # if Year == YearList[0]:
    #     AnnualData.to_csv(((OutputFolder+"\\"+OutputName+".csv")), index = False, header=False)
        

    # AnnualData.to_csv(((OutputFolder+"\\"+OutputName+".csv")), index = False, header=False, mode='a')# , mode='a', chunksize=100000, compression=None )
    # Print_Duration(T1, ("Batch Data written to FACT.csv"))
         
        BatchCount = 1
        # del BatchData
        
        # Correct NULL value format, for input to SQL server:
        # By default NaN is written to CSV as "", this block replaces them with a blank space
        # T3 = dt.now()
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


        









