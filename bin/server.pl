#!/usr/bin/perl

use common::sense;
use feature 'signatures';
use AnyEvent;
#use AnyEvent::Strict;
use AnyEvent::Handle;
use AnyEvent::SerialPort;
use AnyEvent::HTTPD;
use AnyEvent::Socket;
use AnyEvent::ReadLine::Gnu;
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
use Proc::ProcessTable;
use lib "$Bin/..";
use Rigel::Config;
use Rigel::Stellarium;
use Rigel::LX200;
use Rigel::Simbad;
#use Memory::Usage;

# path's are relative to the server.pl script, set it as
# our cwd
BEGIN { chdir($Bin); }

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

my ($domStatus, $camera, $cfg, $term);
my ($httpd, $ra, $dec, $focus, $dome, $lx2);

my $esteps = 12976128;
my $stepsPerDegree = $esteps / 360;

# the config will open usb ports and autodetect
# whats plugged in
$cfg = Rigel::Config->new();
$cfg->set('app', 'template', abs_path('../template'));

$camera = new Camera();
print($camera->getInfo(), "\n");


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
	Long => -91.500299 * DD2R,
	Lat  => 41.889387 * DD2R,   #decimal degrees to radians
	Alt  => 246.888  # metres
);
my $simbad = Simbad->new();
my $stSocket = new Rigel::Stellarium( recv => \&stCommand );

$term = AnyEvent::ReadLine::Gnu->new(
	prompt => "rigel> ",
	on_line => \&processCmd
);

main();
exit 0;

