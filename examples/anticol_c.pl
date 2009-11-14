#!/usr/bin/perl


use Data::Dumper;
use Libnfc qw(:all);
use Libnfc::CONSTANTS ':all';

sub transceive_bytes {
    my ($pdi, $cmd, $len) = @_;
    print "T: " and print_hex($cmd, $len);
    if ($resp = nfc_initiator_transceive_bytes($pdi, $cmd, $len)) {
        print "R: " and print_hex($resp, length($resp));
        return $resp;
    }
    return undef;
}

sub transceive_bits {
    my ($pdi, $cmd, $len) = @_;
    print "T: " and print_hex($cmd, $len);
    if (my $resp = nfc_initiator_transceive_bits($pdi, $cmd, $len)) {
        print "R: " and print_hex($resp, length($resp));
        return $resp;
    }
    return undef;
}

my $pdi = nfc_connect();
if ($pdi == 0) { 
    print "No device!\n"; 
    exit -1;
}
nfc_initiator_init($pdi); 

nfc_configure($pdi, DCO_ACTIVATE_FIELD, 0);

# Configure the CRC and Parity settings
nfc_configure($pdi, DCO_HANDLE_CRC, 0);
nfc_configure($pdi, DCO_HANDLE_PARITY, 1);

# Enable field so more power consuming cards can power themselves up
nfc_configure($pdi, ,DCO_ACTIVATE_FIELD, 1);
my $retry = 0;
do {
    my $cmd = pack("C", MU_REQA);
    if (my $resp = transceive_bits($pdi, $cmd, 7)) {
        $cmd = pack("C2", MU_SELECT1, 0x20); # ANTICOLLISION of cascade level 1
        if ($resp = transceive_bytes($pdi, $cmd, 2)) {
            my (@rb) = unpack("C".length($resp), $resp);
            my $cuid = pack("C3", $rb[1], $rb[2], $rb[3]);
            if ($rb[0] == 0x88) { # define a constant for 0x88
                $cmd = pack("C9", MU_SELECT1, 0x70, @rb); # SELECT of cascade level 1  
                append_iso14443a_crc($cmd, 7);
                if ($resp = transceive_bytes($pdi, $cmd, 9)) {
                    # we need to do cascade level 2
                    # first let's get the missing part of the uid
                    $cmd = pack("C2", MU_SELECT2, 0x20); # ANTICOLLISION of cascade level 2
                    if ($resp = transceive_bytes($pdi, $cmd, 2)) {
                        @rb = unpack("C".length($resp), $resp);
                        $cuid .= pack("C3", $rb[1], $rb[2], $rb[3]);
                        $cmd = pack("C9", MU_SELECT2, 0x70, @rb); # SELECT of cascade level 2
                        append_iso14443a_crc($cmd, 7);
                        if (transceive_bytes($pdi, $cmd, 9)) {
                            if ($uid == $cuid) {
                                 print "2 level cascade anticollision/selection passed for uid : " and
                                 print_hex($uid, 6);
                            } else {
                                # HALT the unwanted tag
                                $cmd = pack("C2", MU_HALT, 0x00);
                                transceive_bytes($pdi, $cmd, 2);
                                print "Halted uid : " and print_hex($uid, 6);
                                $retry = 1;
                            }
                        } else {
                            warn "Select cascade level 2 failed";
                        }
                    } else {
                        warn "Anticollision cascade level 2 failed";
                    }
                } else {
                    warn "Select cascade level 1 failed";
                }
            }
        } else {
                warn "Anticollision cascade level 1 failed";
        }
    } else {
        warn "Device doesn't respond to REQA";
    }
} while ($retry);
exit 0;


