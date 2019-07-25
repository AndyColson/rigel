#!/usr/bin/perl

use common::sense;
use feature 'signatures';
use AnyEvent;
use AnyEvent::SerialPort;
use AnyEvent::HTTPD;
use AnyEvent::Socket;
use Text::Xslate qw(mark_raw);
use FindBin qw($Bin);
use Data::Dumper;
use HTTP::XSCookies qw/bake_cookie crush_cookie/;
use Text::CSV_XS;
use JSON::XS;
use Astro::PAL;
use Astro::Coords;
use Astro::Telescope;
use POSIX qw(strftime);
use PDL;
use PDL::Core::Dev;
use Cwd 'abs_path';
use lib "$Bin/..";
use Rigel::Config;
use Rigel::Stellarium;
use Rigel::LX200;
use Rigel::Simbad;
#use Memory::Usage;

use Inline CPP => config =>
	libs => '-lqsiapi -lcfitsio -lftdi1 -lusb-1.0',
	ccflags => '-std=c++11 -I/usr/include/libftdi1 -I/usr/include/libusb-1.0',
	INC           => &PDL_INCLUDE,
    TYPEMAPS      => &PDL_TYPEMAP,
    AUTO_INCLUDE  => &PDL_AUTO_INCLUDE,
    BOOT          => &PDL_BOOT;

use Inline 'CPP' => '../Rigel/camera.cpp';

#my $mu = Memory::Usage->new();
#$mu->record('startup');

my ($domStatus, $camera, $cfg);
my ($httpd, $ra, $dec, $focus, $stSocket, $dome, $lx2);

$camera = new Camera();
print $camera->getInfo(), "\n";

# path's are relative to the server.pl script, set it as
# our cwd
chdir($Bin);


# the config will open usb ports and autodetect
# whats plugged in
$cfg = Rigel::Config->new();
$cfg->set('app', 'template', abs_path('../template'));

if (! -d '/tmp/cache')
{
	mkdir('/tmp/cache') or die;
}
my $tt = Text::Xslate->new(
	path => $cfg->get('app', 'template'),
	cache_dir => '/tmp/cache',
	syntax => 'Metakolon'
);

my %lxCommands = (
	':Aa#' => \&startAlignment,
	':Ga#' => \&getTime,
	':GC#' => \&getDate,
	':hS#' => \&goHome,
	':hF#' => \&goHome,
	':hP#' => \&goHome,
	':h?#' => \&homeStatus,
	':Me#' => \&slewEast,
	':Q#'  => \&allStop
);
my $telescope = new Astro::Telescope(
	Name => 'Rigel',
	Long => -91.498558 * DD2R,
	Lat  => 41.888881 * DD2R,
	Alt  => 246.888
);
my $simbad = Simbad->new();


main();
exit 0;

sub main
{
	$stSocket = new Rigel::Stellarium( recv => \&stCommand );

	if (-r '/dev/ttyS0')
	{
		$lx2 = Rigel::LX200->new( port => '/dev/ttyS0', recv => \&lxCommand );
		if ($lx2) {
			print "lx200 client listening on /dev/ttyS0\n";
		}
	}
	# create our web server
	$httpd = AnyEvent::HTTPD->new(
		host => '::',
		port => 9090,
	);
	$httpd->reg_cb(
		error => sub { my($e) = @_; print "httpd error: $e\n"; },
		request => \&webRequest
	);
	print "web server on port 9090\n";

	my $tmp = $cfg->get('csimc', 'TTY');
	# only start daemon if we auto detected it
	if ($tmp)
	{
		print "connecting to ",$cfg->get('csimc', 'HOST'),':', $cfg->get('csimc', 'PORT'), "\n";
		print "loading csimc scripts...\n";
		# -r reboot, -l load scripts.
		# should start csimcd and load the *.cmc scripts.
		# wont return untill everything is ready
		system('./csimc -rl < /dev/null');

		# each control (ra, dec, focus) gets its own connection
		tcp_connect $cfg->get('csimc', 'HOST'), $cfg->get('csimc', 'PORT'), sub {
			my ($fh) = @_ or die "csimcd connect failed: $!";
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
					print "RA connect, handle: $result\n";
				}
			);
		};

		tcp_connect $cfg->get('csimc', 'HOST'), $cfg->get('csimc', 'PORT'), sub {
			my ($fh) = @_ or die "csimcd connect failed: $!";
			$dec = new AnyEvent::Handle(
				fh     => $fh,
				on_error => sub {
					print "csimcd socket error: $_[2]\n";
					$_[0]->destroy;
				},
				on_eof => sub {
					$dec->destroy;
				}
			);
			# addr=1, why=shell=0, zero
			$dec->push_write( pack('ccc', 1, 0, 0) );
			$dec->push_read( chunk => 1, sub($handle, $data) {
					my $result = unpack('C', $data);
					print "DEC connect, handle: $result\n";
				}
			);
		};

		tcp_connect $cfg->get('csimc', 'HOST'), $cfg->get('csimc', 'PORT'), sub {
			my ($fh) = @_ or die "csimcd connect failed: $!";
			$focus = new AnyEvent::Handle(
				fh     => $fh,
				on_error => sub {
					print "csimcd socket error: $_[2]\n";
					$_[0]->destroy;
				},
				on_eof => sub {
					$focus->destroy;
				}
			);
			# addr=2, why=shell=0, zero
			$focus->push_write( pack('ccc', 2, 0, 0) );
			$focus->push_read( chunk => 1, sub($handle, $data) {
					my $result = unpack('C', $data);
					print "FOCUS connect, handle: $result\n";
				}
			);
		};
	}

	my $tmp = $cfg->get('dome', 'TTY');
	if ($tmp)
	{
		$domStatus = 'Connecting...';
		$dome = 0;
		eval {
			$dome = AnyEvent::SerialPort->new(
				serial_port => $tmp,   #defaults to 9600, 8n1
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
			$dome = 0;
		};

		if ($dome) {
			#get us a status update
			$dome->push_write('GINF');
		}
	}
	else {
		$domStatus = 'Unplugged';
	}

	my $t;
	$t = AnyEvent->timer (
		after => 3,
		interval => 3,
		cb => sub {
			if ($cfg->checkMonitor())
			{
				# usb add/removed
			}
		}
	);

	#$mu->record('ready');
	#$mu->dump();

	$httpd->run();  #start event loop, never returns
}


