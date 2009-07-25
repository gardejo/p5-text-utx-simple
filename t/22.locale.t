use strict;
use warnings;
# use utf8;
use lib 't/lib';

use Test::More tests => 240;
use Test::Exception;
# use Test::Warn;
use Test::Text_UTX_Simple;

use Text::UTX::Simple;


# ================================================================
# subroutine for test
# ----------------------------------------------------------------
sub test_locale { # [ 5 tests ]
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

    is_deeply( [ @{$utx->{header}}{qw(source target)} ],
               $test_case->{result}{internal},
               $test_case->{name} . ' : internal' );
    is(        $utx->get_alignment(),
               $test_case->{result}{alignment},
               $test_case->{name} . ' : API, alignment' );
    is(        $utx->get_source(),
               $test_case->{result}{source},
               $test_case->{name} . ' : API, source' );
    is(        $utx->get_target(),
               $test_case->{result}{target},
               $test_case->{name} . ' : API, target' );

    return;
}


# ================================================================
# create without option / with version
# [ 5subtests * 3versions = 15 tests ]
# ----------------------------------------------------------------
foreach my $version (@Versions) {
    test_locale({
        name   => "create with version only, $version",
        query  => {
            new => {
                version => $version,
            },
        },
        result => {
            internal  => [ 'en', undef ],
            alignment => 'en',
            source    => 'en',
            target    => undef,
        },
    });
}


# ================================================================
# create with source (ja, ja-JP)
# [ 5subtests * 2alignments * 3versions = 30 tests ]
# ----------------------------------------------------------------
foreach my $version (@Versions) {
    foreach my $source (qw(ja ja-JP)) {
        test_locale({
            name   => "create with source, $version",
            query  => {
                new => {
                    version => $version,
                    source  => $source,
                },
            },
            result => {
                internal  => [ $source, undef ],
                alignment => $source,
                source    => $source,
                target    => undef,
            },
        });
    }
}


# ================================================================
# create with source (ja, ja-JP) and target (en, en-US)
# [ 5subtests * 2sources * 2targets * 3version = 60 tests ]
# ----------------------------------------------------------------
foreach my $version (@Versions) {
    foreach my $source (qw(ja ja-JP)) {
        foreach my $target (qw(en en-US)) {
            test_locale({
                name   => "create with source and target, $version",
                query  => {
                    new => {
                        version => $version,
                        source  => $source,
                        target  => $target,
                    },
                },
                result => {
                    internal  => [ $source, $target ],
                    alignment => $source . '/' . $target,
                    source    => $source,
                    target    => $target,
                },
            });
        }
    }
}


# ================================================================
# exceptions : source is undef
# [ 1subtest * 3versions = 3 tests ]
# ----------------------------------------------------------------
foreach my $version (@Versions) {
    throws_ok(
        sub { test_locale({
            name   => undef,
            query  => {
                new => {
                    version => $version,
                    source  => undef,
                },
            },
            result => undef,
        }) },
        qr{Can't parse the header: source locale isn't defined},
        "exception (source is undef), $version"
    );
}


