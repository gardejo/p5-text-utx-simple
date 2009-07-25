use strict;
use warnings;
# use utf8;
use lib 't/lib';

use Test::More tests => 64;
use Test::Exception;
# use Test::Warn;
use Test::Text_UTX_Simple;

use Text::UTX::Simple;


# ================================================================
# subroutine for test
# [ 8+8+1+2 = 19 tests ]
# ----------------------------------------------------------------
sub test_clone {
    my $test_case = shift;

    my $version = $test_case->{version};

    my ($original, $clone);

    # --------------------------------
    # header
    # [8 tests]
    # --------------------------------
    $original = Text::UTX::Simple->new({
        %{ $test_case->{query}{new} },
        miscellany => [
            { foo    => 1     },
            { bar    => 2     },
            { baz    => 3     },
            { qux    => undef },
            { quux   => 5     },
        ],
    });

    # clone without option [ 2 tests ]
    pass($clone = $original->clone());
    is_deeply( [ @{$original->{header}}
                    {qw(specification version source target)} ],
               [ @{$clone   ->{header}}
                    {qw(specification version source target)} ],
               $test_case->{name} . ' : same header' );

    # clone with option [ 6 tests ]
    # overwrite clone as original
    pass( $clone = $original->clone({
            source        => 'ja',
            target        => 'eo',
            miscellany => [
                { foo    => q{}   },    # overwrite blank
                # bar                     preserve
                { baz    => 42    },    # overwrite value
                #                         unexist
                { quux   => undef },    # remove
                { corge  => 6     },    # add
            ],
          }) );
    is_deeply( [ @{$original->{header}}
                    {qw(specification version source target)} ],
               [ 'UTX-S', $version, 'en', undef ],
               $test_case->{name} . ' : original locale preserved' );
    is_deeply( [ @{$clone->{header}}
                    {qw(specification version source target)} ],
               [ 'UTX-S', $version, 'ja', 'eo' ],
               $test_case->{name} . ' : clone locale changed' );
    is_deeply( { $original->get_miscellany() },
               { foo => 1,   bar => 2, baz => 3,  quux => 5 },
               $test_case->{name} . ' : original miscellany preserved' );
    is_deeply( { $clone->get_miscellany() },
               { foo => q{}, bar => 2, baz => 42, corge => 6 },
               $test_case->{name} . ' : original miscellany changed' );
    is_deeply( [ $clone->get_columns() ],
               [ $original->get_columns() ],
               $test_case->{name}
                    . ' : create with optional values (proper columns)' );

    # --------------------------------
    # body
    # [8 tests]
    # --------------------------------
    $original = Text::UTX::Simple->new({
        %{ $test_case->{query}{new} },
        text => do {
            join "\n", (
                ( split "\n", $Query{header}{$version}{'en/ja'}{has_column}   ),
                ( join "\t", qw(src0     tgt00 src:pos00 src:foo00 tgt:bar00) ),
                ( join "\t", '#src1', qw(tgt10 src:pos10 src:foo10 tgt:bar10) ),
                ( join "\t", qw(src1     tgt11 src:pos11 src:foo11 tgt:bar11) ),
            )
        },
    });

    # clone without option
    pass($clone = $original->clone());
    is_deeply( $original->{entries},
               $clone->{entries},
               $test_case->{name} . ' : entries(array data) cloned, internal' );
    is_deeply( $original->{entry},
               $clone->{entry},
               $test_case->{name} . ' : entry(hash index) cloned, internal' );
    # is_deeply( [ $original->dump_entries() ],
    #            [ $clone->dump_entries() ],
    #            $test_case->{name} . ' : entries cloned' );
    is_deeply( [ $original->dump_body() ],
               [ $clone->dump_body() ],
               $test_case->{name} . ' : entries cloned' );

    # does make a clear distinction between original and clone?
    # OK - entry leaves no impression on original from clone
    $original->parse( do {
        join "\n", (
            ( split "\n", $Query{header}{$version}{'en/ja'}{has_column}   ),
            ( join "\t", qw(src2     tgt20 src:pos20 src:foo20 tgt:bar20) ),
            ( join "\t", '#src3', qw(tgt30 src:pos30 src:foo30 tgt:bar30) ),
            ( join "\t", qw(src3     tgt31 src:pos31 src:foo31 tgt:bar31) ),
        )
    } );
    is_deeply( $original->dump_body({array_ref => 1}),
               [ [qw(src2     tgt20 src:pos20 src:foo20 tgt:bar20)],
                 ['#src3', qw(tgt30 src:pos30 src:foo30 tgt:bar30)],
                 [qw(src3     tgt31 src:pos31 src:foo31 tgt:bar31)], ],
               $test_case->{name} . ' : original changed' );
    is_deeply( $clone->dump_body({array_ref => 1}),
               [ [qw(src0     tgt00 src:pos00 src:foo00 tgt:bar00)],
                 ['#src1', qw(tgt10 src:pos10 src:foo10 tgt:bar10)],
                 [qw(src1     tgt11 src:pos11 src:foo11 tgt:bar11)], ],
               $test_case->{name} . ' : clone preserved' );
    $clone->parse( do {
        join "\n", (
            ( split "\n", $Query{header}{$version}{'en/ja'}{has_column}   ),
            ( join "\t", qw(src4     tgt40 src:pos40 src:foo40 tgt:bar40) ),
            ( join "\t", '#src5', qw(tgt50 src:pos50 src:foo50 tgt:bar50) ),
            ( join "\t", qw(src5     tgt51 src:pos51 src:foo51 tgt:bar51) ),
        )
    } );
    is_deeply( $original->dump_body({array_ref => 1}),
               [ [qw(src2     tgt20 src:pos20 src:foo20 tgt:bar20)],
                 ['#src3', qw(tgt30 src:pos30 src:foo30 tgt:bar30)],
                 [qw(src3     tgt31 src:pos31 src:foo31 tgt:bar31)], ],
               $test_case->{name} . ' : original preserved' );
    is_deeply( $clone->dump_body({array_ref => 1}),
               [ [qw(src4     tgt40 src:pos40 src:foo40 tgt:bar40)],
                 ['#src5', qw(tgt50 src:pos50 src:foo50 tgt:bar50)],
                 [qw(src5     tgt51 src:pos51 src:foo51 tgt:bar51)], ],
               $test_case->{name} . ' : clone changed' );

    # --------------------------------
    # invalid usage: clone()'s wrong option
    # [1 test]
    # --------------------------------
    throws_ok(
        sub { $original->clone([qw(foo bar)]) },
        qr{Can't clone an object: option isn't a HASH reference},
        "clone()'s option is not a HASH reference"
    );

    # --------------------------------
    # monomania: internal Text::UTX::Simple::Body::clone()
    # [2 tests]
    # --------------------------------
    my $original_entry = $original->{body};
    my $clone_entry    = $clone   ->{body};
    undef $clone_entry;
    throws_ok(
        sub { $clone_entry = $original_entry->clone() },
        qr{Can't clone a Text::UTX::Simple::Body instance: a back-link to parent doesn't exist},
        'invalid call (without back-link)'
    );
    is( $clone_entry,
        undef,
        'undef' );
}


