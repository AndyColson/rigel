#!/usr/bin/perl

use common::sense;
use Device::SerialPort;

my $tty = Device::SerialPort->new('/dev/ttyUSB0') || die "Can't open: $!\n";
$tty->databits(8);
$tty->baudrate(38400);
$tty->parity("none");
$tty->stopbits(1);
$tty->handshake("none");
$tty->write_settings    || die "no settings";


$tty->purge_all;
$tty->lookclear();

$tty->read_char_time(0);     # don't wait for each character
$tty->read_const_time(1000); # 1 second per unfulfilled "read" call

sendPing();

while (1)
{
	my ($count, $buf) = $tty->read(1);
	print "read count $count\n";
	if ($count == 1)
	{
		my $x = unpack('C', $buf);
		print "::$x\n";
		if ($x == 0x88)
		{
			my ($count, $buf) = $tty->read(5);
			if ($count == 5)
			{
				my ($to, $from, $syn, $count, $crc) = unpack('C*', $buf);
				print "got a good packet\n";
			} else {
				print "read packet failed\n";
			}
		}
	}
}


sub sendPing
{
	my $buf = pack('CCCCCC', 0x88, 0x00, 0x20, 0x16, 0x00, 0xbe);
	open(F, '>', 'out');
	print F $buf;
	close(F);
	my $x = $tty->write($buf);
	print "wrote $x bytes\n";

}

