#!/usr/bin/perl

use common::sense;
use Udev::FFI;
use Data::Dumper;

my $udev = Udev::FFI->new() or
    die "Can't create Udev::FFI object: $@";

my $monitor = $udev->new_monitor() or
    die "Can't create udev monitor: $@.\n";

$monitor->filter_by_subsystem_devtype('tty');

$monitor->start();

for(;;) {
    my $device = $monitor->poll(); # blocking read
	#next if ($device->get_driver() eq 'usb');

    print 'ACTION: '.$device->get_action()."\n";
    print 'DevPath '.$device->get_devpath()."\n";
    print 'Subsystem '.$device->get_subsystem()."\n";
    print 'DevType '.$device->get_devtype()."\n";
    print 'SysPath: '.$device->get_syspath()."\n";
    print 'SysName '.$device->get_sysname()."\n";
    print 'Sysnum '.$device->get_sysnum()."\n";
    print 'DevNode '.$device->get_devnode()."\n";
    print 'Driver '.$device->get_driver()."\n";
    print 'devnum '.$device->get_devnum()."\n";
    print 'udev '.$device->get_udev()."\n";
    print 'devlinks '. Dumper($device->get_devlinks_list_entries())."\n";
    print "properties: \n";
	for my $p ( $device->get_properties_list_entries )
	{
		print "\t$p: " . $device->get_property_value($p) . "\n";
	}

    print 'tags: '. Dumper($device->get_tags_list_entries())."\n";

    print "sysattr:\n";
	for my $p ( $device->get_sysattr_list_entries )
	{
		print "\t$p: " . $device->get_sysattr_value($p) . "\n";
	}
	print "------------------\n";
}



