package Text::UTX::Simple::Header::Base::Inherited;

use 5.008_001;
use strict;
use warnings;
use utf8;

use base qw( Text::UTX::Simple::Header::Base );

sub load_module_dynamically {
    my $self = shift;
    return $self->SUPER::load_module_dynamically(@_);
}

1;
