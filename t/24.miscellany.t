use strict;
use warnings;
# use utf8;
use lib 't/lib';

use Test::More tests => 122;
use Test::Exception;
# use Test::Warn;
use Test::Text_UTX_Simple;

use Text::UTX::Simple;
use DateTime;
use Tie::IxHash;


# ================================================================
# subroutine for test
# [ 8 tests / 1 test ]
# ----------------------------------------------------------------
sub test_miscellany { # [ 7/7 tests ]
    my $test_case = shift;

    my $utx;

    if ($test_case->{exception}) {
        throws_ok( sub { $utx
                        = Text::UTX::Simple->new($test_case->{query}{new}); },
                   qr{$test_case->{result}},
                   $test_case->{name} );
        return;
    }

    my $test_parse = exists $test_case->{query}{parse};

    if ($test_parse) {
        $utx = Text::UTX::Simple->new($test_case->{query}{new});
        pass( $utx->parse( $test_case->{query}{parse} ) );
    }
    else {
        # note: overwrite, preserve, remove and add are tested at 70.clone.t
        pass( $utx = Text::UTX::Simple->new({
            miscellany => [
                { foo   => 'bar' },
                { baz   => 'qux' },
                { quux  => undef },
                { corge => undef },
            ],
            %{ $test_case->{query}{new} },
        }) );
    }

    if (exists $test_case->{no_result}) {
        is_deeply( [ $utx->{header}{miscellany}->Keys() ],
                   [ ],
                   $test_case->{name} . ': internal/keys' );
        is_deeply( [ $utx->{header}{miscellany}->Values() ],
                   [ ],
                   $test_case->{name} . ': internal/values' );
        is(        $utx->get_miscellany('foo'),
                   undef,
                   $test_case->{name} . ': API, get foo' );
        is(        $utx->get_miscellany('baz'),
                   undef,
                   $test_case->{name} . ': API, get baz' );
        is(        $utx->get_miscellany('foobar'),
                   undef,
                   $test_case->{name} . ': API, get unexists' );
        is_deeply( ( scalar $utx->get_miscellany() ),
                   {  },
                   $test_case->{name} . ': API, get by hashref' );
        is_deeply( { $utx->get_miscellany() },
                   {  },
                   $test_case->{name} . ': API, get by hash' );
        return;
    }

    if (
        ! $test_parse ||
        $test_case->{version} > 0.90
    ) {
        is_deeply( [ $utx->{header}{miscellany}->Keys() ],
                   [ qw(foo baz) ], # quux, corge, grault are not exist
                   $test_case->{name} . ': internal/keys' );
        is_deeply( [ $utx->{header}{miscellany}->Values() ],
                   [ qw(bar qux) ],
                   $test_case->{name} . ': internal/values' );
        is(        $utx->get_miscellany('foo'),
                   'bar',
                   $test_case->{name} . ': API, get foo' );
        is(        $utx->get_miscellany('baz'),
                   'qux',
                   $test_case->{name} . ': API, get baz' );
        is(        $utx->get_miscellany('foobar'),
                   undef,
                   $test_case->{name} . ': API, get unexists' );
        is_deeply( ( scalar $utx->get_miscellany() ),
                   { foo => 'bar', baz => 'qux' },
                   $test_case->{name} . ': API, get by hashref' );
        is_deeply( { $utx->get_miscellany() },
                   { foo => 'bar', baz => 'qux' },
                   $test_case->{name} . ': API, get by hash' );
    }
    else {
        ok(        exists $utx->{header}{miscellany},
                   $test_case->{name} . ': internal' );
        is_deeply( [ $utx->{header}{miscellany}->Keys() ],
                   [],  # empty
                   $test_case->{name} . ': internal' );
        is(        $utx->get_miscellany('foo'),
                   undef,
                   $test_case->{name} . ': API, get foo' );
        is(        $utx->get_miscellany('baz'),
                   undef,
                   $test_case->{name} . ': API, get baz' );
        is(        $utx->get_miscellany('foobar'),
                   undef,
                   $test_case->{name} . ': API, get unexists' );
        is_deeply( ( scalar $utx->get_miscellany() ),
                   {},
                   $test_case->{name} . ': API, get by hashref' );
        is_deeply( { $utx->get_miscellany() },
                   {},
                   $test_case->{name} . ': API, get by hash' );
    }

    return;
}


