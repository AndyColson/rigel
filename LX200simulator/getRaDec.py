# covert alt az to ra dec
import math
def getRaDec (Lat,alt,az):
# internal 
 dr = math.pi/180.0
 ra = math.atan2(math.sin(az),(math.cos(az)*math.cos(Lat))+ (math.tan(alt)*math.cos(Lat)) )/dr
 dec = math.asin((math.sin(Lat)*math.sin(alt))- (math.cos(Lat)*math.cos(az)) )/dr
 return {'rightascension': ra,'declination': dec}