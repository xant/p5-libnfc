package Libnfc::Tag::ISO14443A_106::ULTRA;

use strict;

use base qw(Libnfc::Tag::ISO14443A_106);
use Libnfc qw(nfc_initiator_select_tag nfc_initiator_mifare_cmd);
use Libnfc::CONSTANTS ':all';

sub readBlock {
    my ($self, $block, $noauth) = @_;
    my $mp = mifare_param->new();
    my $mpt = $mp->_to_ptr;
    if (nfc_initiator_mifare_cmd($self->{reader}->{_pdi}, 0x30, $block, $mpt)) {
        return unpack("a16", $mpt->mpd); 
    } else {
    #warn "NOT OK";
    }
    return undef;
}

sub writeBlock {
    my ($self, $block) = @_;
    warn "TODO - ImplementMe";
    return undef;
}

sub readSector {
    my ($self, $sector) = @_;
    warn "TODO - ImplementMe";
    return undef;
}

sub writeSector {
    my ($self, $sector, $data) = @_;
    warn "TODO - ImplementMe";
    return undef;
}

sub read {
    my $self = shift;
    return $self->readSector(@_);
}

sub write {
    my $self = shift;
    return $self->writeSector(@_);
}

# number of blocks on the tag
sub blocks {
    return 16;
}

# number of sectors on the tag
sub sectors {
    return 16;
}


1;
