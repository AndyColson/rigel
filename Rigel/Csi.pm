package Csi;

use common::sense;
use feature 'signatures';
use AnyEvent;
use AnyEvent::Socket;
use AnyEvent::Handle;

sub new
{
	my $class  = shift;
	my $self = {
		host => '127.0.0.1',
		port => 7623,
		hwaddr => 0,
		error => 0,
		ready => 0,
		connect_event => sub($msg) {  },
		@_,
	};
	bless($self, $class);
	$self->connect();
	return $self;
}

sub home($self)
{
	$self->{handle}->push_write("findhome;\n");
}

sub etpos_offset($self, $offset)
{
	if ($offset > 0) {
		$self->{handle}->push_write("etpos=epos+$offset;\n");
	}
	else {
		$self->{handle}->push_write("etpos=epos$offset;\n");
	}}
}

sub etpos($self, $value)
{
	$self->{handle}->push_write("etpos=$value;\n");
}

sub stop($self)
{
	$self->{handle}->push_write("\x03stop();\n");
}

sub etvel($self, $value)
{
	$self->{handle}->push_write("etvel=$value;\n");
}

sub epos($self, $cb)
{
	$self->{handle}->push_read(
		line => sub($handle, $line, $eol)
		{
			$cb->($line);
		}
	);
	$self->{handle}->push_write("=epos;\n");
}

sub reader($self, $handle)
{
	my $at = CORE::index($handle->{rbuf}, "\n");
	while ($at > -1)
	{
		my $line = substr($handle->{rbuf}, 0, $at+1, '');
		chomp($line);
		push($self->{lines}->@*, $line);
		$at = CORE::index($handle->{rbuf}, "\n");
	}
}

sub connect($self)
{
	tcp_connect(
		$self->{host},
		$self->{port},
		sub {
			$self->{fh} = shift;
			if (! $self->{fh})
			{
				$self->{error} = "csimcd connect failed: $!";
				$self->{connect_event}->();
				return;
			}

			#print "fh = ", $fh->{fh}, "\n";
			$self->{handle} = new AnyEvent::Handle(
				fh			=> $self->{fh},
				rbuf_max	=> 12 * 1024,		# 12k max
				on_error	=> sub($hdl, $fatal, $msg) {
					$self->{error} = "csimcd socket error: $msg";
					$hdl->destroy;
					$self->{handle} = 0;
					$self->{fh} = 0;
				},
				on_eof		=> sub {
					$self->{handle}->destroy;
					$self->{handle} = 0;
					$self->{fh} = 0;
				},
				on_read		=> sub { $self->reader(@_) }
			);
			# addr, why=shell=0, zero
			$self->{handle}->push_write( pack('ccc', $self->{hwaddr}, 0, 0) );
			$self->{handle}->push_read( chunk => 1, sub($handle, $data) {
					my $result = unpack('C', $data);
					$self->{ready} = 1;
					$self->{connect_event}->("connect handle: $result");
				}
			);
		}
	);
}


1;
