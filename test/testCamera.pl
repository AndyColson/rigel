#!/usr/bin/perl

use common::sense;
use PDL;
use PDL::Core::Dev;

# https://www.perlmonks.org/?node_id=1214437
# https://stackoverflow.com/questions/5379418/perl-inlinec-return-pdl-or-0-on-failure
# http://pdl.perl.org/?docs=API&title=PDL%3a%3aAPI#Creating-a-piddle-in-C
# https://perldoc.perl.org/perlapi.html
# https://metacpan.org/pod/PDL::API
#

# -I/usr/include/libftdi1 -I/usr/include/libusb-1.0
# -lcfitsio -ltiff -lftdi1 -lusb-1.0
use Inline CPP => config =>
	libs => '-lqsiapi -lcfitsio -lftdi1 -lusb-1.0 -ltiff',
	ccflags => '-std=c++11 -I/usr/include/libftdi1 -I/usr/include/libusb-1.0',
	INC           => &PDL_INCLUDE,
    TYPEMAPS      => &PDL_TYPEMAP,
    AUTO_INCLUDE  => &PDL_AUTO_INCLUDE, # declarations
    BOOT          => &PDL_BOOT;

use Inline 'CPP' => '../Rigel/camera.cpp';

print "Startup\n";

my $c = new Camera();
print $c->getInfo(), "\n";

my $p = $c->test();
# add header
$p->fhdr->{COOL} = 1;
print $p;

$p->wfits('junk.fits');

# $c->takePicture();
# print "done\n";
# undef $c;

