# consult a dictionary for the meanning (lookup the meaning)

use strict;
use warnings;
# use utf8;
use lib 't/lib';

use Test::More tests => 18;
use Test::Exception;
use Test::Warn;
use Test::Text_UTX_Simple;

use Text::UTX::Simple;


# ================================================================
# subroutine for test
# [ 1 test or (1+3 = 4) tests ]
# ----------------------------------------------------------------
sub test_consult {
    my $test_case = shift;

    my $version = $test_case->{version};

    my $utx = Text::UTX::Simple->new({
        %{ $test_case->{query}{new} },
        text => do {
            join "\n", (
                ( split "\n",
                    $Query{header}{$version}{'en/ja'}
                          {has_column} ),
                ( join "\t", qw(src0 tgt00 src:pos00 src:foo00 tgt:bar00) ),
            )
        },
    });

    if ($test_case->{exception}) {  # 1test
        throws_ok( sub { my $error
                            = $utx->consult($test_case->{query}{consult}) },
                   qr{$test_case->{result}},
                   $test_case->{name} );
        return;
    }

    # --------------------------------
    # singular entry
    # [1 test]
    # --------------------------------
    is_deeply( $utx->consult('src0'),
               'tgt00',
               $test_case->{name} . ' consult: 1 entry 1 column' );

    # --------------------------------
    # plural entry
    # [3 tests]
    # --------------------------------
    $utx = Text::UTX::Simple->new({
        %{ $test_case->{query}{new} },
        text => do {
            join "\n", (
                ( split "\n",
                    $Query{header}{$version}{'en/ja'}
                          {has_column} ),
                ( join "\t", qw(src0     tgt00 src:pos00 src:foo00 tgt:bar00) ),
                ( join "\t", '#src1', qw(tgt10 src:pos10 src:foo10 tgt:bar10) ),
                ( join "\t", qw(src1     tgt11 src:pos11 src:foo11 tgt:bar11) ),
                ( join "\t", qw(src1     tgt12 src:pos12 src:foo12 tgt:bar12) ),
                ( join "\t", qw(src2     tgt20 src:pos20 src:foo20 tgt:bar20) ),
            )
        },
    });
    is_deeply( $utx->consult('src0'),
               'tgt00',
               $test_case->{name} . ' consult: 4 entries, 1 column' );
    is_deeply( ( scalar $utx->consult('src1') ),
               'tgt11',             # avoid comment entries
               $test_case->{name} . ' consult: 4 entries, 3 results, '
                                  . 'scalar context = first reuslt' );
    is_deeply( [ $utx->consult('src1') ],
               [qw(tgt11 tgt12)],   # avoid comment entries
               $test_case->{name} . ' consult: 4 entries, 3 results, '
                                  . 'list context = all results' );
}


# ================================================================
# consult, and exception
# [ 12 + 3 = 15tests ]
# ----------------------------------------------------------------
foreach my $version (@Versions) {
    my %version_definition = ( version => $version );

    my $column_number
        = scalar @{ $Query{column}{$version}{array}{all} };

    # normal: 4subtests * 1kind * 3versions = 12tests
    test_consult({
        name    => "version: $version",
        query   => {
            new => \%version_definition,
        },
        version => $version,
        column_number => $column_number,
    });

    # exception: 1subtest * 1kind * 3versions = 3tests
    test_consult({
        name      => "exception: absentee entry, $version",
        exception => 1,
        version   => $version,
        column_number => $column_number,
        query     => {
            new     => \%version_definition,
            consult => 'amazing_absentee_entry_name',
        },
        result    => q{Can't select rows: }
                   . q{entry \(amazing_absentee_entry_name\) doesn't exist},
    });
}


# ================================================================
# warning
# write end of the file, to evade invalid exception
# "Bizarre copy of HASH in sassign at ...../Carp/Heavy.pm line 104."
# [ 1subtest * 3versions = 3tests ]
# ----------------------------------------------------------------
foreach my $version (@Versions) {
    my $utx = Text::UTX::Simple->new({version => $version});
    warning_is
        { $utx->consult('src0') }
        { carped => 'Useless use private variable in void context' }
    ;
}
