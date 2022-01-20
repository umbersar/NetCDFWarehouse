'''
EXTRACT ANNUAL DAILY GRIDDED CLIMATE DATA FROM AWRA-L NetCDF FILES AND WRITE 
TO CSV FOR INSERTION TO MICROSOFT SQL SERVER MANAGEMENT STUDIO.

FORMAT 1:
The CSV files exported are in STAR-schema format, with columns DateID, and GridID joining
the dimension and fact tables. The fact tables contain annual data for multiple variables,
alongisde the corresponding DateID and GridID values.

'DIMENSION_GRID.csv'      : | GridID (int) |   Latitude (float)  | Longitude (float)|
'DIMENSION_DATETIME.csv'  : | DateID (int) | DateTime (datetime) |
'DIMENSION_YMD.csv'       : | DateID (int) |     Year (int)      |    Month (int)   | Day (int)|
'FACT_YYYY.csv'           : | DateID (int) |     GridID (int)    |   Var1 (float)   |   ...    | VarN (float)|

'''
## IMPORT NECESSARY LIBRARIES
import xarray as xr
import pandas as pd
import numpy as np
import os
from datetime import datetime as dt

## SET INPUT AND OUTPUT DIRECTORIES
InputFolder = "C:\\AWRA_nc_dataset\\AWRA-L_historical_data\\e0\\RAW NETCDF\\TEST"
OutputFolder = "D:\\CSIRO\\CSV FORMAT 1"
   
''' 
## PART 1: CONFIRM THAT NetCDF FILES:
           1. Cover a continuous and non-overlapping time period 
           2. Cover a consistent set of variables throughout that time period
           3. Cover a consistent spatial domain across all files.
'''

# All .nc files from the InputFolder are collated into a list, alongwith the corresponding
# year and variable they contain data for - assuming they follow the naming convention "VariableName_YYYY.nc"
NClist = [FileName for FileName in os.listdir(InputFolder) if FileName[-3:] == '.nc']
YearList = [int(FileName.split(".")[0].split("_")[-1]) for FileName in NClist]
VarList = [FileName.rsplit("_", maxsplit=1)[0] for FileName in NClist]

# Dimensions are extracted from each list and assembled into a DataFrame
TimeRes = np.array([], dtype='int')
TimeStep = np.array([], dtype='timedelta64')
StartDate = np.array([], dtype='datetime64')
EndDate = np.array([], dtype='datetime64')
LatitudeRes = np.array([], dtype='int')
NorthBoundary = np.array([])
SouthBoundary = np.array([])
LongitudeRes = np.array([], dtype='int')
EastBoundary = np.array([])
WestBoundary = np.array([])

for FileName in NClist:
    DS = xr.open_dataset(InputFolder+"\\"+FileName)
    
    TimeRes = np.append(TimeRes, len(DS.time.values))
    TimeStep = np.append(TimeStep ,np.unique(np.diff(DS.time.values)))
    StartDate = np.append(StartDate, np.amin(DS.time.values))
    EndDate = np.append(EndDate, np.amax(DS.time.values))
    LatitudeRes = np.append(LatitudeRes, len(DS.latitude.values))
    NorthBoundary = np.append(NorthBoundary, np.amax(DS.latitude.values))
    SouthBoundary = np.append(SouthBoundary, np.amin(DS.latitude.values))
    LongitudeRes = np.append(LongitudeRes, len(DS.longitude.values))
    EastBoundary = np.append(EastBoundary, np.amax(DS.longitude.values))
    WestBoundary = np.append(WestBoundary, np.amin(DS.longitude.values))
    
    DS.close()

FileTable = pd.DataFrame({
    "FileName": NClist,
    "Year": YearList,
    "Variable": VarList,
    "Time Resolution":TimeRes,
    "Time Step":TimeStep,
    "Start Date": StartDate,
    "End Date": EndDate,
    "Latitude Resolution": LatitudeRes,
    "North Boundary": NorthBoundary,
    "South Boundary": SouthBoundary,
    "Longitude Resolution": LongitudeRes, 
    "East Boundary": EastBoundary, 
    "West Boundary": WestBoundary})

