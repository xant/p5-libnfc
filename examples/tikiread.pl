#!/usr/bin/perl

use Data::Dumper;
use Libnfc::Reader;
use Libnfc::CONSTANTS ':all';

my $r = Libnfc::Reader->new();
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
    for (my $i = 0; $i < $tag->blocks; $i++) {
        if (my $data = $tag->read_block($i)) {
            # when reading a block from an ultralight token, 
            # we receive always 16 bytes (so 4 blocks, since 
            # a single block on the token is 4bytes long)
            $i += 3 if ($tag->type eq "ULTRA");
            my $len = length($data);
            my @databytes = unpack("C".$len, $data);
            my @chars = map { ($_ > 31 and $_ < 127) ? $_ : '.' } @databytes;
            printf ("[" . "%02x" x $len . "]\t" . "%c" x $len . "\n", @databytes, @chars);
        } else {
            warn $tag->error."\n";
        }
    }
}

