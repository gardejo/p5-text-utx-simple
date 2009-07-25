# convert entry hash into entry array

use strict;
use warnings;
# use utf8;
use lib 't/lib';

use Test::More tests => 30;
use Test::Exception;
# use Test::Warn;
use Test::Text_UTX_Simple;

use Text::UTX::Simple;


# ================================================================
# subroutine for test
# [ 4 + 1 = 5 tests ]
# ----------------------------------------------------------------
sub test_convert {
    my $test_case = shift;

    my $utx;

    $utx = Text::UTX::Simple->new($test_case->{query}{new}{has_no_column});
    is_deeply( $utx->hash_to_array({
                $Regularized{$test_case->{version}}{'src'}     => 'src0',
               }),
               ['src0'],
               $test_case->{name} . ' : 1 column' );
    is_deeply( $utx->hash_to_array({
                $Regularized{$test_case->{version}}{'src'}     => 'src0',
                $Regularized{$test_case->{version}}{'tgt'}     => 'tgt0',
                $Regularized{$test_case->{version}}{'src:pos'} => 'pos0',
               }),
               ['src0', 'tgt0', 'pos0'],
               $test_case->{name} . ' : 3 columns' );
    is_deeply( $utx->hash_to_array({
                $Regularized{$test_case->{version}}{'src'}     => 'src0',
                $Regularized{$test_case->{version}}{'src:pos'} => 'pos0',
               }),
               ['src0', undef, 'pos0'],
               $test_case->{name} . ' : implicit undef' );
    is_deeply( $utx->hash_to_array({
                $Regularized{$test_case->{version}}{'src'}     => 'src0',
                $Regularized{$test_case->{version}}{'tgt'}     => undef,
                $Regularized{$test_case->{version}}{'src:pos'} => 'pos0',
               }),
               ['src0', undef, 'pos0'],
               $test_case->{name} . ' : explicit undef' );

    $utx = Text::UTX::Simple->new($test_case->{query}{new}{has_column});
    is_deeply( $utx->hash_to_array({
                $Regularized{$test_case->{version}}{'src'}     => 'src0',
                $Regularized{$test_case->{version}}{'tgt'}     => undef,
                $Regularized{$test_case->{version}}{'src:pos'} => undef,
                $Regularized{$test_case->{version}}{'src:foo'} => 'foo0',
               }),
               ['src0', undef, undef, 'foo0'],
               $test_case->{name} . ' : user defined column (offset 3)' );
}


# ================================================================
# convert
# [ 15 + 15 = 30 tests ]
# ----------------------------------------------------------------
foreach my $version (@Versions) {
    my %version_definition = ( version => $version );

    # 5subtests * 1kind * 3versions = 15 tests
    test_convert({
        name    => "version $version",
        version => $version,
        query   => {
            new => {
                has_no_column => {
                    %version_definition,
                    text => $Query{header}{$version}{'en/ja'}{has_no_column},
                },
                has_column => {
                    %version_definition,
                    text => $Query{header}{$version}{'en/ja'}{has_column},
                },
            },
        },
    });

    # 1 * 5kinds * 3versions = 15 tests
    my $utx = Text::UTX::Simple->new(\%version_definition);
    throws_ok(
        sub { $utx->hash_to_array({
            $Regularized{$version}{'tgt'} => 'tgt42',
            $Regularized{$version}{'src'} => 'src42',
            amazing_absentee_column_name  => 'blah42',
        }) },
        qr{Can't convert entry hash into entry array: column name \(amazing_absentee_column_name\) isn't defined on header},
        "exception: unexists in HASH, $version"
    );
    throws_ok(
        sub { $utx->hash_to_array() },
        qr{Can't convert entry hash into entry array: entry hash isn't defined},
        'exception: undef'
    );
    throws_ok(
        sub { $utx->hash_to_array(
                $Regularized{$version}{'src'}     => 'src0',
                $Regularized{$version}{'src:pos'} => 'pos0',
        ) },
        qr{Can't convert entry hash into entry array: attempt to use LIST as names \(you should use an ARRAY reference\)},
        "exception: LIST, $version"
    );
    throws_ok(
        sub { $utx->hash_to_array('foo') },
        qr{Can't convert entry hash into entry array: type of entry hash \(foo\) isn't a HASH reference},
        "exception: SCALAR, $version"
    );
    throws_ok(
        sub { $utx->hash_to_array(['blah', 42]) },
        qr{Can't convert entry hash into entry array: type of entry hash \(.+?\) isn't a HASH reference},
        "exception: ARRAY reference, $version"
    );
}
