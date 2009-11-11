package Libnfc::Tag::ISO14443A_106;

use strict;

use base qw(Libnfc::Tag);
use Libnfc qw(nfc_initiator_select_tag nfc_initiator_mifare_cmd);
use Libnfc::CONSTANTS ':all';

sub type {
    my $self = shift;
    my $type;
    my $pti;
    if (ref($self) and UNIVERSAL::isa($self, "Libnfc::Tag::ISO14443A_106")) { # instance method
        $type = $self->{_type};
        $pti = $self->{_pti};
    } else { # instance method. expecting $pti as argument
        $pti = shift; 
    }
    unless ($type) {
        $type =  
            ($pti->btSak==0x00)?"ULTRA":
            ($pti->btSak==0x08)?"1K":
            ($pti->btSak==0x09)?"MINI":
            ($pti->btSak==0x18)?"4K":
            ($pti->btSak==0x20)?"DESFIRE":
            ($pti->btSak==0x28)?"JCOP30":
            ($pti->btSak==0x38)?"JCOP40":
            ($pti->btSak==0x88)?"OYSTER":
            ($pti->btSak==0x98)?"GEMPLUS MPCOS":
            "unknown";
    }
    return $type;
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
        printf ("Uid:\t". "%02x " x scalar(@{$self->uid}). "\n", @{$self->uid});
    } else {
        printf ("Uid:\tunknown\n");
    }
    printf ("Type:\t%s\n", $self->type || "unknown");
    if ($self->atqa && scalar(@{$self->atqa})) {
        printf ("Atqa:\t%02x %02x\n", @{$self->atqa});
    } else {
        printf ("Atqa:\tunknown\n");
    }
    printf ("BtSak:\t%02x\n", $self->btSak);
    if ($self->ats) {
        printf ("Ats:\t". "%02x " x scalar(@{$self->ats}) ."\n", @{$self->ats});
    }
}

1;
