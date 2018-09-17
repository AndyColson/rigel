#!/usr/bin/perl

use common::sense;
use feature 'signatures';
use AnyEvent;
use AnyEvent::SerialPort;
use AnyEvent::HTTPD;
use AnyEvent::Socket;
use Text::Xslate qw(mark_raw);
use FindBin qw($Bin);
use Cwd 'abs_path';
use Data::Dumper;
use HTTP::XSCookies qw/bake_cookie crush_cookie/;
use Text::CSV_XS;
use Astro::Coords;
use lib $Bin;
use Rigel::Config;
use Rigel::LX200;

use Inline CPP => config =>
	libs => '-lqsiapi -lcfitsio -lftdi1 -lusb-1.0',
	ccflags => '-std=c++11 -I/usr/include/libftdi1 -I/usr/include/libusb-1.0';

use Inline 'CPP' => './Rigel/camera.cpp';

my $domStatus;

my $camera = new Camera();
print $camera->getInfo(), "\n";

my $cfg = Rigel::Config->new();
$cfg->set('app', 'template', "$Bin/template");

my $tt = Text::Xslate->new(
	path => $cfg->get('app', 'template'),
	cache_dir => "$Bin/cache",
	syntax => 'Metakolon'
);

main();
exit 0;

sub main
{
	my($httpd, $ra, $dec, $focus, $lx);

	$lx = new Rigel::LX200( recv => \&lxCommand );

	print "connecting to ",$cfg->get('csimc', 'HOST'),':', $cfg->get('csimc', 'PORT'), "\n";

	if (! -d "$Bin/cache")
	{
		mkdir("$Bin/cache") or die;
	}

	print "loading csimc scripts...\n";
	# -r reboot, -l load scripts.
	# system('csimc -rl < /dev/null');

	tcp_connect $cfg->get('csimc', 'HOST'), $cfg->get('csimc', 'PORT'), sub {
		my ($fh) = @_ or die "csimcd connect failed: $!";

		print "csimcd connected\n";
		$ra = new AnyEvent::Handle(
			fh     => $fh,
			on_error => sub {
				print "csimcd socket error: $_[2]\n";
				$_[0]->destroy;
			},
			on_eof => sub {
				$ra->destroy;
			}
		);
		# addr=0, why=shell=0, zero
		$ra->push_write( pack('ccc', 0, 0, 0) );
		$ra->push_read( chunk => 1, sub($handle, $data) {
				my $result = unpack('C', $data);
				print "RA connect, result: $result\n";
			}
		);

	};



	print "init http\n";
	$httpd = AnyEvent::HTTPD->new(
		host => '::',
		port => 9090,
	);
	$httpd->reg_cb(
		error => sub { my($e) = @_; print "httpd error: $e\n"; },
		request => \&webRequest
	);

	$domStatus = 'Connecting...';
	my $dome;
	eval {
		$dome = AnyEvent::SerialPort->new(
			serial_port => '/dev/ttyUSB0',   #defaults to 9600, 8n1
			on_read => \&readDomeSerial,
			on_error => sub {
				my ($hdl, $fatal, $msg) = @_;
				print "serial error: $msg\n";
				$hdl->destroy;
			}
		);
	};
	if ($@) {
		print "Connect to dome failed\n";
		print $@;
		$domStatus = $@;
		$dome = undef;
	};

	if ($dome) {
		#get us a status update
		$dome->push_write('GINF');
	}
	my $t;
	$t = AnyEvent->timer (
		after => 1,
		#interval => 1,
		cb => sub {
			print "timer fired\n";
	  }
	);



	$httpd->run();
}


