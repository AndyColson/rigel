#!/usr/bin/perl
use strict;
use warnings;
#use Inline 'info';  #, 'force', 'clean';

use Inline 'CPP' => Config => force_build => 1;

print "9 + 16 = ", add(9, 16), "\n";
print "9 - 16 = ", subtract(9, 16), "\n";


__END__
__CPP__

// random junk;

int add(int x, int y) {
  return x + y;
}

int subtract(int x, int y) {
  return x - y;
}
