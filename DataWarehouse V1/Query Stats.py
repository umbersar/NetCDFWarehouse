
import numpy as np
import matplotlib.pyplot as plt
import datetime as dt
import pandas as pd
DW2_Time = np.array([0.6,   6,       1675,  100,    65])
# DW4_Read = pd.DataFrame({"seconds":[0,     0,   22255745,  0,      0]})
DW2_Q3 = np.array([177,     609,    1675])
# DW4_Q3_Reads = np.array([22255745,      3058752,    1675])
DW2_Q4 = np.array([7,       23,     100])
DW2_Q5 = np.array([61,     60,    65])


DW3_Time = np.array([0.5,   7,       1563,  393,    61])
DW3_Q3 = np.array([184,     622,    1563])
DW3_Q4 = np.array([7,       77,     393])
DW3_Q5 = np.array([61,     60,    61])


DW2_2_Time = np.array([0.6,   0.2,    440,   14,     5])
# DW5_Read = pd.DataFrame({"seconds":[0,     0,      17962463,  0,      0]})
DW2_2_Q3 = np.array([32,      213,    440])
DW2_2_Q4 = np.array([13,      14,     14])
DW2_2_Q5 = np.array([0.7,     1.3,    0.4])

X1 = ["QUERY1", "QUERY2", "QUERY3", "QUERY4", "QUERY5" ]
XQ3 = ["10yr Range", "25yr Range", "50yr Range"]
XQ4 = ["1yr Range", "10yr Range", "50yr Range"]
XQ5 = ["Single Day", "Aggregated Month", "Aggregated Year"]


## ALL QUERIES
fig = plt.figure()

width = 0.25  # the width of the bars
X = np.arange(len(X1)) + 1
plt.grid()
DW2 = plt.bar(X - (width), DW2_Time/60, width)
DW3 = plt.bar(X , DW3_Time/60, width)
DW2_2 = plt.bar(X + (width), DW2_2_Time/60, width)

plt.ylabel('Time [Minutes]')
plt.xlabel('Query')
plt.title('Query Runtime')

plt.show()


## QUERY THREE
fig = plt.figure()

X = np.arange(3) + 1
plt.grid()
DW2 = plt.bar(X - (width), DW2_Q3/60, width)
DW3 = plt.bar(X , DW3_Q3/60, width)
DW2_2 = plt.bar(X + (width), DW2_2_Q3/60, width)


plt.ylabel('Time [Minutes]')
plt.xlabel('Query')
plt.title('Query 3: Runtime')
plt.xticks(X, XQ3)

# plt.show()

## QUERY FOUR
fig = plt.figure()

X = np.arange(3) + 1
plt.grid()
DW2 = plt.bar(X - (width), DW2_Q4/60, width)
DW3 = plt.bar(X , DW3_Q4/60, width)
DW2_2 = plt.bar(X + (width), DW2_2_Q4/60, width)

plt.ylabel('Time [Minutes]')
plt.xlabel('Query')
plt.title('Query 4: Runtime')
plt.xticks(X, XQ4)

plt.show()

## QUERY FIVE
fig = plt.figure()

X = np.arange(3) + 1
plt.grid()
DW2 = plt.bar(X - (width), DW2_Q5, width)
DW3 = plt.bar(X , DW3_Q5, width)
DW2_2 = plt.bar(X + (width), DW2_2_Q5, width)

plt.ylabel('Time [Seconds]')
plt.xlabel('Query')
plt.title('Query 5: Runtime')
plt.xticks(X, XQ5)

plt.show()
