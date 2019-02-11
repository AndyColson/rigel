#!/usr/bin/perl

use feature 'signatures';
use common::sense;
use Astro::Coords;
use Time::HiRes qw( gettimeofday tv_interval );
use List::Util qw/min/;
use Data::Dumper;
use lib '../Rigel';
use Simbad;

sub test
{
	my @list = (
	'*   3 Lyr',
	'8pc 128.93',
	'ADS 11510 A',
	'AG+38 1711',
	'BD+38  3238',
	'CCDM J18369+3847A',
	'CEL   4636',
	'CSI+38  3238  1',
	'CSV 101745',
	'FK5  699',
	'GC 25466',
	'GCRV 11085',
	'GEN# +1.00172167',
	'GJ   721',
	'HD 172167',
	'HGAM    706',
	'HIC  91262',
	'HIP  91262',
	'HR  7001',
	'IDS 18336+3841 A',
	'IRC -20041',
	'CD-22  1154',
	'CPD-22   352',
	'CSI-22   584  1'
	);

	for my $x (@list)
	{
		my ($catalog, $id) = split(/\-|\+|\s+/, $x, 2);
		$id =~ s/\s{2,}/ /g;
		print "[$x] = [$catalog] [$id]\n";
	}

	exit 0;
}
#test();



my $x = Simbad->new('..');
importTyco();
#find();
#$x->query('coo 3:19 -21:45 radius=20m');
#$x->query('wildcard M [0-9]');
#$x->query('vega');
#$x->query("around HD 50 radius=20m");

#my $result = $x->query("around TYC 5094-523-1 radius=20m");
#print "saved=$result->{saved} skpped=$result->{skipped} elaps=$result->{webq} / $result->{saveStar}\n";
exit 0;


sub find
{
	my $c = new Astro::Coords(
		name => "Nunki",
		ra   => '18:55:15.95',
		dec  => '-26:17:49.3',
		type => 'j2000',
		units=> 'sexagesimal'
	);
	my $star = $x->findLocal('TYC', '5094-523-1');
	#my $star = $x->findLocal('HD', '161592');
	#my $star = $x->findLocal('coord', $c);
	print Dumper($star);
	exit 0;
}


sub importHD
{
	my $saved = 0;
	my $skipped = 0;
	# 359083
	for my $series (21..35)
	{
		for my $i (0..9)
		{
			#my $star = $x->findLocal('HD', $i);
			#next if ($star);

			print "HD ${series}$i??? ";
			#my $result = $x->query("around HD $i radius=20m");
			my $result = $x->query("wildcard HD ${series}$i??? ");
			print "saved=$result->{saved} skpped=$result->{skipped} elaps=$result->{webq} / $result->{saveStar}\n";
			$saved += $result->{saved};
			$skipped += $result->{skipped};
			my $sleep = rand(5) + 8;
			print "sleep $sleep\n";
			sleep($sleep);
		}
	}
	print "\nFinished:\n";
	print "   Ttl Saved: $saved\n";
	print " Ttl Skipped: $skipped\n";
}

sub importTyco_around
{
	my $t0 = [gettimeofday];
	my $saved = 0;
	my $skipped = 0;
	my $already = 0;
	my $file = "/tmp/x/tyc2.dat.01.gz";
	open(IN, "zcat $file |") or die "gunzip $file: $!";
	while ( <IN> )
	{
		#next if ($. < 58475);

		my($id) = split(/\|/, $_, 2);
		my @key = split(' ', $id);
		for (@key)
		{
			s/^0+//d;
		}
		$id = "$key[0]-$key[1]-$key[2]";

		my $star = $x->findLocal('TYC', $id);
		if (! $star)
		{
			print "$.) $id loading\n";
			my $result = $x->query("around TYC $id radius=20m");
			my $elaps = (tv_interval($t0) / 60);  # to minutes
			print "   saved: $result->{saved} skipped: $result->{skipped} web: $result->{webq} db: $result->{saveStar}  minutes: $elaps\n";
			$saved += $result->{saved};
			$skipped += $result->{skipped};
			#last if ($saved > 20_000);
			my $sleep = min(rand(3) + 3, $result->{saved});
			$elaps = $saved / $elaps;  # saved / minute
			print "ttlsaved: $saved  skipped: $skipped  already: $already ins/min: $elaps  sleep: $sleep\n";
			if (-e 'stop')
			{
				unlink('stop');
				last;
			}
			sleep($sleep);
		} else {
			#print "$.) $id got it\n";
			$already++;
		}
	}
	print "\nFinished:\n";
	print "     Already: $already\n";
	print "   Ttl Saved: $saved\n";
	print " Ttl Skipped: $skipped\n";
}

sub importTyco
{
	# $SIG{INT} = sub { die "Caught a sigint $!, line number $.\n" };
	my $t0 = [gettimeofday];
	my $saved = 0;
	my $skipped = 0;
	my $already = 0;
	my $file = "/tmp/x/tyc2.dat.gz";
	my @list;
	open(IN, "zcat $file |") or die "gunzip $file: $!";
	while ( <IN> )
	{
		next if ($. < 2_000_000);

		my($id) = split(/\|/, $_, 2);
		my @key = split(' ', $id);
		for (@key)
		{
			s/^0+//d;
		}
		$id = "$key[0]-$key[1]-$key[2]";

		my $star = $x->findLocal('TYC', $id);
		if (! $star)
		{
			push(@list, "query id TYC $id");
			if (scalar(@list) >= 100)
			{
				print "$.) ";
				my $result = $x->query(\@list);
				@list = ();
				my $elaps = (tv_interval($t0) / 60);  # to minutes
				print "saved: $result->{saved} skipped: $result->{skipped} web: $result->{webq} db: $result->{saveStar}  minutes: $elaps\n";
				$saved += $result->{saved};
				$skipped += $result->{skipped};
				#last if ($saved > 5000);
				my $sleep = min(rand(3) + 3, $result->{saved});
				$elaps = $saved / $elaps;  # saved / minute
				print "ttlsaved: $saved  skipped: $skipped  already: $already ins/min: $elaps  sleep: $sleep\n";
				sleep($sleep);
			}
		} else {
			#print "$.) $id got it\n";
			$already++;
		}
	}
	if (scalar(@list) > 0)
	{
		my $result = $x->query(\@list);
		my $elaps = (tv_interval($t0) / 60);  # to minutes
		print "EOF) saved: $result->{saved} skipped: $result->{skipped} web: $result->{webq} db: $result->{saveStar}  minutes: $elaps\n";
		$saved += $result->{saved};
		$skipped += $result->{skipped};
		$elaps = $saved / $elaps;  # saved / minute
		print "ttlsaved: $saved  skipped: $skipped  already: $already ins/min: $elaps\n";
	}
	print "\nFinished\n";
}



