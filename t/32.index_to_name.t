# convert column index into column name

use strict;
use warnings;
# use utf8;
use lib 't/lib';

use Test::More tests => 78;
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
# ----------------------------------------------------------------
sub test_convert { # [ 26 tests ]
    my $test_case = shift;

    my $version = $test_case->{version};

    # scalar (7)
    is(        $utx{$version}{has_no_column}
                ->index_to_name(0),
               $Regularized{$version}{$Name_Of{0}},
               $test_case->{name} . ': src' );
    is(        $utx{$version}{has_no_column}
                ->index_to_name(1),
               $Regularized{$version}{$Name_Of{1}},
               $test_case->{name} . ': tgt' );
    is(        $utx{$version}{has_no_column}
                ->index_to_name(2),
               $Regularized{$version}{$Name_Of{2}},
               $test_case->{name} . ': src:pos' );

    is(        $utx{$version}{has_column}
                ->index_to_name(3),
               $Regularized{$version}{$Name_Of{3}},
               $test_case->{name} . ': src:foo' );
    is(        $utx{$version}{has_column}
                ->index_to_name(4),
               $Regularized{$version}{$Name_Of{4}},
               $test_case->{name} . ': tgt:bar' );
    is(        $utx{$version}{has_no_column}
                ->index_to_name(-1),
               $Regularized{$version}{$Name_Of{2}},
               $test_case->{name} . ': src:pos (reverse)' );
    is(        $utx{$version}{has_no_column}
                ->index_to_name(3),
               '3(UNDEFINED)',
               $test_case->{name} . ': 3/excess' );

    # array (4)
    is_deeply( $utx{$version}{has_no_column}
                ->index_to_name([]),
               [],
               $test_case->{name} . ': empty ARRAY reference' );
    is_deeply( $utx{$version}{has_no_column}
                ->index_to_name([0]),
               [$Regularized{$version}{$Name_Of{0}}],
               $test_case->{name} . ': src' );
    is_deeply( $utx{$version}{has_no_column}
                ->index_to_name([2, -2]),
               [ $Regularized{$version}{$Name_Of{2}},
                 $Regularized{$version}{$Name_Of{1}}, ],
               $test_case->{name} . ': pos and tgt(reverse)' );
    is_deeply( $utx{$version}{has_no_column}
                ->index_to_name([0, 3]),
               [ $Regularized{$version}{$Name_Of{0}},
                 '3(UNDEFINED)', ],
               $test_case->{name} . ': src and 3/excess' );

    # exception/type (2)
    throws_ok(
        sub { $utx{$version}{has_no_column}->index_to_name(1, 3, 5) },
        qr{Can't convert column index into column name: attempt to use LIST as indexes \(you should use an ARRAY reference\)},
        'exception: LIST'
    );
    throws_ok(
        sub { $utx{$version}{has_no_column}->index_to_name({foo => 1}) },
        qr{Can't convert column index into column name: type of column index \(.+?\) isn't valid},
        'exception: HASH reference'
    );

    # exception/scalar: undef (2)
    throws_ok(
        sub { $utx{$version}{has_no_column}->index_to_name() },
        qr{Can't convert column index into column name: column index isn't defined},
        'exception: SCALAR is not a number'
    );
    throws_ok(
        sub { $utx{$version}{has_no_column}->index_to_name(undef) },
        qr{Can't convert column index into column name: column index isn't defined},
        'exception: SCALAR is not a number'
    );

    # exception/scalar: string (3)
    throws_ok(
        sub { $utx{$version}{has_no_column}->index_to_name('blah42') },
        qr{Can't convert column index into column name: column index \(blah42\) isn't number},
        'exception: SCALAR is not a number'
    );
    throws_ok(
        sub { $utx{$version}{has_no_column}->index_to_name('Inf') },
        qr{Can't convert column index into column name: column index \(Inf\) isn't number},
        'exception: SCALAR is not a number'
    );
    throws_ok(
        sub { $utx{$version}{has_no_column}->index_to_name('Infinity') },
        qr{Can't convert column index into column name: column index \(Infinity\) isn't number},
        'exception: SCALAR is not a number'
    );

    # exception/scalar: past end of array (1)
    throws_ok(
        sub { $utx{$version}{has_no_column}->index_to_name(-5) },
        qr{Can't convert column index into column name: column index \(-5\) past end of array},
        'exception: -5'
    );

    # exception/scalar: excess column (1)
    Text::UTX::Simple->is_defined_column_only(1);
    throws_ok(
        sub { $utx{$version}{has_no_column}->index_to_name(3) },
        qr{Can't convert column index into column name: column index \(3\) isn't defined on header},
        'exception: 3(excess) under is_defined_column_only(1)'
    );
    Text::UTX::Simple->is_defined_column_only(0);

    # exception/array: undef (1)
    throws_ok(
        sub { $utx{$version}{has_no_column}
                ->index_to_name([undef]) },
        qr{Can't convert column index into column name: column index at argument's offset \(0\) isn't defined},
        'exception: ARRAY element is not a number'
    );

    # exception/array: string (3)
    throws_ok(
        sub { $utx{$version}{has_no_column}
                ->index_to_name([0, 'blah42']) },
        qr{Can't convert column index into column name: column index \(blah42\) isn't number},
        'exception: ARRAY element is not a number'
    );
    throws_ok(
        sub { $utx{$version}{has_no_column}
                ->index_to_name([0, 'Inf']) },
        qr{Can't convert column index into column name: column index \(Inf\) isn't number},
        'exception: ARRAY element is not a number'
    );
    throws_ok(
        sub { $utx{$version}{has_no_column}
                ->index_to_name([0, 'Infinity']) },
        qr{Can't convert column index into column name: column index \(Infinity\) isn't number},
        'exception: ARRAY element is not a number'
    );

    # exception/array: past end of array (1)
    throws_ok(
        sub { $utx{$version}{has_no_column}
                ->index_to_name([0, -5]) },
        qr{Can't convert column index into column name: column index \(-5\) past end of array},
        'exception: -5'
    );

    # exception/array: excess column (1)
    Text::UTX::Simple->is_defined_column_only(1);
    throws_ok(
        sub { $utx{$version}{has_no_column}
                ->index_to_name([3]) },
        qr{Can't convert column index into column name: column index \(3\) isn't defined on header},
        'exception: 3(excess) under is_defined_column_only(1)'
    );
    Text::UTX::Simple->is_defined_column_only(0);

    return;
}


# ================================================================
# normal: NUM(SCALAR) into STR(SCALAR)
# [ 26subtests * 3versions = 78 tests ]
# ----------------------------------------------------------------
foreach my $version (@Versions) {
    test_convert({
        name    => "convert, $version",
        version => $version,
    });
}
