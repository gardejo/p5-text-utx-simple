# convert entry array into entry hash

use strict;
use warnings;
# use utf8;
use lib 't/lib';

use Test::More tests => 27;
use Test::Exception;
# use Test::Warn;
use Test::Text_UTX_Simple;

use Text::UTX::Simple;


# ================================================================
# subroutine for test
# [ 1 test / 3 + 2 = 5 tests ]
# ----------------------------------------------------------------
sub test_convert {
    my $test_case = shift;

    my $utx;

    if ($test_case->{exception}) {
        $utx = Text::UTX::Simple->new($test_case->{query}{new});
        throws_ok( sub { $utx->array_to_hash($test_case->{query}{convert}) },
                   qr{$test_case->{result}},
                   $test_case->{name} );
        return;
    }

    $utx = Text::UTX::Simple->new($test_case->{query}{new}{has_no_column});
    is_deeply( $utx->array_to_hash([qw(src0)]),
               { $Regularized{$test_case->{version}}{'src'}     => 'src0', },
               $test_case->{name} . ' : basic(0)' );
    is_deeply( $utx->array_to_hash([qw(src0 tgt0 pos0)]),
               { $Regularized{$test_case->{version}}{'src'}     => 'src0',
                 $Regularized{$test_case->{version}}{'tgt'}     => 'tgt0',
                 $Regularized{$test_case->{version}}{'src:pos'} => 'pos0', },
               $test_case->{name} . ' : basic(0 1 2)' );
    is_deeply( $utx->array_to_hash(['src0', undef, 'pos0']),
               { $Regularized{$test_case->{version}}{'src'}     => 'src0',
                 $Regularized{$test_case->{version}}{'tgt'}     => undef,
                 $Regularized{$test_case->{version}}{'src:pos'} => 'pos0', },
               $test_case->{name} . ' : basic(0 1(undef) 2)' );

    $utx = Text::UTX::Simple->new($test_case->{query}{new}{has_column});
    if ($utx->get_version() < 0.91) {
        is_deeply(
            $utx->array_to_hash([qw(src0 tgt0 pos0 foo0 bar0 comment0)]),
            { $Regularized{$test_case->{version}}{'src'}     => 'src0',
              $Regularized{$test_case->{version}}{'tgt'}     => 'tgt0',
              $Regularized{$test_case->{version}}{'src:pos'} => 'pos0',
              $Regularized{$test_case->{version}}{'src:foo'} => 'foo0',
              $Regularized{$test_case->{version}}{'tgt:bar'} => 'bar0',
              '5(UNDEFINED)' => 'comment0', },   # offset past end of array
            $test_case->{name} . ' : basic(0 1 2 3 4 5(undef))'
        );
        $utx->is_defined_column_only(1);
        my $message = q{Can't convert entry array into entry hash: }
                    . q{column index \(5\) isn't defined on header};
        throws_ok(
            sub { $utx->array_to_hash([qw(src0 tgt0 pos0 foo0 bar0 baz0)]) },
            qr{$message},
            'exception: 5(excess) under is_defined_column_only(1)'
        );
        $utx->is_defined_column_only(0);
    }
    else {
        is_deeply(
            $utx->array_to_hash([qw(src0 tgt0 pos0 foo0 bar0 comment0 baz0)]),
            { $Regularized{$test_case->{version}}{'src'}     => 'src0',
              $Regularized{$test_case->{version}}{'tgt'}     => 'tgt0',
              $Regularized{$test_case->{version}}{'src:pos'} => 'pos0',
              $Regularized{$test_case->{version}}{'src:foo'} => 'foo0',
              $Regularized{$test_case->{version}}{'tgt:bar'} => 'bar0',
              $Regularized{$test_case->{version}}{'comment'} => 'comment0',
              '6(UNDEFINED)' => 'baz0', },       # offset past end of array
            $test_case->{name} . ' : basic(0 1 2 3 4 5 6(undef))'
        );
        $utx->is_defined_column_only(1);
        my $message = q{Can't convert entry array into entry hash: }
                    . q{column index \(6\) isn't defined on header};
        throws_ok(
            sub { $utx->array_to_hash
                    ([qw(src0 tgt0 pos0 foo0 bar0 comment0 baz0)]) },
            qr{$message},
            'exception: 6(excess) under is_defined_column_only(1)'
        );
        $utx->is_defined_column_only(0);
    }
}


# ================================================================
# convert
# [ 15 + 9 + 3 = 27 tests ]
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

    # 1subtest * 3kinds * 3versions = 9 tests
    test_convert({
        name      => "exception: undef, $version",
        exception => 1,
        query   => {
            new     => \%version_definition,
            convert => undef,
        },
        result => q{Can't convert entry array into entry hash: }
                . q{entry array isn't define},
    });
    test_convert({
        name      => "exception: SCALAR, $version",
        exception => 1,
        query   => {
            new     => \%version_definition,
            convert => 'foo',
        },
        result => q{Can't convert entry array into entry hash: }
                . q{type of entry array \(foo\) isn't an ARRAY reference},
    });
    test_convert({
        name      => "exception: HASH reference, $version",
        exception => 1,
        query   => {
            new     => \%version_definition,
            convert => {
                foo => 1,
            },
        },
        result => q{Can't convert entry array into entry hash: }
                . q{type of entry array \(HASH.+?\) isn't an ARRAY reference},
    });

    # 1subtest * 1kind * 3versions = 3 tests
    my $utx = Text::UTX::Simple->new(\%version_definition);
    throws_ok(
        sub { $utx->array_to_hash(qw(src0 tgt0 pos0)) },
        qr{Can't convert entry array into entry hash: attempt to use LIST as names \(you should use an ARRAY reference\)},
        "exception: LIST, $version"
    );
}
