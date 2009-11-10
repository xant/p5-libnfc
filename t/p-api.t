# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Libnfc.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More qw(no_plan);
use Data::Dumper;
BEGIN { use_ok('Libnfc::Reader') };
use Libnfc::CONSTANTS ':all';

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $r = Libnfc::Reader->new();

if (ok ($r->init())) {
    printf ("Reader: %s\n", $r->name);

    my $tag = $r->connectTag(IM_ISO14443A_106);

    if (ok $tag) {
        $tag->dumpInfo
    }



    my @keys = (
        pack("C6", 0x00,0x00,0x00,0x00,0x00,0x00),
        pack("C6", 0xb5,0xff,0x67,0xcb,0xa9,0x51),
    );

    $tag->setKeys(@keys);

    #warn Dumper($tag);

    my $data = $tag->read(0);
    printf("Reading sector 0 : ". "%x " x length($data) . "\n", 
            unpack("C".length($data), $data));
    my $data = $tag->readBlock(3);
    printf("Reading block 3 : ". "%x " x length($data) . "\n", 
            unpack("C".length($data), $data));
    my $acl = $tag->acl(0);
    warn Dumper($acl);
}
