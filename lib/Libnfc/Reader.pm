package Libnfc::Reader;

use 5.008008;
use strict;
use warnings;
use Carp;

use Libnfc qw(nfc_connect nfc_disconnect nfc_initiator_init nfc_configure);
use Libnfc::Tag;
use Libnfc::Constants;

sub new {
    my ($class, %args) = @_;
    my $self = bless {%args}, $class;
    $self->{_pdi} = nfc_connect();
    croak "No device" unless $self->{_pdi};
    return $self;
}

sub init {
    my $self = shift;
    if (nfc_initiator_init($self->{_pdi})) {
        return $self;
    }
    return undef;
}

sub name {
    my $self = shift;
    unless($self->{_name}) {
        $self->{_name} = $self->{_pdi}->acName;
    }
    return $self->{_name};
}

sub connect {
    return Libnfc::Tag->new(@_);
}

sub pdi {
    my $self = shift;
    return $self->{_pdi};
}

# just an accessor
sub print_hex {
    my $self = shift;
        Libnfc::print_hex(@_);
}

sub DESTROY {
    my $self = shift;
    nfc_disconnect($self->{_pdi}) if ($self->{_pdi});
}

1;
__END__
=head1 NAME

Libnfc::Reader - Access libnfc-compatible tag readers

=head1 SYNOPSIS

  use Libnfc;

  $r = Libnfc::Reader->new();
  if ($r->init()) {
    printf ("Reader: %s\n", $r->name);
  }

  $tag = $r->connectTag(IM_ISO14443A_106);

=head1 DESCRIPTION

  This reader class allows to access RFID tags 
  (actually only mifare ones have been implemented/tested)
  readable from any libnfc-compatible reader

=head2 EXPORT

None by default.

=head2 Exportable functions

=head1 METHODS

=item name ( )

returns the name of the current reader

for ex.
$name = $r->name

=item connect ( TAGFAMILY, BLOCKING )

tries to connect a tag and returns a new ready-to-use Libnfc::Tag object 
or undef if no tag is found.
If blocking is TRUE, connect won't return untill a tag is found in the field

for ex.
$tag = $r->connect( ISO14443A_106 )

NOTE: ISO14443A_106 is the only type actually implemented/supported

=item pdi ( )

returns the underlying reader descriptor (to be used with the Libnfc procedural api)
$pdi = $r->pdi

=head1 SEE ALSO

Libnfc Libnfc::Constants Libnfc::Tag 

< check also documentation for libnfc c library [ http://www.libnfc.org/documentation/introduction ] >

=head1 AUTHOR

xant

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by xant <xant@xant.net>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
