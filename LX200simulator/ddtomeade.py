# convert decimal degress to Meade telescope protocol string sDD*MM'SS#
# don't think this has leading zeros for numbers smaller than 10
import math
def ddtostr (dd):
 a = math.modf(dd)
 deg = int(a[1])
 min = int(math.modf(a[0]*60)[1]) 
 sec = int( math.modf(a[0]*60)[0]*60)
 degreestr = 's'+("{:02d}".format(deg))+'*'+("{:02d}".format(min))+'\''+("{:02d}".format(sec))+'#'
 return degreestr
