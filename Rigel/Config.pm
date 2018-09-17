package Rigel::Config;

use common::sense;
use feature 'signatures';
use DBI;

sub new($class)
{
	my $self = {modified => 0};
	bless($self, $class);
	$self->{db} = DBI->connect("dbi:SQLite:dbname=$ENV{TELHOME}/config.sqlite");
	$self->{app} = {};
	return $self;
}

sub set($self, $app, $key, $value)
{
	if ($app eq 'app')
	{
		$self->{app}->{$key} = $value;
	}
}

sub get($self, $app, $key)
{
	my($q, $value);
	if ($app eq 'app')
	{
		return $self->{app}->{$key};
	}
	$q = $self->{db}->prepare_cached('select value from config where app = $1 and key = $2');
	$q->execute($app, $key);
	($value) = $q->fetchrow_array;
	$q->finish;
	return $value;
}

1;
