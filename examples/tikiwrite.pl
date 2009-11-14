#!/usr/bin/perl

use Data::Dumper;
use Libnfc::Reader;
use Libnfc::CONSTANTS ':all';

my $r = Libnfc::Reader->new();
die "Can't connect to reader" unless $r and $r->init;

die "no input" unless $ARGV[0];
my $tag = $r->connect(IM_ISO14443A_106);
warn "No TAG" and exit -1 unless($tag);

$tag->set_keys(@keys);

$tag->select;
if ($tag->write_block(15, $ARGV[0])) {
    warn "input will be truncated to 4 chars";
} else {
        warn $tag->error."\n";
}
