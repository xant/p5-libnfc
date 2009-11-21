#!/usr/bin/perl

use Libnfc::Reader;
use Libnfc::Constants;
use Data::Dumper;

my $DEBUG = 0;

my $r = Libnfc::Reader->new( debug => $DEBUG );
while (1) {
    if (my $tag = $r->connect(IM_ISO14443A_106, 1)) {
        print "Tag: " . join ':', map { sprintf("%02x", $_) } @{$tag->uid};
        sleep 1 while ($tag->ping);
    }
}
