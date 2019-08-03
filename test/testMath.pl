#!/usr/bin/perl

use feature 'signatures';
use common::sense;
use Astro::Coords;
use Astro::PAL;
use Astro::Telescope;
use Time::HiRes qw( gettimeofday tv_interval );
use Data::Dumper;
use lib '../Rigel';
use Simbad;

$Astro::Coords::DEBUG = 1;

my $telescope = new Astro::Telescope(
	Name => 'Rigel',
	Long => -91.498558 * DD2R,
	Lat  => 41.888881 * DD2R,
	Alt  => 246.888
);

my $simbad = Simbad->new();
my $star = $simbad->findLocal('BMB', '1');

if (! $star)
{
	die;
}


my $cc = new Astro::Coords(
	name => "test",
	ra   => $star->{ra},
	dec  => $star->{dec},
	type => 'J2000',
	units=> 'degrees'
);

#$cc->usenow( 1 );
#$cc->datetime_is_unsafe(1);
$cc->telescope($telescope);
#print "-- Status:\n", $cc->status, "\n";
#print "usenow: ", $cc->usenow, "\n";

print " Hour angle: ", $cc->ha( format => "h"), " hours\n";
print " Hour angle: ", $cc->ha( format => "d"), " degrees\n";
print " Hour angle: ", $cc->ha( format => "s"), " h:m:s\n";
print "Apparent RA: ", $cc->ra_app( format => 'd'), " degrees\n";
print "Apparent RA: ", $cc->ra_app( format => 's'), " h:m:s\n";
print "    Azimuth: ", $cc->az( format => 'd'), " degrees\n";
print "    Azimuth: ", $cc->az( format => 's'), " h:m:s\n";
print "        LST: ", $cc->_lst( format => "d"), " degrees\n";
print "        LST: ", $cc->_lst->hours, " hours\n";

=pod
my ($ra, $dec) = $cc->radec();
#print "J2000     RA: $ra, Dec: $dec\n";

print "polaris: $polaris->{ra}\n";
print "    hip: $hip->{ra}\n";
print "polaris - hip = ", $polaris->{ra} - $hip->{ra}, "\n";
=cut

=pod
https://stackoverflow.com/questions/7570808/how-do-i-calculate-the-difference-of-two-angle-measures/30887154
https://stackoverflow.com/questions/1878907/the-smallest-difference-between-2-angles

 public static int distance(int alpha, int beta) {
        int phi = Math.abs(beta - alpha) % 360;       // This is either the distance or 360 - distance
        int distance = phi > 180 ? 360 - phi : phi;
        return distance;
    }

=cut

