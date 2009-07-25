use strict;
use warnings;
# use utf8;
use lib 't/lib';

use Test::More tests => 170;
use Test::Exception;
# use Test::Warn;
use Test::Text_UTX_Simple;

use Text::UTX::Simple;


# ================================================================
# subroutine for test
# ----------------------------------------------------------------
sub test_last_updated { # [ 4 tests ]
    my $test_case = shift;

    my $utx;

    if (exists $test_case->{query}{parse}) {
        $utx = Text::UTX::Simple->new($test_case->{query}{new});
        diag "test data of $test_case->{name} is not defined"
            unless defined $test_case->{query}{parse};
        pass( $utx->parse($test_case->{query}{parse}) );
    }
    else {
        pass( $utx = Text::UTX::Simple->new($test_case->{query}{new}) );
    }

    ok(   ! $utx->{header}{miscellany}->EXISTS('time_zone'),
          $test_case->{name} . ' : time_zone is not defined' );
    like( $utx->{header}{last_updated},
          $test_case->{result},
          $test_case->{name} . ' : internal' );
    like( $utx->get_last_updated(),
          $test_case->{result},
          $test_case->{name} . ' : API' );

    return;
}


# ================================================================
# create without option / with version
# [ 4subtests * 3versions = 12 tests ]
# ----------------------------------------------------------------
foreach my $version (@Versions) {
    test_last_updated({
        name   => "create with version only, $version",
        query  => {
            new => {
                version => $version,
            },
        },
        result => qr{$Pattern{last_updated}{'local'}},
    });
}


# ================================================================
# create with time zone
# [ 4subtests * 6locales * 3versions = 72 tests ]
# ----------------------------------------------------------------
foreach my $version (@Versions) {
    foreach my $time_zone (@Time_Zones) {
        test_last_updated({
            name   => 'create with time zone'
                    . (defined $time_zone ? " ($time_zone), " : " (local), ")
                    . $version,
            query  => {
                new => {
                    version   => $version,
                    time_zone => $time_zone,
                },
            },
            result => qr{$Pattern{last_updated}{
                defined $time_zone ? $time_zone : 'local'
            }},
        });
    }
}


# ================================================================
# create with last updated
# [ 4subtests * 6locales * 3versions = 72 tests ]
# ----------------------------------------------------------------
foreach my $version (@Versions) {
    foreach my $time_zone (@Time_Zones) {
        test_last_updated({
            name   => 'create with last updated'
                    . (defined $time_zone ? " ($time_zone), " : " (local), ")
                    . (defined $version ? $version : 'latest'),
            query  => {
                new => {
                    version      => $version,
                    time_zone    => $time_zone,
                    last_updated => $Query{last_updated}{UTC},
                },
            },
            result => qr{$Pattern{last_updated}{UTC}},  # isn't $time_zone!
        });
    }
}


# ================================================================
# parse
# [ 4subtests * 3versions = 12 tests ]
# ----------------------------------------------------------------
foreach my $version (@Versions) {
    test_last_updated({
        name   => "parse, $version",
        query  => {
            new   => {
                version => $version,
            },
            parse => $Query{header}{$version}{'en-US/ja-JP'}{has_column},
        },
        result => qr{$Pattern{last_updated}{'Asia/Tokyo'}},
    });
}


# ================================================================
# exceptions
# [ 2 tests ]
# ----------------------------------------------------------------
throws_ok(
    sub { test_last_updated({
        name => 'create/exception (undef)',
        query => {
            new => {
                last_updated => undef,
            },
        },
        result => undef,
    }); },
    qr{Can't parse the header: last updated date/time isn't defined},
);

throws_ok(
    sub { test_last_updated({
        name => 'create/exception (slash)',
        query => {
            new => {
                last_updated => $Query{last_updated}{slash},
            },
        },
        result => undef,
    }); },
    qr{Can't parse the header: last updated date/time isn't valid as ISO 8601 format},
);
