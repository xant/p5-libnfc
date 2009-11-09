package Libnfc::Tag;

use strict;

use Libnfc qw(nfc_initiator_select_tag);
use Libnfc::CONSTANTS ':all';
use Data::Dumper;

my %types = (
    scalar(IM_ISO14443A_106) => 'Libnfc::Tag::ISO14443A_106'
);

sub new {
    my ($class, $reader, $type) = @_;

    return unless ($reader and UNIVERSAL::isa($reader, "Libnfc::Reader"));

    my $self = {};
    if ($types{$type} && eval "require $types{$type};") {
        bless $self, $types{$type};
    } else {
        warn "Unknown tag type $type";
        return undef;
    }

    # Try to find the requested tag type
    $self->{_ti} = tag_info->new();
    $self->{_pti} = $self->{_ti}->_to_ptr;
    $self->{reader} = $reader;
    if (!nfc_initiator_select_tag($reader->{_pdi}, $type, 0, 0, $self->{_pti}))
    {
        printf("Error: no tag was found\n");
        return undef;
    } else {
        printf("Card:\t ".(split('::', $types{$type}))[2]." found\n");
    }

    $self->{keys} = [];
    return $self;

}

sub setKey {
    my ($self, $sector, $keyA, $keyB) = @_;
    $self->{keys}->[$sector] = [$keyA, $keyB];
}

sub setKeys {
    my ($self, @keys) = @_;
    my $cnt = 0;
    foreach my $key (@keys) {
        if (ref($key) and ref($key) eq "ARRAY") {
            $self->setKey($cnt++, @$key[0], @$key[1]);
        } else {
            $self->setKey($cnt++, $key, undef);
        }
    }
}

sub blockSector {
    my ($self, $block) = @_;
    if ($block < 128) {
        return $block/4;
    } else {
        $block -= 128;
        return 31 + $block/16;
    }
}

sub read {
    my ($self, $block);
    my $sector = $self->blockSector($block);
    $self->unlock($sector);
}

sub write {
    my ($self, $block, $data);
}

sub dumpKeys {
}

sub dumpInfo {
    my $self = shift;
    warn "[",ref($self)."] Libnfc::Tag::dumpInfo() - OVERRIDE ME";
}

1;
