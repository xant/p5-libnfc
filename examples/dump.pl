#!/usr/bin/perl

use Data::Dumper;
use Libnfc::Reader;
use Libnfc::CONSTANTS ':all';
my @keys = (
    # default keys
    pack("C6", 0x00,0x00,0x00,0x00,0x00,0x00),
    pack("C6", 0xb5,0xff,0x67,0xcb,0xa9,0x51),

#   ... add your keys here in the format [ keya, keyb ] ...
#   for instance : 
#   [ pack("C6", 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF),
#     pack("C6", 0xAA, 0xAA, 0xAA, 0xAA, 0xAA, 0xAA) ],
#   one couple for each sector. The index inside this array must
#   coincide with the sector number they open.
#

);

my $r = Libnfc::Reader->new(debug => 1);

if ($r->init()) {
    printf ("Reader: %s\n", $r->name);

    my $tag = $r->connect(IM_ISO14443A_106);

    if ($tag) {
        $tag->dump_info;
    } else {
        warn "No TAG";
        exit -1;
    }

    $tag->set_keys(@keys);

    $tag->select;
    open(DUMP, ">./dump") or die "Can't open dump file: $!";
    for (my $i = 0; $i < $tag->blocks; $i++) {
        if (my $data = $tag->read_block($i)) {
            print DUMP $data;
        } else {
            warn $tag->error."\n";
            if ($tag->type eq "4K") {
                print DUMP "" x 16
            }
        }
    }
    close(DUMP);
}

