use strict;
use warnings;
use utf8;
use lib 't/lib';

use Test::More tests => 256;
# use Test::Exception;
use Test::Warn;
use Test::Text_UTX_Simple;

use Text::UTX::Simple;


# ================================================================
# subroutine for test
# [ 5 tests (+ 5 tests) ]
# ----------------------------------------------------------------
sub test_dump {
    my $test_case = shift;

    my $utx;

    # --------------------------------
    # header only [2 tests / 2+5=7 tests)]
    # --------------------------------
    $utx = Text::UTX::Simple->new($test_case->{query}{new});
    # it is necessary to "\n" also to the final line,
    # if dictionary has no entry
    like( $utx->as_string($test_case->{query}{dump}),
          $test_case->{result},
          $test_case->{name} . ': as string, without option' );
    like( ${ $utx->as_string({
            %{ $test_case->{query}{dump} },
            scalar_ref => 1,
          }) },
          $test_case->{result},
          $test_case->{name} . ': as string, without option' );

    # other option is "scalar"
    if ($test_case->{verbose}) {    # 5 tests
        like( $utx->as_string({
                %{ $test_case->{query}{dump} },
                scalar => 1,
              }),
              $test_case->{result},
              $test_case->{name} . ': as string, without option' );
        like( $utx->as_string({
                %{ $test_case->{query}{dump} },
                array_ref => 1,
              }),
              $test_case->{result},
              $test_case->{name} . ': as string, without option' );
        like( $utx->as_string({
                %{ $test_case->{query}{dump} },
                array => 1,
              }),
              $test_case->{result},
              $test_case->{name} . ': as string, without option' );
        like( $utx->as_string({
                %{ $test_case->{query}{dump} },
                list => 1,
              }),
              $test_case->{result},
              $test_case->{name} . ': as string, without option' );
        like( $utx->as_string({
                %{ $test_case->{query}{dump} },
                foobar => 1,
              }),
              $test_case->{result},
              $test_case->{name} . ': as string, without option' );
    }

    # --------------------------------
    # with body
    # [ 3 tests ]
    # --------------------------------
    my $number_of_header_line = (($test_case->{result}) =~ s{\\n}{\\n}g);
    my @dumped_lines;
    my $body;

    # normal
    $utx = Text::UTX::Simple->new({
        version => $test_case->{query}{new}{version},
        text    => $test_case->{query}{new}{text}
              . do {
                join "\n",
                    ( join "\t", qw(src0     tgt00 src:pos00  foo00 bar00) ),
                    '', # empty line (ignored)
                    ( join "\t", qw(src1     tgt10), q{},  qw(foo10 bar10) ),
                    ( join "\t", '#src1', qw(tgt11 src:pos11  foo11 bar11) ),
                    ( join "\t", qw(src1     tgt12 src:pos12  foo12 bar12) ),
                    ( join "\t", qw(src2     tgt20), q{-}, qw(foo20 bar20) ),
              },
    });
    @dumped_lines  = split "\n", $utx->as_string();
    $body = join "\n",
                @dumped_lines[$number_of_header_line .. $#dumped_lines],
                q{};    # last entry also have "\n" (last line is empty line)
    is( $body,
        do { join "\n",
            ( join "\t", qw(src0     tgt00 src:pos00  foo00 bar00) ),
            ( join "\t", qw(src1     tgt10), q{},  qw(foo10 bar10) ),
            ( join "\t", '#src1', qw(tgt11 src:pos11  foo11 bar11) ),
            ( join "\t", qw(src1     tgt12 src:pos12  foo12 bar12) ),
            ( join "\t", qw(src2     tgt20), q{-}, qw(foo20 bar20) ),
            '',  # last entry also have "\n" (last line is empty line)
        },
        $test_case->{name} . ': as string, middle column is void' );

    # turn complement text on, and influences!
    $utx->set_complement_of_void_value('BLAH_BLAH_BLAH');

    # complement void value q{}
    $utx = Text::UTX::Simple->new({
        version => $test_case->{query}{new}{version},
        text    => $test_case->{query}{new}{text}
              . do {
                join "\n",
                    ( join "\t", qw(src0), q{}, qw(src:pos00  foo00 bar00) ),
              },
    });
    @dumped_lines  = split "\n", $utx->as_string();
    $body = join "\n",
                @dumped_lines[$number_of_header_line .. $#dumped_lines],
                q{};    # last entry also have "\n" (last line is empty line)
    is( $body,
        do { join "\n",
            ( join "\t", qw(src0 BLAH_BLAH_BLAH src:pos00  foo00 bar00) ),
            '',  # last entry also have "\n" (last line is empty line)
        },
        $test_case->{name} . ': as string, middle column is void' );

    # does not complement ineffective value {-}
    $utx = Text::UTX::Simple->new({
        version => $test_case->{query}{new}{version},
        text    => $test_case->{query}{new}{text}
              . do {
                join "\n",
                    ( join "\t", qw(src0 - src:pos00  foo00 bar00) ),
              },
    });
    @dumped_lines  = split "\n", $utx->as_string();
    $body = join "\n",
                @dumped_lines[$number_of_header_line .. $#dumped_lines],
                q{};    # last entry also have "\n" (last line is empty line)
    is( $body,
        do { join "\n",
            ( join "\t", qw(src0 - src:pos00  foo00 bar00) ),
            '',  # last entry also have "\n" (last line is empty line)
        },
        $test_case->{name} . ': as string, middle column is ineffective' );

    $utx->set_complement_of_void_value('');

    return;
}


# ================================================================
# normal
# [ 96 + 15 = 87 tests ]
# [ 5subtests * 2columns * 4locales * 2alignments * 3versions = 240 tests ]
# [ 5subtests * 1column  * 1locale  * 1alignment  * 3versions =  15 tests ]
# ----------------------------------------------------------------
foreach my $version (@Versions) {
    my %version_definition = ( version => $version );
    foreach my $alignment (qw(en en-US/ja-JP)) {
        foreach my $locale (undef, qw(local UTC Asia/Tokyo)) {
            my $locale_key  = defined $locale ? $locale : 'local';
            my %dump_option = defined $locale ? (time_zone => $locale) : ();
            foreach my $column (qw(has_no_column has_column)) {
                test_dump({
                    name    => "normal, $column, $locale_key, $alignment, "
                             . "$version",
                    verbose => $alignment  eq 'en'            &&
                               $locale_key eq 'UTC'           &&
                               $column     eq 'has_no_column',
                    query  => {
                        new  => {
                            %version_definition,
                            text => $Query{header}{$version}{$alignment}
                                          {$column},
                        },
                        dump => \%dump_option,
                    },
                    result => $Result{header}{$version}{$alignment}
                                     {$locale_key}{$column}{say},
                });
            }
        }
    }
}


# ================================================================
# dump as string
# invalid usage: call at void context
# write end of this file, to evade "Bizarre copy of HASH in sassign"
# at Carp::Heavy line 104
# [ 1 test ]
# ----------------------------------------------------------------
{
    my $utx = Text::UTX::Simple->new();
    warning_is
        { $utx->as_string({scalar_ref => 1}) }
        { carped => "Useless use private variable in void context" }
    ;
}
