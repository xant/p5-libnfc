#!/usr/bin/perl

use strict;
use Libnfc::Reader;
use Libnfc::Constants;
use Data::Dumper;
use POSIX;

$::DEBUG = 0;
$::quit = 0;

my $sigset = POSIX::SigSet->new(SIGINT, SIGQUIT);
my $sigaction = POSIX::SigAction->new( \&graceful_quit, $sigset, &POSIX::SA_NOCLDSTOP );
POSIX::sigaction(SIGINT, $sigaction);
POSIX::sigaction(SIGQUIT, $sigaction);

my $r = Libnfc::Reader->new( debug => $::DEBUG ) or die "Can't connect to reader";
while (!$::quit) {
    if (my $tag = $r->connect) {
        printf "Tag: %s\n", join ':', map { sprintf("%02x", $_) } @{$tag->uid};
        sleep 1 while (!$::quit and $tag->ping);
    } else {
        sleep 1; # polling frequency
    }
}
undef($r); # ensure calling DESTROY
exit 0;

sub graceful_quit {
    $::quit = 1;
};
