package Libnfc::Tag::ISO14443A_106::ULTRA;

use strict;

use base qw(Libnfc::Tag::ISO14443A_106);
use Libnfc qw(nfc_configure nfc_initiator_transceive_bytes nfc_initiator_transceive_bits append_iso14443a_crc print_hex);
use Libnfc::CONSTANTS ':all';

sub read_block {
    my ($self, $block, $noauth, $truncate) = @_;
    my $cmd = pack("C4", MU_READ, $block); # ANTICOLLISION of cascade level 1
    append_iso14443a_crc($cmd, 2);
    if (my $resp = nfc_initiator_transceive_bytes($self->{reader}->{_pdi}, $cmd, 4)) {
        if ($self->{debug}) {
            printf("R: ");
            # don't dump out parity bytes, which will be dropped later
            # when returning the buffer back to the caller
            print_hex($resp, length($resp) -2); 
        }
        # if we are reading page 15 we must return only 4 bytes, 
        # since following 12 bytes will come from page 0 
        # (according to the the "roll back" property described in chapter 6.6.4 on 
        # the spec document : M028634_MF0ICU1_Functional_Spec_V3.4.pdf
        if ($block == $self->blocks-1 or $truncate) { 
            # if $truncate is true, we will return back the exact block
            # (which on ultralight tokens is 4 bytes, even if read returns always 16 bytes).
            return unpack("a4", $resp); 
        } else {
            return unpack("a16", $resp); 
        }
    } else {
        $self->{_last_error} = "Error reading block $block";
    }
    return undef;
}

sub write_block {
    my ($self, $block, $data) = @_;

    return undef unless $data;
    if ($block > 3) { # data block
        my $acl = $self->acl;
        return undef unless $acl;
        if ($acl->{plbits}->{$block}) {
            $self->{_last_error} = "Lockbits deny writes on block $block";
            return undef;
        }

        #my $len = (length($data) <= 4) ? 4 : 16;
        #my $cmdtag = ($len == 4)?MU_WRITE:MU_CWRITE;
        my $len = 4;
        my $cmdtag = MU_WRITE; # XXX use only standard WRITE command for now
        my $prefix = pack("C2", $cmdtag, $block);
        my $postfix = pack("C2", 0, 0);
        my $cmd = $prefix.pack("a".$len, $data).$postfix;
        append_iso14443a_crc($cmd, $len+2);
        if (my $resp = nfc_initiator_transceive_bytes($self->{reader}->{_pdi}, $cmd, $len+4)) {
            if ($self->{debug}) {
                printf("W: ");
                print_hex($data, length($data));
            }
            return 1;
        } else {
            $self->{_last_error} = "Error trying to write on block $block";
        }
    } else {
        $self->{_last_error} = "You are actually not allowed to write on blocks 0, 1 and 2";
    }
    return undef;
}

sub read_sector {
    my $self = shift;
    return $self->read_block(@_);
}

sub write_sector {
    my $self = shift;
    $self->write_block(@_);
}

sub read {
    my $self = shift;
    return $self->read_sector(@_);
}

sub write {
    my $self = shift;
    return $self->write_sector(@_);
}

# number of blocks on the tag
sub blocks {
    return 16;
}

# number of sectors on the tag
sub sectors {
    return 16;
}

sub acl {
    my $self = shift;
    my $data = $self->read_block(2);
    if ($data) {
        return $self->_parse_locking_bits(unpack("x2a2", $data));
    }
    $self->{_last_error} = "Can't read ACL from sector 2";
    return undef;
}

