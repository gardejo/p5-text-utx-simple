use strict;
use warnings;
# use utf8;
use lib 't/lib';

use Test::More tests => 6;
# use Test::Exception;
# use Test::Warn;
use Test::Text_UTX_Simple;

use Text::UTX::Simple;


# ================================================================
# subroutine for test
# [ 2 tests ]
# ----------------------------------------------------------------
sub test_clear {
    my $test_case = shift;

    my $version = $test_case->{version};

    my $utx = Text::UTX::Simple->new({
        %{ $test_case->{query}{new} },
        text => do {
            join "\n", (
                ( split "\n",
                    $Query{header}{$version}{'en/ja'}
                          {has_column} ),
                ( join "\t", qw(src2     tgt20 src:pos20 src:foo20 tgt:bar20) ),
                ( join "\t", qw(src0     tgt00 src:pos00 src:foo00 tgt:bar00) ),
                ( join "\t", '#src1', qw(tgt13 src:pos13 src:foo13 tgt:bar13) ),
                ( join "\t", qw(src1     tgt11 src:pos11 src:foo11 tgt:bar11) ),
                ( join "\t", '#src1', qw(tgt10 src:pos10 src:foo10 tgt:bar10) ),
                ( join "\t", qw(src1     tgt12 src:pos12 src:foo12 tgt:bar12) ),
            )
        },
    });

    pass( $utx->clear() );
    is( $utx->dump_body(),
        undef,
        $test_case->{name} . ' : cleared!' );
}


# ================================================================
# clear
# [ 2subtests * 3versions = 6tests ]
# ----------------------------------------------------------------
foreach my $version (@Versions) {
    my %version_definition = ( version => $version );

    test_clear({
        name    => "version: $version",
        query   => {
            new => \%version_definition,
        },
        version => $version,
    });
}
