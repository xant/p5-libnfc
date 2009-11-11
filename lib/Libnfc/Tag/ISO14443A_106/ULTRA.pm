package Libnfc::Tag::ISO14443A_106::ULTRA;

use strict;

use base qw(Libnfc::Tag::ISO14443A_106);
use Libnfc qw(nfc_initiator_select_tag nfc_initiator_mifare_cmd);
use Libnfc::CONSTANTS ':all';

sub readBlock {
    my ($self, $block, $noauth) = @_;
    warn "TODO - ImplementMe";
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

1;
