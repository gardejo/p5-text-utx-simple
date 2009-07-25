package Text::UTX::Simple::Header::Factory;


# ****************************************************************
# pragmas
# ****************************************************************

use 5.008_001;
use strict;
use warnings;
use utf8;


# ****************************************************************
# superclasses
# ****************************************************************

use base qw(
    Text::UTX::Simple::Header
);


# ****************************************************************
# dependencies
# ****************************************************************

use Attribute::Util qw(Abstract Alias Protected);
use Carp qw(croak);
use Scalar::Util qw(blessed);
use Storable qw(dclone);


# ****************************************************************
# package global symbols
# ****************************************************************

our $VERSION = '0.02_00';   # $Rev: 60 $


# ****************************************************************
# constructors
# ****************************************************************

# ================================================================
# Purpose    : create a new Text::UTX::Simple::Header object
# Usage      : 1) $header = Text::UTX::Simple::Header->new()
#            : 2) $header = Text::UTX::Simple::Header->new(HASHREF)
# Parameters : *HASHREF: spec, ver, src, tgt, user_defined_columns
# Returns    : Text::UTX::Simple::Header object
# Throws     : no exceptions
# Comments   : 1) FOR INTERNAL USE ONLY
#            : 2) complement is_modified ?
# See Also   : new
# ----------------------------------------------------------------
sub new : Public {
    my ($class, $option) = @_;

    # regularize option
    $option = $class->_regularize_option($option);

    # load Concrete Factory class
    my $factory_class
        = $class->get_version_distinct_class('Header', $option->{version});
    $class->load_module_dynamically($factory_class);

    # create and initialize object
    my $self = bless {}, $factory_class;    # object of any version
    $self->initialize($option);

    return $self;
}

# ================================================================
# Purpose    : clone an existent object
# Usage      : 1) $clone = $self->clone()
#            : 2) $clone = $self->clone(HASHREF)
# Parameters : *HASHREF: spec, ver, src, tgt, user_defined_columns
#            : always specified by Text::UTX::Simple::new()
# Returns    : Text::UTX::Simple::Header object
# Throws     : no exceptions
# Comments   : 1) FOR INTERNAL USE ONLY
#            : 2) complement is_modified ?
# See Also   : Text::UTX::Simple::clone
# ----------------------------------------------------------------
sub clone : Public {
    my ($self, $option) = @_;

    $option = $self->_regularize_option($option);

    my $clone = bless {}, ref $self;
    $clone->{version} = $self->{version};
    $clone->initialize($option);

    return $clone;
}


# ****************************************************************
# private methods
# ****************************************************************

# ================================================================
# Purpose    : regularize option
# Usage      : 1) $class->_regularize_option($option) # from new()
#            : 2) $self->_regularize_option($option)  # from clone()
# Parameters : HASHREF option
# Returns    : none
# Throws     : if xxx
# Comments   : none
# See Also   : n/a
# ----------------------------------------------------------------
sub _regularize_option : Private {
    my ($invocant, $option) = @_;

    my $regularized_option = dclone $option;

    croak "Can't create an object: ",
          "you can't specify both alignment and group of source and/or target"
            if exists $regularized_option->{alignment}
            && ( exists $regularized_option->{source} ||
                 exists $regularized_option->{target} );
    croak "Can't create an object: ",
          "you must specify both source and target ",
          "to create multilingual dictionary"
            if exists $regularized_option->{target}
            && ! exists $regularized_option->{source};

    if (exists $regularized_option->{column}) {
        croak "Can't parse the header: ",
              "'columns' and 'user_defined_columns' are exclusive"
                if exists $regularized_option->{user_defined_columns};
        $regularized_option->{user_defined_columns}
            = $regularized_option->{column};
        delete $regularized_option->{column};
    }
    if (blessed $invocant) {
        $regularized_option->{original_miscellany}
            = dclone $invocant->{miscellany};
    }

    %$regularized_option
        = blessed $invocant ? (%$invocant, %$regularized_option)
                            : (%{ $invocant->get_default_field() },
                               %$regularized_option);

    if (! exists $regularized_option->{last_updated}) {
        $regularized_option->{last_updated}
            = $invocant->get_now($regularized_option);
    }
    if (exists $regularized_option->{time_zone}) {
        delete $regularized_option->{time_zone};
    }

    return $regularized_option;
}


1; # magic true value required at end of module
__END__

=head1 NAME

Text::UTX::Simple::Header::Factory - internal: create a header instance


