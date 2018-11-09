#!/usr/bin/bash

https://github.com/liberfa/erfa
https://github.com/Starlink/pal
sbo cfitsio, vips

qsiapi


# one time: curl -L https://cpanmin.us | perl - --sudo App::cpanminus
/usr/local/bin/cpanm  --skip-installed \
	File::Temp  \
	common::sense \
	Config::Tiny \
	Types-Serialiser \
	JSON::XS \
	DBI \
	DBD::SQLite \
	EV \
	AnyEvent \
	AnyEvent::SerialPort \
	AnyEvent::HTTPD \
	AnyEvent::Socket \
	Text::Xslate \
	HTTP::XSCookies \
	Text::CSV_XS \
	Astro::PAL \
	Astro::Coords \
	Udev::FFI \
	Net::Curl \
	Inline::CPP

# XSCookies requires Date::Parse



