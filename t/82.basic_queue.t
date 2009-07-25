# queue structure

use strict;
use warnings;
# use utf8;
use lib 't/lib';

use Test::More tests => 180;
use Test::Exception;
use Test::Warn;
use Test::Text_UTX_Simple;

use Text::UTX::Simple;


# ================================================================
# subroutine for test
# [ 8+9+4+4+6+6=37 tests or 2 tests ]
# ----------------------------------------------------------------
sub test_manipulate {
    my $test_case = shift;

    my $version = $test_case->{version};
    my $utx = Text::UTX::Simple->new($test_case->{query}{new});
    my $removed;

    if ($test_case->{exception}) {  # 2 test
        throws_ok( sub { $utx->push($test_case->{query}{manipulate}); },
                   qr{$test_case->{result}},
                   $test_case->{name} );
        is( $utx->dump_body({array_ref => 1}),
            undef,
            $test_case->{name} . ' : no elements' );
        return;
    }

    # --------------------------------
    # unshift an ARRAY reference
    # 2*4 = 8tests
    # --------------------------------
    is(        $utx->unshift( [qw(src0 tgt0 src:pos0 foo0 bar0)] ),
               1,
               $test_case->{name} . ' : undef + unshift 0 = 0 (length 1)' );
    is_deeply( $utx->dump_body({array_ref => 1}),
               [ [qw(src0 tgt0 src:pos0 foo0 bar0)], ],
               $test_case->{name} . ' : undef + unshift 0 = 0' );
    is(        $utx->unshift( [qw(src1 tgt1 src:pos1 foo1 bar1)] ),
               2,
               $test_case->{name} . ' : 0 + unshift 1 = 1 0 (length 2)' );
    is_deeply( $utx->dump_body({array_ref => 1}),
               [ [qw(src1 tgt1 src:pos1 foo1 bar1)],
                 [qw(src0 tgt0 src:pos0 foo0 bar0)], ],
               $test_case->{name} . ' : 0 + unshift 1 = 1 0' );
    is(        $utx->unshift(),
               2,
               $test_case->{name} . ' : 1 0 + unshift undef = 1 0(length 2)' );
    is_deeply( $utx->dump_body({array_ref => 1}),
               [ [qw(src1 tgt1 src:pos1 foo1 bar1)],
                 [qw(src0 tgt0 src:pos0 foo0 bar0)], ],
               $test_case->{name} . ' : 1 0 + unshift undef = 1 0' );
    is(        $utx->unshift( ['#src2', qw(tgt2 src:pos2 foo2 bar2)] ),
               3,
               $test_case->{name} . ' : 1 0 + unshift #2 = #2 1 0(length 3)' );
    is_deeply( $utx->dump_body({array_ref => 1}),
               [ ['#src2', qw(tgt2 src:pos2 foo2 bar2)],
                 [qw(src1     tgt1 src:pos1 foo1 bar1)],
                 [qw(src0     tgt0 src:pos0 foo0 bar0)], ],
               $test_case->{name} . ' : 1 0 + unshift #2 = #2 1 0' );

    # --------------------------------
    # shift
    # 3*3 = 9tests
    # --------------------------------
    pass(      $removed = $utx->shift() );
    is_deeply( $utx->dump_body({array_ref => 1}),
               [ [qw(src1 tgt1 src:pos1 foo1 bar1)],
                 [qw(src0 tgt0 src:pos0 foo0 bar0)], ],
               $test_case->{name} . ' : #2 1 0 + shift = rest 1 0' );
    is_deeply( $removed->dump_body({array_ref => 1}),
               [ ['#src2', qw(tgt2 src:pos2 foo2 bar2)], ],
               $test_case->{name} . ' : #2 1 0 + shift = removed #2' );
    $removed = $utx->shift();       #   1 0 + shift = rest 0, removed 1
    pass(      $removed = $utx->shift() );
    is(        $utx->dump_body({array_ref => 1}),
               undef,
               $test_case->{name} . ' : 0 + shift = rest undef' );
    is_deeply( $removed->dump_body({array_ref => 1}),
               [ [qw(src0 tgt0 src:pos0 foo0 bar0)], ],
               $test_case->{name} . ' : 0 + shift = removed 0' );
    pass(      $removed = $utx->shift() );
    is(        $utx->dump_body({array_ref => 1}),
               undef,
               $test_case->{name}
                    . ' : undef + shift(overdose) = rest undef' );
    is(        $removed,
               undef,
               $test_case->{name}
                    . ' : undef + shift(overdose) = removed undef' );

    # --------------------------------
    # unshift LIST
    # 2*2 = 4tests
    # --------------------------------
    $utx->clear();
    is(        $utx->unshift( qw(src0 tgt0 src:pos0 foo0 bar0) ),
               1,
               $test_case->{name} . ' : undef + unshift 0 = 0 (length 1)' );
    is_deeply( $utx->dump_body({array_ref => 1}),
               [ [qw(src0 tgt0 src:pos0 foo0 bar0)], ],
               $test_case->{name} . ' : undef + unshift 0 = 0' );
    is(        $utx->unshift( [ qw(src1     tgt1 src:pos1 foo1 bar1) ],
                              [ '#src2', qw(tgt2 src:pos2 foo2 bar2) ], ),
               3,
               $test_case->{name} . ' : 0 + unshift 1 #2 = 1 #2 0 (length 3)' );
    is_deeply( $utx->dump_body({array_ref => 1}),
               [ [qw(src1     tgt1 src:pos1 foo1 bar1)],
                 ['#src2', qw(tgt2 src:pos2 foo2 bar2)],
                 [qw(src0     tgt0 src:pos0 foo0 bar0)], ],
               $test_case->{name} . ' : 0 + unshift 1 #2 = 1 #2 0' );

    # --------------------------------
    # unshift a HASH reference
    # 2*2 = 4tests
    # --------------------------------
    $utx->parse($Query{header}{$version}{'en-US/ja-JP'}{has_column});
    is(        $utx->unshift({
                    $Regularized{$version}{'src'}     => 'src0',
                    $Regularized{$version}{'tgt'}     => 'tgt0',
                    $Regularized{$version}{'src:pos'} => 'src:pos0',
                    $Regularized{$version}{'src:foo'} => 'foo0',
                    $Regularized{$version}{'tgt:bar'} => 'bar0',
               }),
               1,
               $test_case->{name} . ' : undef + unshift 0 = 0 (length 1)' );
    is_deeply( $utx->dump_body({array_ref => 1}),
               [ [qw(src0 tgt0 src:pos0 foo0 bar0)], ],
               $test_case->{name} . ' : undef + unshift 0 = 0' );
    is(        $utx->unshift({
                    $Regularized{$version}{'src'}     => '#src1',
                    $Regularized{$version}{'tgt'}     => 'tgt1',
                    $Regularized{$version}{'src:pos'} => 'src:pos1',
                    $Regularized{$version}{'src:foo'} => 'foo1',
                    $Regularized{$version}{'tgt:bar'} => 'bar1',
               }, {
                    $Regularized{$version}{'src'}     => 'src2',
                    $Regularized{$version}{'tgt'}     => 'tgt2',
                    $Regularized{$version}{'src:pos'} => 'src:pos2',
                    $Regularized{$version}{'src:foo'} => 'foo2',
                    $Regularized{$version}{'tgt:bar'} => 'bar2',
               }),
               3,
               $test_case->{name} . ' : 0 + unshift #1 2 = #1 2 0(length 3)' );
    is_deeply( $utx->dump_body({array_ref => 1}),
               [ ['#src1', qw(tgt1 src:pos1 foo1 bar1)],
                 [qw(src2     tgt2 src:pos2 foo2 bar2)],
                 [qw(src0     tgt0 src:pos0 foo0 bar0)], ],
               $test_case->{name} . ' : 0 + unshift #1 2 = #1 2 0' );

    # --------------------------------
    # unshift HASH in ARRAY ref
    # 2*3 = 6tests
    # --------------------------------
    $utx->clear();
    is(        $utx->unshift( [ {
                    $Regularized{$version}{'src'}     => '#src0',
                    $Regularized{$version}{'tgt'}     => 'tgt0',
                    $Regularized{$version}{'src:pos'} => 'src:pos0',
                    $Regularized{$version}{'src:foo'} => 'foo0',
                    $Regularized{$version}{'tgt:bar'} => 'bar0',
               }, {
                    $Regularized{$version}{'src'}     => 'src1',
                    $Regularized{$version}{'tgt'}     => 'tgt1',
                    $Regularized{$version}{'src:pos'} => 'src:pos1',
                    $Regularized{$version}{'src:foo'} => 'foo1',
                    $Regularized{$version}{'tgt:bar'} => 'bar1',
               }, ] ),
               2,
               $test_case->{name}
                    . ' : undef + unshift #0 1 = #0 1 (length 2)' );
    is_deeply( $utx->dump_body({array_ref => 1}),
               [ ['#src0', qw(tgt0 src:pos0 foo0 bar0)],
                 [qw(src1     tgt1 src:pos1 foo1 bar1)], ],
               'undef + unshift #0 1 = #0 1 ' );
    is(        $utx->unshift( [ {
                    $Regularized{$version}{'src'}     => '#src2',
                    $Regularized{$version}{'tgt'}     => 'tgt2',
                    $Regularized{$version}{'src:pos'} => 'src:pos2',
                    $Regularized{$version}{'src:foo'} => 'foo2',
                    $Regularized{$version}{'tgt:bar'} => 'bar2',
               } ] ),
               3,
               $test_case->{name}
                    . ' : #0 1 + unshift #2 = #2 #0 1(length 3)' );
    is_deeply( $utx->dump_body({array_ref => 1}),
               [ ['#src2', qw(tgt2 src:pos2 foo2 bar2)],
                 ['#src0', qw(tgt0 src:pos0 foo0 bar0)],
                 [qw(src1     tgt1 src:pos1 foo1 bar1)], ],
               $test_case->{name} . ' : #0 1 + unshift #2 = #2 #0 1' );
    is(        $utx->unshift( [ {
                    $Regularized{$version}{'src'}     => '#src3',
                    $Regularized{$version}{'tgt'}     => 'tgt3',
                    $Regularized{$version}{'src:pos'} => 'src:pos3',
                    $Regularized{$version}{'src:foo'} => 'foo3',
                    $Regularized{$version}{'tgt:bar'} => 'bar3',
               }, ], [ {
                    $Regularized{$version}{'src'}     => 'src4',
                    $Regularized{$version}{'tgt'}     => 'tgt4',
                    $Regularized{$version}{'src:pos'} => 'src:pos4',
                    $Regularized{$version}{'src:foo'} => 'foo4',
                    $Regularized{$version}{'tgt:bar'} => 'bar4',
               }, {
                    $Regularized{$version}{'src'}     => '#src5',
                    $Regularized{$version}{'tgt'}     => 'tgt5',
                    $Regularized{$version}{'src:pos'} => 'src:pos5',
                    $Regularized{$version}{'src:foo'} => 'foo5',
                    $Regularized{$version}{'tgt:bar'} => 'bar5',
               }, ] ),
               6,
               $test_case->{name}
                    . ' : #2 #0 1 + unshift #3 4 #5'
                    . ' = #3 4 #5 #2 #0 1 (length 6)' );
    is_deeply( $utx->dump_body({array_ref => 1}),
               [ ['#src3', qw(tgt3 src:pos3 foo3 bar3)],
                 [qw(src4     tgt4 src:pos4 foo4 bar4)],
                 ['#src5', qw(tgt5 src:pos5 foo5 bar5)],
                 ['#src2', qw(tgt2 src:pos2 foo2 bar2)],
                 ['#src0', qw(tgt0 src:pos0 foo0 bar0)],
                 [qw(src1     tgt1 src:pos1 foo1 bar1)], ],
               $test_case->{name}
                    . ' : #2 #0 1 + unshift #3 4 #5'
                    . ' = #3 4 #5 #2 #0 1' );

    # --------------------------------
    # auto convert undefined value into void value
    # 2*3 = 6tests
    # --------------------------------
    $utx->clear();
    is(        $utx->unshift( [qw(src0), undef, qw(src:pos0 foo0 bar0)] ),
               1,
               $test_case->{name} . ' : undef + unshift 0 = 0 (length 1)' );
    is_deeply( $utx->dump_body({array_ref => 1}),
               [ [qw(src0), q{}, qw(src:pos0 foo0 bar0)], ],
               $test_case->{name} . ' : undef + unshift 0 = 0' );
    $utx->clear();
    is(        $utx->unshift( [qw(src0), q{}, qw(src:pos0 foo0 bar0)] ),
               1,
               $test_case->{name} . ' : undef + unshift 0 = 0 (length 1)' );
    is_deeply( $utx->dump_body({array_ref => 1}),
               [ [qw(src0), q{}, qw(src:pos0 foo0 bar0)], ],
               $test_case->{name} . ' : undef + unshift 0 = 0' );
    $utx->clear();
    is(        $utx->unshift( [qw(src0), q{-}, qw(src:pos0 foo0 bar0)] ),
               1,
               $test_case->{name} . ' : undef + unshift 0 = 0 (length 1)' );
    is_deeply( $utx->dump_body({array_ref => 1}),
               [ [qw(src0), q{-}, qw(src:pos0 foo0 bar0)], ],
               $test_case->{name} . ' : undef + unshift 0 = 0' );

    return;
}


