#!/usr/bin/perl

use common::sense;
use AnyEvent;
use AnyEvent::Strict;
use Data::Dumper;
use feature 'signatures';
use lib '../Rigel';
use Dome;

my $cv = AnyEvent->condvar;
my $dome;
$dome = Dome->new(
	port => '/dev/pts/4',
	connect_event => sub()
	{
		print "DOME: connected\n";
		print $dome->{status}, "\n";
		$dome->ginf();
	}

);

$cv->recv;

