use strict;
use 5.008008;
use ExtUtils::MakeMaker;
my $INC = "-I. ";
my $LIBS = "-lnfc ";
my $DEFINE = "";

# detect libnfc (libnfc-stable installs its main header in <PREFIX>/include/libnfc/libnfc.h
# while newer versions of the library (trunk on svn) uses <PREFIX>/include/nfc/nfc.h
# TODO - cleanup this shit
if (-d "/usr/include/libnfc") {
} elsif (-d "/usr/local/include/nfc") {
    $INC .= "-I/usr/local/include";
    $LIBS .= "-L/usr/local/lib";
} elsif (-d "/usr/local/include/libnfc") {
    die "Obsolete libnfc version. Please upgrade to last stable";
} elsif (-d "/opt/local/include/nfc") {
    $INC .= "-I/opt/local/include";
    $LIBS .= "-L/opt/local/lib";
} elsif (-d "/opt/local/include/libnfc") {
    die "Obsolete libnfc version. Please upgrade to last stable";
} else {
    die "No libnfc installed"
}

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'RFID::Libnfc',
    VERSION_FROM      => 'lib/RFID/Libnfc.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/RFID/Libnfc.pm', # retrieve abstract from module
       AUTHOR         => 'Xant <xant@cpan.org>') : ()),
    LIBS              => [$LIBS], # e.g., '-lm'
    DEFINE            => $DEFINE,
    INC               => $INC,
	# Un-comment this if you add C files to link with later:
    # OBJECT            => '$(O_FILES)', # link all the C files too
);
if  (eval {require ExtUtils::Constant; 1}) {
  # If you edit these definitions to change the constants used by this module,
  # you will need to use the generated const-c.inc and const-xs.inc
  # files to replace their "fallback" counterparts before distributing your
  # changes.
  my @names = (qw());
  ExtUtils::Constant::WriteConstants(
                                     NAME         => 'RIFD::Libnfc',
                                     NAMES        => \@names,
                                     DEFAULT_TYPE => 'IV',
                                     C_FILE       => 'const-c.inc',
                                     XS_FILE      => 'const-xs.inc',
                                  );

}
else {
  use File::Copy;
  use File::Spec;
  foreach my $file ('const-c.inc', 'const-xs.inc') {
    my $fallback = File::Spec->catfile('fallback', $file);
    copy ($fallback, $file) or die "Can't copy $fallback to $file: $!";
  }
}
