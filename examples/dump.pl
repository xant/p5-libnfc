#!/usr/bin/perl

use Data::Dumper;
use Libnfc::Reader;
use Libnfc::CONSTANTS ':all';
my @keys = (
# my card-specific keys

#   ... add your keys here in the format [ keya, keyb ] ...
#   for instance : 
#   [ pack("C6", 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF),
#     pack("C6", 0xAA, 0xAA, 0xAA, 0xAA, 0xAA, 0xAA) ],
#   one couple for each sector. The index inside this array must
#   coincide with the sector number they open.
#
);


my $DEBUG = 1;

my $r = Libnfc::Reader->new(debug => 1);

if ($r->init()) {
    printf ("Reader: %s\n", $r->name);

    my $tag = $r->connectTag(IM_ISO14443A_106);

    if ($tag && $DEBUG) {
        $tag->dumpInfo
    } else {
        warn "No TAG";
        exit -1;
    }

    $tag->setKeys(@keys);

    for (my $i = 0; $i < $tag->blocks; $i++) {
        if (my $data = $tag->readBlock($i)) {
            printf("%3d : ". "%02x " x length($data) . "\n", 
                $i, unpack("C".length($data), $data));
        } else {
            warn $tag->error;
        }
    }
}
