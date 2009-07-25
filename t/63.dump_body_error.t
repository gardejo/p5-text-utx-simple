use strict;
use warnings;
# use utf8;
use lib 't/lib';

use Test::More tests => 3;
# use Test::Exception;
use Test::Warn;
use Test::Text_UTX_Simple;

use Text::UTX::Simple;

my $utx = Text::UTX::Simple->new();


# ================================================================
# warning: invalid usage - call at void context
# write end of this file, to evade "Bizarre copy of HASH in sassign"
# at Carp::Heavy line 104
# [ 1test * 3versions = 3 tests ]
# ----------------------------------------------------------------
foreach my $version (@Versions) {
    my %version_definition = ( version => $version );

    $utx = Text::UTX::Simple->new(\%version_definition);
    warning_is
        { $utx->dump_body({scalar_ref => 1}) }
        { carped => "Useless use private variable in void context" }
    ;
}