FileTable.sort_values(["Year", "Variable"], ignore_index=True)
FileTable.index = FileTable.index + 1
print(FileTable)

## Testing the set of files for the conditions described above:
# Assert that dataset covers a continuous time period.
assert(FileTable["Year"].drop_duplicates().diff().dropna().nunique() == 1,
       "The temporal coverage of files is not continuous, there are likely one or more gaps")
assert(set(FileTable["Time Resolution"].values).issubset(set([365, 366])),
       "One or more files have a temporal resolution outside of the accepted range.")

# Assert that all variables are covered in each year of the dataset.
assert((False in (FileTable["Year"].value_counts() == (FileTable.nunique()["Variable"])).values),
       "There an inconsistent number of entries be, there is likely one or more years missing a variable")

# Assert that all spatial dimensions are the same before proceeding
assert(FileTable.nunique()["North Boundary"] == 1, "One or more files have a different northern boundary")
assert(FileTable.nunique()["South Boundary"] == 1, "One or more files have a different southern boundary")
assert(FileTable.nunique()["Latitude Resolution"] == 1, "One or more files have a different latitudinal resolution.")

assert(FileTable.nunique()["East Boundary"] == 1, "One or more files have a different eastern boundary")
assert(FileTable.nunique()["West Boundary"] == 1, "One or more files have a different western boundary")
assert(FileTable.nunique()["Longitude Resolution"] == 1, "One or more files have a different longitudinal resolution.")

# Write the DataFrame to CSV for record keeping
FileTable.to_csv((OutputFolder+"\\Files Ingested.csv"))



'''
PART 2: WRITE DIMENSION TABLE TO CSV'

2.1 GRID DIMENSION TABLE
This will be a table with columns; |GridID (int)|Latitude (float)|Longitude (float)|
As confirmed above, all files have the same spatial dimensions, so this table can be extracted from any file.
'''
DS = xr.open_dataset(InputFolder+"\\"+FileTable["FileName"][1]) 

# The longitude and latitude dimensions are extracted, and meshed together into a grid and flattened into a 
# one dimensional array.
DimLat = len(DS.latitude.values)
DimLon = len(DS.longitude.values)
DimGrid = DimLon * DimLat
Longitude, Latitude = np.meshgrid(DS.longitude.values, DS.latitude.values)
DS.close()

Longitude = Longitude.flatten()
Latitude = Latitude.flatten()

# These are written to a dataframe and then on to a CSV, with the index acting as the Grid location identifier.
DF_Grid = pd.DataFrame({ "LATITUDE":Latitude, "LONGITUDE":Longitude})
DF_Grid.index = DF_Grid.index + 1
DF_Grid.to_csv(((OutputFolder+"\\DIMENSION_GRID.csv")), index = True, header=True)


'''
2.2 WRITE DATETIME DIMENSION TABLE TO CSV

This will be a table with columns |DateID (int)| DateTime (datetime)|
Note: In SSMS, the smalldatetime datatype (YYYY-MM-DD hh:mm:ss) is 4 bytes, but dates prior to 1900 aren't allowed.
'''

# Start by iterating through the .nc files for a single variable
DateTime = np.array([], dtype='datetime64')
FileSeries = FileTable.loc[FileTable["Variable"] == FileTable["Variable"].drop_duplicates()[1]]["FileName"].astype(str)

for FileName in FileSeries:
    DS = xr.open_dataset(InputFolder+"\\"+FileName)
    DateTime = np.append( DateTime, DS.time.values)
    DS.close()
    
# These are written to a dataframe and then on to a CSV, with the index acting as the Time Dimension identifier.
DF_DateTime = pd.DataFrame({"DateTime":DateTime})
DF_DateTime.index = DF_DateTime.index + 1
DF_DateTime.to_csv(((OutputFolder+"\\DIMENSION_DATETIME.csv")), index = True, header=True)

