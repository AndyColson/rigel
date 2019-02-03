#!/usr/bin/perl

use common::sense;
use Mojo::UserAgent;
use Data::Dumper;

# Fine grained response handling (dies on connection errors)
my $ua  = Mojo::UserAgent->new;
my $res = $ua->get('https://www.cedar-astronomers.org')->result;  # Mojo::Message::Response
#print $res->body;

# https://metacpan.org/pod/Mojo::DOM
my $x = $res->dom->find('form#login-form input');

my %post;

#say $x->join("\n");
#print "\n";
$x->each(sub  {
	my($e, $num) = @_;
	#print $e->attr->{type}, ' ', $e->attr->{name}, ' = ', $e->attr->{value}, "\n";
	$post{ $e->attr->{name} } = $e->attr->{value};
});

$post{username} =  'jacodeguy';
$post{password} = 'password',

#print "\nLogin:", Dumper(\%post), " \n";

$ua->max_redirects(2);

my $tx = $ua->post('https://www.cedar-astronomers.org/' => form => \%post);
if ($res = $tx->success) {
	say "Result: ", $res->code, "\n";  # "\nBody:", $res->body;
	my $x = $res->dom->find('#login-form');
	if ($x) {
		print "Login Failed\n";
	} else {
		print "Login OK!\n";
	}
}
else {
  my $err = $tx->error;
  print "$err->{code} response: $err->{message}" if $err->{code};
  print "Connection error: $err->{message}";
}




