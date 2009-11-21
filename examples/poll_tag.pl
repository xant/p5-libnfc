#!/usr/bin/perl

use strict;
use Libnfc::Reader;
use Libnfc::Constants;
use Data::Dumper;
use Time::HiRes qw(usleep);
use POSIX;

$::DEBUG = 0;
$::quit = 0;
$::polling_frequency = 500000; # microseconds

sub graceful_quit {
    $::quit = 1;
};


# MAIN #
my $sigset = POSIX::SigSet->new(SIGINT, SIGQUIT);
my $sigaction = POSIX::SigAction->new( \&graceful_quit, $sigset, &POSIX::SA_NOCLDSTOP );
POSIX::sigaction(SIGINT, $sigaction);
POSIX::sigaction(SIGQUIT, $sigaction);

my $r = Libnfc::Reader->new( debug => $::DEBUG ) or die "Can't connect to reader";
while (!$::quit) {
    if (my $tag = $r->connect) {
        printf "Tag: %s\n", join ':', map { sprintf("%02x", $_) } @{$tag->uid};
        usleep $::polling_frequency while (!$::quit and $tag->ping);
    } else {
        usleep $::polling_frequency;
    }
}
printf "Exiting \n";
exit 0;

