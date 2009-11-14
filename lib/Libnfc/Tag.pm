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
    $self->{debug} = $reader->{debug};
    # Try to find the requested tag type
    $self->{_last_error} = "";
    $self->{_ti} = tag_info->new();
    $self->{_pti} = $self->{_ti}->_to_ptr;
    $self->{reader} = $reader;
    if (!nfc_initiator_select_tag($reader->{_pdi}, $type, 0, 0, $self->{_pti}))
    {
        warn("Error: no tag was found\n");
        return undef;
    } else {
        print "Card:\t ".(split('::', $types{$type}))[2]." found\n" if $self->{debug};
    }

    if ($types{$type} && eval "require $types{$type};") {
        my $productType = $types{$type}->type($self->{_pti});
        if ($productType && eval "require $types{$type}::$productType;") {
            bless $self, "$types{$type}::$productType";
        } else {
            warn "Unsupported product type $productType";
            return undef;
        }
    } else {
        warn "Unknown tag type $type";
        return undef;
    }

    $self->{_keys} = [];
    return $self;

}

sub set_key {
    my ($self, $sector, $keyA, $keyB) = @_;
    $self->{_keys}->[$sector] = [$keyA, $keyB];
}

sub set_keys {
    my ($self, @keys) = @_;
    my $cnt = 0;
    foreach my $key (@keys) {
        if (ref($key) and ref($key) eq "ARRAY") {
            $self->set_key($cnt++, @$key[0], @$key[1]);
        } else {
            $self->set_key($cnt++, $key, $key);
        }
    }
}

sub read {
    my ($self) = shift;
    warn "[",ref($self)."] Libnfc::Tag::read() - OVERRIDE ME";
}

sub write {
    my ($self) = shift;
    warn "[",ref($self)."] Libnfc::Tag::write() - OVERRIDE ME";
}

sub dump_keys {
}

sub dump_info {
    my $self = shift;
    warn "[",ref($self)."] Libnfc::Tag::dumpInfo() - OVERRIDE ME";
}

sub error {
    my $self = shift;
    return $self->{_last_error};
}

1;
