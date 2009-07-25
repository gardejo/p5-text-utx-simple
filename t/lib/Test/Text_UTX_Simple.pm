package Test::Text_UTX_Simple;

# QUICK AND DIRTY!
# to do: refactoring and optimizing(use memoize)


# ****************************************************************
# pragmas
# ****************************************************************

use 5.008_006;
use strict;
use warnings;
use utf8;


# ****************************************************************
# superclasses
# ****************************************************************

use base qw(Exporter);


# ****************************************************************
# dependencies
# ****************************************************************

use Cwd;
use List::MoreUtils qw(mesh);
use Regexp::Common qw(time);
use Storable qw(dclone);


# ****************************************************************
# package global symbols
# ****************************************************************

our @EXPORT      = qw(
    @Versions
    @Time_Zones
    %Query
    %Pattern
    %Result
    %Regularized
    %Index_Of    %Name_Of
    %Delimiter   %Special_Value
    %Parser      %Dumper
    get_latest_version
    is_compatible_version
);
our @EXPORT_OK   = qw(
    get_dictionary_path
);
our %EXPORT_TAGS = ();


our $VERSION       = '0.02_00';
# our @Versions      = (qw(0.90 0.91 0.92), undef);
our @Versions      = qw(0.90 0.91 0.92);
my $Latest_Version = '0.92';

sub get_latest_version {
    return $Latest_Version;
}

# true (1) is compatible
# false (0) is explicit error
# false (undef) is parse error (ex. 0.90 as 0.91)
my %Compatible_Table = (
    '0.90' => {                  '0.91' => undef, '0.92' => undef, },
    '0.91' => { '0.90' => undef,                  '0.92' => 1,     },
    '0.92' => { '0.90' => undef, '0.91' => 1,                      },
);
sub is_compatible_version {
    return $Compatible_Table{$_[0]}{$_[1]};
}

our @Time_Zones    = (
    undef, qw(local UTC America/New_York Europe/London Asia/Tokyo)
);
our %Regularized   = %{make_regularized()};
our %Index_Of      = %{make_index_of()};
our %Name_Of       = reverse %Index_Of;
our %Pattern       = %{make_pattern()},
our %Delimiter     = (
    column => "\t",
    line   => "\n",
);
our %Special_Value = (
    ineffective => q{-},
    void        => q{},
);
our %Query         = (
    header => make_query_header(),
    column => make_query_column(),
    last_updated => {
        'UTC'
            => q{2009-02-13T23:31:30Z},
        # 'America/New_York'
        #     => q{2009-02-13T18:31:30-05:00},
        # ...
        'slash'
            => q{2009/02/13T23:31:30Z},
    },
    body   => {},
    text   => {},
);
our %Result        = (
    header => make_result_header(),
    column => make_result_column(),
    last_updated => { # time(1234567890)
        'local'
            => q{2009-02-1[34]T}
             . $RE{time}{tf}{-pat => q{hh:mm{in}:ss} }
             . '[\+\-]\d{2}:?\d{2}',
        'UTC'
            => q{2009-02-13T23:31:30}
             . 'Z',
        'America/New_York'
            => q{2009-02-13T18:31:30}
             . '\-05:?00',
        'Europe/London'
            => q{2009-02-13T23:31:30}
             . '\+00:?00',
        'Asia/Tokyo'
            => q{2009-02-14T08:31:30}
             . '\+09:?00',
    },
    body   => {},
    text   => {},
);
our %Parser        = %{ make_parser_test_case() };
our %Dumper        = %{ make_dumper_test_case() };


# ================================================================
# Purpose    : ???
# Usage      : ???
# Parameters : ???
# Returns    : ???
# Throws     : ??? / no exceptions
# Comments   : none
# See Also   : n/a
# ----------------------------------------------------------------
sub make_regularized {
    my %regularized = (
        '0.90' => {
            'src'     => 'source',     'tgt'     => 'target',
            'src:pos' => 'pos',
            'src:foo' => 'source:foo', 'tgt:bar' => 'target:bar',
            '5(UNDEFINED)' => '5(UNDEFINED)',
            '6(UNDEFINED)' => '6(UNDEFINED)',
        },
        '0.91' => {
            'src'     => 'src',        'tgt'     => 'tgt',
            'src:pos' => 'src:pos',
            'src:foo' => 'src:foo',    'tgt:bar' => 'tgt:bar',
            'comment' => 'comment',
            '5(UNDEFINED)' => '5(UNDEFINED)',
            '6(UNDEFINED)' => '6(UNDEFINED)',
        },
    );
    %regularized = (
        %regularized,
        '0.92'   => $regularized{'0.91'},
        'latest' => $regularized{'0.91'},
    );

    return \%regularized;
}


