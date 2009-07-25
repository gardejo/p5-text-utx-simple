use strict;
use warnings;
# use utf8;
use lib 't/lib';

use Test::More tests => 14;
# use Test::Exception;
use Test::Warn;
# use Test::Text_UTX_Simple;

use Text::UTX::Simple;
use Text::UTX::Simple::Body;    # monomania

my $utx = Text::UTX::Simple->new();


# ================================================================
# DEFINED_COLUMN_ONLY @ header
# ----------------------------------------------------------------
is( $utx->is_defined_column_only(),
    0,
    "DEFINED_COLUMN_ONLY: default = off" );
is( $utx->is_defined_column_only(1),
    1,
    "DEFINED_COLUMN_ONLY: tarned on" );
is( $utx->is_defined_column_only(0),
    0,
    "DEFINED_COLUMN_ONLY: tarned off" );

$utx->is_defined_column_only(1);
is( $utx->is_defined_column_only(),
    1,
    "DEFINED_COLUMN_ONLY: tarned on, void context" );

$utx->is_defined_column_only(0);
is( $utx->is_defined_column_only(),
    0,
    "DEFINED_COLUMN_ONLY: tarned off, void context" );

warning_is
    { $utx->is_defined_column_only() }
    { carped => 'Useless use private variable in void context' }
;


# ================================================================
# COMPLEMENT_VOID_VALUE @ entry
# ----------------------------------------------------------------
is( $utx->get_complement_of_void_value(),
    q{},
    'COMPLEMENT_VOID_VALUE: default = empty' );
is( $utx->get_complement_of_void_value(42),
    q{},
    'COMPLEMENT_VOID_VALUE: default = empty (ignore arguments)' );
is( $utx->set_complement_of_void_value('foo'),
    undef,
    'COMPLEMENT_VOID_VALUE: set STR = return void' );
is( $utx->get_complement_of_void_value(),
    'foo',
    'COMPLEMENT_VOID_VALUE: set STR = chenged' );

is( $utx->set_complement_of_void_value(),
    undef,
    'COMPLEMENT_VOID_VALUE: set void' );
is( $utx->get_complement_of_void_value(),
    q{},
    'COMPLEMENT_VOID_VALUE: set void = default empty' );

$utx->get_complement_of_void_value(42);
is( $utx->set_complement_of_void_value(q{}),
    undef,
    'COMPLEMENT_VOID_VALUE: set emtpy' );
is( $utx->get_complement_of_void_value(q{}),
    q{},
    'COMPLEMENT_VOID_VALUE: set emtpy = changed' );
