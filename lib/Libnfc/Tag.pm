package Libnfc::Tag;

use strict;

use Libnfc qw(nfc_initiator_select_tag nfc_initiator_deselect_tag);
use Libnfc::Constants;
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
    if (!nfc_initiator_select_tag($reader->pdi, $type, 0, 0, $self->{_pti}))
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

    $self->init;
    return $self;
}

sub error {
    my $self = shift;
    return $self->{_last_error};
}

sub reader {
    my $self = shift;
    return $self->{reader};
}
sub AUTOLOAD {
    our $AUTOLOAD;
    warn "$AUTOLOAD not implemented \n";
    return undef;
}

sub DESTROY {
    my $self = shift;
    nfc_initiator_deselect_tag($self->reader->pdi);
}

1;
