#!/usr/bin/perl

use strict;
use warnings;

# -I/usr/include/libftdi1 -I/usr/include/libusb-1.0
# -lcfitsio -ltiff -lftdi1 -lusb-1.0
use Inline CPP => config =>
	libs => '-lqsiapi -lcfitsio -lftdi1 -lusb-1.0 -ltiff',
	ccflags => '-std=c++11 -I/usr/include/libftdi1 -I/usr/include/libusb-1.0';

use Inline 'CPP' => '../Rigel/camera.cpp';

print "Startup\n";

my $c = new Camera();
print $c->getInfo(), "\n";

$c->takePicture();
print "done\n";
undef $c;

