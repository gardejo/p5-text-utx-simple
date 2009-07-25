package Text::UTX::Simple::Version::Header::V0_92;


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
    Text::UTX::Simple::Version::Header::V0_91
);


# ****************************************************************
# dependencies
# ****************************************************************

# use Attribute::Util qw(Abstract Alias Protected);
use Readonly;
use Scalar::Util qw(blessed);


# ****************************************************************
# package global symbols
# ****************************************************************

our $VERSION = '0.01_00';   # $Rev: 59 $


# ****************************************************************
# class constants
# ****************************************************************

Readonly my $UTX_VERSION         => '0.92';


# ****************************************************************
# accessor for class constant (protected method)
# ****************************************************************

# ================================================================
# Purpose    : get a version string of the specification on the dictionary
# Usage      : 1) $version = $self->get_version()
#            : 2) $version = $class->get_version()
# Parameters : none
# Returns    : STR (don't cast in NUM): version number of the specification
# Throws     : no exceptions
# Comments   : FOR INTERNAL USE ONLY
# See Also   : n/a
# ----------------------------------------------------------------
sub get_version {
    return blessed $_[0] ? $_[0]->{version} : $UTX_VERSION;
}


1; # magic true value required at end of module
__END__

=head1 NAME

Text::UTX::Simple::Version::Header::V0_92 - internal: treat header of UTX-Simple 0.92


=head1 SYNOPSIS

    # FOR INTERNAL USE ONLY
    use Text::UTX::Simple::Version::Header::V0_92;


=head1 DESCRIPTION

=head2 FOR INTERNAL USE ONLY

This class is part of
L<Text::UTX::Simple::Header|Text::UTX::Simple::Header> class.


=head2 Don't use attribute provided by L<Attribute::Protected|Attribute::Protected>

Because this class loaded dynamically by
L<Text::UTX::Simple::Auxiliary::Factory|Text::UTX::Simple::Auxiliary::Factory>,
return values of L<Attribute::Handlers|Attribute::Handlers> is imperfect.


=head1 METHODS

ALl methods are I<protected>.

=head2 Accessor for class constant

=head3 C<< get_version() >>

Returns version number C<0.92>.


=head1 DIAGNOSTICS

Please refer to
L<the Text::UTX::Simple::Manual::Diagnostics documentation|
Text::UTX::Simple::Manual::Diagnostics>
for the explanation of all error messages.


=head1 CONFIGURATION AND ENVIRONMENT

C<Text::UTX::Simple::Version::Header::V0_92>
requires no configuration files or environment variables.


=head1 DEPENDENCIES

C<Text::UTX::Simple::Version::Header::V0_92>
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

L<Readonly|Readonly>
- core module

=item *

L<Scalar::Util|Scalar::Util>
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

=item L<Text::UTX::Simple|
        Text::UTX::Simple>

User interface class.

=back


=head1 AUTHOR

=over 4

=item MORIYA Masaki

E<lt>moriya at ermitejo.comE<gt>,
L<http://ttt.ermitejo.com/>

=back

is responsible for
C<Text::UTX::Simple::Version::Header::V0_92>
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

This document describes version 0.01_00 ($Rev: 59 $) of
C<Text::UTX::Simple::Version::Header::V0_92>,
released C<$Date: 2009-04-12 06:04:24 +0900 (日, 12 4 2009) $>.
