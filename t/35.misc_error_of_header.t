use strict;
use warnings;
# use utf8;
use lib 't/lib';

use Test::More tests => 5;
use Test::Exception;
use Test::Warn;
# use Test::Text_UTX_Simple;
use Text::UTX::Simple::Header::Base::Inherited;

use Text::UTX::Simple;

my $utx = Text::UTX::Simple->new();


# ================================================================
# parse null
# ----------------------------------------------------------------
throws_ok(
    sub { $utx->parse() },
    qr{Can't parse strings: strings aren't defined},
    'undef'
);
throws_ok(
    sub { $utx->parse(q{}) },
    qr{Can't parse strings: strings aren't defined},
    'empty string'
);

# ================================================================
# monomania (can't happen): parse
# ----------------------------------------------------------------
throws_ok(
    sub { $utx->{header}->parse() },
    qr{Can't parse the header: header strings isn't defined},
    "can't happen"
);

# ================================================================
# monomania (can't happen): load
# ----------------------------------------------------------------
# my $invalid_class = 'Text::UTX::Simple::Version::Header::V0_00';
# my $filename_pattern = Class::Inspector->filename($invalid_class);
# $filename_pattern =~ s{\\}{\\\\}g;  # for Win32 environment
# $filename_pattern =~ s{\.}{\\.}g;
throws_ok(
    sub {
        Text::UTX::Simple::Header::Base::Inherited->load_module_dynamically
            # ($invalid_class);
            ('Text::UTX::Simple::Version::Header::V0_00');
    },
    # qr{Can't locate $filename_pattern},
    qr{Can't locate Text/UTX/Simple/Version/Header/V0_00},
    "can't happen"
);

# ================================================================
# invalid usage: call at void context
# write end of this file, to evade "Bizarre copy of HASH in sassign"
# at Carp::Heavy line 104
# ----------------------------------------------------------------
warning_is
    { $utx->dump_header({scalar_ref => 1}) }
    { carped => "Useless use private variable in void context" }
;
