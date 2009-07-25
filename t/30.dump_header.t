use strict;
use warnings;
use utf8;
use lib "t/lib";

use Test::More tests => 123;
use Test::Exception;
use Test::Warn;
use Test::Text_UTX_Simple;

use Text::UTX::Simple;
use Storable qw(dclone);


# ================================================================
# subroutine for test
# ----------------------------------------------------------------
sub test_dump {     # [ 1 test or 9+9+1=19 tests ]
    my $test_case = shift;

    my $utx = Text::UTX::Simple->new($test_case->{query}{new});

    if ($test_case->{exception}) {  # (0 + 1)
        # no test
        throws_ok( sub { my $error
                            = $utx->dump_header($test_case->{query}{dump}); },
                   qr{$test_case->{result}},
                   $test_case->{name} );
    }
    else {                          # (9 + 9 + 1)
        # normal (without "\n") [9 tests]
        like(      do { join q{},
                        @{ scalar $utx->dump_header() } },
                   $test_case->{result}{print},
                   $test_case->{name} . ': scalar context = arrayref' );
        like(      do { join q{}, $utx->dump_header() },
                   $test_case->{result}{print},
                   $test_case->{name} . ': list context = arrayref' );
        like(      $utx->dump_header({scalar => 1}),
                   $test_case->{result}{print},
                   $test_case->{name} . ': scalar' );
        like(      ${ $utx->dump_header({scalar_ref => 1}) },
                   $test_case->{result}{print},
                   $test_case->{name} . ': scalarref' );
        like(      do { join q{},
                        $utx->dump_header({list => 1}) },
                   $test_case->{result}{print},
                   $test_case->{name} . ': list' );
        like(      do { join q{},
                        $utx->dump_header({array => 1}) },
                   $test_case->{result}{print},
                   $test_case->{name} . ': array' );
        like(      do { join q{},
                        @{ $utx->dump_header({array_ref => 1}) } },
                   $test_case->{result}{print},
                   $test_case->{name} . ': arrayref' );
        my $header = dclone $utx->{header};
        $header->{miscellany} = $utx->get_miscellany();
        is_deeply( { $utx->dump_header({hash => 1}) },
                   $header,
                   $test_case->{name} . ': hash' );
        is_deeply( $utx->dump_header({hash_ref => 1}),
                   $header,
                   $test_case->{name} . ': hashref' );

        # say (with "\n") [8 tests]
        like(      do { join q{},
                        @{ scalar $utx->dump_header({say => 1}) } },
                   $test_case->{result}{say},
                   $test_case->{name} . ': scalar context = arrayref, say' );
        like(      do { join q{}, $utx->dump_header({say => 1}) },
                   $test_case->{result}{say},
                   $test_case->{name} . ': list context = arrayref, say' );
        like(      $utx->dump_header({scalar => 1, say => 1}),
                   $test_case->{result}{say},
                   $test_case->{name} . ': scalar, say' );
        like(      ${ $utx->dump_header({scalar_ref => 1, say => 1}) },
                   $test_case->{result}{say},
                   $test_case->{name} . ': scalarref, say' );
        like(      do { join q{},
                        $utx->dump_header({list => 1, say => 1}) },
                   $test_case->{result}{say},
                   $test_case->{name} . ': list, say' );
        like(      do { join q{},
                        $utx->dump_header({array => 1, say => 1}) },
                   $test_case->{result}{say},
                   $test_case->{name} . ': array, say' );
        like(      do { join q{},
                        @{ $utx->dump_header({array_ref => 1, say => 1}) } },
                   $test_case->{result}{say},
                   $test_case->{name} . ': arrayref, say' );
        my $say_error = q{Can't dump the dictionary: }
                      . q{can't use 'say' option }
                      . q{with 'hash' or 'hash_ref' option};
        throws_ok( sub { my $error
                            = $utx->dump_header({hash => 1, say => 1}) },
                   qr{$say_error},
                   $test_case->{name} . ': hash, say' );
        throws_ok( sub { my $error
                            = $utx->dump_header({hash_ref => 1, say => 1}) },
                   qr{$say_error},
                   $test_case->{name} . ': hashref, say' );

        # multiple data type [1 test]
        my $multiple_data_type_error
            = q{Can't validate type: }
            . q{type assignment isn't exclusive }
            . q{\(you ware assined multiple types below, scalar, scalar_ref\)};
        throws_ok( sub { my $error
                            = $utx->dump_header
                                ({scalar => 1, scalar_ref => 1}) },
                   qr{$multiple_data_type_error},
                   $test_case->{name} . ': scalar and scalarref' );
    }

    return;
}

# To evade "Bizzare copy of HASH in sassin" or "Bizzare copy of CODE in sassin"
# at Carp::Heavy line 104!!
sub test_warn {
    my $test_case = shift;

    my $utx = Text::UTX::Simple->new($test_case->{query}{new});

    # void context [1 test]
    warning_is
        { $utx->dump_header({scalar => 1}) }
        { carped => 'Useless use private variable in void context' }
    ;

    return;
}


# ================================================================
# create
# [ 57 + 57 + 3 = 117 tests ]
# ----------------------------------------------------------------
foreach my $version (@Versions) {
    my %version_definition = (version => $version);

    # --------------------------------
    # without user defined columns (default columns only)
    #  (19*3 = 57 tests)
    # --------------------------------
    test_dump({
        name    => "default columns (3 columns) only, $version",
        query   => {
            new => {
                %version_definition,
                text => $Query{header}{$version}{'en/ja'}
                              {has_no_column},
            },
        },
        result  => $Result{header}{$version}{'en/ja'}{'local'}
                          {has_no_column},
    });
    # --------------------------------
    # with user defined columns
    #  (19*3 = 57 tests)
    # --------------------------------
    test_dump({
        name    => "with user defined columns (3+N columns), $version",
        query   => {
            new => {
                %version_definition,
                text => $Query{header}{$version}{'en/ja'}
                              {has_column},
            },
        },
        result  => $Result{header}{$version}{'en/ja'}{'local'}
                          {has_column},
    });
    # --------------------------------
    # invalid type
    #  (1*3 = 3 tests)
    # --------------------------------
    test_dump({
        name      => "invalid data type, $version",
        exception => 1,
        query     => {
            new => {
                %version_definition,
            },
            dump => [qw(foo bar)],
        },
        result    => q{Can't validate type: option isn't a HASH reference},
    });
}


# ================================================================
# warning
# *** CAVEAT: ATTEMPT IT AT LAST OF TEST TO EVADE ERROR FROM Carp::Heavy ***
# [ 3 + 3 = 6 tests ]
# ----------------------------------------------------------------
foreach my $version (@Versions) {
    my %version_definition = ( version => $version );

    # --------------------------------
    # without user defined columns (default columns only)
    #  (1*4 = 4 tests)
    # --------------------------------
    test_warn({
        name    => "scalar context, array ref & list context, list: "
                 . "with user defined columns (3+N columns), $version",
        query   => {
            new => {
                %version_definition,
                text => $Query{header}{$version}{'en/ja'}
                              {has_no_column},
            },
        },
        result  => $Result{header}{$version}{'en/ja'}{'local'}
                          {has_no_column},
    });
    # --------------------------------
    # with user defined columns
    #  (1*4 = 4 tests)
    # --------------------------------
    test_warn({
        name    => "scalar context, array ref & list context, list: "
                 . "with user defined columns (3+N columns), $version",
        query   => {
            new => {
                %version_definition,
                text => $Query{header}{$version}{'en/ja'}
                              {has_column},
            },
        },
        result  => $Result{header}{$version}{'en/ja'}{'local'}
                          {has_column},
    });
}
