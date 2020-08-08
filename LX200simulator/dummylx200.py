import re
import math
import serial
import logging
from datetime import datetime
from pytz import timezone
from ddtomeade import ddtostr
from getAltAz import getAltAz
try:
 ser = serial.Serial('COM4',baudrate = 9600,timeout=100) # open com port at 9600 8n1
except: 
 print ('Could not open serial port')
 exit(1) 
logging.basicConfig(filename='dummylx200.log',filemode ='a',format='%(asctime)s,%(name)s %(levelname)s %(message)s',datefmt='%m-%d-%Y %H:%M:%S',level=logging.DEBUG)
logging.info('dummy LX200 started') 
print ('dummy LX200 started')
# variables and constants
latitude = 42.20833333
longitude = -91.65433333
# feet
height = 930
# siderealtime = '16:24:30#'
telescopera = 124
# ra stored as seconds
telescopeversion =  "ETX Autostar|A|43Eg|Apr 03 2007@11:25:53#" 
gvfresponse = "Version 4.2g"
telescopedeclination = 62.28
# decimal degrees
maximumslewrate = 2
trackingrate = 60.1
quitflag = False
alignmentmounting = "P" 
# variable to store incoming commands
s=""

# decode Meade format DD*MM:SS to float degrees
# need to add some checking and return nothing if bad data
def decodeDMS(s):
# get rid of any spaces
 s = s.replace(" ","") 
 print (len(s))
 if len(s) == 11: 
  deg = s[4:6]
  min = s[7:9]
  sec = '00'
 elif len(s)== 12:
  deg = s[3:5]
  min = s[6:8]
  sec = s[9:11]
 degi = int(deg)
 mini = int(min)
 seci = int(sec)
 degf = degi + (mini/60.0)+ (seci/3600.0)
 return degf
  
# decode Meade format HH:MM:SS to seconds integer
# need to add some checking and return nothing if bad data
def decodeHMS(s):
 # get rid of any spaces
 s = s.replace(" ","")
 print (len(s))
 if len(s) == 11:
  hr = s[3:5]
  mn = s[6:8]
  sn = '00'
 elif len(s)== 12:
  hr = s[3:5]
  mn = s[6:8]
  sn = s[9:11] 
 hri = int(hr)
 mni = int(mn)
 sni = int(sn)
 timesec = (3600*hri)+ (60*mni) + sni
 return timesec
 
def sectomeade(sec):
 hr = sec//3600
 mn = (sec%3600)//60
 sn = (sec%3600)%60  
 res = ("{:02d}".format(hr))+':'+("{:02d}".format(mn))+':'+("{:02d}".format(sn))+'#'
 return res
 
def LandAlignmentMode(s):
 global alignmentmounting
 alignmentmounting = "L"
 print ("Land Alignment Mode")
 
def PolarAlignmentMode(s):
 global alignmentmounting
 alignmentmounting = "P"
 print ("Polar Alignment Mode")
 
def AltAzAlignmentMode(s):
 global alignmentmounting
 alignmentmounting = "A"
 print ("Alt Az Alignment Mode") 
 
def GetSidrealTime(s):
 print ("Get Sidreal Time")
 # return Sidreal Time HH:MM:SS#
 now = datetime.now()
 siderealtime = now.strftime("%H:%M:%S#")
 print (siderealtime)
 # just use clock time for now
 ser.write(siderealtime.encode('utf-8') ) 
 
def GetTelescopeRA(s):
 global telescopera
 print ("Get Telescope RA")
 # return Telescope RA  HH:MM.T# or HH:MM:SS# 
 res = sectomeade(telescopera)
 print (res)
 ser.write(res.encode('utf-8'))
 
def GetTelescopeInfo(s):
 print ("Get Telescope Info")
 # convert this to individual routines if needed
 #  sub commands  D N P T F 
 
def GetTelescopeAzimuth(s):
 print ("Get Telescope Azimuth")
 altaz = getAltAz(latitude,telescopera,telescopedeclination)
 azstr = ddtostr(altaz['Azimuth'])
 ser.write(azstr.encode('utf-8'))
 # return azimuth info DDD*MM#T or DDD*MM'SS# 
 
