#!/usr/bin/perl

use Data::Dumper;
use RFID::Libnfc::Reader;
use RFID::Libnfc::Constants;

my $outfile = undef;
my $keyfile = "/Users/xant/mykeys";

sub usage {
    printf("%s sector_number [ -o dump_filename ]\n", $0);
    exit -1;
}

my $sector = shift;
usage unless($sector =~ /^\d+$/);

sub parse_cmdline {
    for (my $i = 0; $i < scalar(@ARGV); $i++) {
        my $opt = $ARGV[$i];
        if ($opt eq "-h") {
            usage();
        } elsif ($opt eq "-k") {
            $keyfile = $ARGV[++$i];
        } elsif ($opt eq "-o") {
            $outfile = $ARGV[++$i];
            usage() unless($outfile);
        }
    }
}

parse_cmdline();
my $r = RFID::Libnfc::Reader->new(debug => 0);
if ($r->init()) {
    printf ("Reader: %s\n", $r->name);
    my $tag = $r->connect(IM_ISO14443A_106);

    if ($tag) {
        $tag->dump_info;
    } else {
        warn "No TAG";
        exit -1;
    }

    $tag->load_keys($keyfile) if (-f $keyfile); 

    $tag->select if ($tag->can("select")); 

    if ($outfile) {
        open(DUMP, ">$outfile") or die "Can't open dump file: $!";
    }
    if (my $data = $tag->read_sector($sector)) {
        print DUMP $data if ($outfile);
        my $len = length($data);
        my @databytes = unpack("C".$len, $data);
        # let's format the output.
        # unprintable chars will be outputted as a '.' (like any other hexdumper)
        while (my @blockbytes = splice(@databytes, 0, 16)) {
            my @chars = map { ($_ > 31 and $_ < 127) ? $_ : ord('.') } @blockbytes; 
            printf ("%03d: " . "%02x " x 16 . "\t|" . "%c" x 16 . "|\n", $i, @blockbytes, @chars);
        }
    } else {
        warn $tag->error."\n";
    }
    close (DUMP) if ($outfile);
}

