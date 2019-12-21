#!/usr/bin/perl
use strict;
use warnings;
use Inline 'timers'; #, 'noisy'; # 'info';  #, 'force', 'clean';
#use Inline Config => force_build => 1;
use Inline 'C';

print "9 + 16 = ", add(9, 16), "\n";
print "9 - 16 = ", subtract(9, 16), "\n";


__END__
__C__

// random junk;

int add(int x, int y) {
  return x + y;
}

int subtract(int x, int y) {
  return x - y;
}
