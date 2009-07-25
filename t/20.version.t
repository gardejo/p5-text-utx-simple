use strict;
use warnings;
# use utf8;
use lib 't/lib';

use Test::More tests => 138;
use Test::Exception;
use Test::Warn;
use Test::Text_UTX_Simple;

use Storable qw(dclone);
use Text::UTX::Simple;


# ================================================================
# subroutine for test
# [ 1 test or 6/7 tests ]
# ----------------------------------------------------------------
sub test_version {
    my $test_case = shift;

    if ($test_case->{exception}) {  # (0 + 1)
        throws_ok( sub { _make($test_case); },
                   qr{$test_case->{result}},
                   $test_case->{name} );
    }
    else {                          # (1/2 + 4)
        my $utx = _make($test_case);
        isa_ok(    $utx->{header},
                   $test_case->{result}{class} );
        is(        $utx->guess_version(),
                   $test_case->{result}{version},
                   $test_case->{name} . ' : guess_version');
        my $header_class = ref $utx->{header};
        is(        $header_class->guess_version(),
                   $test_case->{result}{version},
                   $test_case->{name} . ' : guess_version');    # monomania
        is_deeply( [ @{$utx->{header}}{qw(specification version)} ],
                   [ 'UTX-S', $test_case->{result}{version} ],
                   $test_case->{name} . ' : internal' );
        is(        $utx->get_version(),
                   $test_case->{result}{version},
                   $test_case->{name} . ' : get_version');
    }

    return;
}

sub _make {
    my $test_case = shift;

    my $utx;

    if (exists $test_case->{query}{parse}) {
        if ($test_case->{warning}) {
            warning_is
                { $utx = Text::UTX::Simple->new($test_case->{query}{new}); }
                { carped => $test_case->{result}{warning} }
            ;
            warning_is
                { $utx->parse($test_case->{query}{parse}); }
                { carped => $test_case->{result}{warning} }
            ;
        }
        else {
            # to avoid "Bizarre copy of ARRAY in sassin"
            # at Carp::Heady line 104
            # if (exists $test_case->{query}{utx}) {
            #     $utx = dclone $test_case->{query}{utx};
            # }
            # else {
            #     $utx = Text::UTX::Simple->new($test_case->{query}{new});
            # }
            $utx = Text::UTX::Simple->new($test_case->{query}{new});
            pass( $utx->parse($test_case->{query}{parse}) );
        }
    }
    else {
        if ($test_case->{warning}) {
            warning_is
                { $utx = Text::UTX::Simple->new($test_case->{query}{new}); }
                { carped => $test_case->{result}{warning} }
            ;
        }
        else {
            pass( $utx = Text::UTX::Simple->new($test_case->{query}{new}) );
        }
    }

    return $utx;
}

sub _get_class {
    my $version = shift;

    (my $class = $version) =~ tr{.}{_};
    $class = 'Text::UTX::Simple::Version::Header::V' . $class;

    return $class;
}


# ================================================================
# create, parse same version
# [ 6subtests * 2kinds * 3versions = 36 tests ]
# ----------------------------------------------------------------
foreach my $version (@Versions) {
    my $class = _get_class($version);

    test_version({
        name   => "new : version $version",
        query  => {
            new   => {
                version => $version,
            },
        },
        result => {
            class   => $class,
            version => $version,
        },
    });
    test_version({
        name   => "parse : version $version",
        query  => {
            new   => {
                version => $version,
            },
            parse => $Query{header}{$version}{'en/ja'}{has_column},
        },
        result => {
            class   => $class,
            version => $version,
        },
    });
}


# ================================================================
# create, parse same version : without version
# [ 6subtests * 2kinds * 1version = 12 tests ]
# ----------------------------------------------------------------
{
    my $latest_version = get_latest_version();
    my $class = _get_class($latest_version);

    test_version({
        name   => "new : without version",
        query  => {
            new   => {},
        },
        result => {
            class   => $class,
            version => $latest_version,
        },
    });
    test_version({
        name   => "parse : without version",
        query  => {
            new   => {},
            parse => $Query{header}{$latest_version}{'en/ja'}{has_column},
        },
        result => {
            class   => $class,
            version => $latest_version,
        },
    });
}


# ================================================================
# 0.9 -> 0.90
# [ 6subtests * 2kinds * 1version = 12 tests ]
# ----------------------------------------------------------------
{
    my $version           = '0.9';
    my $canonical_version = '0.90';
    my $class = _get_class($canonical_version);

    test_version({
        name   => "new : version $version",
        query  => {
            new   => {
                version => $version,
            },
        },
        result => {
            class   => $class,
            version => $canonical_version,
        },
    });
    test_version({
        name   => "parse : version $version",
        query  => {
            new   => {
                version => $version,
            },
            parse => $Query{header}{$canonical_version}{'en/ja'}{has_column},
        },
        result => {
            class   => $class,
            version => $canonical_version,
        },
    });
}


