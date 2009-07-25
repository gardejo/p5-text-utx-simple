use strict;
use warnings;
# use utf8;
use lib 't/lib';

use Test::More tests => 157;
use Test::Exception;
# use Test::Warn;
use Test::Text_UTX_Simple;

use Text::UTX::Simple;


# ================================================================
# subroutine for test
# ----------------------------------------------------------------
sub test_column { # [ 1 test or 5 tests ]
    my $test_case = shift;

    if ($test_case->{exception}) {  # (0 + 1)
        throws_ok( sub { _make($test_case); },
                   qr{$test_case->{result}},
                   $test_case->{name} );
    }
    else {                          # (1 + 4)
        my $utx = _make($test_case);
        is_deeply( $utx->{header}{column},
                   $test_case->{result}{hash},
                   $test_case->{name} . ': internal' );
        is_deeply( [ $utx->get_columns() ],
                   $test_case->{result}{list},
                   $test_case->{name} . ': API, get as list' );
        is_deeply( ( scalar $utx->get_columns() ),
                   $test_case->{result}{list},
                   $test_case->{name} . ': API, get as arrayref' );
        is(        $utx->get_number_of_columns(),
                   (scalar @{$test_case->{result}{list}}),
                   $test_case->{name} . ': column number' );
    }

    return;
}

sub _make {
    my $test_case = shift;

    my $utx;

    if ( exists $test_case->{query}{parse} ) {
        $utx = Text::UTX::Simple->new($test_case->{query}{new});
        pass( $utx->parse( $test_case->{query}{parse} ) );
    }
    else {
        pass( $utx = Text::UTX::Simple->new($test_case->{query}{new}) );
    }

    return $utx;
}