# ================================================================
# manipulate
# [ (37+2)subtests * 3versions = 117 tests ]
# ----------------------------------------------------------------
foreach my $version (@Versions) {
    my %version_definition = ( version => $version );

    # normal : 9subtests * 1kinds * 3versions = 27tests
    test_manipulate({
        name    => "normal : write, version $version",
        query   => {
            new => \%version_definition,
        },
        version => $version,
    });

    # exception: 1subtest * 1kinds * 3versions = 3tests
    # exception: array to array to array
    test_manipulate({
        exception => 1,
        name      => "undef + array to array to array = croak, $version",
        query     => {
            new        => \%version_definition,
            manipulate => [[ [ qw(src0 tgt0 src:pos0 foo0 bar0) ],
                             [ qw(src1 tgt1 src:pos1 foo1 bar1) ], ]],
        },
        result    => q{Can't parse elements: deep recursion},
    });
}


# ================================================================
# warning
# 3+3+3+12 = 21subtests * 3versions = 63tests
# notice: write end of file, to evade "Bizarre copy of..."
# ----------------------------------------------------------------
foreach my $version (@Versions) {
    my %version_definition = ( version => $version );

    my $utx = Text::UTX::Simple->new(\%version_definition);

    # warning: undef at first column [3]
    warning_is
        { $utx->unshift( [undef, qw(tgt0 src:pos0 foo0 bar0)] ) }
        { carped => q{Can't parse an entry: }
                  . q{headword (first column) is void or is ineffective, }
                  . q{therefore, specified element (0) was skipped} }
    ;
    is_deeply( $utx->{body}{entries},
               [ ],
               "$version : 0 entry and 1 skipped undef headword (value)" );
    is_deeply( $utx->{body}{entry},
               { },
               "$version : 0 entry and 1 skipped undef headword (index)" );

    # warning: empty at first column [3]
    warning_is
        { $utx->unshift( [q{}, qw(tgt0 src:pos0 foo0 bar0)] ) }
        { carped => q{Can't parse an entry: }
                  . q{headword (first column) is void or is ineffective, }
                  . q{therefore, specified element (0) was skipped} }
    ;
    is_deeply( $utx->{body}{entries},
               [ ],
               "$version : 0 entry and 1 skipped empty headword (value)" );
    is_deeply( $utx->{body}{entry},
               { },
               "$version : 0 entry and 1 skipped empty headword (index)" );

    # warning: ineffective at first column [3]
    warning_is
        { $utx->unshift( [q{-}, qw(tgt0 src:pos0 foo0 bar0)] ) }
        { carped => q{Can't parse an entry: }
                  . q{headword (first column) is void or is ineffective, }
                  . q{therefore, specified element (0) was skipped} }
    ;
    is_deeply( $utx->{body}{entries},
               [ ],
               "$version : "
                . "0 entry and 1 skipped ineffective headword (value)" );
    is_deeply( $utx->{body}{entry},
               { },
               "$version : "
                . "0 entry and 1 skipped ineffective headword (index)" );

    # warning: number at first column [3*4=12]
    warning_is
        { $utx->unshift([qw(42 tgt0 src:pos0 foo0 bar0)]) }
        { carped => q{Can't parse an entry: }
                  . q{headword (first column) looks like number, }
                  . q{therefore, specified element (0) was skipped} }
    ;
    is_deeply( $utx->{body}{entries},
               [ ],
               "$version : 0 entry and 1 skipped number headword (value)" );
    is_deeply( $utx->{body}{entry},
               { },
               "$version : 0 entry and 1 skipped number headword (index)" );
    warning_is
        { $utx->unshift(['#42', qw(tgt0 src:pos0 foo0 bar0)]) }
        { carped => q{Can't parse an entry: }
                  . q{headword (first column) looks like number, }
                  . q{therefore, specified element (0) was skipped} }
    ;
    is_deeply( $utx->{body}{entries},
               [ ],
               "$version : 0 entry and 1 skipped number headword (value)" );
    is_deeply( $utx->{body}{entry},
               { },
               "$version : 0 entry and 1 skipped number headword (index)" );
    warning_is
        { $utx->unshift([qw(Inf tgt0 src:pos0 foo0 bar0)]) }
        undef
    ;
    is_deeply( $utx->{body}{entries},
               [ { is_comment => q{},
                   columns    => [qw(Inf tgt0 src:pos0 foo0 bar0)] } ],
               "$version : 1 entry and 0 skipped headword (value)" );
    is_deeply( $utx->{body}{entry},
               { 'Inf' => [ 0 ], },
               "$version : 1 entry and 0 skipped headword (index)" );
    warning_is
        { $utx->unshift([qw(Infinity tgt1 src:pos1 foo1 bar1)]) }
        undef
    ;
    is_deeply( $utx->{body}{entries},
               [ { is_comment => q{},
                   columns    => [qw(Infinity tgt1 src:pos1 foo1 bar1)] },
                 { is_comment => q{},
                   columns    => [qw(Inf      tgt0 src:pos0 foo0 bar0)] } ],
               "$version : 1 entry and 0 skipped headword (value)" );
    is_deeply( $utx->{body}{entry},
               { 'Inf'      => [ 1 ],
                 'Infinity' => [ 0 ], },
               "$version : 1 entry and 0 skipped headword (index)" );
}
