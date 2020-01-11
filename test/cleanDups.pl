#!/usr/bin/perl

use feature 'signatures';
use common::sense;
use DBI;
use lib '../Rigel';
use Simbad;

#testSplitNames();
sub testSplitNames
{
	my ($c, $i) = Simbad::splitName('OGLE17abc');
	print "[$c] [$i]\n";

	my ($c, $i) = Simbad::splitName('ZTF17abc');
	print "[$c] [$i]\n";

	my ($c, $i) = Simbad::splitName('CSI+17abc');
	print "[$c] [$i]\n";

	my ($c, $i) = Simbad::splitName('SPIRITS15mo');
	print "[$c] [$i]\n";

	my ($c, $i) = Simbad::splitName('DES15S1lyi');
	print "[$c] [$i]\n";

	my ($c, $i) = Simbad::splitName('AG+05 2572');
	print "[$c] [$i]\n";

	my ($c, $i) = Simbad::splitName('CSI+05-18391 1');
	print "[$c] [$i]\n";

	my ($c, $i) = Simbad::splitName('HD 12345');
	print "[$c] [$i]\n";

	my ($c, $i) = Simbad::splitName('[GPH2009]D634-03-01');
	print "($c) ($i)\n";

	my ($c, $i) = Simbad::splitName('[GPH2009] D634-03-01');
	print "($c) ($i)\n";

	exit 0;
}


$|++;

my $lookup = Simbad->new();

my $db = $lookup->{db};

my($ttlDups) = $db->selectrow_array(q{
select count(*) from (
select catid, id, count(*)
from lookup
where catid <> 78
group by catid, id
having count(*) > 1
)});
print "Dups: $ttlDups\n";

my $q = $db->prepare(q{
select catalog.catid, catalog.name, tmpx.id
from catalog
inner join (
	select catid, id, count(*)
	from lookup
	where catid <> 78
	group by catid, id
	having count(*) > 1
	limit 1
) as tmpx on tmpx.catid = catalog.catid
});

my $r = $db->prepare(q{select starid from lookup where catid = ? and id = ?});
my $loop = 0;
my $last;
while (1)
{
	$q->execute();
	my $row = $q->fetchrow_arrayref();
	if (! $row)
	{
		print "No dups found\n";
		last;
	}
	$lookup->{intrans} = 1;
	$db->begin_work();
	my $catid = $row->[0];
	my $cat = $row->[1];
	my $id = $row->[2];

	#$catid = 78;
	#$cat = '**';
	#$id = 'H 151';

	my $tmp = "$cat($catid) $id";
	print "$loop) found $tmp\n";
	if ($tmp eq $last)
	{
		print "already did $tmp once!\n";
		die;
	}
	$last = $tmp;
	$r->execute($catid, $id);
	my $ttlS = 0;
	my $ttlL = 0;
	while ($row = $r->fetchrow_arrayref)
	{
		#print "  rowid $row->[0]\n";
		$ttlS += $db->do("delete from star where starid = $row->[0]");
		$ttlL += $db->do("delete from lookup where starid = $row->[0]");
	}
	print "  Delete $ttlS stars, $ttlL lookups\n";
	importStar($cat, $id);
	$loop++;
	my $sleep = rand(2) + 1;
	if ($loop >= 100)
	{
		$loop = 0;
		# catid 78 = **, which is dupped
		my($done) = $db->selectrow_array(q{
		select count(*) from (
		select catid, id, count(*)
		from lookup
		where catid <> 78
		group by catid, id
		having count(*) > 1
		)});
		$done = (1 - ($done/$ttlDups)) * 100;
		printf "  Sleep: %.2f  Pct Done: %.2f\n", $sleep, $done;
	}
	else
	{
		printf "  Sleep: %.2f\n",$sleep;
	}
	$db->commit;
	$lookup->{intrans} = 0;
	if ($loop == 0)
	{
		$db->do('pragma optimize');
	}
	sleep($sleep);
}
$r = undef;
$q = undef;

exit 0;

sub importStar($cat, $id)
{
	state $ttl = 0;
	my ($result, $keep);

	$result = $lookup->query(['set limit 500', "around $cat $id radius=10m"]);
	$ttl += $result->{saved};
	$keep = $result->{saved};
	printf "  Saved1: %d/$ttl  skipped: %d  web: %.2f  db: %.2f\n", $result->{saved}, $result->{skipped}, $result->{webq}, $result->{saveStar};
	if ($result->{saved} > 2)
	{
		$result = $lookup->query(['set limit 3000', "around $cat $id radius=20m"]);
		$ttl += $result->{saved};
		printf "  Saved2: %d/$ttl  skipped: %d  web: %.2f  db: %.2f\n", $result->{saved}, $result->{skipped}, $result->{webq}, $result->{saveStar};
	}

	#$result = $lookup->query("$cat $id");
	#$ttl += $result->{saved};
	#printf "  Saved3: %d/$ttl  skipped: %d  web: %.2f  db: %.2f\n", $result->{saved}, $result->{skipped}, $result->{webq}, $result->{saveStar};

}
