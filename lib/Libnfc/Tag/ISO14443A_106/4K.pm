package Libnfc::Tag::ISO14443A_106::4K;

use strict;

use base qw(Libnfc::Tag::ISO14443A_106);
use Libnfc qw(nfc_initiator_select_tag nfc_initiator_mifare_cmd);
use Libnfc::CONSTANTS ':all';

# Internal representation of TABLE 3 (M001053_MF1ICS50_rev5_3.pdf)
# the key are the actual ACL bits (C1 C2 C3) ,
# the value holds read/write condition for : KeyA, ACL, KeyB
# possible values for read and write conditions are :
#    0 - operation not possible
#    1 - operation possible using Key A
#    2 - operation possible using Key B
#    3 - operation possible using either Key A or Key B
#   
# for instance: 
#
#   3 => { A => [ 0, 2 ], ACL => [ 3, 2 ], B => [ 0, 2 ] },
#
#   means that when C1C2C3 is equal to 011 (3) and so we can :
#      - NEVER read keyA
#      - write keyA using KeyB
#      - read ACL with any key (either KeyA or KeyB)
#      - write ACL using KeyB
#      - NEVER read KeyB
#      - write KeyB using KeyB
my %trailer_acl = (
    #    | KEYA   R  W  | ACL      R  W  | KEYB   R  W   | 
    0 => { A => [ 0, 1 ], ACL => [ 1, 0 ], B => [ 1, 1 ] },
    1 => { A => [ 0, 1 ], ACL => [ 1, 1 ], B => [ 1, 1 ] },
    2 => { A => [ 0, 1 ], ACL => [ 1, 0 ], B => [ 1, 0 ] },
    4 => { A => [ 0, 2 ], ACL => [ 3, 0 ], B => [ 0, 2 ] },
    3 => { A => [ 0, 2 ], ACL => [ 3, 2 ], B => [ 0, 2 ] },
    5 => { A => [ 0, 0 ], ACL => [ 3, 2 ], B => [ 0, 0 ] },
    6 => { A => [ 0, 0 ], ACL => [ 3, 0 ], B => [ 0, 0 ] },
    7 => { A => [ 0, 0 ], ACL => [ 3, 0 ], B => [ 0, 0 ] }
);

# Internal representation of TABLE 4 (M001053_MF1ICS50_rev5_3.pdf)
# the key are the actual ACL bits (C1 C2 C3) ,
# the value holds read, write, increment and decrement/restore conditions for the datablock
# possible values for any operation are :
#    0 - operation not possible
#    1 - operation possible using Key A
#    2 - operation possible using Key B
#    3 - operation possible using either Key A or Key B
#
# for instance: 
#
#   4 => [ 3, 2, 0, 0 ],
#   
#   means that when C1C2C3 is equal to 100 (4) and so we can :
#       - read the block using any key (either KeyA or KeyB)
#       - write the block using KeyB
#       - never increment the block
#       - never decrement/restore the block
#
my %data_acl = (            # read, write, increment, decrement/restore/transfer
    0 => [ 3, 3, 3, 3 ],    #  A|B   A|B      A|B        A|B
    1 => [ 3, 0, 0, 3 ],    #  A|B   never    never      A|B
    2 => [ 3, 0, 0, 0 ],    #  A|B   never    never      never
    3 => [ 2, 2, 0, 0 ],    #  B     B        never      never
    4 => [ 3, 2, 0, 0 ],    #  A|B   B        never      never
    5 => [ 2, 0, 0, 0 ],    #  B     never    never      never
    6 => [ 3, 2, 2, 3 ],    #  A|B   B        B          A|B
    7 => [ 0, 0, 0, 0 ]     #  never never    never      never
);

sub readBlock {
    my ($self, $block, $noauth) = @_;

    use integer; # force integer arithmetic to round divisions

    my $sector; # sort out the sector we are going to access
    if ($block < 128) { # small data blocks : 4 x 16 bytes
        $sector = $block/4;
    } else { # big datablocks : 16 x 16 bytes
        $sector = 32 + ($block - 128)/16;
    }
    
    # check the ack for this datablock
    my $acl = $self->acl($sector);
    my $step = ($sector < 32)?4:16;
    my $datanum = "data".($block % $step);
    if ($acl && $acl->{parsed}->{$datanum}) {
        unless (@{$data_acl{$acl->{parsed}->{$datanum}}}[0]) {
            $self->{_last_error} = "ACL denies reads on sector $sector, block $block";
            return undef;
        }
    }

    # try to do authentication only if we have required keys loaded
    if (scalar(@{$self->{_keys}}) >= $sector && !$noauth) { 
        return undef unless 
            $self->unlock($sector, (@{$data_acl{$acl->{parsed}->{$datanum}}}[0] == 2) ? MC_AUTH_B : MC_AUTH_A);
    }
    my $mp = mifare_param->new();
    my $mpt = $mp->_to_ptr;
    if (nfc_initiator_mifare_cmd($self->{reader}->{_pdi}, MC_READ, $block, $mpt)) {
        return unpack("a16", $mpt->mpd); 
    } else {
        $self->{_last_error} = "Error reading $sector, block $block"; # XXX - does libnfc provide any clue on the ongoing error?
    }
    return undef;
}

