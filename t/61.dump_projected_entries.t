use strict;
use warnings;
# use utf8;
use lib 't/lib';

use Test::More tests => 81;
use Test::Exception;
# use Test::Warn;
use Test::Text_UTX_Simple;

use Text::UTX::Simple;


# ================================================================
# subroutine for test
# [ 1 test or (8+9+1 = 18) tests ]
# ----------------------------------------------------------------
sub test_dump {
    my $test_case = shift;

    my $version = $test_case->{version};

    my $utx = Text::UTX::Simple->new({
        %{ $test_case->{query}{new} },
        text => do {
            join "\n", (
                ( split "\n",
                    $Query{header}{$version}{'en/ja'}
                          {has_column} ),
                ( join "\t",
                    qw(src0 tgt0 src:pos0 src:foo0 tgt:bar0),
                    $test_case->{column_number} == 6 ? 'comment0' : ()
                ),
            )
        },
    });

    if ($test_case->{exception}) {  # 1test
        throws_ok( sub { my $error = $utx->dump_body({
                                        columns => $test_case->{query}{dump}
                                     }) },
                   qr{$test_case->{result}},
                   $test_case->{name} );
        return;
    }

    # --------------------------------
    # singular entry
    # [8 tests]
    # --------------------------------
    is_deeply( $utx->dump_body({array_ref => 1, columns => [qw(0)]}),
               [ [qw(src0)], ],
               $test_case->{name} . ' projection: 1 entry 1 column' );
    is_deeply( $utx->dump_body({
                            array_ref => 1,
                            columns => [
                                $Regularized{$version}{'src'},
                            ],
               }),
               [ [qw(src0)], ],
               $test_case->{name} . ' projection: 1 entry 1 column' );
    is_deeply( $utx->dump_body({array_ref => 1, columns => [qw(0 4)]}),
               [ [qw(src0 tgt:bar0)], ],
               $test_case->{name} . ' projection: 1 entry 2 column' );
    is_deeply( $utx->dump_body({
                            array_ref => 1,
                            columns => [
                                $Regularized{$version}{'src'},
                                $Regularized{$version}{'tgt:bar'},
                            ],
               }),
               [ [qw(src0 tgt:bar0)], ],
               $test_case->{name} . ' projection: 1 entry 2 column' );
    is_deeply( $utx->dump_body({
                            array_ref => 1,
                            columns => [
                                0,
                                $Regularized{$version}{'tgt:bar'},
                            ],
               }),
               [ [qw(src0 tgt:bar0)], ],
               $test_case->{name} . ' projection: 1 entry 2 column' );
    is_deeply( $utx->dump_body({array_ref => 1, columns => undef}),
               [ [qw(src0 tgt0 src:pos0 src:foo0 tgt:bar0),
                  $test_case->{column_number} == 6 ? 'comment0' : ()], ],
               $test_case->{name} . ' undef = same as no projection' );
    is_deeply( $utx->dump_body({array_ref => 1, columns => []}),
               [ [], ],
               $test_case->{name} . ' projection: 1 entry 0 column' );
    is_deeply( $utx->dump_body({
                    array_ref => 1,
                    columns => [- $test_case->{column_number}],
               }),
               [ [qw(src0)], ],
               $test_case->{name} . ' projection: 1 entry 1 column' );

    # --------------------------------
    # plural entries
    # [9 tests]
    # --------------------------------
    $utx = Text::UTX::Simple->new({
        %{ $test_case->{query}{new} },
        text => do {
            join "\n", (
                ( split "\n",
                    $Query{header}{$version}{'en/ja'}
                          {has_column} ),
                ( join "\t",
                    qw(    src0 tgt00 src:pos00 src:foo00 tgt:bar00),
                    $test_case->{column_number} == 6 ? 'comment00' : () ),
                ( join "\t",
                    qw(    src1 tgt10 src:pos10 src:foo10 tgt:bar10),
                    $test_case->{column_number} == 6 ? 'comment10' : () ),
                ( join "\t",
                    '#src1', qw(tgt11 src:pos11 src:foo11 tgt:bar11),
                    $test_case->{column_number} == 6 ? 'comment11' : () ),
                ( join "\t",
                    qw(    src1 tgt12 src:pos12 src:foo12 tgt:bar12),
                    $test_case->{column_number} == 6 ? 'comment12' : () ),
                ( join "\t",
                    qw(    src2 tgt20 src:pos20 src:foo20 tgt:bar20),
                    $test_case->{column_number} == 6 ? 'comment20' : () ),
            )
        },
    });
    is_deeply( $utx->dump_body({array_ref => 1, columns => [qw(0)]}),
               [ [qw(src0)],
                 [qw(src1)],
                 ['#src1'],
                 [qw(src1)],
                 [qw(src2)], ],
               $test_case->{name}
                . ' projection: 5 entries 1 column (index)' );
    is_deeply( $utx->dump_body({
                            array_ref => 1,
                            columns => [
                                $Regularized{$version}{'src'},
                            ],
               }),
               [ [qw(src0)],
                 [qw(src1)],
                 ['#src1'],
                 [qw(src1)],
                 [qw(src2)], ],
               $test_case->{name}
                . ' projection: 5 entries 1 column (name)' );
    is_deeply( $utx->dump_body({array_ref => 1, columns => [qw(0 4)]}),
               [ [qw(src0     tgt:bar00)],
                 [qw(src1     tgt:bar10)],
                 ['#src1', qw(tgt:bar11)],
                 [qw(src1     tgt:bar12)],
                 [qw(src2     tgt:bar20)], ],
               $test_case->{name}
                . ' projection: 5 entries 2 columns (indexes)' );
    is_deeply( [ $utx->dump_body({columns => [qw(0 4)]}) ],
               [ [qw(src0     tgt:bar00)],
                 [qw(src1     tgt:bar10)],
                 ['#src1', qw(tgt:bar11)],
                 [qw(src1     tgt:bar12)],
                 [qw(src2     tgt:bar20)], ],
               $test_case->{name}
                . ' projection: 5 entries 2 columns (indexes), LIST' );
    is_deeply( $utx->dump_body({
                            array_ref => 1,
                            columns => [
                                $Regularized{$version}{'src'},
                                $Regularized{$version}{'tgt:bar'},
                            ],
               }),
               [ [qw(src0     tgt:bar00)],
                 [qw(src1     tgt:bar10)],
                 ['#src1', qw(tgt:bar11)],
                 [qw(src1     tgt:bar12)],
                 [qw(src2     tgt:bar20)], ],
               $test_case->{name}
                . ' projection: 5 entries 2 columns (names)' );
    is_deeply( $utx->dump_body({
                            array_ref => 1,
                            columns => [
                                0,
                                $Regularized{$version}{'tgt:bar'},
                            ],
               }),
               [ [qw(src0     tgt:bar00)],
                 [qw(src1     tgt:bar10)],
                 ['#src1', qw(tgt:bar11)],
                 [qw(src1     tgt:bar12)],
                 [qw(src2     tgt:bar20)], ],
               $test_case->{name}
                . ' projection: 5 entries 2 columns (index and name)' );
    is_deeply( $utx->dump_body({array_ref => 1, columns => undef}),
               [ [qw(src0     tgt00 src:pos00 src:foo00 tgt:bar00),
                    $test_case->{column_number} == 6 ? 'comment00' : () ],
                 [qw(src1     tgt10 src:pos10 src:foo10 tgt:bar10),
                    $test_case->{column_number} == 6 ? 'comment10' : () ],
                 ['#src1', qw(tgt11 src:pos11 src:foo11 tgt:bar11),
                    $test_case->{column_number} == 6 ? 'comment11' : () ],
                 [qw(src1     tgt12 src:pos12 src:foo12 tgt:bar12),
                    $test_case->{column_number} == 6 ? 'comment12' : () ],
                 [qw(src2     tgt20 src:pos20 src:foo20 tgt:bar20),
                    $test_case->{column_number} == 6 ? 'comment20' : () ], ],
               $test_case->{name}
                . ' undef = same as no projection' );
    is_deeply( $utx->dump_body({array_ref => 1, columns => []}),
               [ [],
                 [],
                 [],
                 [],
                 [], ],
               $test_case->{name}
                . ' projection: 5 entry 0 column' );
    is_deeply( $utx->dump_body({
                    array_ref => 1,
                    columns => [- $test_case->{column_number}],
               }),
               [ [qw(src0)],
                 [qw(src1)],
                 ['#src1'],
                 [qw(src1)],
                 [qw(src2)], ],
               $test_case->{name}
                . ' projection: 5 entry 1 column' );

    # --------------------------------
    # plural entries, selection and projection
    # [1 test]
    # --------------------------------
    is_deeply( $utx->dump_body({
                            array_ref => 1,
                            columns => [
                                0,
                                $Regularized{$version}{'tgt:bar'},
                            ],
               }, [qw(0 2)]),
               [ [qw(src0     tgt:bar00)],
                 ['#src1', qw(tgt:bar11)], ],
               $test_case->{name}
                . ' projection + selection: 2 entry 2 columns' );
}


