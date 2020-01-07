import argparse
from julianday import getjulianday
from datetime import datetime
from pytz import timezone
parser = argparse.ArgumentParser()
parser.add_argument("DateTime", help="YEAR-M-D H:M:S") 
args = parser.parse_args()
print (args.DateTime)
DT = datetime.strptime(args.DateTime,"%Y-%m-%d %H:%M:%S" )
JD = getjulianday(DT)
print (JD)
rightnow = datetime.now(timezone ('US/Central'))
JD = getjulianday(rightnow)
print (JD)