def GetTelescopeDeclination(s):
 print ("Get Telescope Declination")
 decstr = ddtostr(telescopedeclination)
 print (decstr)
 ser.write(decstr.encode('utf-8'))
 
def GetAlignmentMounting():
 print ("Get alignment mounting mode")
 ser.write(alignmentmounting.encode('utf-8')) 
 
def SetMaximumSlewRate(s):
 global maximumslewrate
 print ("Set Maximum Slew Rate")
 try:
  sr = int (s[3])
 except:
  ser.write('0'.encode('utf-8'))
 else: 
  if (2 <= sr <= 8): 
   ser.write('1'.encode('utf-8'))
   maximumslewrate = sr
  else:
   ser.write('0'.encode('utf-8')) 
 
def TogglePrecision(s):
 print ("Toggle Precision")
 
def GetTrackingRate(s):
 print ("Get Tracking Rate")
 str = ("%2.1d#" % (trackingrate))
 # format leaves off .0 fix
 ser.write(str.encode('utf-8'))  
 
def GetTelescopeAltitude(s):
 altaz = getAltAz(latitude,telescopera,telescopedeclination)
 altstr = ddtostr(altaz['Elevation'])
 ser.write(altstr.encode('utf-8'))
 print ("Get Telescope Altitude") 
 
def HaltSlewing (s):
 print ("Quit command")
 quitflag = True
 # this should stop the scope from tracking
 
def SetRA(s):
 global telescopera
 print("Set RA")
 print (s)
 ra = decodeHMS(s)
 if ra:
  telescopera = ra
  print (telescopera)
  ser.write('1'.encode('utf-8'))
 else:
  ser.write('0'.encode('utf-8')) 
 
def GetVersion(s): 
 print ("Get Version")
 ser.write(gvfresponse.encode('utf-8'))
 
def  GetLatitude(s):
 print ("Get Telescope Latitude")
 decstr = ddtostr(latitude)
 ser.write(decstr.encode('utf-8'))
 
def SetDeclination(s):
 global telescopedeclination
 print ("Set Declination")
 print (s)
 dec = decodeDMS(s)
 if dec:
  print(dec)
  telescopedeclination = dec 
  ser.write('1'.encode('utf-8'))
 else:
  ser.write('0'.encode('utf-8')) 
  
def SlewToTarget(s):
 print ("Slew To Target")
 # Say were are good for now
 ser.write('0'.encode('utf-8'))   
 
commands ={
":AL" : LandAlignmentMode,
":AP" : PolarAlignmentMode,
":AA" : AltAzAlignmentMode,
":GS" : GetSidrealTime,
":GR" : GetTelescopeRA,
":GV" : GetTelescopeInfo,
":GZ" : GetTelescopeAzimuth,
":GD" : GetTelescopeDeclination,
":Sw" : SetMaximumSlewRate,
":U"  : TogglePrecision,
":GT" : GetTrackingRate,
":GA" : GetTelescopeAltitude,
":Q"  : HaltSlewing,
":Sr" : SetRA,
":GVF" : GetVersion,
":Gt"  : GetLatitude,
":Sds" : SetDeclination,
":Sd" : SetDeclination,
":MS" : SlewToTarget
} 

while True:
 # read a character from port
 line = ser.read() 
 # convert binary to character string
 # need a try here to catch non ascii bytes
 character = str(line, 'utf-8')  
 # ack (\x06) is an odball command
 if character == '\x06':
  GetAlignmentMounting()
 else:
  s= s + (character)
  if character == "#":
   #print (len(s))
   print (s)
   x = re.search(':[a-zA-Z]{1,3}',s)
   if x:
   # print (x.group())
    idx = x.group()
   # need to extract data in commands
    if idx in commands:
     commands[idx](s)
    else:
     print ("Unrecognized Command ",s)
     logging.info('Unrecognized Command %s'%s)
   s=""
ser.close()