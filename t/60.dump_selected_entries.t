use strict;
use warnings;
# use utf8;
use lib 't/lib';

use Test::More tests => 54;
use Test::Exception;
use Test::Warn;
use Test::Text_UTX_Simple;

use Text::UTX::Simple;


# ================================================================
# subroutine for test
# [ 1 test or (5+7 = 12) tests ]
# ----------------------------------------------------------------
sub test_dump {
    my $test_case = shift;

    my $utx = Text::UTX::Simple->new({
        %{ $test_case->{query}{new} },
        text => do {
            join "\n", (
                ( split "\n",
                    $Query{header}{$test_case->{version}}{'en/ja'}
                          {has_column} ),
                ( join "\t", qw(src0 tgt0 src:pos0 src:foo0 tgt:bar0) ),
            )
        },
    });

    if ($test_case->{exception}) {  # 1test
        throws_ok( sub { my $error
                            = $utx->dump_body($test_case->{query}{dump}) },
                   qr{$test_case->{result}},
                   $test_case->{name} );
        return;
    }

    # --------------------------------
    # singular entry
    # [5 tests]
    # --------------------------------
    is_deeply( $utx->dump_body({array_ref => 1}, undef),
               [[qw(src0 tgt0 src:pos0 src:foo0 tgt:bar0)]],
               $test_case->{name} . ' : undef = same as no selection' );
    is_deeply( $utx->dump_body({array_ref => 1}, []),
               [],
               $test_case->{name} . ' : no element' );
    is_deeply( $utx->dump_body({array_ref => 1}, [qw(0)]),
               [[qw(src0 tgt0 src:pos0 src:foo0 tgt:bar0)]],
               $test_case->{name} . ' : element #0' );
    is_deeply( $utx->dump_body({array_ref => 1}, [qw(-1)]),
               [[qw(src0 tgt0 src:pos0 src:foo0 tgt:bar0)]],
               $test_case->{name} . ' : element #0' );
    is_deeply( $utx->dump_body({array_ref => 1}, [qw(src0)]),
               [[qw(src0 tgt0 src:pos0 src:foo0 tgt:bar0)]],
               $test_case->{name} . ' : element src0' );

    # --------------------------------
    # plural entries
    # [7 tests]
    # --------------------------------
    $utx = Text::UTX::Simple->new({
        %{ $test_case->{query}{new} },
        text => do {
            join "\n", (
                ( split "\n",
                    $Query{header}{$test_case->{version}}{'en/ja'}
                          {has_column} ),
                ( join "\t", qw(    src0 tgt00 src:pos00 src:foo00 tgt:bar00) ),
                ( join "\t", qw(    src1 tgt10 src:pos10 src:foo10 tgt:bar10) ),
                ( join "\t", '#src1', qw(tgt11 src:pos11 src:foo11 tgt:bar11) ),
                ( join "\t", qw(    src1 tgt12 src:pos12 src:foo12 tgt:bar12) ),
                ( join "\t", qw(    src2 tgt20 src:pos20 src:foo20 tgt:bar20) ),
            )
        },
    });
    is_deeply(   $utx->dump_body({array_ref => 1}, [qw(0 3)]),
               [ [qw(src0 tgt00 src:pos00 src:foo00 tgt:bar00)],
                 [qw(src1 tgt12 src:pos12 src:foo12 tgt:bar12)], ],
               $test_case->{name} . ' : dump selected 2 entries, positive' );
    is_deeply(   $utx->dump_body({array_ref => 1}, [qw(-2 -4)]),
               [ [qw(src1 tgt12 src:pos12 src:foo12 tgt:bar12)],
                 [qw(src1 tgt10 src:pos10 src:foo10 tgt:bar10)], ],
               $test_case->{name} . ' : dump selected 2 entries, negative' );
    is_deeply(   $utx->dump_body({array_ref => 1}, [qw(1 0)]),
               [ [qw(src1 tgt10 src:pos10 src:foo10 tgt:bar10)],
                 [qw(src0 tgt00 src:pos00 src:foo00 tgt:bar00)], ],
               $test_case->{name} . ' : dump selected 2 entries, reverse' );
    # NOTE: comment entry does not return IF ACCESSED BY ARRAY-ENTRIES
    is_deeply(   $utx->dump_body({array_ref => 1}, [qw(1 2)]),
               [ [qw(src1     tgt10 src:pos10 src:foo10 tgt:bar10)    ],
                 ['#src1', qw(tgt11 src:pos11 src:foo11 tgt:bar11)], ],
               $test_case->{name} . ' : dump selected 2 entries, comment out' );
    is_deeply( [ $utx->dump_body(                  [qw(0 3)]) ],
               [ [qw(src0 tgt00 src:pos00 src:foo00 tgt:bar00)],
                 [qw(src1 tgt12 src:pos12 src:foo12 tgt:bar12)], ],
               $test_case->{name} . ' : dump selected 2 entries, list' );
    # NOTE: comment entry does not return IF ACCESSED BY HASH-KEY
    is_deeply( [ $utx->dump_body(                  [qw(src1)]) ],
               [ [qw(    src1 tgt10 src:pos10 src:foo10 tgt:bar10)],
             #   ['#src1', qw(tgt11 src:pos11 src:foo11 tgt:bar11)],
                 [qw(    src1 tgt12 src:pos12 src:foo12 tgt:bar12)], ],
               $test_case->{name} . ' : dump selected 3 entries, list' );
    is_deeply( [ $utx->dump_body(                  [qw(src1 src0)]) ],
               [ [qw(    src1 tgt10 src:pos10 src:foo10 tgt:bar10)],
             #   ['#src1', qw(tgt11 src:pos11 src:foo11 tgt:bar11)],
                 [qw(    src1 tgt12 src:pos12 src:foo12 tgt:bar12)],
                 [qw(    src0 tgt00 src:pos00 src:foo00 tgt:bar00)], ],
               $test_case->{name} . ' : dump selected 4 entries, list' );
}


