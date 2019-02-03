#!/usr/bin/perl

use common::sense;
use lib '../Rigel';
use Simbad;
use feature 'signatures';

my $x = Simbad->new();
$x->initdb();
$x->query('wildcard M [0-9]');




