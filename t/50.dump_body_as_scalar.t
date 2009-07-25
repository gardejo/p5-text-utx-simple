use strict;
use warnings;
# use utf8;
use lib 't/lib';

use Test::More tests => 72;
# use Test::Exception;
# use Test::Warn;
use Test::Text_UTX_Simple;

use Text::UTX::Simple;


# ================================================================
# subroutine for test
# [ 2 tests ]
# ----------------------------------------------------------------
sub test_dump {
    my $test_case = shift;

    # call new() with text option (parse)
    my $utx = Text::UTX::Simple->new($test_case->{query}{new});

    is_deeply( $utx->dump_body({scalar => 1}),
               $test_case->{result},
               $test_case->{name} . ' scalar' );
    is_deeply( ${ $utx->dump_body({scalar_ref => 1}) },
               $test_case->{result},
               $test_case->{name} . ' scalar ref' );

    return;
}


# ================================================================
# dump as scalar
# [ 2subtests * 1kind * 12kinds * 3versions = 72 tests ]
# ----------------------------------------------------------------
foreach my $version (@Versions) {
    my %version_definition = ( version => $version );

    foreach my $test_case (@{ $Dumper{normal}{scalar} }) {  # 12kinds
        test_dump({
            name    => "dump, $test_case->{name}, $version",
            query   => {
                new   => {
                    %version_definition,
                    text => do {
                        join "\n", (
                            (split "\n",
                                $Query{header}{$version}{'en/ja'}{has_column}),
                            $test_case->{query}
                        )
                    },
                },
            },
            result => $test_case->{result},
        });
    }
}
