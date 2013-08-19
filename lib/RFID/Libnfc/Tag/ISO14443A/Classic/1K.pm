package RFID::Libnfc::Tag::ISO14443A::Classic::1K;

use strict;

use base qw(RFID::Libnfc::Tag::ISO14443A::Classic);
use RFID::Libnfc;
use RFID::Libnfc::Constants;

our $VERSION = '0.13';

# number of blocks in the tag
sub blocks {
    return 16*4;
}

# number of sectors in the tag
sub sectors {
    return 16;
}

1;
