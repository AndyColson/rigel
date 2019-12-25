#!/usr/bin/perl

use feature 'signatures';
use common::sense;
use DBI;
use lib '../Rigel';
use Simbad;

my $lookup = Simbad->new();

my $db = $lookup->{db};

my($ttlDups) = $db->selectrow_array(q{
select count(*) from (
select catid, id, count(*)
from lookup
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
	group by catid, id
	having count(*) > 1
	limit 1
) as tmpx on tmpx.catid = catalog.catid
});

my $r = $db->prepare(q{select starid from lookup where catid = ? and id = ?});
my $loop = 0;
while (1)
{
	$q->execute();
	my $row = $q->fetchrow_arrayref();
	if (! $row)
	{
		print "No dups found\n";
		last;
	}
	my $catid = $row->[0];
	my $cat = $row->[1];
	my $id = $row->[2];

	#$catid = 1;
	#$cat = '2MASS';
	#$id = 'J00001575-3010193';
	#$id = 'J00003704-3011547';

	print "found $cat $id\n";
	$r->execute($catid, $id);
	my $ttlS = 0;
	my $ttlL = 0;
	while ($row = $r->fetchrow_arrayref)
	{
		$ttlS += $db->do("delete from star where starid = $row->[0]");
		$ttlL += $db->do("delete from lookup where starid = $row->[0]");
	}
	print "  Delete $ttlS stars, $ttlL lookups\n";
	importStar($cat, $id);
	$loop++;
	my $sleep = rand(4) + 3;
	if ($loop >= 10)
	{
		$loop = 0;
		my($done) = $db->selectrow_array(q{
		select count(*) from (
		select catid, id, count(*)
		from lookup
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
	sleep($sleep);
}
$r = undef;
$q = undef;

exit 0;

sub importStar($cat, $id)
{
	state $ttl = 0;
	my $saved = 0;
	my $skipped = 0;

	my $result = $lookup->query("around $cat $id radius=20m");
	$ttl += $result->{saved};
	printf "  Saved: %d/$ttl  skipped: %d  web: %.2f  db: %.2f\n", $result->{saved}, $result->{skipped}, $result->{webq}, $result->{saveStar};
}
