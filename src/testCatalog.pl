use strict;
use warnings;

use Astro::Catalog::Query::Vizier;
use Astro::Coords;
use Data::Dumper;

my $c = new Astro::Coords(
	name => "Nunki",
	ra   => '18:55:15.95',
	dec  => '-26:17:49.3',
	type => 'j2000',
	units=> 'sexagesimal'
);


my $gsc = new Astro::Catalog::Query::Vizier(
	# Catalog   => 'GSC',
	Catalog		=> 'I/271',
	Coords    => $c,
	Radius    => 5,   # arc minutes
	Sort      => 'RA',   # RA, DEC, RMAG, BMAG, DIST
	Nout      => 10
);

my $catalog = $gsc->querydb();
print Dumper($catalog);

