use 5.008_001;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Text::UTX::Simple',
    LICENSE             => 'perl',  # the GPL or the Artistic License
    AUTHOR              => 'MORIYA Masaki <moriya at ermitejo.com>',
    VERSION_FROM        => 'lib/Text/UTX/Simple.pm',
    ABSTRACT_FROM       => 'lib/Text/UTX/Simple.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Attribute::Abstract'  => 0,
        'Attribute::Alias'     => 0,
        'Attribute::Protected' => 0,
        'Attribute::Util'      => 0,
        'Carp'                 => 0,
        'Class::Inspector'     => 0,
        'Cwd'                  => 0,
        'DateTime'             => 0,
        'DateTime::TimeZone'   => 0,
        'Encode'               => 0,
        'English'              => 0,
        'File::Slurp'          => 0,
        'List::MoreUtils'      => 0,
        'List::Util'           => 0,
        'Locale::Country'      => 0,
        'Locale::Language'     => 0,
        'Readonly'             => 0,
        'Regexp::Common::time' => 0,
        'Scalar::Util'         => 0,
        'Storable'             => 0,
        'Test::Exception'      => 0,
        'Test::Harness'        => 0,
        'Test::More'           => 0,
        'Test::Warn'           => 0,
        'Tie::IxHash'          => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Text-UTX-Simple-*' },
);