sub main
{

	if (-r '/dev/ttyS0')
	{
		$lx2 = Rigel::LX200->new( port => '/dev/ttyS0', recv => \&lxCommand );
		if ($lx2) {
			$term->print("lx200 client listening on /dev/ttyS0\n");
		}
	}
	# create our web server
	$httpd = AnyEvent::HTTPD->new(
		host => '::',
		port => 9090,
	);
	$httpd->reg_cb(
		error => sub { my($e) = @_; $term->print("httpd error: $e\n"); },
		request => \&webRequest
	);
	$term->print("web server on port 9090\n");


	my $tmp = $cfg->get('csimc', 'TTY');
	#$tmp = 1;
	# only start daemon if we auto detected it
	if ($tmp)
	{
		$term->print("connecting to ",$cfg->get('csimc', 'HOST'),':', $cfg->get('csimc', 'PORT'), "\n");
		my $pid = findCsimcd();
		#$pid = 1;
		if (! $pid)
		{
			$term->print("loading csimc scripts...\n");
			# -r reboot, -l load scripts.
			# should start csimcd and load the *.cmc scripts.
			# wont return untill everything is ready
			system('./csimc -rl < /dev/null');
		}
		else
		{
			$term->print("csimcd is already running\n");
		}

		# each control (ra, dec, focus) gets its own connection
		tcp_connect(
			$cfg->get('csimc', 'HOST'),
			$cfg->get('csimc', 'PORT'),
			sub {
				my ($fh) = @_ or die "csimcd connect failed: $!";
				$ra = new AnyEvent::Handle(
					fh     => $fh,
					on_error => sub {
						$term->print("csimcd socket error: $_[2]\n");
						$_[0]->destroy;
					},
					on_eof => sub {
						$ra->destroy;
					},
					on_read => \&raReader
				);
				# addr=0, why=shell=0, zero
				$ra->push_write( pack('ccc', 0, 0, 0) );
				$ra->push_read( chunk => 1, sub($handle, $data) {
						my $result = unpack('C', $data);
						$term->print("RA connect, handle: $result\n");
					}
				);
			}
		);

		tcp_connect(
			$cfg->get('csimc', 'HOST'),
			$cfg->get('csimc', 'PORT'),
			sub {
				my ($fh) = @_ or die "csimcd connect failed: $!";
				$dec = new AnyEvent::Handle(
					fh     => $fh,
					on_error => sub {
						$term->print("csimcd socket error: $_[2]\n");
						$_[0]->destroy;
					},
					on_eof => sub {
						$dec->destroy;
					},
					on_read => \&decReader
				);
				# addr=1, why=shell=0, zero
				$dec->push_write( pack('ccc', 1, 0, 0) );
				$dec->push_read( chunk => 1, sub($handle, $data) {
						my $result = unpack('C', $data);
						$term->print("DEC connect, handle: $result\n");
					}
				);
			}
		);

		tcp_connect(
			$cfg->get('csimc', 'HOST'),
			$cfg->get('csimc', 'PORT'),
			sub {
				my ($fh) = @_ or die "csimcd connect failed: $!";
				$focus = new AnyEvent::Handle(
					fh     => $fh,
					on_error => sub {
						$term->print("csimcd socket error: $_[2]\n");
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
						$term->print("FOCUS connect, handle: $result\n");
					}
				);
			}
		);
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
					$term->print("serial error: $msg\n");
					$hdl->destroy;
				}
			);
		};
		if ($@) {
			$term->print("Connect to dome failed\n");
			$term->print($@, "\n");
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
			#$term->print("3-sec timer\n");
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

sub getStatus($sub)
{
	my $data = {
		status => 'telescope stuff'
	};

	my $wait = AnyEvent->condvar;

	$wait->begin(sub{
		$data->{ra} = $data->{raEncoder} / $stepsPerDegree;
		$data->{dec} = $data->{decEncoder} / $stepsPerDegree;

		$sub->($data)
	});

	$ra->push_write("=epos;\n");
	$wait->begin;

	$dec->push_write("=epos;\n");
	$wait->begin;

	$ra->push_read( line => sub {
			my($handle, $line) = @_;
			$term->print("get RA: [$line]\n");
			$data->{raEncoder} = int($line);
			$wait->end;
		}
	);
	$dec->push_read( line => sub {
			my($handle, $line) = @_;
			$term->print("get DEC: [$line]\n");
			$data->{decEncoder} = int($line);
			$wait->end;
		}
	);
	$wait->end;
}

sub webRequest($httpd, $req)
{
	# $term->print(Dumper($req->headers));
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
		$term->print("go west\n");
		slewWest();
		return sendJson($req, {});
	}
	if ($path eq '/east')
	{
		$term->print("go east\n");
		slewEast();
		return sendJson($req, {});
	}
	if ($path eq '/stop')
	{
		$term->print("Stop\n");
		allStop();
		return sendJson($req, {});
	}
	if ($path eq '/status')
	{
		return getStatus(
			sub
			{
				my($data) = @_;
				# cpos = (2*PI) * mip->esign * draw / mip->estep;
				return sendJson($req, $data);
			}
		);
	}

	my $t = $cfg->get('app', 'template');
	if ($path eq '/') {
		$path = '/index.html';
	}

	my $file = abs_path($t . $path);

	if ($file !~ /^$t/)
	{
		$term->print("uri [$path] -> [$file]: 404 bad path\n");
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
		$term->print("uri [$path] -> [$file]: 200 ok\n");
		#$mu->record('web');
		#$mu->dump();
		return;
	}
	else
	{
		$term->print("uri [$path] -> [$file]: 404 not found\n");
		$req->respond([404, '', { 'Content-Type' => 'text/html' }, 'Sorry, file not found']);
		return;
	}
}


sub raReader($handle)
{
	my $at = index($handle->{rbuf}, "\n");
	return if ($at == -1);
	my $line = substr($handle->{rbuf}, 0, $at, '');
	$term->print("RA: ", $line, "\n");
}
sub decReader($handle)
{
	my $at = index($handle->{rbuf}, "\n");
	return if ($at == -1);
	my $line = substr($handle->{rbuf}, 0, $at, '');
	$term->print("DEC: ", $line, "\n");
}