# ================================================================
# dump projected entries, and exception
# [ 54 + 27 = 81tests ]
# ----------------------------------------------------------------
foreach my $version (@Versions) {
    my %version_definition = ( version => $version );

    my $column_number
        = scalar @{ $Query{column}{$version}{array}{all} };

    # normal: 18subtests * 1kind * 3versions = 54tests
    test_dump({
        name    => "version: $version",
        query   => {
            new => \%version_definition,
        },
        version => $version,
        column_number => $column_number,
    });

    # exception: 1subtest * 9kinds * 3versions = 27tests
    test_dump({
        name      => "exception: past end of array, $version",
        exception => 1,
        version   => $version,
        column_number => $column_number,
        query     => {
            new  => \%version_definition,
            dump => [$column_number],
        },
        result    => q{Can't project columns: }
                   . q{offset \(} . $column_number
                   . q{\) past end of array},
    });
    test_dump({
        name      => "exception: negative offset past end of array, $version",
        exception => 1,
        version   => $version,
        column_number => $column_number,
        query     => {
            new  => \%version_definition,
            dump => [ -$column_number - 1],
        },
        result    => q{Can't project columns: }
                   . q{offset \(-} . ($column_number + 1)
                   . q{\) past end of array},
    });
    test_dump({
        name      => "exception: offset past end of array, $version",
        exception => 1,
        version   => $version,
        column_number => $column_number,
        query     => {
            new  => \%version_definition,
            dump => [4, $column_number, 0],
        },
        result    => q{Can't project columns: }
                   . q{offset \(} . $column_number
                   . q{\) past end of array},
    });
    test_dump({
        name      => "exception: offset past end of array (more right), "
                   . $version,
        exception => 1,
        version   => $version,
        column_number => $column_number,
        query     => {
            new  => \%version_definition,
            dump => [4, $column_number, $column_number + 1],
        },
        result    => q{Can't project columns: }
                   . q{offset \(} . ($column_number + 1)
                   . q{\) past end of array},
    });
    test_dump({
        name      => "exception: undef, $version",
        exception => 1,
        version   => $version,
        column_number => $column_number,
        query     => {
            new  => \%version_definition,
            dump => [undef],
        },
        result    => q{Can't convert column name into column index: }
                   . q{column name isn't defined},
    });
    test_dump({
        name      => "exception: undef and valid, $version",
        exception => 1,
        version   => $version,
        column_number => $column_number,
        query     => {
            new  => \%version_definition,
            dump => [qw(0 1), undef],
        },
        result    => q{Can't convert column name into column index: }
                   . q{column name isn't defined},
    });
    test_dump({
        name      => "exception: unexist, $version",
        exception => 1,
        version   => $version,
        column_number => $column_number,
        query     => {
            new  => \%version_definition,
            dump => [qw(amazing_absentee_column_name)],
        },
        result    => q{Can't convert column name into column index: }
                   . q{column name \(amazing_absentee_column_name\) }
                   . q{isn't defined on header},
    });
    test_dump({
        name      => "exception: Inf, $version",
        exception => 1,
        version   => $version,
        column_number => $column_number,
        query     => {
            new  => \%version_definition,
            dump => [qw(Inf)],
        },
        result    => q{Can't convert column name into column index: }
                   . q{column name \(Inf\) }
                   . q{isn't defined on header},
    });
    test_dump({
        name      => "exception: Infinity, $version",
        exception => 1,
        version   => $version,
        column_number => $column_number,
        query     => {
            new  => \%version_definition,
            dump => [qw(Infinity)],
        },
        result    => q{Can't convert column name into column index: }
                   . q{column name \(Infinity\) }
                   . q{isn't defined on header},
    });
}