# locking-bits parsing as defined on M028634_MF0ICU1_Functional_Spec_V3.4.pdf 
sub _parse_locking_bits {
    my ($self, $lockbytes) = @_;
    my ($b1, $b2) = unpack("CC", $lockbytes);
    my %acl = (
        blbits => {
            otp   => $b1 & 1,
            9_4   => ($b1 >> 1) & 1,
            10_15 => ($b1 >> 2) & 1
        },
        plbits => {
             3 => ($b1 >> 3) & 1,
             4 => ($b1 >> 4) & 1,
             5 => ($b1 >> 5) & 1,
             6 => ($b1 >> 6) & 1,
             7 => ($b1 >> 7) & 1,
             8 => $b2 & 1,
             9 => ($b2 >> 1) & 1,
            10 => ($b2 >> 2) & 1,
            11 => ($b2 >> 3) & 1,
            12 => ($b2 >> 4) & 1,
            13 => ($b2 >> 5) & 1,
            14 => ($b2 >> 6) & 1,
            15 => ($b2 >> 7) & 1
        }
    );
    return \%acl;
}

# anticollision/selection as defined on M028634_MF0ICU1_Functional_Spec_V3.4.pdf 
sub select {
    my $self = shift;

    my $uid = pack("C6", @{$self->uid});
    nfc_configure($self->{reader}->{_pdi}, DCO_ACTIVATE_FIELD, 0);

    # Configure the CRC and Parity settings
    nfc_configure($self->{reader}->{_pdi}, DCO_HANDLE_CRC, 0);
    nfc_configure($self->{reader}->{_pdi}, DCO_HANDLE_PARITY, 1);

    # Enable field so more power consuming cards can power themselves up
    nfc_configure($self->{reader}->{_pdi}, ,DCO_ACTIVATE_FIELD, 1);
    my $retry = 0;
    do {
        if (my $resp = nfc_initiator_transceive_bits($self->{reader}->{_pdi}, pack("C", MU_REQA), 7)) {
            my $cmd = pack("C2", MU_SELECT1, 0x20); # ANTICOLLISION of cascade level 1
            if ($resp = nfc_initiator_transceive_bytes($self->{reader}->{_pdi}, $cmd, 2)) {
                my (@rb) = unpack("C".length($resp), $resp);
                my $cuid = pack("C3", $rb[1], $rb[2], $rb[3]);
                if ($rb[0] == 0x88) { # define a constant for 0x88
                    $cmd = pack("C9", MU_SELECT1, 0x70, @rb); # SELECT of cascade level 1  
                    #my $crc = $self->crc($cmd);
                    append_iso14443a_crc($cmd, 7);
                    if ($resp = nfc_initiator_transceive_bytes($self->{reader}->{_pdi}, $cmd, 9)) {
                        # we need to do cascade level 2
                        # first let's get the missing part of the uid
                        $cmd = pack("C2", MU_SELECT2, 0x20); # ANTICOLLISION of cascade level 2
                        if ($resp = nfc_initiator_transceive_bytes($self->{reader}->{_pdi}, $cmd, 2)) {
                            @rb = unpack("C".length($resp), $resp);
                            $cuid .= pack("C3", $rb[1], $rb[2], $rb[3]);
                            $cmd = pack("C9", MU_SELECT2, 0x70, @rb); # SELECT of cascade level 2
                            #my $crc = $self->crc($cmd);
                            append_iso14443a_crc($cmd, 7);
                            if ($resp = nfc_initiator_transceive_bytes($self->{reader}->{_pdi}, $cmd, 9)) {
                                if ($uid == $cuid) {
                                    return 1;
                                } else {
                                    # HALT the unwanted tag
                                    $cmd = pack("C2", MU_HALT, 0x00);
                                    nfc_initiator_transceive_bytes($self->{reader}->{_pdi}, $cmd, 2);
                                    $retry = 1;
                                }
                            } else {
                                $self->{_last_error} = "Select cascade level 2 failed";
                            }
                        } else {
                            $self->{_last_error} = "Anticollision cascade level 2 failed";
                        }
                    } else {
                        $self->{_last_error} = "Select cascade level 1 failed";
                    }
                }
            } else {
                    $self->{_last_error} = "Anticollision cascade level 1 failed";
            }
        } else {
            $self->{_last_error} = "Device doesn't respond to REQA";
        }
    } while ($retry);
    return 0;
}

1;
