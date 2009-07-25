package Text::UTX::Simple::Inherited;

use 5.008_001;
use strict;
use warnings;
use utf8;

use base qw( Text::UTX::Simple );

use Text::UTX::Simple::Header::Factory::Inherited;
use Text::UTX::Simple::Body::Inherited;

use Attribute::Util qw(Abstract Alias Protected);
use Carp;

our $VERSION = '0.02_00';   # $Rev: 52 $

sub new : Public {
    my ($class, $option) = @_;

    croak "Can't create a new object: ",
          "$class is not a class (you must use clone())"
            if blessed $class;

    $option = defined $option ? $option : {};
    croak "Can't create an object: option isn't a HASH reference"
        if ref $option ne 'HASH';

    my $self = bless {
        #### header => Text::UTX::Simple::Header::Factory->new($option),
        header => Text::UTX::Simple::Header::Factory::Inherited->new($option),
    }, $class;
    $self->{body}
        #### = Text::UTX::Simple::Body->new({%$option, parent => $self});
        = Text::UTX::Simple::Body::Inherited->new({%$option, parent => $self});

    if (%$option) {
        $self->_fetch_method_by($option);
    }
    else {
        # disuse Mediator methods, _header() and _body(), for optimization
        $self->{header}->index_columns();
        $self->{body}->index_entries();
    }

    return $self;
}

sub _fetch_method_by : Private {
    my ($self, $option) = @_;

    croak "Can't create an object: ",
          "option should have only one behavior key"
            if exists $option->{text}
            && exists $option->{file};

    while (my ($attribute, $value) = each %$option) {
        if ($attribute eq 'text') {
            $self->parse($value);
        }
        elsif ($attribute eq 'file') {
            $self->read($value);
        }
    }

    return;
}

1;
