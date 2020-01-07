import math
def getAltAz (Lat,Hour_Angle,Declination):
# internal
 dr = math.pi/180.0
 Elevation=(math.asin(math.sin(Lat*dr)*math.sin(Declination*dr)+math.cos(Lat*dr)*math.cos(Declination*dr)*math.cos(Hour_Angle*dr)))/dr
 Azimuth=(math.atan2(math.sin(Hour_Angle*dr),math.cos(Hour_Angle*dr)*math.sin(Lat*dr)-math.tan(Declination*dr)*math.cos(Lat*dr)))/dr 
 return {'Elevation': Elevation,'Azimuth': Azimuth}
 # add 180 degrees to azimuth