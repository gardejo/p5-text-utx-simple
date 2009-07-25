use strict;
use warnings;
# use utf8;
use lib 't/lib';

use Test::More tests => 414;    # toooooooooooooooo much ^^;
use Test::Exception;
use Test::Warn;
use Test::Text_UTX_Simple;

use Text::UTX::Simple;


# ================================================================
# subroutine for test
# [ 5 tests ]
# ----------------------------------------------------------------
sub test_parse {
    my $test_case = shift;

    my $utx;
    if (exists $test_case->{query}{parse}) {
        # new() and parse()
        $utx = Text::UTX::Simple->new($test_case->{query}{new});
        diag "test data of $test_case->{name} is not defined"
            unless defined $test_case->{query}{parse};
        pass( $utx->parse($test_case->{query}{parse}) );
    }
    else {
        # call new() with text option (parse)
        pass( $utx = Text::UTX::Simple->new($test_case->{query}{new}) );
    }

    is_deeply( $utx->{body}{entries},
               $test_case->{result}{entries},
               $test_case->{name} . ' : internal, entries' );
    is_deeply( $utx->{body}{entry},
               $test_case->{result}{entry},
               $test_case->{name} . ' : internal, entry' );
    is(        $utx->get_number_of_entries(),
               $test_case->{result}{number_of_entries},
               $test_case->{name} . ' : number of entries' );
    is(        $utx->get_line_of_entries(),
               $test_case->{result}{line_of_body},
               $test_case->{name} . ' : line of body' );

    return;
}

sub test_warn {
    my $test_case = shift;

    my $utx;
    if (exists $test_case->{query}{parse}) {
        # new() and parse()
        $utx = Text::UTX::Simple->new($test_case->{query}{new});
        diag "test data of $test_case->{name} is not defined"
            unless defined $test_case->{query}{parse};
        warning_is
            { $utx->parse($test_case->{query}{parse}); }
            { carped => $test_case->{result}{message} }
        ;
    }
    else {
        # call new() with text option (parse)
        warning_is
            { $utx = Text::UTX::Simple->new($test_case->{query}{new}); }
            { carped => $test_case->{result}{message} }
        ;
    }

    is_deeply( $utx->{body}{entries},
               $test_case->{result}{entries},
               $test_case->{name} . ' : internal, entries' );
    is_deeply( $utx->{body}{entry},
               $test_case->{result}{entry},
               $test_case->{name} . ' : internal, entry' );

    return;
}


# ================================================================
# normal
# [ 5subtests * 2kinds * 12kinds * 3versions = 360 tests ]
# ----------------------------------------------------------------
foreach my $version (@Versions) {
    my %version_definition = ( version => $version );

    foreach my $test_case (@{ $Parser{normal}{scalar} }) {  # 12kinds
        my $parsing_query
            = $Query{header}{$version}{'en/ja'}{has_column}
            . $test_case->{query};

        test_parse({
            name    => "parse, $test_case->{name}, $version",
            query   => {
                new   => \%version_definition,
                parse => $parsing_query,
            },
            result => $test_case->{result},
        });
        test_parse({
            name    => "new + parse, $test_case->{name}, $version",
            query   => {
                new   => {
                    %version_definition,
                    text => $parsing_query,
                },
            },
            result => $test_case->{result},
        });
    }
}


# ================================================================
# warning
# *** CAVEAT: ATTEMPT IT AT LAST OF TEST TO EVADE ERROR FROM Carp::Heavy ***
# [ 3subtest * 2kinds * 3kinds * 3versions = 54 tests ]
# ----------------------------------------------------------------
foreach my $version (@Versions) {
    my %version_definition = ( version => $version );

    foreach my $test_case (@{ $Parser{warning}{scalar} }) { # 9kinds
        my $parsing_query = $Query{header}{$version}{'en/ja'}{has_column}
                          . $test_case->{query};
        test_warn({
            name   => "$test_case->{name} (parse), $version",
            query  => {
                new   => \%version_definition,
                parse => $parsing_query,
            },
            result => $test_case->{result},
        });
        test_warn({
            name   => "$test_case->{name} (new), $version",
            query  => {
                new   => {
                    %version_definition,
                    text => $parsing_query,
                },
            },
            result => $test_case->{result},
        });
    }
}
