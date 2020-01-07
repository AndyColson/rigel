import serial
import logging
from datetime import datetime
from pytz import timezone
try:
 ser = serial.Serial('COM4',baudrate = 9600,timeout=100) # open com port at 9600 8n1
except: 
 print ('Could not open serial port')
 exit(1) 
logging.basicConfig(filename='dummylx200.log',filemode ='a',format='%(asctime)s,%(name)s %(levelname)s %(message)s',datefmt='%m-%d-%Y %H:%M:%S',level=logging.DEBUG)
logging.info('dummy LX200 started') 

latitude = '42,11.90N'
longitude = '91,39.26W'
height = 930 
# siderealtime = '16:24:30#'
# telescopera = '12:22:40#'
telescopeazimuth = '062*13\'25#'
telescopeversion =  "ETX Autostar|A|43Eg|Apr 03 2007@11:25:53#" 
telescopedeclination = 's75*46\'55#'
telescopealtitude = 's31*15\'45#'
quitflag = False
def LandAlignmentMode():
 print ("Land Alignment Mode")
def PolarAlignmentMode():
 print ("Polar Alignment Mode")
def AltAzAlignmentMode():
 print ("Alt Az Alignment Mode") 
def GetSidrealTime():
 print ("Get Sidreal Time")
 # return Sidreal Time HH:MM:SS#
 now = datetime.now()
 siderealtime = now.strftime("%H:%M:%S#")
 print (siderealtime)
 # just use clock time for now
 ser.write(siderealtime.encode('utf-8') ) 
def GetTelescopeRA():
 print ("Get Telescope RA")
 # return Telescope RA  HH:MM.T# or HH:MM:SS# 
 now = datetime.now()
 telescopera = now.strftime("%H:%M:%S#")
 # just use clock time for now
 ser.write(telescopera.encode('utf-8'))
def GetTelescopeInfo():
 print ("Get Telescope Info")
 # add the sub commands here D N P T F
def GetTelescopeAzimuth():
 print ("Get Telescope Azimuth")
 ser.write(telescopeazimuth.encode('utf-8'))
 # return azimuth info DDD*MM#T or DDD*MM'SS# 
def GetTelescopeDeclination():
 print ("Get Telescope Declination")
 ser.write(telescopedeclination.encode('utf-8'))
def GetAlignmentMounting():
 print ("Get alignment mounting mode")
 ser.write('P'.encode('utf-8')) 
def SetMaximumSlewRate():
 print ("Set Maximum Slew Rate")
 ser.write('1'.encode('utf-8'))
 # need to add reading slew rate to set 
def TogglePrecision():
 print ("Toggle Precision")
def GetTrackingRate():
 print ("Get Tracking Rate")
 ser.write('60.0#'.encode('utf-8'))  
 # say we have a 60Hz motor
def GetTelescopeAltitude():
 ser.write(telescopealtitude.encode('utf-8'))
 print ("Get Telescope Altitude") 
def Quit ():
 print ("Quit command")
 quitflag = True
 # this should stop the scope from tracking
def SetRA():
 print("Set RA")
 # extract RA from command string and store it 
 # return valid for now
 ser.write('1'.encode('utf-8'))
 
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
":U#" : TogglePrecision,
":Gt" : GetTrackingRate,
":GA" : GetTelescopeAltitude,
":Q#" : Quit,
":Sr" : SetRA
} 
s=""
while True:
 line = ser.read()  # read a character from port 
 character = str(line, 'utf-8') # convert binary to character string 
 if character == '\x06':
  GetAlignmentMounting()
 
 # need to deal with ack character 0x06 
 # ACK <0x06> Query of alignment mounting mode.
 # Returns:
 # A If scope in AltAz Mode
 # L If scope in Land Mode
 # P If scope in Polar Mode
 else:
  s= s + (character)
  if character == "#":
   print (s)
   idx = (s[0:3])
   if idx in commands:
    commands[idx]()
   else:
    print ("Unrecognized Command ",s)
    logging.info('Unrecognized Command %s'%s)
   s=""
ser.close()