use strict;
use warnings;
# use utf8;
use lib 't/lib';

use Test::More tests => 51;
use Test::Exception;
# use Test::Warn;
use Test::Text_UTX_Simple;

use Text::UTX::Simple;


# ================================================================
# subroutine for test
# [ 1 test or 4 tests ]
# ----------------------------------------------------------------
sub test_specification {
    my $test_case = shift;

    if ($test_case->{exception}) {  # (0 + 1)
        throws_ok( sub { _make($test_case); },
                   qr{$test_case->{result}},
                   $test_case->{name} );
    }
    else {                          # (1 + 2)
        my $utx = _make($test_case);
        is_deeply( [ @{$utx->{header}}{qw(specification version)} ],
                   [ 'UTX-S', $test_case->{version} ],
                   $test_case->{name} . ': internal' );
        is(        $utx->get_specification(),
                   'UTX-S',
                   $test_case->{name} . ': API, get_specification' );
        my $header_class = ref $utx->{header};
        is(        $header_class->get_specification(),
                   'UTX-S',
                   $test_case->{name} . ' : guess_version');    # monomania
    }

    return;
}

sub _make {
    my $test_case = shift;

    my $utx;

    if ( exists $test_case->{query}{parse} ) {
        $utx = Text::UTX::Simple->new($test_case->{query}{new});
        pass( $utx->parse( $test_case->{query}{parse} ) );
    }
    else {
        pass( $utx = Text::UTX::Simple->new($test_case->{query}{new}) );
    }

    return $utx;
}


# ================================================================
# create, parse
# [ 4subtests * 2kinds * 3versions = 24tests ]
# ----------------------------------------------------------------
foreach my $version (@Versions) {
    my %version_definition = (version => $version);

    test_specification({
        name   => "new : version $version",
        query  => {
            new   => {
                %version_definition,
            },
        },
        version => $version,
    });
    test_specification({
        name   => "parse : version $version",
        query  => {
            new   => {
                version => $version,
            },
            parse => $Query{header}{$version}{'en/ja'}{has_column},
        },
        version => $version,
    });
}


# ================================================================
# exceptioon: create, parse
# [ 1subtest * (6+3)kinds * 3versions = 27tests ]
# ----------------------------------------------------------------
foreach my $version (@Versions) {
    my %version_definition = (version => $version);

    # create 6kinds
    test_specification({
        name      => "UTX-Simple, new : version $version",
        exception => 1,
        query     => {
            new   => {
                %version_definition,
                specification => 'UTX-Simple',
            },
        },
        result    => q{Can't parse the header: }
                   . q{specification \(UTX-Simple\) isn't valid specification},
    });
    test_specification({
        name      => "UTX Simple, new : version $version",
        exception => 1,
        query     => {
            new   => {
                %version_definition,
                specification => 'UTX Simple',
            },
        },
        result    => q{Can't parse the header: }
                   . q{specification \(UTX Simple\) isn't valid specification},
    });
    test_specification({
        name      => "UTX-XML, new : version $version",
        exception => 1,
        query     => {
            new   => {
                %version_definition,
                specification => 'UTX-XML',
            },
        },
        result    => q{Can't parse the header: }
                   . q{specification \(UTX-XML\) isn't valid specification},
    });
    test_specification({
        name      => "version, new : version $version",
        exception => 1,
        query     => {
            new   => {
                %version_definition,
                specification => $version,
            },
        },
        result    => q{Can't parse the header: }
                   . q{specification \(} . $version
                   . q{\) isn't valid specification},
    });
    test_specification({
        name      => "undef, new : version $version",
        exception => 1,
        query     => {
            new   => {
                %version_definition,
                specification => undef,
            },
        },
        result    => q{Can't parse the header: }
                   . q{specification isn't defined},
    });
    test_specification({
        name      => "order = version > specification, new : version $version",
        exception => 1,
        query     => {
            new   => {
                version       => 'foobar',
                specification => undef,
            },
        },
        result    => q{Can't parse the header: }
                   . q{version \(foobar\) isn't numeric},
    });

    # parse 3kinds
    my $string_to_parse;
    ($string_to_parse = $Query{header}{$version}{'en/ja'}{has_column})
        =~ s{ \A (\#) [^ ]+}{$1 . 'UTX-Simple'}xmse;
    test_specification({
        name      => "UTX-Simple, parse : version $version",
        exception => 1,
        query     => {
            new   => \%version_definition,
            parse => $string_to_parse,
        },
        result    => q{Can't parse the header: }
                   . q{specification \(UTX-Simple\) isn't same as UTX-S},
    });
    ($string_to_parse = $Query{header}{$version}{'en/ja'}{has_column})
        =~ s{ \A (\#) [^ ]+}{$1 . 'UTX-XML'}xmse;
    test_specification({
        name      => "UTX-XML, parse : version $version",
        exception => 1,
        query     => {
            new   => \%version_definition,
            parse => $string_to_parse,
        },
        result    => q{Can't parse the header: }
                   . q{specification \(UTX-XML\) isn't same as UTX-S},
    });
    ($string_to_parse = $Query{header}{$version}{'en/ja'}{has_column})
        =~ s{ \A (\#) [^ ]+}{$1 . $version}xmse;
    test_specification({
        name      => "version, parse : version $version",
        exception => 1,
        query     => {
            new   => \%version_definition,
            parse => $string_to_parse,
        },
        result    => q{Can't parse the header: }
                   . q{specification \(} . $version . q{\) isn't same as UTX-S},
    });
}