sub webRequest($httpd, $req)
{
	# print Dumper($req->headers);
	my $c = $req->headers->{cookie};
	if ($c ) {
		my $values = crush_cookie($c);
		print 'cookie: ', Dumper($values), "\n";
	}

	if ($req->method eq 'POST')
	{

		my %v = $req->vars;
		my $buf = "<html><body>name = " . $req->parm('name') . '<br> method = ' . $req->method
			. '<br>path = ' . $req->url->path
			. '<br>vars = ' . Dumper(\%v);

		$req->respond ({ content => ['text/html', $buf]});
		return;
	}

	#if ($req->method eq 'GET')
	{
		my $t = $cfg->get('app', 'template');
		my $x = $t . $req->url->path;
		my $file = abs_path($x);
		# print "TMP: $x\nNew: $file\n";
		if ($file !~ /^$t/)
		{
			$req->respond([404, 'not found', { 'Content-Type' => 'text/html' }, 'Sorry, file not found']);
			return;
		}

		if ( -e $file ){

			my $buf = $tt->render($req->url->path);
			my $cookie = bake_cookie('baz', {
					value   => 'Frodo',
					expires => '+11h'
			});
			$req->respond([
				200, 'ok',
				{'Content-Type' => 'text/html; charset=utf-8',
				'Content-Length' => length($buf),
				'Set-Cookie' => $cookie
				},
				$buf
			]);
			return;
		}
	}
}


sub readDomeSerial($handle)
{
	state $buf = '';
	state $csv = Text::CSV_XS->new ({ binary => 1, auto_diag => 1 });

	$buf .= $handle->{rbuf};
	$handle->{rbuf} = '';
	exit if (! $buf);
	print "Start [$buf]\n";

	# T, Pnnnnn  (0-32767) means its moving
	# V.... \n\n is an Info Packet
	# S, Pnnnn means shutter open/close

	# dump stuff until we get to the start of something we recognize
	my $again = 1;
	while ($again)
	{
		given (substr($buf, 0, 1))
		{
			when ('T') {
				$domStatus = 'turning...';
				substr($buf, 0, 1, '');
			}
			when ('S') {
				$domStatus = 'shutter...';
				substr($buf, 0, 1, '');
			}
			when ('P') {
				if ($buf =~ /^P(\d{4})/)
				{
					$domStatus = "Azm $1";
					substr($buf, 0, 5, '');
				}
				else {
					$again = 0;
					# if we receive Pjnk1234 we'll collect till out of mem
					if (length($buf) > 15) {
						#bah..  buf is weird, kill it
						$buf = '';
					}
				}
			}
			when ('V') {
				my $at = index($buf, "\r\r");
				if ($at > -1)
				{
					my $status = $csv->parse(substr($buf, 0, $at));
					my @columns = $csv->fields();
					$domStatus = Dumper(\@columns);
					$buf = substr($buf, $at+2);
				}
				else {
					$again = 0;
					if (length($buf) > 200) {
						#something very wrong this this status, kill it
						$buf = '';
					}
				}
			}
			default {
				#toss it
				substr($buf, 0, 1, '');
			}
		}
		print "Status [$domStatus]\n";
		$again = 0 if (length($buf) == 0);
	}
	print "End [$buf]\n";
}


sub sendJson
{
	my ($j, $buf, $h, $cookie);

	($j, $cookie) = @_;

	$buf = encode_json($j);
	$h = [
		'Content-Type' => 'application/json; charset=utf-8',
		'Content-Length' => length($buf)
	];
	if ($cookie)
	{
		#		push(@$h, 'Set-Cookie' => bake_cookie(SESSKEY, $cookie));
	}
	return [ 200, $h, [$buf] ];
}

sub showTemplate($tt)
{
	my($file, $vars) = @_;
	#warn("showTemplate $file");

	my $buf;
	$buf = $tt->render($file, $vars);
	return [
		200,
		['Content-Type' => 'text/html; charset=utf-8',
		'Content-Length' => length($buf)],
		[$buf]
	];
}

sub telescopeStatus
{
=pod

	if (mip->haveenc)
	{
		double draw;
		int raw;

		/* just change by half-step if encoder changed by 1 */
		raw = csi_rix (MIPSFD(mip), "=epos;");
		draw = abs(raw - mip->raw)==1 ? (raw + mip->raw)/2.0 : raw;
		mip->raw = raw;
		mip->cpos = (2*PI) * mip->esign * draw / mip->estep;

	}
	else
	{
		mip->raw = csi_rix (MIPSFD(mip), "=mpos;");
		mip->cpos = (2*PI) * mip->sign * mip->raw / mip->step;
	}
=cut
}


sub lxCommand($coords)
{
	print "Main lxCommand\n";
	print $coords->status, "\n";
}
