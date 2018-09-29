use strict;
use warnings;
use Astro::PAL;
use Astro::Coords;

my $ra = 2505409104;
my $dec = -210784574;

#print $ra;
#print hex('0x80000000'), "\n";
my $ra2  = $ra * (3.141/0x80000000);
my $dec2 = $dec * (3.141/0x80000000);
#my $cdec = cos($dec2);
#$ra2 = $ra2 * (180 / 3.141);
#$dec2 = $dec2 * (180 / 3.141);
#print " RA: $ra2\n";
#print "Dec: $dec2\n";


my $c = new Astro::Coords(
	name => "My target",
	ra   => $ra2,
	dec  => $dec2,
	type => 'j2000',
	units=> 'radians'
);

print $c->status, "\n";

