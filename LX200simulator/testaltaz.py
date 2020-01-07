from getAltAz import getAltAz
lat = 42.0
ha =136.25
dec = 48.0
res = getAltAz(lat,ha,dec)
azimuth = res['Azimuth']
elevation = res['Elevation']
print ('Hour Angle ',ha)
print ('Declination ',dec)
print ('Azimuth ',azimuth)
print ('Elevation ',elevation)