# ================================================================
# dump selected entries, and exception
# [ 36 + 15 = 51tests ]
# ----------------------------------------------------------------
foreach my $version (@Versions) {
    my %version_definition = ( version => $version );

    # normal: 12subtests * 1kind * 3versions = 36tests
    test_dump({
        name    => "version: $version",
        query   => {
            new => \%version_definition,
        },
        version => $version,
    });

    # exception: 1subtest * 5kinds * 3versions = 15tests
    test_dump({
        name      => "exception: positive offset past end of array, $version",
        exception => 1,
        version   => $version,
        query     => {
            new  => \%version_definition,
            dump => [5],
        },
        result    => q{Can't select rows: }
                   . q{offset \(5\) past end of array},
    });
    test_dump({
        name      => "exception: negative offset past end of array, $version",
        exception => 1,
        version   => $version,
        query     => {
            new  => \%version_definition,
            dump => [-6],
        },
        result    => q{Can't select rows: }
                   . q{offset \(-6\) past end of array},
    });
    test_dump({
        name      => "exception: absentee column name (STR)",
        exception => 1,
        version   => $version,
        query     => {
            new  => \%version_definition,
            dump => [qw(amazing_absentee_column_name)],
        },
        result    => q{Can't select rows: }
                   . q{entry \(amazing_absentee_column_name\) doesn't exist},
    });
    test_dump({
        name      => "exception: absentee column name (Inf)",
        exception => 1,
        version   => $version,
        query     => {
            new  => \%version_definition,
            dump => [qw(Inf)],
        },
        result    => q{Can't select rows: }
                   . q{entry \(Inf\) doesn't exist},
    });
    test_dump({
        name      => "exception: absentee column name (Infinity)",
        exception => 1,
        version   => $version,
        query     => {
            new  => \%version_definition,
            dump => [qw(Infinity)],
        },
        result    => q{Can't select rows: }
                   . q{entry \(Infinity\) doesn't exist},
    });
}


# ================================================================
# warning
# write end of the file, to evade invalid exception
# "Bizarre copy of HASH in sassign at ...../Carp/Heavy.pm line 104."
# [ 1subtests * 3versions = 3tests ]
# ----------------------------------------------------------------
foreach my $version (@Versions) {
    my $utx = Text::UTX::Simple->new({version => $version});
    warning_is
        { $utx->dump_body([0]) }
        { carped => 'Useless use private variable in void context' }
    ;
}