# ================================================================
# clone, and exception
# [ 19subtests + 3versions = 57tests ]
# ----------------------------------------------------------------
foreach my $version (@Versions) {
    my %version_definition = ( version => $version );

    # Xsubtests * 3versions = Xtests
    test_clone({
        name    => "version: $version",
        query   => {
            new => \%version_definition,
        },
        version => $version,
    });
}


# ================================================================
# clone compatible/incompatible version
# 6tests
# ----------------------------------------------------------------
DICTIONARY0:
foreach my $version0 (@Versions) {
    my %version_definition = ( version => $version0 );
    my $utx = Text::UTX::Simple->new(\%version_definition);
    DICTIONARY1:
    foreach my $version1 (@Versions) {
        next DICTIONARY1
            if $version0 eq $version1;
        my $clone;
        if (is_compatible_version($version0, $version1)) {  # test function
            # 0.91 - 0.92; 1subtest * (2! = 2kinds) = 2tests
            lives_ok(  sub { $clone = $utx->clone({version => $version1}); },
                       "compatible: $version0 - $version1" );
        }
        else {
            # 1subtest * (3! - 2! = 4kinds) = 4tests
            throws_ok( sub { $clone = $utx->clone({version => $version1}); },
                       qr{Can't parse the header: version \($version0\) isn't compatible with $version1},
                       "incompatible: $version0 - $version1" );
        }
    }
}


# ================================================================
# general exception: invalid usage: new() as clone()
# [ 1 test ]
# ----------------------------------------------------------------
throws_ok(
    sub { Text::UTX::Simple->clone() },
    qr{Can't clone an object: Text::UTX::Simple is not an object \(you must use new\(\)\)},
    'invalid usage: new() as clone()'
);
