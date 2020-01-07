import math
import datetime
def getjulianday(DT):
 m = DT.month
 y = DT.year
 d = DT.day
 minute = DT.minute
 second = DT.second
 hour = DT.hour
 if (m < 3):
  y = y-1
  m = m+12
 A = math.floor(y/100)
 B = 2 -A + math.floor(A/4)	
 JD = math.floor(365.25*(y+4716))+math.floor(30.6001*(m+1))+d+B-1524.5
 JD = JD+hour/24.0+minute/1440.0+second/86400.0
 JD = round(JD,6)
 return JD