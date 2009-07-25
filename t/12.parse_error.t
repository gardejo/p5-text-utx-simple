use strict;
use warnings;
# use utf8;
use lib 't/lib';

use Test::More tests => 18;
use Test::Exception;
# use Test::Warn;
use Test::Text_UTX_Simple;

use Text::UTX::Simple;


# ================================================================
# exception
# [ 6kinds * 3versions = 18tests ]
# ----------------------------------------------------------------
foreach my $version (@Versions) {
    my $utx = Text::UTX::Simple->new({version => $version});
    throws_ok(
        sub { $utx->parse($utx) },
        qr{Can't parse strings: element of lines \(Text::UTX::Simple\) isn't valid type},
        "object, $version"
    );
    throws_ok(
        sub { $utx->parse({foo => 1}) },
        qr{Can't parse strings: element of lines \(HASH\) isn't valid type},
        "HASHREF, $version"
    );
    throws_ok(
        sub { $utx->parse() },
        qr{Can't parse strings: strings aren't defined},
        "without argument, $version"
    );
    throws_ok(
        sub { $utx->parse(undef) },
        qr{Can't parse strings: strings aren't defined},
        "with undef, $version"
    );
    throws_ok(
        sub { $utx->parse(q{}) },
        qr{Can't parse strings: strings aren't defined},
        "with empty, $version"
    );

    my $header = $Query{header}{$version}{'en/ja'}{has_column};
    $header =~ s{ \A \# }{}xms; # delete comment sign
    throws_ok(
        sub { $utx->parse($header) },
        qr{Can't parse the header: comment sign doesn't exist},
        "without comment sign, $version"
    );
}
