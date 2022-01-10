## EXTRACT RELEVANT PERFORMANCE STATISTICS FROM THE SQL SERVER TEXT OUTPUTS FOR
## FOR EACH DATA WAREHOUSE, THEN AND SAVE TO CSV.

import os
import re
import pandas as pd

InputFolder = 'C:\\Users\\SOR035\\Documents\\NetCDFWarehouse\\DataWarehouse V2\Query Testing'
OutputFolder = 'C:\\Users\\SOR035\\Documents\\NetCDFWarehouse\\DataWarehouse V2\Results'

def Performance_Statistics(QueryOutput, StatisticName, QueryName):
    '''
    Splits the query text output by line, comma, and full stop to count stats for each individual 
    query or sub-query, and then returns results as a dataframe

    '''
    
    # Query output text into individual statistics, be delimiting with , . and \n. 
    # The remove empty lines, leading spaces, and transform to lower case
    QueryLines = re.split('[,.\n]', QueryOutput)
    QueryLines = [Line.lstrip().lower() for Line in QueryLines if Line]
    
    # Aggregate the count of each statistic in the Query Lines
    StatisticValue = []
    for Statistic in StatisticName:
        Count = 0
        for Line in QueryLines:
            if Line.startswith(Statistic):
                # The time statistics are reported with the ms unit, meaning they require slightly different treatement.
                if "time" in Statistic:
                    Count = Count + int(Line.split(" ")[-2])/1000
                else:
                    Count = Count + int(Line.split(" ")[-1])
        StatisticValue.append(Count)
        
    return pd.DataFrame({QueryName:StatisticValue}, index=StatisticName)



# ITERATE THROUGH 'DWX Performance.txt' FILES TO AGGREGATE, EXTRACT, AND SAVE PERFORMANCE STATS
FileList = [FileName for FileName in os.listdir(InputFolder) if (("Performance" in FileName) and ("txt" in FileName))]
for FileName in FileList:
    
    DataWarehouse = FileName.split(" ")[0]
    
    # OPEN TEXT FILE
    File = open(InputFolder+'\\'+FileName, 'r')
    FullText = File.read()
    File.close()
    
    # REMOVE FINAL MESSAGES AFTER "TESTING COMPLETE"
    Text = FullText.split("TESTING COMPLETE")[0]
    
    # PARTITION TEXT "STANDARD QUERY" AND REMOVE STARTING MESSAGES
    Text = Text.split("STANDARD QUERY")[1:]
    
    # FURTHER PARTITION TEXT BY SUB-TESTS WITHIN EACH QUERY
    QueryText = []
    for Query in Text:
        if len(Query.split("TEST")) > 1:
            TestText = Query.split("TEST")[1:]
            for Test in TestText:
                QueryText.append(Test)
            
        else:
            QueryText.append(Query)
            
    QueryName = [
            "Query 1",
            "Query 2",
            "Query 3.1",
            "Query 3.2",
            "Query 3.3",
            "Query 3.4",
            "Query 4.1",
            "Query 4.2",
            "Query 4.3",
            "Query 4.4",
            "Query 5.1",
            "Query 5.2",
            "Query 5.3"
            ]
    StatisticName = [
            "scan count",
            "logical reads",
            "physical reads",
            "page server reads",
            "read-ahead reads",
            "page server read-ahead reads",
            "lob logical reads",
            "lob physical reads",
            "lob page server reads",
            "lob read-ahead reads",
            "lob page server read-ahead reads",
            "segment reads",
            "segment skipped",
            "cpu time",
            "elapsed time"
            ]
    
    # EXTRACT STATISTICS FROM QueryText AND COMPILE IN DATAFRAME
    for i in range(len(QueryName)):
        if i == 0:
            StatTable = (Performance_Statistics(QueryText[i], StatisticName, QueryName[i]))
        else:
            StatTable[QueryName[i]] = Performance_Statistics(QueryText[i], StatisticName, QueryName[i])
            
    # ADDING RELEVANT COMPUTED STATISTICS:
    StatTable = StatTable.T
    StatTable["total logical reads"] = StatTable["logical reads"] + StatTable["lob logical reads"];
    StatTable["total read-aheads"] = StatTable["read-ahead reads"] + StatTable["page server read-ahead reads"] +\
                                        StatTable["lob read-ahead reads"] + StatTable["lob page server read-ahead reads"]
    StatTable["cpu parallelisation"] =  StatTable["cpu time"] / StatTable["elapsed time"] 
    StatTable["segment efficiency"] = StatTable["segment reads"] / (StatTable["segment reads"] + StatTable["segment skipped"])
    StatTable = StatTable.T
    
    print(StatTable)
            
    # EXPORT DATAFRAME TO CSV
    StatTable.to_csv(((OutputFolder+"\\"+DataWarehouse+" Performance.csv")))
            