# ================================================================
# exceptions : target only
# [ 1subtest * 3versions = 3 tests ]
# ----------------------------------------------------------------
foreach my $version (@Versions) {
    throws_ok(
        sub { test_locale({
            name   => undef,
            query  => {
                new => {
                    version => $version,
                    target  => 'en-US',
                },
            },
            result => undef,
        }) },
        qr{Can't create an object: you must specify both source and target to create multilingual dictionary},
        "exception (target only), $version"
    );
}


# ================================================================
# exceptions : alignment and source
# [ 1subtest * 3kinds * 3versions = 9 tests ]
# ----------------------------------------------------------------
foreach my $version (@Versions) {
    throws_ok(
        sub { test_locale({
            name   => undef,
            query  => {
                new => {
                    version   => $version,
                    alignment => 'de-DE/es-ES',
                    target    => 'es-ES',
                },
            },
            result => undef,
        }) },
        qr{Can't create an object: you can't specify both alignment and group of source and/or target},
        "exception (alignment and target), $version"
    );
    throws_ok(
        sub { test_locale({
            name   => undef,
            query  => {
                new => {
                    version   => $version,
                    alignment => 'de-DE/es-ES',
                    source    => 'de-DE',
                },
            },
            result => undef,
        }) },
        qr{Can't create an object: you can't specify both alignment and group of source and/or target},
        "exception (alignment and source), $version"
    );
    lives_ok(
        sub { Text::UTX::Simple->new({
                version   => $version,
                alignment => 'de-DE/es-ES',
              }) },
        "normal exit (alignment only), $version"
    );
}


# ================================================================
# exceptions : invalid source/target language/region
# [ 1subtest * 5kinds *3versions = 15 tests ]
# ----------------------------------------------------------------
foreach my $version (@Versions) {
    throws_ok(
        sub { test_locale({
            name   => undef,
            query  => {
                new => {
                    version => $version,
                    source  => 'FOO',
                },
            },
            result => undef,
        }) },
        qr{Can't parse the header: source language \(FOO\) isn't valid as ISO 639-1 format},
        "exception (invalid source language), $version"
    );
    throws_ok(
        sub { test_locale({
            name   => undef,
            query  => {
                new => {
                    version => $version,
                    source  => 'en-BAR',
                },
            },
            result => undef,
        }) },
        qr{Can't parse the header: source region \(BAR\) isn't valid as ISO 3166 format},
        "exception (invalid source region), $version"
    );
    throws_ok(
        sub { test_locale({
            name   => undef,
            query  => {
                new => {
                    version => $version,
                    source  => 'en-US',
                    target  => 'BAZ',
                },
            },
            result => undef,
        }) },
        qr{Can't parse the header: target language \(BAZ\) isn't valid as ISO 639-1 format},
        "exception (invalid target language), $version"
    );
    throws_ok(
        sub { test_locale({
            name   => undef,
            query  => {
                new => {
                    version => $version,
                    source  => 'en-US',
                    target  => 'ja-QUX',
                },
            },
            result => undef,
        }) },
        qr{Can't parse the header: target region \(QUX\) isn't valid as ISO 3166 format},
        "exception (invalid target region), $version"
    );
    throws_ok(
        sub { test_locale({
            name   => undef,
            query  => {
                new => {
                    version => $version,
                    source  => 'en-BAR',
                    target  => 'ja-QUX',
                },
            },
            result => undef,
        }) },
        qr{Can't parse the header: source region \(BAR\) isn't valid as ISO 3166 format},
        "exception (validation order is source > target), $version"
    );
}


# ================================================================
# parse source (en, en-US) and target (n/a, ja, ja-JP)
# [ 5subtests * 2source * 3target * 3versions = 90 tests ]
# ----------------------------------------------------------------
foreach my $version (@Versions) {
    foreach my $source (qw(en en-US)) {
        foreach my $target (undef, qw(ja ja-JP)) {
            my $alignment = defined $target ? $source . '/' . $target
                                            : $source;
            test_locale({
                name   => "parse with source/target, $version",
                query  => {
                    new   => {
                        version => $version,
                    },
                    parse => $Query{header}{$version}{$alignment}
                                   {has_no_column},
                },
                result => {
                    internal  => [ $source, $target ],
                    alignment => $alignment,
                    source    => $source,
                    target    => $target,
                },
            });
        }
    }
}


# ================================================================
# exceptions : invalid source/target language/region
# [ 1subtest * 5kinds * 3versions = 15 tests ]
# ----------------------------------------------------------------
foreach my $version (@Versions) {
    throws_ok(
        sub { test_locale({
            name   => undef,
            query  => {
                new => {
                    version => $version,
                },
                parse => $Query{header}{$version}{'FOO'}
                               {has_no_column},
            },
            result => undef,
        }) },
        qr{Can't parse the header: source language \(FOO\) isn't valid as ISO 639-1 format},
        "exception (invalid source language), $version"
    );
    throws_ok(
        sub { test_locale({
            name   => undef,
            query  => {
                new => {
                    version => $version,
                },
                parse => $Query{header}{$version}{'en-BAR'}
                               {has_no_column},
            },
            result => undef,
        }) },
        qr{Can't parse the header: source region \(BAR\) isn't valid as ISO 3166 format},
        "exception (invalid source region), $version"
    );
    throws_ok(
        sub { test_locale({
            name   => undef,
            query  => {
                new => {
                    version => $version,
                },
                parse => $Query{header}{$version}{'en-US/BAZ'}
                               {has_no_column},
            },
            result => undef,
        }) },
        qr{Can't parse the header: target language \(BAZ\) isn't valid as ISO 639-1 format},
        "exception (invalid target language), $version"
    );
    throws_ok(
        sub { test_locale({
            name   => undef,
            query  => {
                new => {
                    version => $version,
                },
                parse => $Query{header}{$version}{'en-US/ja-QUX'}
                               {has_no_column},
            },
            result => undef,
        }) },
        qr{Can't parse the header: target region \(QUX\) isn't valid as ISO 3166 format},
        "exception (invalid target region), $version"
    );
    throws_ok(
        sub { test_locale({
            name   => undef,
            query  => {
                new => {
                    version => $version,
                },
                parse => $Query{header}{$version}{'en-BAR/ja-QUX'}
                               {has_no_column},
            },
            result => undef,
        }) },
        qr{Can't parse the header: source region \(BAR\) isn't valid as ISO 3166 format},
        "exception (validation order is source > target), $version"
    );
}
