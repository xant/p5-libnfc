package Libnfc::Reader;

use 5.008008;
use strict;
use warnings;
use Carp;

use Libnfc qw(nfc_connect nfc_disconnect nfc_initiator_init nfc_configure);
use Libnfc::Tag;
use Libnfc::CONSTANTS ':all';

sub new {
    my ($class) = shift;
    my $self = bless {}, $class;
    $self->{_pdi} = nfc_connect();
    croak "No device" unless $self->{_pdi};
    return $self;
}

sub init {
    my $self = shift;
    if (nfc_initiator_init($self->{_pdi})) {
        nfc_configure($self->{_pdi}, DCO_ACTIVATE_FIELD, 0);
        # Let the reader only try once to find a tag
        nfc_configure($self->{_pdi}, DCO_INFINITE_SELECT, 0);
        nfc_configure($self->{_pdi}, DCO_HANDLE_CRC, 1);
        nfc_configure($self->{_pdi}, DCO_HANDLE_PARITY, 1);
        # Enable field so more power consuming cards can power themselves up
        nfc_configure($self->{_pdi}, DCO_ACTIVATE_FIELD, 1);
        return 1;
    }
    return 0;
}

sub name {
    my $self = shift;
    unless($self->{_name}) {
        $self->{_name} = $self->{_pdi}->acName;
    }
    return $self->{_name};
}

sub connectTag {
    my ($self, $type) = @_;
    return Libnfc::Tag->new($self, $type);
}

sub DESTROY {
    my $self = shift;
    nfc_disconnect($self->{_pdi}) if ($self->{_pdi});
}

1;