=head1 SYNOPSIS

    package Text::UTX::Simple;

    # I simplify codes shown below, for synopsis only!
    use Text::UTX::Simple::Header::Factory;
    use Text::UTX::Simple::Body;

    sub new {
        my ($class, $option) = @_;
        return bless {
            header => Text::UTX::Simple::Header::Factory->new($option),
            body   => Text::UTX::Simple::Body->new($option),
        }, $class;
    }


=head1 DESCRIPTION

=head2 FOR INTERNAL USE ONLY

This class is part of
L<Text::UTX::Simple::Header|Text::UTX::Simple::Header> class.

This class is I<Abstract Creator> class (and I<Concrete Creator> class)
of I<Factory Method> pattern.

This class also have I<Template Method> for I<Concrete Product> classes.


=head1 METHODS

=head2 Constructors

All constructors are I<protected>.

=head3 C<< new(\%option) >>

Creates a new instance of I<Concrete Product> classes.

See L<< Text::UTX::Simple::new()|
Text::UTX::Simple/new >>
for further details of usage.

=head3 C<< clone(\%option) >>

Clones a new instance of C<$self>'s class.

See L<< Text::UTX::Simple::clone()|
Text::UTX::Simple/clone >>
for further details of usage.


=head1 DIAGNOSTICS

Please refer to
L<the Text::UTX::Simple::Manual::Diagnostics documentation|
Text::UTX::Simple::Manual::Diagnostics>
for the explanation of all error messages.


=head1 CONFIGURATION AND ENVIRONMENT

C<Text::UTX::Simple::Header::Factory>
requires no configuration files or environment variables.


=head1 DEPENDENCIES

C<Text::UTX::Simple::Header::Factory>
depends on:

=over 4

=item *

perl 5.8.1 or later

=item *

L<strict|strict>
- pragma

=item *

L<warnings|warnings>
- pragma

=item *

L<utf8|utf8>
- pragma

=item *

L<Attribute::Abstract|Attribute::Abstract>
- CPAN module

=item *

L<Attribute::Alias|Attribute::Alias>
- CPAN module

=item *

L<Attribute::Protected|Attribute::Protected>
- CPAN module

=item *

L<Attribute::Util|Attribute::Util>
- CPAN module

=item *

L<Carp|Carp>
- core module

=item *

L<Scalar::Util|Scalar::Util>
- core module

=item *

L<Storable|Storable>
- core module

=back


=head1 INCOMPATIBILITIES

None reported.

B<HOWEVER, THIS LIBRARY IS IN ITS ALPHA QUALITY.
THE API MAY CHANGE IN THE FUTURE.>


=head1 BUGS AND LIMITATIONS

Please refer to
L<the BUGS AND LIMITATIONS section of the Text::UTX::Simple documentation|
Text::UTX::Simple/BUGS_AND_LIMITATIONS>
for information about bugs and limitations of this library.


=head1 SUPPORT

Please refer to
L<the SUPPORT section of the Text::UTX::Simple documentation|
Text::UTX::Simple/SUPPORT>
for information about support of this library.


=head1 CODE COVERAGE

Please refer to
L<the CODE COVERAGE section of the Text::UTX::Simple documentation|
Text::UTX::Simple/CODE_COVERAGE>
for information about the code coverage of this library's test suite.


=head1 TO DO

There is nothing to do.


=head1 SEE ALSO

=over 4

=item L<Text::UTX::Simple|Text::UTX::Simple>

User interface class.

=item L<Text::UTX::Simple::Header|Text::UTX::Simple::Header>

I<Abstract Product> class of I<Factory Method> pattern.

=item Text::UTX::Simple::Version::Header::V*

I<Concrete Product> classes of I<Factory Method> pattern.

=back



=head1 AUTHOR

=over 4

=item MORIYA Masaki

E<lt>moriya at ermitejo.comE<gt>,
L<http://ttt.ermitejo.com/>

=back

is responsible for
C<Text::UTX::Simple::Header::Factory>
module.

The UTX specification and the UTX-Simple specification
are results of examination by AAMT
(Asia-Pacific Association for Machine Translation, L<http://www.aamt.info/>);
and all rights are reserved by AAMT.


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2008-2009, MORIYA Masaki E<lt>moriya at ermitejo.comE<gt>.
All rights reserved.

This is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
See L<perlgpl|perlapi> and L<perlartistic|perlartistic>.


=head1 VERSION

This document describes version 0.02_00 ($Rev: 60 $) of
C<Text::UTX::Simple::Header::Factory>,
released C<$Date: 2009-04-13 06:26:16 +0900 (月, 13 4 2009) $>.
