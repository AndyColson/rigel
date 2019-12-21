#!/usr/bin/perl
use strict;
use CPAN;

# XSCookies requires Date::Parse ?

my @list = qw(
common::sense
Digest::MD5
Term::ReadLine::Gnu
File::Temp
common::sense
Types::Serialiser
JSON::XS
DBI
DBD::SQLite
EV
AnyEvent
AnyEvent::SerialPort
AnyEvent::HTTPD
AnyEvent::Socket
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
);

# Astro::FITS::Header  (will install Tk)
# OpenGL
# PDL
# Starlink::AST (used?)

for my $x (@list)
{
	CPAN::Shell->install($x);
}