# ================================================================
# Purpose    : ???
# Usage      : ???
# Parameters : ???
# Returns    : ???
# Throws     : ??? / no exceptions
# Comments   : none
# See Also   : n/a
# ----------------------------------------------------------------
sub make_index_of {
    return {
        'src'     => 0,
        'tgt'     => 1,
        'src:pos' => 2,
        'src:foo' => 3,
        'tgt:bar' => 4,
        # 'baz'     => 5,
        # 'qux'     => 6,
        '5(UNDEFINED)' => 5,
        '6(UNDEFINED)' => 6,
    };
}


# ================================================================
# Purpose    : ???
# Usage      : ???
# Parameters : ???
# Returns    : ???
# Throws     : ??? / no exceptions
# Comments   : none
# See Also   : n/a
# ----------------------------------------------------------------
sub make_pattern {
    return {
        last_updated => {
            'local'
                => $RE{time}{tf}{-pat => q{yyyy-mm{on}-ddThh:mm{in}:ss}}
                 . '[\+\-]'
                 . $RE{time}{tf}{-pat => q{mm{in}}                     }
                 . ':?'
                 . $RE{time}{tf}{-pat => q{ss}                         },
            'UTC'
                => $RE{time}{tf}{-pat => q{yyyy-mm{on}-ddThh:mm{in}:ss}}
                 . 'Z',
            'America/New_York'      # EST(-05:00) or EDT(-04:00)
                => $RE{time}{tf}{-pat => q{yyyy-mm{on}-ddThh:mm{in}:ss}}
                 . '\-0[54]:?00',
            'Europe/London'         # GMT(+00:00) or BST(+01:00)
                => $RE{time}{tf}{-pat => q{yyyy-mm{on}-ddThh:mm{in}:ss}}
                 . '\+0[01]:?00',
            'Asia/Tokyo'            # JST(+09:00), Japan does not introduce DST
                => $RE{time}{tf}{-pat => q{yyyy-mm{on}-ddThh:mm{in}:ss}}
                 . '\+09:?00',
        },
    };
}

