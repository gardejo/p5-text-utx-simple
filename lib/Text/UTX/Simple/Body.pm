package Text::UTX::Simple::Body;


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
    Text::UTX::Simple::Body::Parser
    Text::UTX::Simple::Body::Dumper
    Text::UTX::Simple::Body::Manipulator
    Text::UTX::Simple::Body::Base
);


# ****************************************************************
# dependencies
# ****************************************************************

use Attribute::Util qw(Abstract Alias Protected);
use Carp qw(croak);
use Scalar::Util qw(weaken);
use Storable qw(dclone);


# ****************************************************************
# package global symbols
# ****************************************************************

our $VERSION = '0.02_00';   # $Rev: 59 $


# ****************************************************************
# constructors (public methods)
# ****************************************************************

# ================================================================
# Purpose    : create a new Text::UTX::Simple::Body object
# Usage      : $body = Text::UTX::Simple::Body->new(HASHREF)
# Parameters : HASHREF option
#            :   parent: Text::UTX::Simple object (for back-link)
# Returns    : Text::UTX::Simple::Body object
# Throws     : if parent object not specified
# Comments   : I want to have it access each line of the dictionary by the HASH
#            : that has a key as a headword (first column of row).
#            : Moreover, by the ARRAY that means row index.
#            : Therefore, HASH and ARRAY are updated every time the line is
#            : added and removed. I do not use Tie::IxHash.
#            : It has the substance of the line in the array, and  HASH is
#            : used as index information assisting.
# See Also   : clone
# ----------------------------------------------------------------
sub new : Public {
    my ($class, $option) = @_;

    croak "Can't create a new $class instance: ",
          "a back-link to parent doesn't exist"
            unless exists $option->{parent};

    my $self = bless {
        entries => [],
        entry   => {},
        parent  => $option->{parent},
    }, $class;
    weaken($self->{parent});

    return $self;
}

# ================================================================
# Purpose    : clone specified object
# Usage      : $clone = $self->clone(HASH)
# Parameters : HASHREF option
#            :   parent: Text::UTX::Simple object (for back-link)
# Returns    : Text::UTX::Simple::Body object
# Throws     : if parent object not specified
# Comments   : none
# See Also   : n/a
# ----------------------------------------------------------------
sub clone : Public {
    my ($self, $option) = @_;

    croak "Can't clone a ", ref $self, " instance: ",
          "a back-link to parent doesn't exist"
            unless exists $option->{parent};

    my $clone = dclone $self;
    $clone->{parent} = $option->{parent};
    weaken($clone->{parent});

    $clone->index_entries();

    return $clone;
}


1; # magic true value required at end of module
__END__

=head1 NAME

Text::UTX::Simple::Body - internal: parse/dump UTX-Simple body


=head1 SYNOPSIS

    use Text::UTX::Simple::Body;    # FOR INTERNAL USE ONLY


=head1 DESCRIPTION

=head2 FOR INTERNAL USE ONLY

This class is part of L<Text::UTX::Simple|Text::UTX::Simple> class.
This class behaves itself like a delegation of C<Text::UTX::Simple>,
and treats the body (entries) of the dictionary.


=head1 METHODS

=head2 Constructors

=head3 C<< new({parent => $parent}) >>

Creates a new C<Text::UTX::Simple::Body> instance.

See L<< Text::UTX::Simple::new()|
Text::UTX::Simple/new >>
for further details of usage.

=head3 C<< clone({parent => $parent}) >>

Clones a C<Text::UTX::Simple::Body> instance.

See L<< Text::UTX::Simple::clone()|
Text::UTX::Simple/clone >>
for further details of usage.


=head1 DIAGNOSTICS

Please refer to
L<the Text::UTX::Simple::Manual::Diagnostics documentation|
Text::UTX::Simple::Manual::Diagnostics>
for the explanation of all error messages.


=head1 CONFIGURATION AND ENVIRONMENT

C<Text::UTX::Simple::Body>
requires no configuration files or environment variables.


=head1 DEPENDENCIES

C<Text::UTX::Simple::Body> depends on:

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

=back


=head1 AUTHOR

=over 4

=item MORIYA Masaki

E<lt>moriya at ermitejo.comE<gt>,
L<http://ttt.ermitejo.com/>

=back

is responsible for C<Text::UTX::Simple::Body> module.

The UTX specification and the UTX-Simple specification
are results of examination by AAMT
(Asia-Pacific Association for Machine Translation, L<http://www.aamt.info/>);
and all rights are reserved by AAMT.


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2008-2009, MORIYA Masaki E<lt>moriya at ermitejo.comE<gt>.
All rights reserved.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
See L<perlgpl|perlgpl> and L<perlartistic|perlartistic>.


=head1 VERSION

This document describes version 0.02_00 ($Rev: 59 $) of
C<Text::UTX::Simple::Body>,
released C<$Date: 2009-04-12 06:04:24 +0900 (日, 12 4 2009) $>.
