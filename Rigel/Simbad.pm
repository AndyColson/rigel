package Simbad;
use common::sense;
use Net::Curl::Easy qw(:constants);
use DBI;
use feature 'signatures';
  use Time::HiRes qw( gettimeofday tv_interval );

sub new {
	my $class = shift;
	my $obj = {
		curl	=> Net::Curl::Easy->new(),
		db		=> 0,
		@_
	};
	my $c = $obj->{curl};
	$c->setopt(CURLOPT_SSL_VERIFYPEER, 0 );
	$c->setopt(CURLOPT_USERAGENT, "Net::Curl/$Net::Curl::VERSION");
	#$c->setopt(CURLOPT_VERBOSE, 1 );
	$c->setopt(CURLOPT_CONNECTTIMEOUT, 5);
	$c->setopt(CURLOPT_ACCEPT_ENCODING, '');  # accept any
	$c->setopt(CURLOPT_FOLLOWLOCATION, 1);
	$c->setopt(CURLOPT_MAXREDIRS, 4);

	return bless $obj, $class;
}

sub initdb($self)
{
	my $t0 = [gettimeofday];
	my $db = DBI->connect("dbi:SQLite:dbname=stars.sqlite");
	$db->do('create table if not exists star(mainid text not null primary key, ra float, dec float, type text, plx float, pmra float, pmdec float, radial float, redshift float, spec text, bmag float, vmag float)');
	$db->do('create table if not exists lookup(mainid text not null, altname text)');
	$self->{db} = $db;
	print "initdb: ", tv_interval ( $t0, [gettimeofday]), "\n";
}

sub query($self, $id)
{
	my $t0 = [gettimeofday];
	my $c = $self->{curl};

	$c->setopt(CURLOPT_HTTPGET, 1);
	#my $url = 'http://simbad.u-strasbg.fr/simbad/sim-script?script=' . $c->escape("output console=off script=off\n"
	my $url = 'http://simbad.harvard.edu/simbad/sim-script?script=' . $c->escape("output console=off script=off\n"
		. 'format object "%IDLIST(1)\n'
		. '%COO(d;A)\n'
		. '%COO(d;D)\n'
		. '%OTYPELIST\n'
		. '%PLX(V)\n'
		. '%PM(A)\n'
		. '%PM(D)\n'
		. '%RV(V)\n'
		. '%RV(Z)\n'
		. '%SP(S)\n'
		. '%FLUXLIST(B)[%flux(F)]\n'
		. '%FLUXLIST(V)[%flux(F)]\n'
		. '%IDLIST\n'
		. "\n"
		. "set epoch J2000\n"
		. "set limit 10\n"
		. "query id $id\n"
	);

	$c->setopt( CURLOPT_URL, $url);
	my $resp;
	$c->setopt(CURLOPT_WRITEDATA,  \$resp);
	eval { $c->perform(); };
	if ($@) {
		die "curl failed: $@";
	}
	print "webq ", tv_interval ( $t0, [gettimeofday]), "\n";
	$t0 = [gettimeofday];
	my $x = $c->getinfo(CURLINFO_HTTP_CODE);
	my $db = $self->{db};
	if ($x == 999)
	{
		$db->begin_work;
		my $q = $db->prepare('insert into star(mainid, ra, dec, type, plx, pmra, pmdec, radial, redshift, spec, bmag, vmag) '
			. ' values (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?) '
		);

		my @list = split(/\n/, $resp);
		$q->execute( @list[0 .. 11] );

		$q = $db->prepare('insert into lookup(mainid, altname) values (?,?)');
		for my $alt ( @list[12 .. $#list] )
		{
			if ($list[0] ne $alt) {
				$q->execute( $list[0], $alt );
			}
		}
		$q = undef;
		$db->commit;
		print "insert ", tv_interval ( $t0, [gettimeofday]), "\n";
	}

	print "Result Code: $x\n[$resp]\n";
}


1;