# ================================================================
# create
# [ 15 + 15 + (7 + 34) + 18 + 12 + 10 = 111 tests ]
# ----------------------------------------------------------------
foreach my $version (@Versions) {
    my %version_definition = (version => $version);

    # --------------------------------
    # not specified (5*3 = 15)
    # --------------------------------
    test_column({
        name    => "create without user defined columns, $version",
        query   => {
            new => \%version_definition,
        },
        result  => $Result{column}{$version}{has_no_column},
    });

    # --------------------------------
    # array/user (5*3 = 15)
    # --------------------------------
    test_column({
        name    => "create with user defined columns "
                 . "(array/without basic) $version",
        query   => {
            new => {
                %version_definition,
                column  => $Query{column}{$version}{array}{user}{full},
            },
        },
        result  => $Result{column}{$version}{has_column},
    });

    # --------------------------------
    # array/basic+user, scalar/user, scalar/basic+user
    # --------------------------------
    if ($version eq '0.90') {    # (7)
        test_column({   # (1*1)
            exception => 1,
            name      => "create with user defined columns"
                       . "(arra/with basic) $version",
            query     => {
                new => {
                    %version_definition,
                    column  => $Query{column}{$version}{array}{all},
                },
            },
            result    => q{Can't parse the header: }
                       . q{language for user defined column's definition }
                       . q{isn't defined},
        });
        test_column({   # (5*1)
            name    => "create with user defined columns "
                     . "(scalar/without basic) $version",
            query   => {
                new => {
                    %version_definition,
                    column => $Query{column}{$version}{scalar}{user}{full},
                },
            },
            result  => $Result{column}{$version}{has_column},
        });
        test_column({   # (1*1)
            exception => 1,
            name      => "create with user defined columns"
                       . "(scalar/with basic) $version",
            query     => {
                new => {
                    %version_definition,
                    column => $Query{column}{$version}{scalar}{all},
                },
            },
            result    => q{Can't parse the header: }
                       . q{language for user defined column's definition }
                       . q{isn't defined},
        });
    }
    else {  # (26)
        test_column({   # (5*2)
            name    => "create with user defined columns "
                     . "(array/with basic) $version",
            query   => {
                new => {
                    %version_definition,
                    column => $Query{column}{$version}{array}{all},
                },
            },
            result  => $Result{column}{$version}{has_column},
        });
        test_column({   # (1*2)
            exception => 1,
            name      => "create with user defined columns"
                       . "(scalar/without basic 1) $version",
            query     => {
                new => {
                    %version_definition,
                    column => $Query{column}{$version}{scalar}{lacked},
                },
            },
            result    => q{Can't parse the header: }
                       . q{specified string is lacking in basic columns},
        });
        test_column({   # (1*2)
            exception => 1,
            name      => "create with user defined columns"
                       . "(scalar/without basic 2) $version",
            query     => {
                new => {
                    %version_definition,
                    column => $Query{column}{$version}{scalar}{user}{full},
                },
            },
            result    => q{Can't parse the header: }
                       . q{column \(0\) isn't basic column},
        });
        test_column({   # (5*2)
            name      => "create with user defined 1 column "
                       . "(scalar/with basic) $version",
            query     => {
                new => {
                    %version_definition,
                    column => $Query{column}{$version}{array}{user}{simple},
                },
            },
            result    => $Result{column}{$version}{has_simple_column},
        });
        test_column({   # (5*2)
            name    => "create with user defined 3 columns "
                     . "(scalar/with basic) $version",
            query   => {
                new => {
                    %version_definition,
                    column => $Query{column}{$version}{scalar}{all},
                },
            },
            result  => $Result{column}{$version}{has_column},
        });
    }

    # --------------------------------
    # exceptions: invalid definition (1*6*3 = 18)
    # --------------------------------
    test_column({
        exception => 1,
        name      => "create with user defined columns"
                   . "(undef), $version",
        query     => {
            new => {
                %version_definition,
                column => undef,
            },
        },
        result    => q{Can't parse the header: }
                   . q{user defined column is specified, but isn't defined},
    });
    test_column({
        exception => 1,
        name      => "create with user defined columns"
                   . "(undef in ARRAY reference), $version",
        query     => {
            new => {
                %version_definition,
                column => [undef],
            },
        },
        result    => q{Can't parse the header: }
                   . q{definition list has undefined element},
    });
    test_column({
        exception => 1,
        name      => "create with user defined columns"
                   . "(empty), $version",
        query     => {
            new => {
                %version_definition,
                column => q{},
            },
        },
        result    => q{Can't parse the header: }
                   . q{user defined column is specified, but isn't filled},
    });
    test_column({
        exception => 1,
        name      => "create with user defined columns"
                   . "(empty ARRAY reference), $version",
        query     => {
            new => {
                %version_definition,
                column => q[],
            },
        },
        result    => q{Can't parse the header: }
                   . q{user defined column is specified, but isn't filled},
    });
    test_column({
        exception => 1,
        name      => "create with user defined columns"
                   . "HASH reference, $version",
        query     => {
            new => {
                %version_definition,
                column => {'src:foo' => 3},
            },
        },
        result    => q{Can't parse the header: }
                   . q{type of user defined column }
                   . q{isn't a SCALAR or an ARRAY reference},
    });
    test_column({
        exception => 1,
        name      => "create with 'columns' and 'user_defined_columns', "
                   . $version,
        query     => {
            new => {
                %version_definition,
                column
                    => $Query{column}{$version}{array}{user}{full},
                user_defined_columns
                    => $Query{column}{$version}{array}{user}{full},
            },
        },
        result    => q{Can't parse the header: }
                   . q{'columns' and 'user_defined_columns' are exclusive},
    });

    # --------------------------------
    # exceptions: duplicate (1*4*3 = 12)
    # --------------------------------
    test_column({
        exception => 1,
        name      => "create with user defined columns"
                   . "(array:duplicated:user), $version",
        query     => {
            new => {
                %version_definition,
                column => $Query{column}{$version}
                                {array}{duplicated}{user},
            },
        },
        result    => q{Can't parse the header: }
                   . q{user defined column \(.*?foo\) is duplicated},
    });
    test_column({
        exception => 1,
        name      => "create with user defined columns"
                   . "(array:duplicated:basic), $version",
        query     => {
            new => {
                %version_definition,
                column => $Query{column}{$version}
                                {array}{duplicated}{basic},
            },
        },
        result    => q{Can't parse the header: }
                   . q{user defined column \(.*?pos\) is duplicated},
    });

    test_column({
        exception => 1,
        name      => "create with user defined columns"
                   . "(scalar:duplicated:user), $version",
        query     => {
            new => {
                %version_definition,
                column => $Query{column}{$version}
                                {scalar}{duplicated}{user},
            },
        },
        result    => q{Can't parse the header: }
                   . q{user defined column \(.*?foo\) is duplicated},
    });
    test_column({
        exception => 1,
        name      => "create with user defined columns"
                   . "(scalar:duplicated:basic), $version",
        query     => {
            new => {
                %version_definition,
                column => $Query{column}{$version}
                                {scalar}{duplicated}{basic},
            },
        },
        result    => q{Can't parse the header: }
                   . q{user defined column \(.*?pos\) is duplicated},
    });

    # --------------------------------
    # fuzzy parsing (5*2*1 = 10)
    # --------------------------------
    if ($version eq '0.90') {
        while (
            my ($type, $value)
                = each %{ $Query{column}{$version}{scalar}{fuzzy} }
        ) {
            test_column({
                name      => "create with user defined columns"
                           . "(fuzzy:$type), $version",
                query     => {
                    new => {
                        %version_definition,
                        column => $value,
                    },
                },
                result  => $Result{column}{$version}{fuzzy},
            });
        }
    }
}


# ================================================================
# parse
# [ 30 + 6 + 10 = 46 tests ]
# ----------------------------------------------------------------
foreach my $version (@Versions) {
    my %version_definition = defined $version ? ( version => $version ) : ();

    # --------------------------------
    # basic, user (5*2*3 = 30)
    # --------------------------------
    test_column({
        name    => "parse without user defined columns, $version",
        query   => {
            new   => \%version_definition,
            parse => $Query{header}{$version}{'en/ja'}{has_no_column},
        },
        result  => $Result{column}{$version}{has_no_column},
    });

    test_column({
        name    => "parse with user defined columns, $version",
        query   => {
            new   => \%version_definition,
            parse => $Query{header}{$version}{'en/ja'}{has_column},
        },
        result  => $Result{column}{$version}{has_column},
    });

    # --------------------------------
    # exceptions: duplicate (1*2*3 = 6)
    # --------------------------------
    test_column({
        exception => 1,
        name      => "parse with user defined columns"
                   . "(duplicated:user), $version",
        query     => {
            new   => \%version_definition,
            parse => $Query{header}{$version}{'en/ja'}
                           {duplicated}{user},
        },
        result    => q{Can't parse the header: }
                   . q{user defined column \(.*?foo\) is duplicated},
    });
    test_column({
        exception => 1,
        name      => "parse with user defined columns"
                   . "(duplicated:basic), $version",
        query     => {
            new   => \%version_definition,
            parse => $Query{header}{$version}{'en/ja'}
                           {duplicated}{basic},
        },
        result    => q{Can't parse the header: }
                   . q{user defined column \(.*?pos\) is duplicated},
    });

    # --------------------------------
    # fuzzy parsing (5*2*1 = 10)
    # --------------------------------
    if ($version eq '0.90') {
        while (
            my ($type, $value)
                = each %{ $Query{header}{$version}{'en/ja'}{fuzzy} }
        ) {
            test_column({
                name      => "create with user defined columns"
                           . "(fuzzy:$type), $version",
                query     => {
                    new   => \%version_definition,
                    parse => $value,
                },
                result  => $Result{column}{$version}{fuzzy},
            });
        }
    }
}
