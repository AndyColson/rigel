#!/usr/bin/perl
# use common::sense;
use strict;
use warnings;
use Astro::PAL;
use Astro::Coords;
use Astro::Telescope;
use Data::Dumper;

my $c = new Astro::Coords(
	name => "My target",
	ra   => '05:22:56',
	dec  => '-26:20:40.4',
	type => 'B1950',
	units=> 'sexagesimal'
);

$c = new Astro::Coords(
	name => "Nunki",
	ra   => '18:55:15.95',
	dec  => '-26:17:49.3',
	type => 'j2000',
	units=> 'sexagesimal'
);
#my $c = $c = new Astro::Coords( long => '05:22:56',
#                        lat  => '-26:20:40.4',
#                        type => 'galactic'
#);
#print "long = ", -91.498558 * DD2R, "\n";
my $tel = new Astro::Telescope(
		Name => 'Rigel',
		Long => -91.498558 * DD2R,
		Lat => 41.888881 * DD2R,
		Alt => 246.888
);

print Dumper($tel);
$c->telescope($tel);
# $c->datetime( new Time::Piece() );
$c->usenow( 1 );

my($ra, $dec) = $c->apparent;
print "Apparent: RA: $ra, Dec: $dec\n";

($ra, $dec) = $c->radec();
print "J2000     RA: $ra, Dec: $dec\n";
$ra = $c->ra(format => 'dec' );
$dec = $c->dec(format => 'dec' );
print "J2000     RA: $ra, Dec: $dec\n";

# print join("\n", Astro::Telescope->telNames);
#print join("\n", $c->array);

my($az, $el) = $c->azel();
print "Az: $az\nEl: $el\n";

#print "Status: ", $c->status, "\n";
