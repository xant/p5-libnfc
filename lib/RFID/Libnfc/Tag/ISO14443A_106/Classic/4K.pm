package RFID::Libnfc::Tag::ISO14443A_106::Classic::4K;

use strict;

use base qw(RFID::Libnfc::Tag::ISO14443A_106::Classic);

our $VERSION = '0.11';

# number of blocks in the tag
sub blocks {
    return 256;
}

# number of sectors in the tag
sub sectors {
    return 40;
}

1;