# ================================================================
# Purpose    : ???
# Usage      : ???
# Parameters : ???
# Returns    : ???
# Throws     : ??? / no exceptions
# Comments   : none
# See Also   : n/a
# ----------------------------------------------------------------
sub make_query_header {
    my %query;

    my $sequence_time = q{2009-02-14T08:31:30+09:00};

    VERSION:
    foreach my $version (@Versions) {
        foreach my $alignment qw(
            en       en/ja    en/ja-JP
            en-US en-US/ja en-US/ja-JP
            FOO   en-BAR   en-US/BAZ   en-US/ja-QUX en-BAR/ja-QUX
        ) {
            if ($version < 0.91) {
                $query{$version}{$alignment}{lack}
                    = qq{#UTX-S $version $alignment\n};
                my $basic = qq{#UTX-S $version $alignment $sequence_time};
                $query{$version}{$alignment}{has_no_column}
                    = $basic
                    . "\n";
                $query{$version}{$alignment}{has_column}
                    = $basic
                    . q{ source:foo/target:bar}
                    . "\n";
                $query{$version}{$alignment}{duplicated} = {
                    user  => $basic
                           . q{ source:foo/bar/foo}
                           . "\n",
                    basic => $basic
                           . q{ source:foo/pos}
                           . "\n",
                };
                $query{$version}{$alignment}{fuzzy} = {
                    empty => $basic
                           . q{ source:/target:foo/bar}
                           . "\n",
                    space => $basic
                           . q{ source: /target:foo/bar}
                           . "\n",
                };
            }
            else {
                $query{$version}{$alignment}{lack}
                    = qq{#UTX-S $version; $alignment\n}
                    . qq{#src\ttgt\tsrc:pos\n};
                # $query{$version}{$alignment}{lack}
                #     = qq{#UTX-S $version; $alignment\n;}
                #     . qq{#src\ttgt\tsrc:pos\n};
                # is last_update is undef,
                # therefore, exception was thrown by validate()!!
                $query{$version}{$alignment}{mandatory_only}{without_semicolon}
                    = qq{#UTX-S $version; $alignment; $sequence_time}
                    . qq{\n}
                    . qq{#src\ttgt\tsrc:pos\n};
                $query{$version}{$alignment}{mandatory_only}{with_semicolon}
                    = qq{#UTX-S $version; $alignment; $sequence_time;}
                    . qq{\n}
                    . qq{#src\ttgt\tsrc:pos\n};
                my $basic = qq{#UTX-S $version; $alignment; $sequence_time;}
                          .  q{ foo: bar; baz: qux;}
                          . qq{\n}
                          . qq{#src\ttgt\tsrc:pos};
                $query{$version}{$alignment}{has_no_column}
                    = $basic
                    . "\n";
                $query{$version}{$alignment}{has_column}
                    = $basic
                    . qq{\tsrc:foo\ttgt:bar\tcomment}
                    . "\n";
                $query{$version}{$alignment}{duplicated} = {
                    user  => $basic
                           . qq{\tsrc:foo\tsrc:bar\tsrc:foo}
                           . "\n",
                    basic => $basic
                           . qq{\tsrc:foo\tsrc:pos}
                           . "\n",
                };
            }
        }
    }

    return \%query;
}

# ================================================================
# Purpose    : ???
# Usage      : ???
# Parameters : ???
# Returns    : ???
# Throws     : ??? / no exceptions
# Comments   : none
# See Also   : n/a
# ----------------------------------------------------------------
sub make_query_column {
    my %column;

    VERSION:
    foreach my $version (@Versions) {
        if ($version < 0.91) {
            $column{$version}{array}{user}{full}
                = [ qw(source:foo target:bar) ];
            $column{$version}{scalar}{user}{full}
                = join '/', @{ $column{$version}{array}{user}{full} };
            $column{$version}{array}{basic}
                = [ qw(source target pos) ];
            $column{$version}{array}{all}
                = [ @{ $column{$version}{array}{basic}      },
                    @{ $column{$version}{array}{user}{full} } ];
            $column{$version}{scalar}{all}
                = 'source/target/pos/source:foo/target:bar';
            $column{$version}{array}{duplicated} = {
                user    => [ qw(source:foo source:bar source:foo) ],
                basic   => [ qw(source:foo source:pos) ],
                # regular => [ qw(src:pos src:foo) ], # language 'source:'
                # regular => [ qw(pos src:foo) ],     # language 'source:'
            };
            $column{$version}{scalar}{duplicated} = {
                user    => 'source:foo/bar/foo',
                basic   => 'source:foo/pos',
            };
            $column{$version}{scalar}{fuzzy} = {
                empty   => 'source:/target:foo/bar',
                space   => 'source: /target:foo/bar',
            };
        }
        else {
            $column{$version}{array}{user}{full}
                = [ qw(src:foo tgt:bar comment) ];
            $column{$version}{array}{user}{simple}
                = [ qw(comment) ];
            $column{$version}{scalar}{user}{full}
                = join "\t", @{ $column{$version}{array}{user}{full} };
            $column{$version}{scalar}{user}{simple}
                = join "\t", @{ $column{$version}{array}{user}{simple} };
            $column{$version}{array}{basic}
                = [ qw(src tgt src:pos) ];
            $column{$version}{array}{all}
                = [ @{ $column{$version}{array}{basic}      },
                    @{ $column{$version}{array}{user}{full} } ];
            $column{$version}{scalar}{all}
                = join "\t", @{ $column{$version}{array}{all} };
            $column{$version}{scalar}{lacked}
                = join "\t", qw(src:foo);
            $column{$version}{array}{duplicated} = {
                user    => [ qw(src tgt src:pos),
                             qw(src:foo src:bar src:foo) ],
                basic   => [ qw(src tgt src:pos),
                             qw(src:foo src:pos) ],
            };
            $column{$version}{scalar}{duplicated} = {
                user    => do { join "\t",
                            @{ $column{$version}{array}{duplicated}{user}  } },
                basic   => do { join "\t", 
                            @{ $column{$version}{array}{duplicated}{basic} } },
            };
        }
    }

    return \%column;
}

# ================================================================
# Purpose    : ???
# Usage      : ???
# Parameters : ???
# Returns    : ???
# Throws     : ??? / no exceptions
# Comments   : none
# See Also   : n/a
# ----------------------------------------------------------------
sub make_result_header {
    my %result;

    VERSION:
    foreach my $version (@Versions) {
        (my $escaped_version = $version) =~ tr{.}{\.};

        foreach my $alignment qw(
            en       en/ja    en/ja-JP
            en-US en-US/ja en-US/ja-JP
        ) {
            while (
                my ($locale, $last_updated) = each %{$Pattern{last_updated}}
            ) {
                if ($version < 0.91) {
                    my $pattern = q{ \A \# \s* UTX-S \s* }
                                . $escaped_version . q{ \s* }
                                . $alignment       . q{ \s* }
                                . $last_updated;
                    $result{$version}{$alignment}{$locale}{has_no_column} = {
                        say   => qr{ $pattern \r?\n \z }xms,
                        print => qr{ $pattern       \z }xms,
                        file  => qr{ $pattern \r?\n \z }xms,
                    };
                    $pattern .= q{ \s+ source: \s* foo \s* / }
                             .  q{ \s* target: \s* bar };
                    $result{$version}{$alignment}{$locale}{has_column} = {
                        say   => qr{ $pattern \r?\n \z }xms,
                        print => qr{ $pattern       \z }xms,
                        file  => qr{ $pattern
                                     \s* / \s*
                                     baz
                                     \r?\n \z          }xms,
                    };
                }
                else {
                    my $pattern1 = q{ \A \# \s* UTX-S \s }
                                 . $escaped_version . q{ \s* ; \s* }
                                 . $alignment       . q{ \s* ; \s* }
                                 . $last_updated    . q{ \s* ; \s* }
                                 . q{ foo \s* : \s* bar \s* ; \s* }
                                 . q{ baz \s* : \s* qux \s* ;? };
                    my $file     = q{ \A \# \s* UTX-S \s }
                                 . $escaped_version . q{ \s* ; \s* }
                                 . $alignment       . q{ \s* ; \s* }
                                 . $last_updated    . q{ \s* ; \s* }
                                 . q{ copyright \s* : \s* [^;]+ ; \s* }
                                 . q{ license   \s* : \s* [^;]+ ;?    };
                    my $pattern2 = q{ \# \s* src \t tgt \t src:pos };
                    $result{$version}{$alignment}{$locale}{has_no_column} = {
                        say   => qr{ $pattern1 \r?\n $pattern2 \r?\n \z }xms,
                        print => qr{ $pattern1       $pattern2       \z }xms,
                        file  => qr{ $file     \r?\n $pattern2 \r?\n \z }xms,
                    };
                    $pattern2 .= q{ \t src:foo \t tgt:bar \t comment };
                    $result{$version}{$alignment}{$locale}{has_column} = {
                        say   => qr{ $pattern1 \r?\n $pattern2 \r?\n \z }xms,
                        print => qr{ $pattern1       $pattern2       \z }xms,
                        file  => qr{ $file     \r?\n $pattern2 \r?\n \z }xms,
                    };
                }
            }
        }
    }

    return \%result;
}

# ================================================================
# Purpose    : ???
# Usage      : ???
# Parameters : ???
# Returns    : ???
# Throws     : ??? / no exceptions
# Comments   : none
# See Also   : n/a
# ----------------------------------------------------------------
sub make_result_column {
    my %column;

    VERSION:
    foreach my $version (@Versions) {
        $column{$version}{has_no_column}{hash} = {
            # basic => { mesh @basic, @{[0 .. $#basic]} },
            basic => {'src' => 0, 'tgt' => 1, 'src:pos' => 2},
            user  => {},
        };
        $column{$version}{has_column}{hash} = {
            basic => $column{$version}{has_no_column}{hash}{basic},
            user  => {'src:foo' => 3, 'tgt:bar' => 4},
            # user  => { mesh @user, @{[$#basic + 1 .. $#basic + 1 + $#user]} },
        };
        $column{$version}{has_simple_column}{hash} = {
            basic => $column{$version}{has_no_column}{hash}{basic},
            user  => {'comment' => 3,},
        };

        my (@basic, @user_full, @user_simple);
        if ($version < 0.91) {
            @basic     = qw(source target pos);
            @user_full = qw(source:foo target:bar);
            $column{$version}{fuzzy}{list}
                = [@basic, qw(target:foo target:bar)];
            $column{$version}{fuzzy}{hash} = {
                basic => $column{$version}{has_no_column}{hash}{basic},
                user  => {'tgt:foo' => 3, 'tgt:bar' => 4},
            };
        }
        else {
            @basic       = qw(src tgt src:pos);
            @user_full   = qw(src:foo tgt:bar comment);
            @user_simple = qw(comment);
            $column{$version}{has_column}{hash}{user} = {
                %{ $column{$version}{has_column}{hash}{user} },
                'comment' => 5,
            };
            $column{$version}{has_simple_column}{list}
                = [@basic, @user_simple];
        }
        $column{$version}{has_no_column}{list} = \@basic;
        $column{$version}{has_column}{list}    = [@basic, @user_full];
    }

    return \%column;
}

# ================================================================
# Purpose    : ???
# Usage      : ???
# Parameters : ???
# Returns    : ???
# Throws     : ??? / no exceptions
# Comments   : none
# See Also   : n/a
# ----------------------------------------------------------------
sub make_parser_test_case {
    my %test_case;

    my @normal_cases = (
        {
            name   => '1 line',
            query  => [
                [ qw(src0
                     tgt0 src:pos0 src:foo0 tgt:bar0 baz0 qux0) ],
            ],
            result => {
              entries => [
                {
                  is_comment => q{},
                  columns
                    => [ qw(src0
                            tgt0 src:pos0 src:foo0 tgt:bar0 baz0 qux0) ],
                },
              ],
              entry   => {
                'src0' => [0],
              },
              number_of_entries => 1,
              line_of_body      => 1,
            },
        },
        {
            name  => '1 line, includes ineffective value at final column',
            query => [
                [ qw(src0
                     tgt0 pos0 src:foo0 tgt:bar0),
                  $Special_Value{ineffective} ],
            ],
            result => {
              entries => [
                {
                  is_comment => q{},
                  columns
                    => [ qw(src0
                            tgt0 pos0 src:foo0 tgt:bar0),
                         $Special_Value{ineffective} ],
                },
              ],
              entry   => {
                'src0' => [0],
              },
              number_of_entries => 1,
              line_of_body      => 1,
            },
        },
        {
            name  => '1 line, includes ineffective value at middle column',
            query => [
                [ qw(src0
                     tgt0 pos0 src:foo0),
                  $Special_Value{ineffective},
                  qw(tgt:bar0) ],
            ],
            result => {
              entries => [
                {
                  is_comment => q{},
                  columns
                    => [ qw(src0
                            tgt0 pos0 src:foo0),
                         $Special_Value{ineffective},
                         qw(tgt:bar0) ],
                },
              ],
              entry   => {
                'src0' => [0],
              },
              number_of_entries => 1,
              line_of_body      => 1,
            },
        },
        # caveat: ignore set_complement_of_void_value() at parse!
        {
            name  => '1 line, includes void value at final column (regard)',
            query => [
                [ qw(src0
                     tgt0 pos0 src:foo0 tgt:bar0),
                  $Special_Value{void} ],
            ],
            result => {
              entries => [
                {
                  is_comment => q{},
                  columns
                    => [ qw(src0
                            tgt0 pos0 src:foo0 tgt:bar0),
                         $Special_Value{void} ],
                },
              ],
              entry   => {
                'src0' => [0],
              },
              number_of_entries => 1,
              line_of_body      => 1,
            },
        },
        {
            name  => '1 line, includes void value at middle column (regard)',
            query => [
                [ qw(src0
                     tgt0 pos0 src:foo0),
                  $Special_Value{void},
                  qw(tgt:bar0), ],
            ],
            result => {
              entries => [
                {
                  is_comment => q{},
                  columns
                    => [ qw(src0
                            tgt0 pos0 src:foo0),
                         $Special_Value{void},
                         qw(tgt:bar0), ],
                },
              ],
              entry   => {
                'src0' => [0],
              },
              number_of_entries => 1,
              line_of_body      => 1,
            },
        },
        {
            name   => '2 lines',
            query  => [
                [ qw(src0
                     tgt0 src:pos0 src:foo0 tgt:bar0 baz0 qux0) ],
                [ qw(src1
                     tgt1 src:pos1 src:foo1 tgt:bar1 baz1 qux1) ],
            ],
            result => {
              entries => [
                {
                  is_comment => q{},
                  columns
                    => [ qw(src0
                            tgt0 src:pos0 src:foo0 tgt:bar0 baz0 qux0) ],
                },
                {
                  is_comment => q{},
                  columns
                    => [ qw(src1
                            tgt1 src:pos1 src:foo1 tgt:bar1 baz1 qux1) ],
                },
              ],
              entry   => {
                'src0' => [0],
                'src1' => [1],
              },
              number_of_entries => 2,
              line_of_body      => 2,
            },
        },
        {
            name   => '2 lines (same headword)',
            query  => [
                [ qw(src0
                     tgt00 src:pos00 src:foo00 tgt:bar00 baz00 qux00) ],
                [ qw(src0
                     tgt01 src:pos01 src:foo01 tgt:bar01 baz01 qux01) ],
            ],
            result => {
              entries => [
                {
                  is_comment => q{},
                  columns
                    => [ qw(src0
                            tgt00 src:pos00 src:foo00 tgt:bar00 baz00 qux00) ],
                },
                {
                  is_comment => q{},
                  columns
                    => [ qw(src0
                            tgt01 src:pos01 src:foo01 tgt:bar01 baz01 qux01) ],
                },
              ],
              entry   => {
                'src0' => [0, 1],
              },
              number_of_entries => 2,
              line_of_body      => 2,
            },
        },
        {
            name   => '1 comment line',
            query  => [
                [ '#src0',
                  qw(tgt0 src:pos0 src:foo0 tgt:bar0 baz0 qux0) ],
            ],
            result => {
              entries => [
                {
                  is_comment => 1,
                  columns
                    => [ qw(src0
                            tgt0 src:pos0 src:foo0 tgt:bar0 baz0 qux0) ],
                },
              ],
              entry   => {},
              number_of_entries => 0,
              line_of_body      => 1,
            },
        },
        {
            name   => '2 lines and include 1 blank line',
            query  => [
                [ qw(src0
                     tgt0 src:pos0 src:foo0 tgt:bar0 baz0 qux0) ],
                [],
                [ qw(src1
                     tgt1 src:pos1 src:foo1 tgt:bar1 baz1 qux1) ],
            ],
            result => {
              entries => [
                {
                  is_comment => q{},
                  columns
                    => [ qw(src0
                            tgt0 src:pos0 src:foo0 tgt:bar0 baz0 qux0) ],
                },
                {
                  is_comment => q{},
                  columns
                    => [ qw(src1
                            tgt1 src:pos1 src:foo1 tgt:bar1 baz1 qux1) ],
                },
              ],
              entry   => {
                'src0' => [0],
                'src1' => [1],
              },
              number_of_entries => 2,
              line_of_body      => 2,
            },
        },
        {
            name   => '2 lines (same headword) and 1 comment line',
            query  => [
                [ qw(src0
                     tgt00 src:pos00 src:foo00 tgt:bar00 baz00 qux00) ],
                [ '#src0',
                  qw(tgt01 src:pos01 src:foo01 tgt:bar01 baz01 qux01) ],
                [ qw(src0
                     tgt02 src:pos02 src:foo02 tgt:bar02 baz02 qux02) ],
            ],
            result => {
              entries => [
                {
                  is_comment => q{},
                  columns
                    => [ qw(src0
                            tgt00 src:pos00 src:foo00 tgt:bar00 baz00 qux00) ],
                },
                {
                  is_comment => 1,
                  columns
                    => [ qw(src0
                            tgt01 src:pos01 src:foo01 tgt:bar01 baz01 qux01) ],
                },
                {
                  is_comment => q{},
                  columns
                    => [ qw(src0
                            tgt02 src:pos02 src:foo02 tgt:bar02 baz02 qux02) ],
                },
              ],
              entry   => {
                'src0' => [0, 2],
              },
              number_of_entries => 2,
              line_of_body      => 3,
            },
        },
        {
            name   => '1 line (Inf)',
            query  => [
                [ qw(Inf
                     tgt00 src:pos00 src:foo00 tgt:bar00 baz00 qux00) ],
            ],
            result => {
              entries => [
                {
                  is_comment => q{},
                  columns
                    => [ qw(Inf
                            tgt00 src:pos00 src:foo00 tgt:bar00 baz00 qux00) ],
                },
              ],
              entry   => {
                'Inf' => [0],
              },
              number_of_entries => 1,
              line_of_body      => 1,
            },
        },
        {
            name   => '1 line (Infinity)',
            query  => [
                [ qw(Infinity
                     tgt00 src:pos00 src:foo00 tgt:bar00 baz00 qux00) ],
            ],
            result => {
              entries => [
                {
                  is_comment => q{},
                  columns
                    => [ qw(Infinity
                            tgt00 src:pos00 src:foo00 tgt:bar00 baz00 qux00) ],
                },
              ],
              entry   => {
                'Infinity' => [0],
              },
              number_of_entries => 1,
              line_of_body      => 1,
            },
        },
    );

    foreach my $normal_case (@normal_cases) {
        foreach my $line (@{ $normal_case->{query} }) {
            $line = join $Delimiter{column}, @$line;
        }
    }

    $test_case{normal}{scalar} = dclone \@normal_cases;
    foreach my $scalar_case (@{ $test_case{normal}{scalar} }) {
        $scalar_case->{query}
            = join $Delimiter{line}, @{ $scalar_case->{query} };
    }

    $test_case{normal}{array_ref} = dclone \@normal_cases;
    foreach my $array_ref_case (@{ $test_case{normal}{array_ref} }) {
        $array_ref_case->{query} = [
            @{ $array_ref_case->{query} },
        ];
    }

    # making method of "list"       is "on-the-fly dereference"
    # making method of "scalar_ref" is "on-the-fly   reference"

    my @warning_cases = (
        {
            name  => 'ineffective value at first column',
            query => [
                [ $Special_Value{ineffective}, qw(tgt0 pos0 foo0 bar0)]
            ],
            result => {
                message => q{Can't parse an entry: }
                        .  q{headword (first column) is void or }
                        .  q{is ineffective, }
                        .  q{therefore, specified line (2) was skipped},
                entries => [],
                entry   => {},
            },
        },
        {
            name  => 'ineffective value at first column, and normal row',
            query => [
                [ $Special_Value{ineffective}, qw(tgt0 pos0 foo0 bar0)],
                [ qw(src1 tgt1 pos1 foo1 bar1) ],
            ],
            result => {
                message => q{Can't parse an entry: }
                        .  q{headword (first column) is void or }
                        .  q{is ineffective, }
                        .  q{therefore, specified line (2) was skipped},
                entries => [
                    {
                        is_comment => q{},
                        columns
                            => [ qw(src1 tgt1 pos1 foo1 bar1) ],
                    },
                ],
                entry   => {
                    src1 => [ 0 ],
                },
            },
        },
        {
            name  => 'number at first column',
            query => [
                [ qw(42 tgt0 pos0 foo0 bar0) ],
            ],
            result => {
                message => q{Can't parse an entry: }
                        .  q{headword (first column) looks like number, }
                        .  q{therefore, specified line (2) was skipped},
                entries => [],
                entry   => {},
            },
        },
    );

    foreach my $warning_case (@warning_cases) {
        foreach my $line (@{ $warning_case->{query} }) {
            $line = join $Delimiter{column}, @$line;
        }
    }

    $test_case{warning}{scalar} = dclone \@warning_cases;
    foreach my $scalar_case (@{ $test_case{warning}{scalar} }) {
        $scalar_case->{query}
            = join $Delimiter{line}, @{ $scalar_case->{query} };
    }

    $test_case{warning}{array_ref} = dclone \@warning_cases;
    foreach my $array_ref_case (@{ $test_case{warning}{array_ref} }) {
        $array_ref_case->{query} = [
            @{ $array_ref_case->{query} },
        ];
    }

    # making method of "list"       is "on-the-fly dereference"
    # making method of "scalar_ref" is "on-the-fly   reference"

    return \%test_case;
}

# ================================================================
# Purpose    : ???
# Usage      : ???
# Parameters : ???
# Returns    : ???
# Throws     : ??? / no exceptions
# Comments   : none
# See Also   : n/a
# ----------------------------------------------------------------
sub make_dumper_test_case {
    my %test_case;

    my @results = (
        [
            { is_comment => q{},
              columns    => [ qw(src0
                                 tgt0 src:pos0 src:foo0 tgt:bar0 baz0 qux0) ] },
        ],
        [
            { is_comment => q{},
              columns    => [ qw(src0
                                 tgt0 pos0 src:foo0 tgt:bar0),
                              $Special_Value{ineffective} ] },
        ],
        [
            { is_comment => q{},
              columns    => [ qw(src0
                                 tgt0 pos0 src:foo0),
                              $Special_Value{ineffective},
                              qw(tgt:bar0) ] },
        ],
        [
            { is_comment => q{},
              columns    => [ qw(src0
                                 tgt0 pos0 src:foo0 tgt:bar0),
                              $Special_Value{void} ] },
        ],
        [
            { is_comment => q{},
              columns    => [ qw(src0
                                 tgt0 pos0 src:foo0),
                              $Special_Value{void},
                              qw(tgt:bar0) ] },
        ],
        [
            { is_comment => q{},
              columns    => [ qw(src0
                                 tgt0 src:pos0 src:foo0 tgt:bar0 baz0 qux0) ] },
            { is_comment => q{},
              columns    => [ qw(src1
                                 tgt1 src:pos1 src:foo1 tgt:bar1 baz1 qux1) ] },
        ],
        [
            { is_comment => q{},
              columns    => [ qw(src0
                                 tgt00 src:pos00
                                 src:foo00 tgt:bar00 baz00 qux00) ] },
            { is_comment => q{},
              columns    => [ qw(src0
                                 tgt01 src:pos01
                                 src:foo01 tgt:bar01 baz01 qux01) ] },
        ],
        [
            { is_comment => 1,
              columns    => [ qw(src0
                                 tgt0 src:pos0 src:foo0 tgt:bar0 baz0 qux0) ] },
        ],
        [
            { is_comment => q{},
              columns    => [ qw(src0
                                 tgt0 src:pos0 src:foo0 tgt:bar0 baz0 qux0) ] },
            { is_comment => q{},
              columns    => [ qw(src1
                                 tgt1 src:pos1 src:foo1 tgt:bar1 baz1 qux1) ] },
        ],
        [
            { is_comment => q{},
              columns    => [ qw(src0
                                 tgt00 src:pos00
                                 src:foo00 tgt:bar00 baz00 qux00) ] },
            { is_comment => 1,
              columns    => [ qw(src0
                                 tgt01 src:pos01
                                 src:foo01 tgt:bar01 baz01 qux01) ] },
            { is_comment => q{},
              columns    => [ qw(src0
                                 tgt02 src:pos02
                                 src:foo02 tgt:bar02 baz02 qux02) ] },
        ],
        [
            { is_comment => q{},
              columns    => [ qw(Inf
                                 tgt00 src:pos00
                                 src:foo00 tgt:bar00 baz00 qux00) ] },
        ],
        [
            { is_comment => q{},
              columns    => [ qw(Infinity
                                 tgt00 src:pos00
                                 src:foo00 tgt:bar00 baz00 qux00) ] },
        ],
    );

    my $index = 0;
    foreach my $result (@results) {
        # scalar (& scalarref)
        my $result_for_scalar = dclone $result;
        my @lines_for_scalar;
        LINE:
        foreach my $line (@$result_for_scalar) {
            next LINE
                unless @{ $line->{columns} };
            push @lines_for_scalar, do { $line->{is_comment} ? '#' : '' }
                                  . do { join "\t", @{ $line->{columns} } };
        }
        push @{ $test_case{normal}{scalar} }, {
            name   => $Parser{normal}{scalar}[$index]{name},
            query  => $Parser{normal}{scalar}[$index]{query},
            result => do { join "\n", @lines_for_scalar },
        };

        # arrayref (& list)
        my $result_for_arrayref = dclone $result;
        my @lines_for_arrayref;
        foreach my $line (@$result_for_arrayref) {
            if ($line->{is_comment}) {
                $line->{columns}[0] = '#' . $line->{columns}[0];
            }
            push @lines_for_arrayref, $line->{columns};
        }
        push @{ $test_case{normal}{array_ref} }, {
            name   => $Parser{normal}{scalar}[$index]{name},
            query  => $Parser{normal}{scalar}[$index]{query},
            result => \@lines_for_arrayref,
        };

        # hashref (& hash)
        my $result_for_hashref = dclone $result;
        my %result_for_hashref;
        my $name_of = dclone \%Name_Of;
        foreach my $line (@$result_for_hashref) {
            if ($line->{is_comment}) {
                $line->{columns}[0] = '#' . $line->{columns}[0];
            }
        }
        foreach my $version (@Versions) {
            if ($version >= 0.91) {
                $name_of->{5} = 'comment',
                $name_of->{6} = '6(UNDEFINED)';
            }
            my @lines_for_hashref;
            foreach my $line (@$result_for_hashref) {
                my %column;
                foreach my $index (0 .. $#{ $line->{columns} }) {
                    $column{ $Regularized{$version}{ $name_of->{$index} } }
                        = $line->{columns}[$index];
                }
                push @lines_for_hashref, \%column;
            }
            $result_for_hashref{$version} = \@lines_for_hashref,
        }
        push @{ $test_case{normal}{hash_ref} }, {
            name   => $Parser{normal}{scalar}[$index]{name},
            query  => $Parser{normal}{scalar}[$index]{query},
            result => \%result_for_hashref,
        };

        ++ $index;
    }

    return \%test_case;
}

# ================================================================
# Purpose    : ???
# Usage      : ???
# Parameters : ???
# Returns    : ???
# Throws     : ??? / no exceptions
# Comments   : none
# See Also   : n/a
# ----------------------------------------------------------------
sub get_dictionary_path {
    my $dictionary_directory = cwd() . '/t/dictionary';
    my $extension            = '.utx';

    my %base = (
        'old'     => 'valid',
        'invalid' => 'invalid',
        'new'     => 'modified',
    );

    my %path;
    foreach my $version (@Versions) {
        while (my ($sign, $name) = each %base) {
            $path{$version . '_' . $sign}
                = $dictionary_directory . '/'
                . $version . '_' . $name . $extension;
        }
    }
    $path{unexist} = $dictionary_directory . '/'
                   . 'unexist' . $extension;

    return %path;
}

1;

__END__

=head1 NAME

Test::Text_UTX_Simple - Utilities for test of Text::UTX::Simple
