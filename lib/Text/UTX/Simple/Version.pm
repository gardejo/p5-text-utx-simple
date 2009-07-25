package Text::UTX::Simple::Version;


# ****************************************************************
# pragmas
# ****************************************************************

use 5.008_001;
use strict;
use warnings;
use utf8;


# ****************************************************************
# dependencies
# ****************************************************************

use Attribute::Util qw(Abstract Alias Protected);
use Carp qw(carp croak);
use Readonly;
use Scalar::Util qw(blessed looks_like_number);


# ****************************************************************
# package global symbols
# ****************************************************************

our $VERSION = '0.02_00';   # $Rev: 61 $


# ****************************************************************
# class constants
# ****************************************************************

Readonly my %COMPATIBILITY  => (
    '0.90'    => '0.90',    # since 2008-XX-XX
    '0.91'    => '0.91',    # since 2008-04-XX
    '0.92'    => '0.91',    # since 2008-11-13 : $LATEST_VERSION
);
Readonly my $LATEST_VERSION => q{0.92};
Readonly my $VERSION_PREFIX => q{V};


# ****************************************************************
# version guesser (public method)
# ****************************************************************

# ================================================================
# Purpose    : guess version of UTX-Simple specification
# Usage      : 1) $version = $invocant->guess_version($string)
#            : 2) $version = $invocant->guess_version()
# Parameters : 1*) STR to guess
# Returns    : INT version
# Throws     : no exceptions
# Comments   : 1) Do not be too confident in itself!
#            : 2) Not only $header->guess_version($string),
#            :    but also $utx->guess_version($string).
#            :    Because version kind string is first matched value,
#            :    usless split header and body on the dictionary
#            :    from $utx->guess_version($string).
# See Also   : n/a
# ----------------------------------------------------------------
sub guess_version : Public {
    my ($invocant, $string) = @_;

    return $invocant->get_version()
        unless defined $string;

    croak "Can't guess version: ",
          "specified string has no version kind string"
            if $string !~ m{ [\s;] ( .*? \d+ \. \d+ .*? ) [\s;]}xms;

    return $1;
}


# ****************************************************************
# accessors for class variable (protected methods)
# ****************************************************************

# ================================================================
# Purpose    : get latest version of the UTX-Simple specification
# Usage      : $version
#            :     = Text::UTX::Simple::Version->get_latest_version()
# Parameters : none
# Returns    : STR latest version
# Throws     : no exceptions
# Comments   : none
# See Also   : n/a
# ----------------------------------------------------------------
sub get_latest_version : Protected {
    return $LATEST_VERSION;
}

# ================================================================
# Purpose    : classname for specified version of the UTX-Simple specification
# Usage      : Text::UTX::Simple::Version
#            :     ->_load_version_distinct_class($version)
# Parameters : STR version    '0.92'
# Returns    : STR class name 'Text::UTX::Simple::Version::Header::V0_92'
# Throws     : no exceptions
# Comments   : none
# See Also   : n/a
# ----------------------------------------------------------------
sub get_version_distinct_class : Protected {
    my ($invocant, $abstract_class, $version) = @_;

    # carp "I reccomend to use latest version"
    #     if $version < $LATEST_VERSION;

    # be quiet : carp at validate() <- initialize() <- new()
    $invocant->regularize_version(\$version, 1);

    (my $concrete_class = $version) =~ tr{.}{_};
    $concrete_class = join '::',
                        __PACKAGE__,
                        $abstract_class,
                        $VERSION_PREFIX . $concrete_class;

    return $concrete_class;
}


# ****************************************************************
# converter (protected method)
# ****************************************************************

# ================================================================
# Purpose    : ???
# Usage      : ???
# Parameters : ???
# Returns    : ???
# Throws     : ??? / no exceptions
# Comments   : none
# See Also   : n/a
# ----------------------------------------------------------------
sub regularize_version : Protected {
    my ($invocant, $version_ref, $be_quiet) = @_;

    $invocant->validate_version_kind($$version_ref);

    $$version_ref = sprintf "%0.2f", $$version_ref;

    if (! exists $COMPATIBILITY{$$version_ref}) {
        carp "Unknown version ($$version_ref) is detected: ",
             "latest version ($LATEST_VERSION) was applied implicitly"
                unless $be_quiet;
        $$version_ref = $LATEST_VERSION;
    }

    return;
}


# ****************************************************************
# part of validator (protected method)
# ****************************************************************

