use strict;
use warnings;
use utf8;
use lib 't/lib';

use Test::More tests => 42;
use Test::Exception;
# use Test::Warn;
use Test::Text_UTX_Simple qw(:DEFAULT get_dictionary_path);

use Encode qw(encode_utf8);
use Text::UTX::Simple;


# ================================================================
# subroutine for test
# [ 1 test or 3 tests ]
# ----------------------------------------------------------------
sub test_read {
    my $test_case = shift;

    my $version = $test_case->{version};

    if ($test_case->{exception}) {  # (0 + 1)
        throws_ok( sub { _make($test_case); },
                   qr{$test_case->{result}},
                   $test_case->{name} );
    }
    else {                          # (1 + 2)
        my $utx = _make($test_case);
        like(      $utx->dump_header({scalar => 1, say => 1}),
                   $Result{header}{$version}{'en-US/ja-JP'}{'Asia/Tokyo'}
                          {has_column}{file},
                   $test_case->{name} . ' : header' );
        is_deeply( $utx->dump_body({array_ref => 1}),
                   [ [qw(src00     tgt00 pos00 foo00 bar00 baz00 qux00) ],
                     ['#src10', qw(tgt10 pos10 foo10 bar10 baz10 qux10) ],
                     [qw(src10     tgt10 pos10 foo10 bar10 baz10 qux10) ],
                     [qw(src20     tgt20 pos20 foo20 bar20 baz20 qux20) ],
                     [qw(src11     tgt11 pos11 foo11 bar11 baz11 qux11) ],
                     [qw(src21     tgt21 pos21 foo21 bar21 baz21 qux21) ],
                     [('multibyte character',
                       encode_utf8('マルチバイト文字'), # remove BOM
                        'noun',
                       '-', '-', '-', '-'                         ) ],
                     [('Asia-Pacific Association for Machine Translation',
                       encode_utf8('アジア太平洋機械翻訳協会'), # same as above
                       '-',
                       '-', '-', '-', '-'                         ) ], ],
                   $test_case->{name} . ' : entries' );
    }

    return;
}

sub _make {
    my $test_case = shift;

    my $utx;

    if ( exists $test_case->{query}{read} ) {
        $utx = Text::UTX::Simple->new($test_case->{query}{new});
        pass( $utx->read($test_case->{query}{read}) );
    }
    else {
        pass( $utx = Text::UTX::Simple->new($test_case->{query}{new}) );
    }

    return $utx;
}


# ================================================================
# read
# [ 18+24 = 42 tests ]
# ----------------------------------------------------------------
my %path = get_dictionary_path();
foreach my $version (@Versions) {
    my %version_definition = ( version => $version );

    # normal : 3subtests * 2kinds * 3versions = 18tests
    test_read({
        name    => "normal : new + read, version $version",
        query   => {
            new  => \%version_definition,
            read => $path{$version . '_old'},
        },
        version => $version,
    });
    test_read({
        name    => "normal : new, version $version",
        query   => {
            new => {
                %version_definition,
                file => $path{$version . '_old'},
            },
        },
        version => $version,
    });

    # exceptions: 1subtest * 8kinds * 3versions = 24tests
    test_read({
        name      => "exception (invalid) : new + read, version $version",
        exception => 1,
        query     => {
            new  => \%version_definition,
            read => $path{$version . '_invalid'},
        },
        result    => q{Can't guess version: }
                   . q{specified string has no version kind string},
        version   => $version,
    });
    test_read({
        name      => "exception (invalid) : new, version $version",
        exception => 1,
        query     => {
            new  => {
                %version_definition,
                file => $path{$version . '_invalid'},
            },
        },
        result    => q{Can't guess version: }
                   . q{specified string has no version kind string},
        version   => $version,
    });
    test_read({
        name      => "exception (unexist) : new + read, version $version",
        exception => 1,
        query     => {
            new  => \%version_definition,
            read => $path{unexist},
        },
        result    => q{Can't read the file \(.+?\): }
                   . q{sysopen: No such file or directory},
        version   => $version,
    });
    test_read({
        name      => "exception (unexist) : new, version $version",
        exception => 1,
        query     => {
            new  => {
                %version_definition,
                file => $path{unexist},
            },
        },
        result    => q{Can't read the file \(.+?\): }
                   . q{sysopen: No such file or directory},
        version   => $version,
    });
    test_read({
        name      => "exception (undef) : new + read, version $version",
        exception => 1,
        query     => {
            new  => \%version_definition,
            read => undef,
        },
        result    => q{Can't read the dictionary: }
                   . q{filename isn't defined or is empty},
        version   => $version,
    });
    test_read({
        name      => "exception (undef) : new, version $version",
        exception => 1,
        query     => {
            new  => {
                %version_definition,
                file => undef,
            },
        },
        result    => q{Can't read the dictionary: }
                   . q{filename isn't defined or is empty},
        version   => $version,
    });
    test_read({
        name      => "exception (empty) : new + read, version $version",
        exception => 1,
        query     => {
            new  => \%version_definition,
            read => q{},
        },
        result    => q{Can't read the dictionary: }
                   . q{filename isn't defined or is empty},
        version   => $version,
    });
    test_read({
        name      => "exception (empty) : new, version $version",
        exception => 1,
        query     => {
            new  => {
                %version_definition,
                file => q{},
            },
        },
        result    => q{Can't read the dictionary: }
                   . q{filename isn't defined or is empty},
        version   => $version,
    });
}
