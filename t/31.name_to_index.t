# convert column name into column index

use strict;
use warnings;
# use utf8;
use lib 't/lib';

use Test::More tests => 42;
use Test::Exception;
# use Test::Warn;
use Test::Text_UTX_Simple;

use Text::UTX::Simple;


my %utx;

VERSION:
foreach my $version (@Versions) {
    $utx{$version} = {
        has_no_column => Text::UTX::Simple->new({
            (defined $version ? (version => $version) : ()),
            text    => $Query{header}{$version}{'en/ja'}{has_no_column},
        }),
        has_column => Text::UTX::Simple->new({
            (defined $version ? (version => $version) : ()),
            text    => $Query{header}{$version}{'en/ja'}{has_column},
        }),
    };
}


# ================================================================
# subroutine for test
# 8tests or 1test
# ----------------------------------------------------------------
sub test_convert {
    my $test_case = shift;

    my $version = $test_case->{version};

    if ($test_case->{exception}) {
        throws_ok(sub { $utx{$version}{has_no_column}
                            ->name_to_index($test_case->{query}) },
                  qr{$test_case->{result}},
                  $test_case->{name} );
        return;
    }

    is(        $utx{$version}{has_no_column}
                ->name_to_index($Regularized{$version}{'src'}),
               $Index_Of{'src'},
               $test_case->{name} . ': src' );
    is(        $utx{$version}{has_no_column}
                ->name_to_index($Regularized{$version}{'tgt'}),
               $Index_Of{'tgt'},
               $test_case->{name} . ': tgt' );
    is(        $utx{$version}{has_no_column}
                ->name_to_index($Regularized{$version}{'src:pos'}),
               $Index_Of{'src:pos'},
               $test_case->{name} . ': src:pos' );

    is(        $utx{$version}{has_column}
                ->name_to_index($Regularized{$version}{'src:foo'}),
               $Index_Of{'src:foo'},
               $test_case->{name} . ': src:foo' );
    is(        $utx{$version}{has_column}
                ->name_to_index($Regularized{$version}{'tgt:bar'}),
               $Index_Of{'tgt:bar'},
               $test_case->{name} . ': tgt:bar' );

    is_deeply( $utx{$version}{has_no_column}
                ->name_to_index([]),
               [],
               $test_case->{name} . ': empty ARRAY reference' );
    is_deeply( $utx{$version}{has_no_column}
                ->name_to_index([
                    $Regularized{$version}{'src'},
                  ]),
               [$Index_Of{'src'}],
               $test_case->{name} . ': src' );
    is_deeply( $utx{$version}{has_column}
                ->name_to_index([
                    $Regularized{$version}{'tgt'},
                    $Regularized{$version}{'tgt:bar'}
                  ]),
               [$Index_Of{'tgt'}, $Index_Of{'tgt:bar'}],
               $test_case->{name} . ': tgt and tgt:bar' );

    return;
}


# ================================================================
# normal: STR(SCALAR) into NUM(SCALAR)
# [ 8subtests * 3versions = 24 tests ]
# ----------------------------------------------------------------
foreach my $version (@Versions) {
    test_convert({
        name    => "convert, $version",
        version => $version,
    });
}


# ================================================================
# exception
# [ 1subtest * 6kindes * 3version = 18 tests ]
# ----------------------------------------------------------------
foreach my $version (@Versions) {
    test_convert({
        name      => "exception: undef in SCALAR, $version",
        exception => 1,
        version   => $version,
        query     => undef,
        result    => q{Can't convert column name into column index: }
                   . q{column name isn't defined},
    });
    test_convert({
        name      => "exception: undef in ARRAY, $version",
        exception => 1,
        version   => $version,
        query     => [
            $Regularized{$version}{src},
            undef,
        ],
        result    => q{Can't convert column name into column index: }
                   . q{column name at argument's offset \(1\) isn't defined},
    });
    test_convert({
        name      => "exception: unexists in SCALAR, $version",
        exception => 1,
        version   => $version,
        query     => 'amazing_absentee_column_name',
        result    => q{Can't convert column name into column index: }
                   . q{column name \(amazing_absentee_column_name\) }
                   . q{isn't defined},
    });
    test_convert({
        name      => "exception: unexists in ARRAY, $version",
        exception => 1,
        version   => $version,
        query     => [
            $Regularized{$version}{src},
            'amazing_absentee_column_name',
        ],
        result    => q{Can't convert column name into column index: }
                   . q{column name \(amazing_absentee_column_name\) }
                   . q{isn't defined},
    });
    test_convert({
        name      => "exception: HASH reference, $version",
        exception => 1,
        version   => $version,
        query     => {
            foo => 42,
        },
        result    => q{Can't convert column name into column index: }
                   . q{type of column name \(HASH\) isn't valid},
    });

    # list
    my $message = q{Can't convert column name into column index: }
                . q{attempt to use LIST as names }
                . q{\(you should use an ARRAY reference\)};
    throws_ok(sub { $utx{$version}{has_no_column}
                        ->name_to_index(
                                $Regularized{$version}{src},
                                $Regularized{$version}{tgt},
                        ) },
              qr{$message},
              "exception: LIST, $version" );
}
