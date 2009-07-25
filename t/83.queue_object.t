# queue object

use strict;
use warnings;
# use utf8;
use lib 't/lib';

use Test::More tests => 78;
use Test::Exception;
# use Test::Warn;
use Test::Text_UTX_Simple;
use Text::UTX::Simple::Inherited;

use Text::UTX::Simple;

# ================================================================
# subroutine for test
# [ 17+8+1 = 26 tests ]
# ----------------------------------------------------------------
sub test_manipulate {
    my $test_case = shift;

    my $version = $test_case->{version};

    my ( $original_default,          $original_special,
         $clone_default,             $clone_special,
         $original_default_removed,  $original_special_removed,
         $inherited_default,         $inherited_special,
         $inherited_default_removed, $inherited_special_removed, );

    # --------------------------------
    # default column vs. default column
    # [ 17 tests ]
    # --------------------------------
    $original_default  = Text::UTX::Simple->new({
        version => $version,
        text    => $Query{header}{$version}{'en-US/ja-JP'}{has_no_column},
    });
    $clone_default     = $original_default->clone();
    $inherited_default = Text::UTX::Simple::Inherited->new({
        version => $version,
        text    => $Query{header}{$version}{'en-US/ja-JP'}{has_no_column},
    });

    # (already tested at 81.stack_object.t)
    ok(        $original_default->is_same_format_as($clone_default),
               $test_case->{name}
                    . ' : original default vs. clone default: ok' );
    ok(        $original_default->is_same_format_as($inherited_default),
               $test_case->{name}
                    . ' : original default vs. inhrited default: ok' );

    $original_default ->unshift( [ [qw(src0 tgt0 src:pos0 foo0 bar0)],
                                   [qw(src1 tgt1 src:pos1 foo1 bar1)],
                                   [qw(src2 tgt2 src:pos2 foo2 bar2)], ], );
    $inherited_default->unshift( [ [qw(src0 tgt0 src:pos0 foo0 bar0)],
                                   [qw(src1 tgt1 src:pos1 foo1 bar1)],
                                   [qw(src2 tgt2 src:pos2 foo2 bar2)], ], );
    $original_default_removed  = $original_default ->shift(); # od 0 / od 1 2
    $inherited_default_removed = $inherited_default->shift(); # id 0 / id 1 2

    is(        $original_default->unshift($original_default_removed),
               3,
               $test_case->{name}
                    . ' : od 1 2 + unshift od 0 = od 0 1 2 (length 3)' );
    is_deeply( $original_default->dump_body({array_ref => 1}),
               [ [qw(src0 tgt0 src:pos0 foo0 bar0)],
                 [qw(src1 tgt1 src:pos1 foo1 bar1)],
                 [qw(src2 tgt2 src:pos2 foo2 bar2)], ],
               $test_case->{name}
                    . ' : od 1 2 + unshift od 0 = od 0 1 2' );
    throws_ok(
        sub { $original_default->unshift($inherited_default_removed) },
        qr{Can't parse an entry: argument's class \(Text::UTX::Simple::Inherited\) differs from original's class \(Text::UTX::Simple\)},
        $test_case->{name} . ' : od 0 1 2 + unshift id2 = croak'
    );

    is(        $original_default->unshift
                    ($original_default_removed, $original_default_removed),
               5,
               $test_case->{name}
                    . ' : od 0 1 2 + unshift od 2 2 = od 2 2 0 1 2'
                    . '(length 5)' );
    is_deeply( $original_default->dump_body({array_ref => 1}),
               [ [qw(src0 tgt0 src:pos0 foo0 bar0)],
                 [qw(src0 tgt0 src:pos0 foo0 bar0)],
                 [qw(src0 tgt0 src:pos0 foo0 bar0)],
                 [qw(src1 tgt1 src:pos1 foo1 bar1)],
                 [qw(src2 tgt2 src:pos2 foo2 bar2)], ],
               'od 0 1 2 + unshift od 2 2 = od 0 0 0 1 2' );
    throws_ok(
        sub { $original_default->unshift
                ($inherited_default_removed, $inherited_default_removed) },
        qr{Can't parse an entry: argument's class \(Text::UTX::Simple::Inherited\) differs from original's class \(Text::UTX::Simple\)},
        $test_case->{name} . ' : od 0 0 0 1 2 + unshift id0 0 = croak'
    );

    $original_default->clear();
    is(        $original_default->unshift
                    ([$original_default_removed, $original_default_removed]),
               2,
               $test_case->{name}
                    . ' : od undef + unshift od 0 0 = od 0 0 (length 2)' );
    is_deeply( $original_default->dump_body({array_ref => 1}),
               [ [qw(src0 tgt0 src:pos0 foo0 bar0)],
                 [qw(src0 tgt0 src:pos0 foo0 bar0)], ],
               $test_case->{name}
                    . ' : od undef + unshift od 0 0 = od 0 0' );
    $original_default->clear();
    is(        $original_default->unshift
                    ([$original_default_removed], [$original_default_removed]),
               2,
               $test_case->{name}
                    . ' : od undef + unshift od 0 0 = od 0 0 (length 2)' );
    is_deeply( $original_default->dump_body({array_ref => 1}),
               [ [qw(src0 tgt0 src:pos0 foo0 bar0)],
                 [qw(src0 tgt0 src:pos0 foo0 bar0)], ],
               $test_case->{name} . ' : od undef + unshift od 0 0 = od 0 0' );
    $original_default->clear();
    is(        $original_default->unshift([
                    [$original_default_removed],
                    [$original_default_removed, $original_default_removed]
               ]),
               3,
               $test_case->{name}
                    . ' : od undef + unshift od 0 0 0 = od 0 0 0 (length 3)' );
    is_deeply( $original_default->dump_body({array_ref => 1}),
               [ [qw(src0 tgt0 src:pos0 foo0 bar0)],
                 [qw(src0 tgt0 src:pos0 foo0 bar0)],
                 [qw(src0 tgt0 src:pos0 foo0 bar0)], ],
               'od undef + unshift od 0 0 0 = od 0 0 0' );

    throws_ok(
        sub { $original_default->unshift([
                $inherited_default_removed,
                $inherited_default_removed
        ]) },
        qr{Can't parse an entry: argument's class \(Text::UTX::Simple::Inherited\) differs from original's class \(Text::UTX::Simple\)},
        $test_case->{name} . ' : od 0 0 0 + unshift id 0 0 = croak'
    );
    throws_ok(
        sub { $original_default->unshift(
                [$inherited_default_removed],
                [$inherited_default_removed]
        ) },
        qr{Can't parse an entry: argument's class \(Text::UTX::Simple::Inherited\) differs from original's class \(Text::UTX::Simple\)},
        $test_case->{name} . ' : od 0 0 0 + unshift id 0 0 = croak'
    );
    throws_ok(
        sub { $original_default->unshift([
            [$inherited_default_removed],
            [$inherited_default_removed, $inherited_default_removed]
        ]) },
        qr{Can't parse an entry: argument's class \(Text::UTX::Simple::Inherited\) differs from original's class \(Text::UTX::Simple\)},
        $test_case->{name} . ' : od 0 0 0 + unshift id 0 0 = croak'
    );


    # --------------------------------
    # default column vs. special column
    # [ 8 tests ]
    # --------------------------------
    $original_special  = Text::UTX::Simple->new({
        version => $version,
        text    => $Query{header}{$version}{'en-US/ja-JP'}{has_column},
    });
    $clone_special     = $original_special->clone();
    $inherited_special = Text::UTX::Simple::Inherited->new({
        version => $version,
        text    => $Query{header}{$version}{'en-US/ja-JP'}{has_column},
    });

    ok(        $original_special->is_same_format_as($clone_special),
               $test_case->{name}
                    . ' : original special vs. clone special: ok' );
    ok(        $original_special->is_same_format_as($inherited_special),
               $test_case->{name}
                    . ' : original special vs. inhrited special: ok' );
    ok(        ! $original_special->is_same_format_as($original_default),
               $test_case->{name}
                    . ' : original special vs. original default: not ok' );
    ok(        ! $original_default->is_same_format_as($original_special),
               $test_case->{name}
                    . ' : original default vs. original special: not ok' );

    $original_special ->unshift( [ [qw(src0 tgt0 src:pos0 foo0 bar0)],
                                   [qw(src1 tgt1 src:pos1 foo1 bar1)],
                                   [qw(src2 tgt2 src:pos2 foo2 bar2)], ], );
    $inherited_special->unshift( [ [qw(src0 tgt0 src:pos0 foo0 bar0)],
                                   [qw(src1 tgt1 src:pos1 foo1 bar1)],
                                   [qw(src2 tgt2 src:pos2 foo2 bar2)], ], );
    $original_special_removed  = $original_special ->shift(); # os 0 / os 1 2
    $inherited_special_removed = $inherited_special->shift(); # is 0 / is 1 2

    is(        $original_special->unshift($original_special_removed),
               3,
               $test_case->{name}
                    . ' : os 1 2 + unshift os 0 = os 0 1 2 (length 3)' );
    is_deeply( $original_special->dump_body({array_ref => 1}),
               [ [qw(src0 tgt0 src:pos0 foo0 bar0)],
                 [qw(src1 tgt1 src:pos1 foo1 bar1)],
                 [qw(src2 tgt2 src:pos2 foo2 bar2)], ],
               $test_case->{name}
                    . ' : os 1 2 + unshift os 0 = os 0 1 2' );
    throws_ok(
        sub { $original_special->unshift($inherited_special_removed) },
        qr{Can't parse an entry: argument's class \(Text::UTX::Simple::Inherited\) differs from original's class \(Text::UTX::Simple\)},
        $test_case->{name} . ' : os 1 2 + unshift is 0 = croak'
    );
    my $basic_columns_string
        = join q{, }, @{ $Query{column}{$version}{array}{basic} };
    my $all_columns_string
        = join q{, }, @{ $Query{column}{$version}{array}{all}   };
    throws_ok(
        sub { $original_default->unshift($original_special_removed) },
        qr{Can't splice entries: argument's columns \($all_columns_string\) differ from original's columns \($basic_columns_string\)},
        $test_case->{name} . ' : od 0 1 2 + unshift os 0 = croak'
    );

    # --------------------------------
    # alternative specification, version, columns
    # [ 1 test ]
    # --------------------------------
    my $alternative_specification = $original_default->clone();
    # monomania: specification
    $alternative_specification->{header}{specification} = 'BLAH BLAH BLAH';
    ok(        ! $alternative_specification->is_same_format_as
                                                ($original_default),
               $test_case->{name}
                . ' : alternative specification vs. original default: not ok' );

    return;
}


# ================================================================
# manipulate
# [ 26subtests * 3versions = 78 tests ]
# ----------------------------------------------------------------
foreach my $version (@Versions) {
    my %version_definition = ( version => $version );

    test_manipulate({
        name    => "normal : write, version $version",
        version => $version,
    });
}