'''
2.3 WRITE YEAR-MONTH-DAY DIMENSION TABLE TO CSV

This will be a table with columns |DateID (int)| Year (int)| Month (int)| Day (int)|
Note: In SSMS, the month and day columns will use tinyint (1 byte) format, and the year column will use smallint (2 byte) 
'''
DF_YMD = DF_DateTime
DF_YMD["YEAR"] = DF_YMD["DateTime"].dt.year
DF_YMD["MONTH"] = DF_YMD["DateTime"].dt.month
DF_YMD["DAY"] = DF_YMD["DateTime"].dt.day
DF_YMD = DF_YMD.drop(columns = ["DateTime"])
DF_YMD.to_csv(((OutputFolder+"\\DIMENSION_YMD.csv")), index = True, header=True)


'''
PART 3: WRITE FACT TABLES TO CSV

For each year, a CSV file will be written in the format |DateID (int) | GridID (int) | Var1 (float) |...| VarN (float)|
'''
def Print_Duration(start_time, update):
    ''' Report the duration and progess throughout an iteration'''
    elapsed_seconds = (dt.now() - start_time).seconds
    elapsed_hours = elapsed_seconds // 3600
    elapsed_seconds = elapsed_seconds - (elapsed_hours * 3600)
    elapsed_minutes = elapsed_seconds // 60
    elapsed_seconds = elapsed_seconds - (elapsed_minutes * 60)
    print("\t{:02}:{:02}:{:02} - {}".format(elapsed_hours, elapsed_minutes, elapsed_seconds, update))
    
T1 = dt.now()
print("\n\t{} INGESTION STARTED ----------------------------- ".format(T1.strftime("%H:%M:%S %p")))

# Iterate through each year from the file table established in part 1, and then within each year, iterate through
# the different variables.
for Year in FileTable["Year"].drop_duplicates():
    
    FileSeries = FileTable[FileTable["Year"] == Year].reset_index()["FileName"]
    T2 = dt.now()
    print("\n\t{}\n\tYEAR: {}\n".format(T2.strftime("%H:%M:%S %p"), Year)) 
    
    for FileName in FileSeries:
        DS = xr.open_dataset(InputFolder+"\\"+FileName)
        
        ShortName = getattr(getattr(DS, (DS.var_name)), "name")
        DimTime = len(DS.time.values) # this is important because the DimTime value will change for leap years.
        
        # These value correspond to the DateID values from the dimension table.
        DateID_Start =  int(DF_DateTime[DF_DateTime["DateTime"] == DS.time.values[0]].index.values)
        DateID_End =    int(DF_DateTime[DF_DateTime["DateTime"] == DS.time.values[-1]].index.values)
        
        # For the first variable, a dataframe is created with DateID and GridID columns.
        if FileName == FileSeries[0]:
            AnnualData = pd.DataFrame({
                "DateID": np.arange(DateID_Start, DateID_End + 1).repeat(DimGrid),
                "GridID": np.tile(np.arange(1, DimGrid + 1), DimTime),
                ShortName: getattr( getattr(DS, ShortName), "values").flatten()})
            
        # For all subsequent variables in the same year, a column is added.
        else:
            AnnualData[ShortName] = getattr( getattr(DS, ShortName), "values").flatten()
        DS.close()
        
        
    Print_Duration(T1, ("'{}' Extracted from NetCDF".format(FileName)))
        
    # The yearly data combining all variables is then written to CSV.
    OutputName = "FACT_{}".format(str(Year)) 
    AnnualData.to_csv((OutputFolder+"\\"+OutputName+".csv"), index = False, header=False)
    Print_Duration(T1, ("Written to CSV"))
    
    # By default, pandas will write NaN values to CSV as empty strings (with quotations).
    # In order for the files to be read by SSMS, these must be removed, as done below with text processing.
    CSV = open((OutputFolder+"\\"+OutputName+".csv"), 'r')
    Text = CSV.read()
    CSV.close()
    Text = Text.replace("\"\"","")
    CSV = open((OutputFolder+"\\"+OutputName+".csv"), 'w')
    CSV.write(Text)
    CSV.close()
    Print_Duration(T1, "Null values amended")
   
T3 = dt.now()
print("\t{} INGESTION COMPLETE ----------------------------- ".format(T3.strftime("%H:%M:%S %p")))