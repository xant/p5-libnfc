package Libnfc::Tag::ISO14443A_106;

use strict;

use base qw(Libnfc::Tag);
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
my %data_acl = (
    0 => [ 3, 3, 3, 3 ],
    1 => [ 3, 0, 0, 3 ],
    2 => [ 3, 0, 0, 0 ],
    3 => [ 2, 2, 0, 0 ],
    4 => [ 3, 2, 0, 0 ],
    5 => [ 2, 0, 0, 0 ],
    6 => [ 3, 2, 2, 3 ],
    7 => [ 0, 0, 0, 0 ]
);

sub type {
    my $self = shift;
    unless ($self->{_type}) {
        $self->{_type} = 
             ($self->{_pti}->btSak==0x00)?"ULTRA":
             ($self->{_pti}->btSak==0x08)?"1K":
             ($self->{_pti}->btSak==0x09)?"MINI":
             ($self->{_pti}->btSak==0x18)?"4K":
             ($self->{_pti}->btSak==0x20)?"DESFIRE":
             ($self->{_pti}->btSak==0x28)?"JCOP30":
             ($self->{_pti}->btSak==0x38)?"JCOP40":
             ($self->{_pti}->btSak==0x88)?"OYSTER":
             ($self->{_pti}->btSak==0x98)?"GEMPLUS MPCOS":
             "unknown";
    }
    return $self->{_type};
}

sub atqa {
    my $self = shift;
    unless ($self->{_atqa}) {
        #$self->{_atqa} = [ $self->{_pti}->abtAtqa1, $self->{_pti}->abtAtqa2 ];
        $self->{_atqa} = [ unpack("CC", $self->{_pti}->abtAtqa) ];
    }
    return $self->{_atqa};
}

sub uid {
    my $self = shift;
    unless ($self->{_uid}) {
        my $uidLen = $self->{_pti}->uiUidLen;
        if ($uidLen) {
            $self->{_uid} = [ unpack("C".$uidLen, $self->{_pti}->abtUid) ];
        }
    }
    return $self->{_uid};
}

sub btSak {
    my $self = shift;
    unless ($self->{_btSak}) {
        $self->{_btSak} = $self->{_pti}->btSak;
    }
    return $self->{_btSak};
}

sub ats {
    my $self = shift;
    unless ($self->{_ats}) {
        if ($self->{_pti}->uiAtsLen) {
            my $atsLen = $self->{_pti}->uiAtsLen;
            my $self->{_ats} = [ unpack("C".$atsLen, $self->{_pti}->abtAts) ];
        }
    }
    return $self->{_ats};
}

sub dumpInfo {
    my $self = shift;
    if ($self->uid) {
        printf ("Uid:\t". "%x " x scalar(@{$self->uid}). "\n", @{$self->uid});
    } else {
        printf ("Uid:\tunknown\n");
    }
    printf ("Type:\t%s\n", $self->type || "unknown");
    if ($self->atqa && scalar(@{$self->atqa})) {
        printf ("Atqa:\t%x %x\n", @{$self->atqa});
    } else {
        printf ("Atqa:\tunknown\n");
    }
    printf ("BtSak:\t%x\n", $self->btSak);
    if ($self->ats) {
        printf ("Ats:\t". "%x " x scalar(@{$self->ats}) ."\n", @{$self->ats});
    }
}

sub readBlock {
    my ($self, $block) = @_;

    my $mp = mifare_param->new();
    my $mpt = $mp->_to_ptr;
    if (nfc_initiator_mifare_cmd($self->{reader}->{_pdi},MC_READ,$block,$mpt)) {
        my $j = $mpt->mpd;
        return unpack("a16", $mpt->mpd); 
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
    my $keytype = MC_AUTH_A; #defaults to KeyA
    for (my $i = $tblock+1-$nblocks; $i < $tblock; $i++) {
        my $step = ($sector < 32)?4:16;
        my $datanum = "data".($i % $step);
        if ($acl && $acl->{parsed}->{$datanum}) {
            unless (@{$data_acl{$acl->{parsed}->{$datanum}}}[0]) {
                $self->{_last_error} = "ACL denies reads on sector $sector, block $i";
                return undef;
            }
            #warn Dumper($acl);
            my $newkey = (@{$data_acl{$acl->{parsed}->{$datanum}}}[0] == 2) ? MC_AUTH_B : MC_AUTH_A;
            if ($newkey != $keytype) {
                $keytype = $newkey;
                $self->unlock($sector, $keytype);
            }
        }
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
    #warn nfc_initiator_select_tag($self->{reader}->{_pdi},IM_ISO14443A_106,$self->{_pti}->abtUid,4, $p->_to_ptr);
    my $mp = mifare_param->new();
    my $mpt = $mp->_to_ptr;
    # trying key a
    $mpt->mpa($self->{keys}->[$sector][$keyidx], pack("C4", @{$self->uid}));
    # TODO - introduce debug-flag and proper debug messages
    #printf("%x %x %x %x %x %x ---- %x %x %x %x\n", unpack("C10", $mpt->mpa));

    return 1 if (nfc_initiator_mifare_cmd($self->{reader}->{_pdi}, $keytype, $tblock, $mpt));
    return 0;
}

sub acl {
    my ($self, $sector) = @_;
    my $tblock = $self->_trailer_block($sector);

    if ($self->unlock($sector)) {
        my $data = $self->readBlock($tblock);
        #return unpack("x6a4x6", $data) if ($data);
        return $self->_parse_acl(unpack("x6a4x6", $data)) if ($data);
    }
    return undef;
}

sub _parse_acl {
    my ($self, $data) = @_;
    my ($b1, $b2, $b3, $b4) = unpack("C4", $data);
    my %acl = (
        raw => { 
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
        data0   => $acl{raw}->{c1}->[0] | ($acl{raw}->{c2}->[0] << 1) | ($acl{raw}->{c3}->[0] << 2),
        data1   => $acl{raw}->{c1}->[1] | ($acl{raw}->{c2}->[1] << 1) | ($acl{raw}->{c3}->[1] << 2),
        data2   => $acl{raw}->{c1}->[2] | ($acl{raw}->{c2}->[2] << 1) | ($acl{raw}->{c3}->[2] << 2),
        trailer => $acl{raw}->{c1}->[3] | ($acl{raw}->{c2}->[3] << 1) | ($acl{raw}->{c3}->[3] << 2)
    };

    return wantarray?%acl:\%acl;
}

sub _trailer_block {
    my ($self, $sector) = @_;
    if ($sector < 32) {
        return (($sector+1) * 4) -1;
    } else {
        return  127 + ((($sector+1) * 16) -1);
    }
}

1;
