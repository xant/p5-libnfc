#!/usr/bin/perl

use Data::Dumper;
use Libnfc::Reader;
use Libnfc::Constants;

my $DEBUG = 1;

my $r = Libnfc::Reader->new();
if ($r->init()) {
    printf ("Reader: %s\n", $r->name);
    my $tag = $r->connect(IM_ISO14443A_106);
    if ($tag and $DEBUG) {
        $tag->dump_info;
    } else {
        warn "No TAG";
        exit -1;
    }

    $tag->set_keys(@keys);

    die "Token is not a mifare ultralight" unless $tag->type eq "ULTRA";

    # doing the 2-level cascade selection process  is not necessary , 
    # but ensures we will be talking always to the same token 
    # if multiple are within the field
    $tag->select;

    if ($DEBUG) {
        print "ACL - 1 means blocked, 0 means writeable. blbits rule them all\n";
        print Data::Dumper->Dump([$tag->acl], ["ACL"]);
    }

    # Dump the entire token
    # when reading a block from an ultralight token, 
    # we receive always 16 bytes (so 4 blocks, since 
    # a single block on the token is 4bytes long)
    for (my $i = 0; $i < $tag->blocks; $i+= 3) {
        if (my $data = $tag->read_block($i)) {
            my $len = length($data);
            my @databytes = unpack("C".$len, $data);
            # let's format the output.
            # unprintable chars will be outputted as a '.' (like any other hexdumper)
            my @chars = map { ($_ > 31 and $_ < 127) ? $_ : ord('.') } @databytes; 
            printf ("[" . "%02x" x $len . "]\t" . "%c" x $len . "\n", @databytes, @chars);
        } else {
            warn $tag->error."\n";
        }
    }
}

