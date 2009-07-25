use strict;
use warnings;
# use utf8;
# use lib 't/lib';

use Test::More tests => 9;
use Test::Exception;
# use Test::Warn;
# use Test::Text_UTX_Simple;

use Text::UTX::Simple;
use Text::UTX::Simple::Body;    # monomania

my $utx;


# ================================================================
# create without option
# ----------------------------------------------------------------
pass( $utx = Text::UTX::Simple->new() );    # 0.92
is_deeply( [ @{$utx->{header}}
                {qw(specification version source target)} ],
           [ 'UTX-S', '0.92', 'en', undef ],
           'create without option = default values' );


# ================================================================
# create with invalid option
# ----------------------------------------------------------------
pass( $utx = Text::UTX::Simple->new({foo => 1, bar => 2}) );
is_deeply( [ @{$utx->{header}}
                {qw(specification version source target)} ],
           [ 'UTX-S', '0.92', 'en', undef ],
           'create with invalid option = default values' );


# ================================================================
# invalid usage: new()'s wrong option
# ----------------------------------------------------------------
throws_ok(
    sub { my $error = Text::UTX::Simple->new([qw(foo bar)]) },
    qr{Can't create an object: option isn't a HASH reference},
    q{new()'s option is not a HASH reference}
);

throws_ok(
    sub { my $error = Text::UTX::Simple->new({text => 'foo', file => 'file'}) },
    qr{Can't create an object: option should have only one behavior key},
    'more than 1 behavior key is assigned to new()'
);


# ================================================================
# invalid usage: new() as clone()
# ----------------------------------------------------------------
# $utx = Text::UTX::Simple->new();
throws_ok(
    sub { $utx->new() },
    qr{Can't create a new object: Text::UTX::Simple=HASH\(0x[\da-f]+\) is not a class \(you must use clone\(\)\)},
    q{new()'s option is not a HASH reference}
);


# ================================================================
# exception: monomania: internal Text::UTX::Simple::Body::new()
# ----------------------------------------------------------------
my $entry;
throws_ok(
    sub { $entry = Text::UTX::Simple::Body->new() },
    qr{Can't create a new Text::UTX::Simple::Body instance: a back-link to parent doesn't exist},
    'invalid call (without back-link)'
);
is( $entry,
    undef,
    'undef' );
