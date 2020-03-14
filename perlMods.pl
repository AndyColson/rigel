#!/usr/bin/perl
use strict;
use CPAN;

# XSCookies requires Date::Parse ?

my @list = qw(
common::sense
Digest::MD5
Term::ReadLine::Gnu
File::Temp
Types::Serialiser
JSON::XS
DBI
DBD::SQLite
Device::SerialPort
EV
AnyEvent
AnyEvent::SerialPort
AnyEvent::HTTPD
AnyEvent::Socket
IO::AIO
AnyEvent::AIO
Text::Xslate
HTTP::XSCookies
Text::CSV_XS
Astro::PAL
Astro::Coords
Astro::FITS::CFITSIO
Udev::FFI
Net::Curl
Inline::C
Inline::CPP
RPi::WiringPi
PDL
);

# Astro::FITS::Header  (will install Tk)
# OpenGL ??
# Starlink::AST (used?)

CPAN::Shell->o('conf', 'recommends_policy', '0');
CPAN::Shell->install('Astro::FITS::Header');
CPAN::Shell->o('conf', 'recommends_policy', '1');
for my $x (@list)
{
	CPAN::Shell->install($x);
}



