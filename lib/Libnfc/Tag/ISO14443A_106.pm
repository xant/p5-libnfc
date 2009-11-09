package Libnfc::Tag::ISO14443A_106;

use strict;

use base qw(Libnfc::Tag);
use Libnfc qw(nfc_initiator_select_tag nfc_initiator_mifare_cmd);
use Libnfc::CONSTANTS ':all';

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
    return unless ($self->unlock($sector));
    if ($sector < 32) {
        $nblocks = 4;
        $tblock = (($sector+1) * $nblocks) -1;
    } else {
        $nblocks = 16;
        $tblock = 127 + ((($sector+1) * $nblocks) -1);
    }
    my $data;
    for (my $i = $tblock+1-$nblocks; $i < $tblock; $i++) {
        $data .= $self->readBlock($i);
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
    my ($self, $sector) = @_;
    my $tblock;
    if ($sector < 32) {
        $tblock = (($sector+1) * 4) -1;
    } else {
        $tblock = 127 + ((($sector+1) * 16) -1);
    }

    my $p = tag_info->new();
    #warn nfc_initiator_select_tag($self->{reader}->{_pdi},IM_ISO14443A_106,$self->{_pti}->abtUid,4, $p->_to_ptr);
    my $mp = mifare_param->new();
    my $mpt = $mp->_to_ptr;
    # trying key a
    $mpt->mpa($self->{keys}->[$sector][0], pack("C4", @{$self->uid}));
    #printf("%x %x %x %x %x %x ---- %x %x %x %x\n", unpack("C10", $mpt->mpa));

    return 1 if (nfc_initiator_mifare_cmd($self->{reader}->{_pdi}, MC_AUTH_A, $tblock, $mpt));
    if ($self->{keys}->[$sector][1]) {
        # trying key b
        $mpt->mpa(pack("a6C4", $self->{keys}->[$sector][1], @{$self->uid}));
        return 1 if (nfc_initiator_mifare_cmd($self->{_pdi}, MC_AUTH_B, $tblock, $mpt));
    }
    return 0;
}

1;
