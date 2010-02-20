package RFID::Libnfc;

use 5.008008;
use strict;
use warnings;
use Carp;

require Exporter;
use AutoLoader;
use RFID::Libnfc::Constants;

our @ISA = qw(Exporter);

our $VERSION = '0.07';

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use RFID::Libnfc ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	append_iso14443a_crc
	nfc_configure
	nfc_connect
	nfc_disconnect
	nfc_initiator_deselect_tag
	nfc_initiator_init
	nfc_initiator_mifare_cmd
	nfc_initiator_select_tag
	nfc_initiator_transceive_bits
	nfc_initiator_transceive_bytes
	nfc_target_init
	nfc_target_receive_bits
	nfc_target_receive_bytes
	nfc_target_send_bits
	nfc_target_send_bytes
	oddparity
	print_hex
	print_hex_bits
	print_hex_par
	swap_endian32
	swap_endian64
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.

    my $constname;
    our $AUTOLOAD;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "&RFID::Libnfc::constant not defined" if $constname eq 'constant';
    my ($error, $val) = constant($constname);
    if ($error) { croak $error; }
    {
	no strict 'refs';
	# Fixed between 5.005_53 and 5.005_61
#XXX	if ($] >= 5.00561) {
#XXX	    *$AUTOLOAD = sub () { $val };
#XXX	}
#XXX	else {
	    *$AUTOLOAD = sub { $val };
#XXX	}
    }
    goto &$AUTOLOAD;
}

require XSLoader;
XSLoader::load('RFID::Libnfc', $VERSION);

# Preloaded methods go here.

1;
__END__

=head1 NAME

RFID::Libnfc - Perl extension for libnfc (Near Field Communication < http://www.libnfc.org/ >)

=head1 SYNOPSIS

  ObjectOriented API: 

    use RFID::Libnfc;
    use RFID::Libnfc::Constants;

    $r = RFID::Libnfc::Reader->new();
    if ($r->init()) {
        printf ("Reader: %s\n", $r->name);
    }

    $tag->load_keys($keyfile);

    $tag = $r->connect(IM_ISO14443A_106);
    $tag->dumpInfo

    $block_data = $tag->read_block(240);
    $entire_sector = $tag->read_sector(35);

    $tag->write(240, $data); 

    $uid = $tag->uid;

  ===============================================================================

  Procedural API: (equivalend of C api)

    use RFID::Libnfc ':all';
    use RFID::Libnfc::Constants ':all';


    my $pdi = nfc_connect();
    if ($pdi == 0) { 
        print "No device!\n"; 
        exit -1;
    }
    nfc_initiator_init($pdi); 
    # Drop the field for a while
    nfc_configure($pdi, DCO_ACTIVATE_FIELD, 0);
    # Let the reader only try once to find a tag
    nfc_configure($pdi, DCO_INFINITE_SELECT, 0);
    nfc_configure($pdi, DCO_HANDLE_CRC, 1);
    nfc_configure($pdi, DCO_HANDLE_PARITY, 1);
    # Enable field so more power consuming cards can power themselves up
    nfc_configure($pdi, DCO_ACTIVATE_FIELD, 1);

    printf("Reader:\t%s\n", $pdi->acName);

    # Try to find a MIFARE Classic tag
    my $ti = nfc_target_info_t->new();
    my $pti = $ti->_to_ptr;
    my $bool = nfc_initiator_select_tag($pdi, IM_ISO14443A_106, 0, 0, $pti);

    #read UID out of the tag
    my $uidLen = $pti->uiUidLen;
    my @uid = unpack("C".$uidLen, $pti->abtUid);
    printf("UID:\t". "%x " x $uidLen ."\n", @uid);

    # disconnects the tag
    nfc_disconnect($pdi);

  
=head1 DESCRIPTION

  Provides a perl OO api to libnfc functionalities
  (actually implements only mifare-related functionalities)

=head2 EXPORT

None by default.

=head2 Exportable functions

  append_iso14443a_crc($pbtData, $uiLen)
  $pci = nfc_connect()
  nfc_disconnect($pdi)
  $bool = nfc_configure($pdi, $dco, $bEnable)
  $bool = nfc_initiator_deselect_tag($pdi)
  $bool = nfc_initiator_init($pdi)
  $bool = nfc_initiator_mifare_cmd($pdi, $mifare_cmd, $ui8Block, $mifare_param_ref)
  $bool = nfc_initiator_select_tag($pdi, $im, $pbtInitData, $uiInitDataLen, $pti)
  $data = nfc_initiator_transceive_bits($pdi, $pbtTx, $uiTxBits, $pbtTxPar)
  $data = nfc_initiator_transceive_bytes($pdi, $pbtTx, $uiTxLen)
  $data = nfc_target_init($pdi)
  $data = nfc_target_receive_bits($pdi)
  $data = nfc_target_receive_bytes($pdi)
  $bool = nfc_target_send_bits($pdi, $pbtTx, $uiTxBits, $pbtTxPar)
  $bool = nfc_target_send_bytes($pdi, $pbtTx, $uiTxLen)
  $byte = oddparity($bt)
  oddparity_byte_ts($pbtData, $uiLen, $pbtPar)
  print_hex($pbtData, [ $uiLen ])
  print_hex_bits($pbtData, $uiBits)
  print_hex_par($pbtData, $uiBits, $pbtDataPar)
  swap_endian32($pui32)
  swap_endian64($pui64)


=head1 SEE ALSO

RFID::Libnfc::Constants RFID::Libnfc::Reader RFID::Libnfc::Tag 

< check also documentation for libnfc c library [ http://www.libnfc.org/documentation/introduction ] >

=head1 AUTHOR

xant

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by xant <xant@cpan.org>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