# ================================================================
# create without option / with version
# [ 104 + 18 = 122tests ]
# ----------------------------------------------------------------
foreach my $version (@Versions) {
    # 8subtests * (3kinds * 3versions + 2kinds * 2versions) = 104 tests
    test_miscellany({
        name    => "create with version only, $version",
        version => $version,
        query   => {
            new => {
                version => $version,
            },
        },
    });
    test_miscellany({
        name    => "create with version only, $version",
        version => $version,
        query   => {
            new => {
                version => $version,
                miscellany => Tie::IxHash->new(
                    foo   => 'bar',
                    baz   => 'qux',
                    quux  => undef,
                    corge => undef,
                ),
            },
        },
    });
    test_miscellany({
        name    => "parse with version only, $version",
        version => $version,
        query   => {
            new => {
                version => $version,
            },
            parse => $Query{header}{$version}{'en-US/ja-JP'}{has_no_column},
        },
    });
    # 0.91, 0.92
    if (exists $Query{header}{$version}{'en-US/ja-JP'}{mandatory_only}) {
        test_miscellany({
            name    => "parse madatory attributes only, "
                     . "without semicolon, $version",
            version => $version,
            query   => {
                new => {
                    version => $version,
                },
                parse => $Query{header}{$version}{'en-US/ja-JP'}
                         {mandatory_only}{without_semicolon},
            },
            no_result => 1,
        });
        test_miscellany({
            name    => "parse madatory attributes only, "
                     . "with semicolon, $version",
            version => $version,
            query   => {
                new => {
                    version => $version,
                },
                parse => $Query{header}{$version}{'en-US/ja-JP'}
                         {mandatory_only}{with_semicolon},
            },
            no_result => 1,
        });
    }

    # exception
    # # 1subtest * (6kinds * 3versions + 1kind * 1version) = 19 tests
    # 1subtest * (6kinds * 3versions) = 18 tests
    test_miscellany({
        name      => "invalid object, $version",
        exception => 1,
        query     => {
            new => {
                version    => $version,
                miscellany => DateTime->now(),
            },
        },
        result    => q{Can't parse the header: }
                   . q{type of miscellany \(DateTime\) }
                   . q{isn't an ARRAY reference and isn't a Tie::IxHash},
    });
    test_miscellany({
        name      => "invalid hash, $version",
        exception => 1,
        query     => {
            new => {
                version    => $version,
                miscellany => {
                    foo => 1,
                },
            },
        },
        result    => q{Can't parse the header: }
                   . q{type of miscellany \(HASH\) }
                   . q{isn't an ARRAY reference and isn't a Tie::IxHash},
    });
    test_miscellany({
        name      => "scalar in arrayref, $version",
        exception => 1,
        query     => {
            new => {
                version    => $version,
                miscellany => [
                    'foobar'
                ],
            },
        },
        result    => q{Can't parse the header: }
                   . q{type of miscellany item \(\) }
                   . q{isn't a HASH reference},
    });
    test_miscellany({
        name      => "hash in arrayref has plural keys, $version",
        exception => 1,
        query     => {
            new => {
                version    => $version,
                miscellany => [
                    {
                        foo => 1,
                        baz => 2,   # error!
                    }
                ],
            },
        },
        result    => q{Can't parse the header: }
                   . q{miscellany item has more than 1 key},
    });
    test_miscellany({
        name      => "hash has duplicate keys, $version",
        exception => 1,
        query     => {
            new => {
                version    => $version,
                miscellany => [
                    {
                        foo => 1,
                    },
                    {
                        foo => 2,   # error!
                    }
                ],
            },
        },
        result    => q{Can't parse the header: }
                   . q{miscellious attribute \(foo\) is duplicated},
    });
    test_miscellany({
        name      => "hash has duplicate keys, $version",
        exception => 1,
        query     => {
            new => {
                version => $version,
                text    => $Query{header}{$version}{'en-US/ja-JP'}{lack},
            },
        },
        result    => q{Can't parse the header: }
                   . q{string lacks mandatory header properties \(}
                   . ($version < 0.91 ? 3 : 2)
                   . q{ attributes is smaller than }
                   . ($version < 0.91 ? 4 : 3)
                   . q{ mandatory attributes}
                   . q{\)},
    });
    # See Text::UTX::Simple::Header::Parser::_delimit_properties()'s comment!!
    # # 0.90
    # if (exists $Query{header}{$version}{'en-US/ja-JP'}{excess}) {
    #     test_miscellany({
    #         name      => "attributes is excess, $version",
    #         exception => 1,
    #         version   => $version,
    #         query     => {
    #             new   => {
    #                 version => $version,
    #                 text    => $Query{header}{$version}{'en-US/ja-JP'}
    #                                  {excess},
    #             },
    #         },
    #         result    => q{Can't parse the header: }
    #                    . q{string has 6 attributes, }
    #                    . q{but it is larger than 4 mandatory }
    #                    . q{\(and 1 optional\) attributes},
    #     });
    # }
}
