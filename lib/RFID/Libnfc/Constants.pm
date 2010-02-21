package RFID::Libnfc::Constants;

use Exporter;
our @ISA = qw( Exporter );
our $VERSION = '0.08';

BEGIN {    # must be defined at compile time
        %constants = (

            DCO => {    # export tag
                DCO_HANDLE_CRC              => 0x00,
                DCO_HANDLE_PARITY           => 0x01,
                DCO_ACTIVATE_FIELD          => 0x10,
                DCO_ACTIVATE_CRYPTO1        => 0x11,
                DCO_INFINITE_SELECT         => 0x20,    
                DCO_ACCEPT_INVALID_FRAMES   => 0x30,
                DCO_ACCEPT_MULTIPLE_FRAMES  => 0x31
            },
            IM => {
                IM_ISO14443A_106  => 0x00,
                IM_FELICA_212     => 0x01,
                IM_FELICA_424     => 0x02,
                IM_ISO14443B_106  => 0x03,
                IM_JEWEL_106      => 0x04
            },
            MC => {
                MC_AUTH_A         => 0x60,
                MC_AUTH_B         => 0x61,
                MC_READ           => 0x30,
                MC_WRITE          => 0xA0,
                MC_TRANSFER       => 0xB0,
                MC_DECREMENT      => 0xC0,
                MC_INCREMENT      => 0xC1,
                MC_STORE          => 0xC2
            },
            MU => {
                MU_REQA           => 0x26,
                MU_WUPA           => 0x52,
                MU_SELECT1        => 0x93,
                MU_SELECT2        => 0x95,
                MU_READ           => 0x30,
                MU_WRITE          => 0xA2,
                MU_CWRITE         => 0xA0,
                MU_HALT           => 0x50
            }
        );
}

# define the exports
our %EXPORT_TAGS
     = ( 'all' => [map { keys %$_ } values %constants], map { $_ => [ keys %{ $constants{$_} } ] } keys %constants );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

# exporting all constants by default ... there are just a few right now, so it's not a big problem
our @EXPORT = @EXPORT_OK;

use constant + { map { %$_ } values %constants }; 

1;
