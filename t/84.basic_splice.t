# splice structure, object

use strict;
use warnings;
# use utf8;
use lib 't/lib';

use Test::More tests => 174;
# use Test::Exception;
use Test::Warn;
use Test::Text_UTX_Simple;

use Text::UTX::Simple;


# ================================================================
# subroutine for test
# [ 4+3+2+3+3+3+6+6+9+10+9 = 58 tests ]
# ----------------------------------------------------------------
sub test_manipulate {
    my $test_case = shift;

    my $version = $test_case->{version};

    # --------------------------------
    # splice as push
    # [ 4 tests ]
    # --------------------------------
    my $splice = Text::UTX::Simple->new();
    my $push   = $splice->clone();

    is(        $splice->splice( $splice->get_number_of_entries,
                         0,
                         [ [qw(src0 tgt0 src:pos0 foo0 bar0)],
                           [qw(src1 tgt1 src:pos1 foo1 bar1)], ] ),
               undef,
               $test_case->{name}
                    . ' : undef + splice 0,0,0 1 = removed undef' );
    $push->push( [ [qw(src0 tgt0 src:pos0 foo0 bar0)],
                   [qw(src1 tgt1 src:pos1 foo1 bar1)], ] );
    is_deeply( $splice->dump_body({array_ref => 1}),
               $push  ->dump_body({array_ref => 1}),
               $test_case->{name}
                    . ' : undef + splice 0,0,0 1 '
                    . ' = undef + push 0 1 (rest 0 1)' );

    is(        $splice->splice(
                    $splice->get_number_of_entries,
                    0,
                    [ [qw(src2 tgt2 src:pos2 foo2 bar2)] ],
                    [ [qw(src3 tgt3 src:pos3 foo3 bar3)] ]
               ),
               undef,
               $test_case->{name}
                    . ' : 0 1 + splice 0,0,2 3 = removed undef' );
    $push->push( [ [qw(src2 tgt2 src:pos2 foo2 bar2)] ],
                 [ [qw(src3 tgt3 src:pos3 foo3 bar3)] ] );
    is_deeply( $splice->dump_body({array_ref => 1}),
               $push  ->dump_body({array_ref => 1}),
               $test_case->{name}
                    . ' : 0 1 + splice 0,0,2 3 '
                    . '= 0 1 + push 2 3 (rest 0 1 2 3)' );


    # --------------------------------
    # splice as unshift
    # [ 3 tests ]
    # --------------------------------
    my $unshift = $splice->clone();

    is(        $splice->splice(
                    0,
                    0,
                    [ [qw(src4 tgt4 src:pos4 foo4 bar4)],
                      [qw(src5 tgt5 src:pos5 foo5 bar5)], ]
               ),
               undef,
               $test_case->{name}
                    . ' : 0 1 2 3+ splice 0,0,4 5 = removed undef' );
    $unshift->unshift( [ [qw(src4 tgt4 src:pos4 foo4 bar4)],
                         [qw(src5 tgt5 src:pos5 foo5 bar5)], ] );
    is_deeply( $splice ->dump_body({array_ref => 1}),
               $unshift->dump_body({array_ref => 1}),
               $test_case->{name}
                    . ' : 0 1 2 3 + splice 0,0,4 5'
                    . ' = 0 1 2 3 + unshift 4 5 (rest 4 5 0 1 2 3)' );
    is_deeply( $splice->dump_body({array_ref => 1}),
               [ [qw(src4 tgt4 src:pos4 foo4 bar4)],
                 [qw(src5 tgt5 src:pos5 foo5 bar5)],
                 [qw(src0 tgt0 src:pos0 foo0 bar0)],
                 [qw(src1 tgt1 src:pos1 foo1 bar1)],
                 [qw(src2 tgt2 src:pos2 foo2 bar2)],
                 [qw(src3 tgt3 src:pos3 foo3 bar3)], ],
               $test_case->{name}
                    . ' : 0 1 2 3 + splice 0,0,4 5 '
                    . ' = rest 4 5 0 1 2 3' );


    # --------------------------------
    # append new entries to middle of old entries
    # [ 2 tests ]
    # --------------------------------
    pass(      $splice->splice(
                    1,
                    0,
                    [ [qw(src6 tgt6 src:pos6 foo6 bar6)],
                      [qw(src7 tgt7 src:pos7 foo7 bar7)], ] ) );
    is_deeply( $splice->dump_body({array_ref => 1}),
               [ [qw(src4 tgt4 src:pos4 foo4 bar4)],
                 [qw(src6 tgt6 src:pos6 foo6 bar6)],
                 [qw(src7 tgt7 src:pos7 foo7 bar7)],
                 [qw(src5 tgt5 src:pos5 foo5 bar5)],
                 [qw(src0 tgt0 src:pos0 foo0 bar0)],
                 [qw(src1 tgt1 src:pos1 foo1 bar1)],
                 [qw(src2 tgt2 src:pos2 foo2 bar2)],
                 [qw(src3 tgt3 src:pos3 foo3 bar3)], ],
               $test_case->{name}
                    . ' : 4 5 0 1 2 3 + splice 1,0,6 7'
                    . ' = rest 4 6 7 5 0 1 2 3' );


    # --------------------------------
    # remove entries from middle of old entries
    # [ 3 tests ]
    # --------------------------------
    my $spliced;

    pass(      $spliced = $splice->splice(2, 2) );
    is_deeply( $splice->dump_body({array_ref => 1}),
               [ [qw(src4 tgt4 src:pos4 foo4 bar4)],
                 [qw(src6 tgt6 src:pos6 foo6 bar6)],
                 [qw(src0 tgt0 src:pos0 foo0 bar0)],
                 [qw(src1 tgt1 src:pos1 foo1 bar1)],
                 [qw(src2 tgt2 src:pos2 foo2 bar2)],
                 [qw(src3 tgt3 src:pos3 foo3 bar3)], ],
               $test_case->{name}
                    . ' : 4 6 7 5 0 1 2 3 + splice 2,2'
                    . ' = rest 4 6 0 1 2 3' );
    is_deeply( $spliced->dump_body({array_ref => 1}),
               [ [qw(src7 tgt7 src:pos7 foo7 bar7)],
                 [qw(src5 tgt5 src:pos5 foo5 bar5)], ],
               $test_case->{name}
                    . ' : 4 6 7 5 0 1 2 3 + splice 2,2'
                    . ' = removed 7 5' );


    # --------------------------------
    # splice as pop
    # [ 3 tests ]
    # --------------------------------
    my $pop = $splice->clone();

    pass(      $spliced = $splice->splice(-1, 1) );
    my $popped = $pop->pop();
    is_deeply( $splice->dump_body({array_ref => 1}),
               $pop   ->dump_body({array_ref => 1}),
               $test_case->{name}
                    . ' : 2 4 0 1 + splice -1,1'
                    . ' = 2 4 0 1 + pop (rest 2 4 0)' );

    is_deeply( $spliced->dump_body({array_ref => 1}),
               $popped ->dump_body({array_ref => 1}),
               $test_case->{name}
                    . ' : 2 4 0 1 + splice 3,1'
                    . ' = 2 4 0 1 + pop (removed 1)' );


    # --------------------------------
    # splice as shift
    # [ 3 tests ]
    # --------------------------------
    my $shift = $splice->clone();

    pass(      $spliced = $splice->splice(0, 1) );
    my $shifted = $shift->shift();
    is_deeply( $splice->dump_body({array_ref => 1}),
               $shift ->dump_body({array_ref => 1}),
               $test_case->{name}
                    . ' : 0 4 3 + splice 0,1'
                    . ' = 0 4 3 + pop (rest 4 3)' );
    is_deeply( $spliced->dump_body({array_ref => 1}),
               $shifted->dump_body({array_ref => 1}),
               $test_case->{name}
                    . ' : 0 4 3 + splice 0,1'
                    . ' = 0 4 3 + pop (removed 0)' );


    # --------------------------------
    # remove all entries
    # [ 6 tests ]
    # --------------------------------
    my $before_remove = $splice->clone();   # 0 4 3

    pass(      $spliced = $splice->splice(0) );
    is(        $splice->dump_body({array_ref => 1}),
               undef,
               $test_case->{name}
                    . ' : 0 4 3 + splice 0, undef'
                    . ' = rest undef' );
    is_deeply( $spliced      ->dump_body({array_ref => 1}),
               $before_remove->dump_body({array_ref => 1}),
               $test_case->{name}
                    . ' : 0 4 3 + splice 0, undef'
                    . ' = removed 0 4 3' );

    $splice = $spliced->clone();
    warning_is
        { $spliced = $splice->splice() }
        undef,
        $test_case->{name} . ' : splice() has no argument'
    ;
    is(        $splice->dump_body({array_ref => 1}),
               undef,
               $test_case->{name}
                    . ' : 0 4 3 + splice 0, undef'
                    . ' = rest undef' );
    is_deeply( $spliced      ->dump_body({array_ref => 1}),
               $before_remove->dump_body({array_ref => 1}),
               $test_case->{name}
                    . ' : 0 4 3 + splice 0, undef'
                    . ' = removed 0 4 3' );


    # --------------------------------
    # offset beyond the scope
    # [ 6 tests ]
    # --------------------------------
    $splice->push([ [qw(src0 tgt0 src:pos0 foo0 bar0)],
                    [qw(src1 tgt1 src:pos1 foo1 bar1)], ] );

    warning_is
        { $spliced = $splice->splice(3) }
        { carped => q{Can't splice entries: }
                  . q{offset past end of array} },
        $test_case->{name} . ' : offset beyond the scope(plus)'
    ;
    is_deeply( $splice->dump_body({array_ref => 1}),
               [ [qw(src0 tgt0 src:pos0 foo0 bar0)],
                 [qw(src1 tgt1 src:pos1 foo1 bar1)], ],
               $test_case->{name}
                    . ' : 0 1 + splice 3 = rest 0 1' );
    is(        $spliced,
               undef,
               $test_case->{name}
                    . ' : 0 1 + splice 3 = removed undef' );

    warning_is
        { $spliced = $splice->splice(-3) }
        { carped => q{Can't splice entries: }
                  . q{modification of non-creatable array value attempted} },
        $test_case->{name} . ' : offset beyond the scope(minus)'
    ;
    is_deeply( $splice->dump_body({array_ref => 1}),
               [ [qw(src0 tgt0 src:pos0 foo0 bar0)],
                 [qw(src1 tgt1 src:pos1 foo1 bar1)], ],
               $test_case->{name}
                    . ' : 0 1 + splice -3 = rest 0 1' );
    is(        $spliced,
               undef,
               $test_case->{name}
                    . ' : 0 1 + splice -3 = removed undef' );


    # --------------------------------
    # length beyond the scope
    # [ 9 tests ]
    # --------------------------------

    warning_is
        { $spliced = $splice->splice(2, 2) }
        undef,
        $test_case->{name} . " : don't indicate warning"
    ;

    is_deeply( $splice->dump_body({array_ref => 1}),
               [ [qw(src0 tgt0 src:pos0 foo0 bar0)],
                 [qw(src1 tgt1 src:pos1 foo1 bar1)], ],
               $test_case->{name}
                    . ' : 0 1 + splice 3,0 = rest 0 1' );
    is(        $spliced,
               undef,
               $test_case->{name}
                    . ' : 0 1 + splice 3,0 = removed undef' );

    warning_is
        { $spliced = $splice->splice(1, 2) }
        undef,
        $test_case->{name} . " : don't indicate warning"
    ;
    is_deeply( $splice->dump_body({array_ref => 1}),
               [ [qw(src0 tgt0 src:pos0 foo0 bar0)], ],
               $test_case->{name}
                    . ' : 0 1 + splice 3,0 = rest 0' );
    is_deeply( $spliced->dump_body({array_ref => 1}),
               [ [qw(src1 tgt1 src:pos1 foo1 bar1)], ],
               $test_case->{name}
                    . ' : 0 1 + splice 3,0 = removed 1' );

    warning_is
        { $spliced = $splice->splice(1, -1) }
        undef,
        $test_case->{name} . " : don't indicate warning"
    ;
    is_deeply( $splice->dump_body({array_ref => 1}),
               [ [qw(src0 tgt0 src:pos0 foo0 bar0)], ],
               $test_case->{name}
                    . ' : 0 + splice 1,-1 = rest 0' );
    is(        $spliced,
               undef,
               $test_case->{name}
                    . ' : 0 + splice 1,-1 = removed undef' );


    # --------------------------------
    # character to splice()'s arguments #1, #2
    # [ 5*2=10 tests ]
    # --------------------------------
    warning_is
        { $spliced = $splice->splice('foo') }
        { carped => q{Can't splice entries: }
                  . q{argument offset (foo) isn't numeric} },
        $test_case->{name} . ' : character to offset'
    ;
    warning_is
        { $spliced = $splice->splice('Infinity') }
        { carped => q{Can't splice entries: }
                  . q{argument offset (Infinity) isn't numeric} },
        $test_case->{name} . ' : character to offset'
    ;
    warning_is
        { $spliced = $splice->splice('Inf') }
        { carped => q{Can't splice entries: }
                  . q{argument offset (Inf) isn't numeric} },
        $test_case->{name} . ' : character to offset'
    ;
    is_deeply( $splice->dump_body({array_ref => 1}),
               [ [qw(src0 tgt0 src:pos0 foo0 bar0)], ],
               $test_case->{name} . ' : 0 + splice foo = rest 0' );
    is(        $spliced,
               undef,
               $test_case->{name} . ' : 0 + splice foo = removed undef' );

    warning_is
        { $spliced = $splice->splice(0, 'bar') }
        { carped => q{Can't splice entries: }
                  . q{argument length (bar) isn't numeric} },
        $test_case->{name} . ' : character to length'
    ;
    warning_is
        { $spliced = $splice->splice(0, 'Infinity') }
        { carped => q{Can't splice entries: }
                  . q{argument length (Infinity) isn't numeric} },
        $test_case->{name} . ' : character to length'
    ;
    warning_is
        { $spliced = $splice->splice(0, 'Inf') }
        { carped => q{Can't splice entries: }
                  . q{argument length (Inf) isn't numeric} },
        $test_case->{name} . ' : character to length'
    ;
    is_deeply( $splice->dump_body({array_ref => 1}),
               [ [qw(src0 tgt0 src:pos0 foo0 bar0)], ],
               $test_case->{name} . ' : 0 + splice 0,bar = rest 0' );
    is(        $spliced,
               undef,
               $test_case->{name} . ' : 0 + splice 0,bar = removed undef' );


    # --------------------------------
    # overdose splice
    # [ 3*3=9 tests ]
    # --------------------------------
    $splice->clear();
    pass(      $spliced = $splice->splice(0) );
    is(        $splice->dump_body({array_ref => 1}),
               undef,
               $test_case->{name}
                    . ' : undef + splice 0, undef(overdose) = rest undef' );
    is(        $spliced,
               undef,
               $test_case->{name}
                    . ' : undef + splice 0, undef(overdose) = removed undef' );

    pass(      $spliced = $splice->splice($splice->get_number_of_entries()) );
    is(        $splice->dump_body({array_ref => 1}),
               undef,
               $test_case->{name}
                    . ' : undef + splice 0, undef(overdose) = rest undef' );
    is(        $spliced,
               undef,
               $test_case->{name}
                    . ' : undef + splice 0, undef(overdose) = removed undef' );

    pass(      $spliced = $splice->splice($splice->get_number_of_entries()) );
    is(        $splice->dump_body({array_ref => 1}),
               undef,
               $test_case->{name}
                    . ' : undef + splice 0, undef(overdose) = rest undef' );
    is(        $spliced,
               undef,
               $test_case->{name}
                    . ' : undef + splice 0, undef(overdose) = removed undef' );

    return;
}


# ================================================================
# manipulate
# [ 58subtests * 3versions = 174 tests ]
# ----------------------------------------------------------------
foreach my $version (@Versions) {
    my %version_definition = ( version => $version );

    test_manipulate({
        name    => "normal : write, version $version",
        version => $version,
    });
}
