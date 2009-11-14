#!/usr/bin/perl


use Data::Dumper;
use Libnfc qw(:all);
use Libnfc::CONSTANTS ':all';


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
    print "T: " and print_hex($cmd, length($cmd));
    if (my $resp = nfc_initiator_transceive_bits($pdi, $cmd, 7)) {
        print "R: " and print_hex($resp, length($resp));
        $cmd = pack("C2", MU_SELECT1, 0x20); # ANTICOLLISION of cascade level 1
        print "T: " and print_hex($cmd, length($cmd));
        if ($resp = nfc_initiator_transceive_bytes($pdi, $cmd, 2)) {
            print "R: " and print_hex($resp, length($resp));
            my (@rb) = unpack("C".length($resp), $resp);
            my $cuid = pack("C3", $rb[1], $rb[2], $rb[3]);
            if ($rb[0] == 0x88) { # define a constant for 0x88
                $cmd = pack("C9", MU_SELECT1, 0x70, @rb); # SELECT of cascade level 1  
                append_iso14443a_crc($cmd, 7);
                print "T: " and print_hex($cmd, length($cmd));
                if ($resp = nfc_initiator_transceive_bytes($pdi, $cmd, 9)) {
                    print "R: " and print_hex($resp, length($resp));
                    # we need to do cascade level 2
                    # first let's get the missing part of the uid
                    $cmd = pack("C2", MU_SELECT2, 0x20); # ANTICOLLISION of cascade level 2
                    print "T: " and print_hex($cmd, length($cmd));
                    if ($resp = nfc_initiator_transceive_bytes($pdi, $cmd, 2)) {
                        print "R: " and print_hex($resp, length($resp));
                        @rb = unpack("C".length($resp), $resp);
                        $cuid .= pack("C3", $rb[1], $rb[2], $rb[3]);
                        $cmd = pack("C9", MU_SELECT2, 0x70, @rb); # SELECT of cascade level 2
                        append_iso14443a_crc($cmd, 7);
                        print "T: " and print_hex($cmd, length($cmd));
                        if ($resp = nfc_initiator_transceive_bytes($pdi, $cmd, 9)) {
                            print "R: " and print_hex($resp, length($resp));
                            if ($uid == $cuid) {
                                 print "2 level cascade anticollision/selection passed for uid : ";
                                 print_hex($uid, 6);
                            } else {
                                print "Halted uid : ";
                                # HALT the unwanted tag
                                $cmd = pack("C2", MU_HALT, 0x00);
                                nfc_initiator_transceive_bytes($pdi, $cmd, 2);
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