sub writeBlock {
    my ($self, $block) = @_;
}

sub readSector {
    my ($self, $sector) = @_;
    my $tblock;
    my $nblocks;
    if ($sector < 32) {
        $nblocks = 4;
        $tblock = (($sector+1) * $nblocks) -1;
    } else {
        $nblocks = 16;
        $tblock = 127 + (($sector - 31) * $nblocks);
    }
    my $data;
    my $acl = $self->acl($sector);

    return unless ($self->unlock($sector));
    for (my $i = $tblock+1-$nblocks; $i < $tblock; $i++) {
        my $step = ($sector < 32)?4:16;
        my $newdata = $self->readBlock($i);
        unless (defined $newdata) {
            $self->{_last_error} = "read failed on block $i";
            return undef;
        }
        $data .= $newdata;
    }
    return $data;
}

sub writeSector {
    my ($self, $sector, $data) = @_;
}

sub read {
    my $self = shift;
    return $self->readSector(@_);
}

sub write {
    my $self = shift;
    return $self->writeSector(@_);
}

sub unlock {
    my ($self, $sector, $keytype) = @_;
    my $tblock = $self->_trailer_block($sector);

    $keytype = MC_AUTH_A unless ($keytype and ($keytype == MC_AUTH_A or $keytype == MC_AUTH_B));
    my $keyidx = ($keytype == MC_AUTH_A) ? 0 : 1;
    my $p = tag_info->new();
    #warn nfc_initiator_select_tag($self->{reader}->{_pdi}, IM_ISO14443A_106, $self->{_pti}->abtUid, 4, $p->_to_ptr);
    my $mp = mifare_param->new();
    my $mpt = $mp->_to_ptr;
    # trying key a
    $mpt->mpa($self->{_keys}->[$sector][$keyidx], pack("C4", @{$self->uid}));
    # TODO - introduce debug-flag and proper debug messages
    #printf("%x %x %x %x %x %x ---- %x %x %x %x\n", unpack("C10", $mpt->mpa));

    return 1 if (nfc_initiator_mifare_cmd($self->{reader}->{_pdi}, $keytype, $tblock, $mpt));
    $self->{_last_error} = "Failed to authenticate on sector $sector (tblock:$tblock) with key ".
        sprintf("%x %x %x %x %x %x\n", unpack("C6", $mpt->mpa));
        
    return 0;
}

sub acl {
    my ($self, $sector) = @_;
    my $tblock = $self->_trailer_block($sector);

    if ($self->unlock($sector)) {
        my $mp = mifare_param->new();
        my $mpt = $mp->_to_ptr;
        if (nfc_initiator_mifare_cmd($self->{reader}->{_pdi}, MC_READ, $tblock, $mpt)) {
            my $j = $mpt->mpd;
            return $self->_parse_acl(unpack("x6a4x6", $mpt->mpd));
        }
    }
    return undef;
}

# ACL decoding according to specs in M001053_MF1ICS50_rev5_3.pdf
sub _parse_acl {
    my ($self, $data) = @_;
    my ($b1, $b2, $b3, $b4) = unpack("C4", $data);
    # TODO - extend to doublecheck using inverted flags (as suggested in the spec)
    my %acl = (
        bits => { 
            c1 => [
                ($b2 >> 4) & 1,
                ($b2 >> 5) & 1,
                ($b2 >> 6) & 1,
                ($b2 >> 7) & 1,
            ],
            c2 => [
                ($b3) & 1,
                ($b3 >> 1) & 1,
                ($b3 >> 2) & 1,
                ($b3 >> 3) & 1,
            ],
            c3 => [
                ($b3 >> 4) & 1,
                ($b3 >> 5) & 1,
                ($b3 >> 6) & 1,
                ($b3 >> 7) & 1,
            ]
        }
    );
    $acl{parsed} = {
        data0   => $acl{bits}->{c1}->[0] | ($acl{bits}->{c2}->[0] << 1) | ($acl{bits}->{c3}->[0] << 2),
        data1   => $acl{bits}->{c1}->[1] | ($acl{bits}->{c2}->[1] << 1) | ($acl{bits}->{c3}->[1] << 2),
        data2   => $acl{bits}->{c1}->[2] | ($acl{bits}->{c2}->[2] << 1) | ($acl{bits}->{c3}->[2] << 2),
        trailer => $acl{bits}->{c1}->[3] | ($acl{bits}->{c2}->[3] << 1) | ($acl{bits}->{c3}->[3] << 2)
    };

    return wantarray?%acl:\%acl;
}

# compute the trailer block number for a given sector
sub _trailer_block {
    my ($self, $sector) = @_;
    if ($sector < 32) {
        return (($sector+1) * 4) -1;
    } else {
        return 127 + (($sector - 31) * 16);
    }
}

# number of blocks in the tag
sub blocks {
    return 256;
}

# number of sectors in the tag
sub sectors {
    return 40;
}

1;