# ================================================================
# parse compatible/incompatible version
# [ 14 + 8 = 22 tests ]
# ----------------------------------------------------------------
{
    DICTIONARY0:
    foreach my $version0 (@Versions) {
        my $utx0 = Text::UTX::Simple->new({version => $version0});
        DICTIONARY1:
        foreach my $version1 (@Versions) {
            next DICTIONARY1
                if $version0 eq $version1;

            my $utx1 = Text::UTX::Simple->new({version => $version1});

            # 0.91 - 0.92
            # (6subtests + 1subtest) * (2! = 2kinds) = 14tests
            if (is_compatible_version($version0, $version1)) {  # test function
                test_version({
                    name   => "parse : header is changed $version1 "
                            . "(compatible with $version0)",
                    query  => {
                        # utx   => $utx0{$version0},
                        new   => {
                            version => $version0,
                        },
                        parse => $Query{header}{$version1}{'en/ja'}
                                       {has_column},
                    },
                    result => {
                        class   => _get_class($version1),
                        version => $version1,
                    },
                });
                ok( $utx0->is_same_format_as($utx1),
                    "same format, $version0 - $version1" );
            }
            # (1subtest * 2kinds) * (3! - 2! = 4kinds) = 8tests
            else {
                test_version({
                    exception => 1,
                    name      => "parse : $version1 is not compatible"
                               . "with $version0",
                    query     => {
                        # utx   => $utx0{$version0},
                        new   => {
                            version => $version0,
                        },
                        parse => $Query{header}{$version1}{'en/ja'}
                                       {has_column},
                    },
                    result    => q{Can't parse the header: }
                               . q{attempt to parse incompatible version \(}
                               . $version1 . q{\) string with the version \(}
                               . $version0 . q{\) dictionary},
                });
                ok( ! $utx0->is_same_format_as($utx1),
                    "different format, $version0 - $version1" );
            }
        }
    }
}


# ================================================================
# exception: invalid version (new)
# [ 4 + 1 = 5 tests ]
# ----------------------------------------------------------------
{
    # numeric check (1subtests * 1kind * 4pseudo_version = 4 tests)
    foreach my $pseudo_version (qw(foobar v0.90 Inf Infinity)) {
        test_version({
            exception => 1,
            name      => "invalid creating: $pseudo_version is not numeric",
            query     => {
                new => {
                    version => $pseudo_version,
                },
            },
            result    => q{Can't parse the header: }
                       . q{version \(} . $pseudo_version . q{\) isn't numeric},
        });
    }

    # definition check (1subtests * 1kind * 1pseudo_version = 1 tests)
    test_version({
        exception => 1,
        name      => "invalid creating: undefined version",
        query     => {
            new => {
                version => undef,
            },
        },
        result    => q{Can't parse the header: }
                   . q{version isn't defined},
    });
}


# ================================================================
# exception: invalid version (parse)
# [ 1subtest * 4pseudo_versions * 3versions = 12 tests ]
# ----------------------------------------------------------------
foreach my $version (@Versions) {
    my $class = _get_class($version);

    # numeric check (1subtests * 1kind * 4pseudo_version = 4 tests)
    foreach my $pseudo_version (qw(foobar v0.90 Inf Infinity)) {

        (my $string_to_parse = $Query{header}{$version}{'en/ja'}{has_column})
            =~ s{ \d+ \. \d+ }{$pseudo_version}xms;
        test_version({
            exception => 1,
            name      => "invalid creating: $pseudo_version is not numeric "
                       . "(into version $version dictionary)",
            query     => {
                new   => {
                    version => $version,
                },
                parse => $string_to_parse,
            },
            result    => $pseudo_version =~ m{ \d+ \. \d+ }xms
                            ?   q{Can't parse the header: }
                              . q{version \(} . $pseudo_version
                              . q{\) isn't numeric}
                            :   q{Can't guess version: }
                              . q{specified string }
                              . q{has no version kind string},
        });
    }
}


# ================================================================
# warning: turns version into latest automatically
# [ (6subtests + 7subtests) * 3versions = 39 tests ]
# ----------------------------------------------------------------
foreach my $version (qw(0.89 0.93 3.14)) {
    my $latest_version = get_latest_version();
    my $class = _get_class($latest_version);

    test_version({  # 5 subtests
        name    => "new : version $version",
        warning => 1,
        query   => {
            new   => {
                version => $version,
            },
        },
        result  => {
            class   => $class,
            version => $latest_version,
            warning => "Unknown version ($version) is detected: "
                     . "latest version ($latest_version) "
                     . "was applied implicitly",
        },
    });

    (my $string_to_parse
        = $Query{header}{$latest_version}{'en/ja'}{has_column})
        =~ s{$latest_version}{$version};
    test_version({  # 6 subtests
        name    => "parse : version $version",
        warning => 1,
        query   => {
            new   => {
                version => $version,
            },
            parse => $string_to_parse,
        },
        result => {
            class   => $class,
            version => $latest_version,
            warning => "Unknown version ($version) is detected: "
                     . "latest version ($latest_version) "
                     . "was applied implicitly",
        },
    });
}
