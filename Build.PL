use 5.008_001;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Text::UTX::Simple',
    license             => 'perl',  # the GPL or the Artistic License
    dist_author         => 'MORIYA Masaki <moriya at ermitejo.com>',
    dist_version_from   => 'lib/Text/UTX/Simple.pm',
    requires => {
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
        # 'Encode::Guess'        => 0,
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
    add_to_cleanup      => [ 'Text-UTX-Simple-*' ],
);

$builder->create_build_script();