# ================================================================
# Purpose    : ???
# Usage      : ???
# Parameters : ???
# Returns    : ???
# Throws     : ??? / no exceptions
# Comments   : none
# See Also   : n/a
# ----------------------------------------------------------------
sub validate_version_kind : Protected {
    my ($invocant, $version) = @_;

    croak "Can't parse the header: ",
          "version isn't defined"
            unless defined $version;
    croak "Can't parse the header: ",
          "version ($version) isn't numeric"
            if ! looks_like_number($version)
            || $version =~ m{\A Inf(?:inity)? \z}xmsi;

    return;
}


# ****************************************************************
# part of comparison (protected method)
# ****************************************************************

# ================================================================
# Purpose    : return true if $self and $other version are compatible,
#            : otherwise false
# Usage      : 1) if ($self->is_compatible_with($other)) { ... }
#            : 1) if ($self->is_compatible_with('3.14')) { ... }
# Parameters : Text::UTX::Simple::Version::Header(::VX_XX) instance
# Returns    : BOOL true if is compatible / false if is not compatible
# Throws     : no exceptions
# Comments   : none
# See Also   : n/a
# ----------------------------------------------------------------
sub is_compatible_with : Protected {
    my ($self, $other) = @_;

    my $self_version  = $self->get_version();
    my $other_version = blessed $other ? $other->get_version()
                                       : $other;

    $other_version = exists $COMPATIBILITY{$other_version}
                        ? $other_version
                        : $LATEST_VERSION;

    return $COMPATIBILITY{$self_version} == $COMPATIBILITY{$other_version};
}


# ****************************************************************
# abstract method
# ****************************************************************

sub get_version : Abstract;


1; # magic true value required at end of module
__END__

=head1 NAME

Text::UTX::Simple::Version - internal: treat version of the UTX-Simple


=head1 SYNOPSIS

    package Text::UTX::Simple::Header::YourInheritance;

    # FOR INTERNAL USE ONLY
    use base qw(Text::UTX::Simple::Version);

    my $latest_version = __PACKAGE__->get_latest_version();
    my $concrete_class = __PACKAGE__->get_version_distinct_class('3.14');


=head1 DESCRIPTION

=head2 FOR INTERNAL USE ONLY

This class is part of
L<Text::UTX::Simple|Text::UTX::Simple>
class.


=head1 METHODS

For internal use only.

=head2 Guesser

=head3 C<< guess_version($string) >>

Guesses UTX-Simple version of specified C<$string>.


=head2 Accessors for class variables

All accessors for class are I<protected>.

=head3 C<< get_latest_version() >>

Returns latest version of the UTX-Simple specification.

=head3 C<< get_version_distinct_class($version) >>

Returns classname for specified C<$version> of the UTX-Simple specification.


=head2 Converter

This method is I<protected>.

=head3 C<< regularize_version(\$version, $be_quiet) >>

Regularize C<$version> (Converts irregular C<$version> into regular).
Warns L<Carp::carp|Carp>ed message if C<$be_quiet> is false.


=head2 Part of validator

This method is I<protected>.

=head3 C<< validate_version_kind($version) >>

Throws exceptions if specified C<$version> is invalid.


=head2 Part of comparison

=head3 C<< is_compatible_with($other) >>

Returns true if C<$self> and C<$other> version are compatible,
otherwise false.


=head2 Abstract methods

Methods shown below should be override in
C<Text::UTX::Simple::Version::Header::V*> concrete classes. 

=head3 C<< get_version() >>

Returns version number.


=head1 DIAGNOSTICS

Please refer to
L<the Text::UTX::Simple::Manual::Diagnostics documentation|
Text::UTX::Simple::Manual::Diagnostics>
for the explanation of all error messages.


=head1 CONFIGURATION AND ENVIRONMENT

C<Text::UTX::Simple::Version>
requires no configuration files or environment variables.


=head1 DEPENDENCIES

C<Text::UTX::Simple::Version>
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

L<Readonly|Readonly>
- CPAN module

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

=item L<Text::UTX::Simple|Text::UTX::Simple>

User interface class.

=back


=head1 AUTHOR

=over 4

=item MORIYA Masaki

E<lt>moriya at ermitejo.comE<gt>,
L<http://ttt.ermitejo.com/>

=back

is responsible for
C<Text::UTX::Simple::Auxiliary::Factory>
module.

The UTX specification and the UTX-Simple specification
are results of examination by AAMT
(Asia-Pacific Association for Machine Translation, L<http://www.aamt.info/>);
and all rights are reserved by AAMT.


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2008-2009, MORIYA Masaki E<lt>moriya at ermitejo.comE<gt>.
All rights reserved.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
See L<perlgpl|perlapi> and L<perlartistic|perlartistic>.


=head1 VERSION

This document describes version 0.02_00 ($Rev: 61 $) of
C<Text::UTX::Simple::Auxiliary::Factory>,
released C<$Date: 2009-04-16 01:51:54 +0900 (木, 16 4 2009) $>.