sub getStatus($req)
{
	my $data = {
		status => 'telescope stuff'
	};

	my $wait = AnyEvent->condvar;

	$wait->begin(sub
		{
			# cpos = (2*PI) * mip->esign * draw / mip->estep;
			return sendJson($req, $data);
		}
	);

	$ra->push_write('=epos;');
	$wait->begin;

	$dec->push_write('=epos;');
	$wait->begin;

	$ra->push_read( line => sub {
			my($handle, $line) = @_;
			print "get RA: [$line]\n";
			$data->{ra} = $line;
			$wait->end;
		}
	);
	$dec->push_read( line => sub {
			my($handle, $line) = @_;
			print "get DEC: [$line]\n";
			$data->{dec} = $line;
			$wait->end;
		}
	);
	$wait->end;
}

sub webRequest($httpd, $req)
{
	# print Dumper($req->headers);
	my $c = $req->headers->{cookie};
	if ($c ) {
		my $values = crush_cookie($c);
		#print 'cookie: ', Dumper($values), "\n";
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

	my $path = $req->url->path;
	if ($path eq '/west')
	{
		print "go west\n";
		$ra->push_write('etvel=-15000;');

		return sendJson($req, {});
	}
	if ($path eq '/east')
	{
		print "go east\n";
		slewEast();
		return sendJson($req, {});
	}
	if ($path eq '/stop')
	{
		print "Stop\n";
		allStop();
		return sendJson($req, {});
	}
	if ($path eq '/status')
	{
		return getStatus($req);
	}

	my $t = $cfg->get('app', 'template');
	if ($path eq '/') {
		$path = '/index.html';
	}

	my $file = abs_path($t . $path);

	print "uri [$path] -> [$file]";

	if ($file !~ /^$t/)
	{
		print ": 404 bad path\n";
		$req->respond([404, 'not found', { 'Content-Type' => 'text/html' }, 'Bad Path']);
		return;
	}


	if ( -e $file )
	{
		my($buf, $ctype);
		if ($file =~ /\.css$/)
		{
			open(F, '<', $file);
			local $/ = undef;
			$buf = <F>;
			close(F);
			$ctype = 'text/css; charset=utf-8';
		} elsif ($file =~ /\.js$/) {
			open(F, '<', $file);
			local $/ = undef;
			$buf = <F>;
			close(F);
			$ctype = 'application/javascript; charset=utf-8';
		} else {
			$buf = $tt->render($path);
			$ctype = 'text/html; charset=utf-8';
		}
		my $cookie = bake_cookie('baz', {
				value   => 'Frodo',
				expires => '+11h'
		});
		$req->respond([
			200, '',
			{'Content-Type' => $ctype,
			'Content-Length' => length($buf),
			'Set-Cookie' => $cookie
			},
			$buf
		]);
		print ": 200 ok\n";
		#$mu->record('web');
		#$mu->dump();
		return;
	}
	else
	{
		print ": 404 not found\n";
		$req->respond([404, '', { 'Content-Type' => 'text/html' }, 'Sorry, file not found']);
		return;
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
						#something very wrong with this status, kill it
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


sub sendJson($req, $data, $cookie=0)
{
	my $buf = encode_json($data);
	my $headers = {
		'Content-Type' => 'application/json; charset=utf-8',
		'Content-Length' => length($buf)
	};
	if ($cookie)
	{
		$headers->{'Set-Cookie'} = bake_cookie('baz', $cookie);
	}
	$req->respond([200, '', $headers, $buf]);
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

sub stCommand($coords)
{
	print "Main stCommand\n";

	$coords->telescope($telescope);
	# $c->datetime( new Time::Piece() );
	$coords->usenow( 1 );

	$ra = $coords->ra(format => 'dec' );
	$dec = $coords->dec(format => 'dec' );
	print "J2000     RA: $ra, Dec: $dec\n";
	print "-- Database:\n";
	my $star = $simbad->findLocal('coord', $coords);
	print Dumper($star);

	print "-- Status:\n", $coords->status, "\n";
}

sub lxCommand($cmd, $handle)
{
	my $f = $lxCommands{$cmd};
	if ($f) {
		print "lxCommand: $cmd\n";
		$f->($handle);
	} else {
		print "unknown lxCommand: $cmd\n";
	}
}


sub startAlignment($handle)
{
	# not needed, return true
	$handle->push_write('1');
}

sub goHome($handle)
{
	$ra->push_write('findhom();');
}

sub slewEast($handle)
{
	$ra->push_write('etvel=15000;');
	print "ok, going east\n";
}

sub getTime($handle)
{
	my $buf = strftime '%H-%M-%S', localtime();
	$buf .= '#';
	$handle->push_write($buf);
}
sub getDate($handle)
{
	my $buf = strftime '%m/%d/%y', localtime();
	$buf .= '#';
	$handle->push_write($buf);
}

sub allStop()
{
	$ra->push_write('stop();');
}