sub readDomeSerial($handle)
{
	state $buf = '';
	state $csv = Text::CSV_XS->new ({ binary => 1, auto_diag => 1 });

	$buf .= $handle->{rbuf};
	$handle->{rbuf} = '';
	exit if (! $buf);
	$term->print("Start [$buf]\n");

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
		$term->print("Status [$domStatus]\n");
		$again = 0 if (length($buf) == 0);
	}
	$term->print("End [$buf]\n");
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
	$term->print("Main stCommand\n");

	$coords->telescope($telescope);
	# $c->datetime( new Time::Piece() );
	$coords->usenow( 1 );

	$ra = $coords->ra(format => 'dec' );
	$dec = $coords->dec(format => 'dec' );
	$term->print( "J2000     RA: $ra, Dec: $dec\n");
	$term->print( "-- Database:\n");
	my $star = $simbad->findLocal('coord', $coords);
	$term->print( Dumper($star));

	$term->print( "-- Status:\n", $coords->status, "\n");
}

sub lxCommand($cmd, $handle)
{
	my $f = $lxCommands{$cmd};
	if ($f) {
		$term->print("lxCommand: $cmd\n");
		$f->($handle);
	} else {
		$term->print("unknown lxCommand: $cmd\n");
	}
}


sub startAlignment($handle)
{
	# not needed, return true
	$handle->push_write('1');
}

sub goHome($handle)
{
	$term->print("Home requested ...  I'll just fake it\n");
	#$ra->push_write('findhom();');
}

sub slewWest($handle)
{
	$ra->push_write('etvel=-15000;');
	$term->print("ok, going west\n");
}

sub slewEast($handle)
{
	$ra->push_write('etvel=15000;');
	$term->print("ok, going east\n");
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
	$dec->push_write('stop();');
}

sub processCmd($cmd, $length)
{
	$term->hide;
	given ($cmd)
	{
		when ('exit')
		{
			print("bye\n");
			exit 0;
		}
		when ('help')
		{
			showHelp();
		}
		when ('stop')
		{
			print "Stopping...\n";
			allStop();
		}
		when (['s', 'status'])
		{
			getStatus(sub{
				my($data) = @_;
				$term->print(Dumper($data));
			});
		}
		when (/^find\s+(\w+)\s+(\w+)/)
		{
			findStar($1, $2);
		}
		when (/^go\s+(\w+)\s+(.*)/)
		{
			moveMount($1, $2);
		}
		default
		{
			print("CMD: [$cmd]\n");
		}
	}
	$term->show;
}

sub moveMount($dir, $amount)
{
	my $ex = $amount * $stepsPerDegree;
	given ($dir)
	{
		when ('east')
		{
			$ra->push_write("etpos=epos-$ex;");
		}
		when ('west')
		{
			$ra->push_write("etpos=epos+$ex;");
		}
		when ('up')
		{
			$dec->push_write("etpos=epos+$ex;");
		}
		when ('down')
		{
			$dec->push_write("etpos=epos-$ex;");
		}
	}
}

sub findStar($cat, $id)
{
	print "Search [$cat] for [$id]\n";
	my $star = $simbad->findLocal($cat, $id);
	if (! $star)
	{
		print "Star not found\n";
	}
	else
	{
		my $cc = new Astro::Coords(
			name => "$cat $id",
			ra   => $star->{ra},
			dec  => $star->{dec},
			type => 'J2000',
			units=> 'degrees'
		);
		$cc->telescope($telescope);
		print $cc->status, "\n";
	}
}


sub showHelp
{
	$term->print( <<EOS );
Commands:
exit
help
status
stop
find catalog id

EOS
}

sub findCsimcd
{
	my $pt = Proc::ProcessTable->new();
	my @tab;
	for my $p ( @{$pt->table} )
	{
		if ($p->fname eq 'csimcd')
		{
			return $p->pid;
		}
	}
	return undef;
}
