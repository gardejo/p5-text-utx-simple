package Text::UTX::Simple::Header::Dumper;


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
    Text::UTX::Simple::Header::Base
);


# ****************************************************************
# dependencies
# ****************************************************************

use Attribute::Util qw(Abstract Alias Protected);
use Storable qw(dclone);


# ****************************************************************
# package global symbols
# ****************************************************************

our $VERSION = '0.02_00';   # $Rev: 59 $


# ****************************************************************
# dumper (public method)
# ****************************************************************

# ================================================================
# Purpose    : dump(generate) formatted lines of the header of the dictionary
# Usage      : 1) $header_ref = $self->dump()
#            : 2) $header_ref = $self->dump(HASHREF)
# Parameters : *HASHREF: option
# Returns    : ARRAYREF(STR): header strings
# Throws     : no exceptions
# Comments   : 1) FOR INTERNAL USE ONLY
#            : 2) without "\n", point in the time
#            : 3) update $self->{last_update} as aftereffect
#            : 4) to unbless appropriately, call "SvOBJECT_off(sv)" in XS
# See Also   : Acme::Damn, Data::Structure::Util
# ----------------------------------------------------------------
sub dump : Public {
    my ($self, $option) = @_;

    if ($option->{hash_ref} || $option->{hash}) {
        my $dumped_header = { %{ dclone $self } };  # simply unbless
        $dumped_header->{miscellany} = $self->get_miscellany();
        return $dumped_header;
    }

    return $self->comment_out( $self->dump_header($option) );
}


# ****************************************************************
# abstract method
# ****************************************************************

sub dump_header : Abstract;


1; # magic true value required at end of module
__END__

=head1 NAME

Text::UTX::Simple::Header::Dumper - internal: dump header of UTX-Simple


=head1 SYNOPSIS

    package Text::UTX::Simple::Header::YourInheritance;

    # FOR INTERNAL USE ONLY
    use Text::UTX::Simple::Header::Dumper;


=head1 DESCRIPTION

=head2 FOR INTERNAL USE ONLY

This class is part of
L<Text::UTX::Simple::Header|Text::UTX::Simple::Header> class.


=head1 METHODS

=head2 Dumper

All dumpers are I<protected>.

=head3 C<< dump(\%option) >>

Dumps(generates) formatted lines of the header on the dictionary.

See L<< Text::UTX::Simple::dump_body()|
Text::UTX::Simple/dump_body >>
for further details of usage.


=head2 Abstract method

Method shown below should be override in
C<Text::UTX::Simple::Version::Header::V*> classes.

=head3 C<< dump_header >>

Provides primitive process.


=head1 DIAGNOSTICS

Please refer to
L<the Text::UTX::Simple::Manual::Diagnostics documentation|
Text::UTX::Simple::Manual::Diagnostics>
for the explanation of all error messages.


=head1 CONFIGURATION AND ENVIRONMENT

C<Text::UTX::Simple::Header::Dumper>
requires no configuration files or environment variables.


=head1 DEPENDENCIES

C<Text::UTX::Simple::Header::Dumper>
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

L<List::MoreUtils|List::MoreUtils>
- CPAN module

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

Inherited class.

=back


=head1 AUTHOR

=over 4

=item MORIYA Masaki

E<lt>moriya at ermitejo.comE<gt>,
L<http://ttt.ermitejo.com/>

=back

is responsible for
C<Text::UTX::Simple::Header::Dumper>
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

This document describes version 0.02_00 ($Rev: 59 $) of
C<Text::UTX::Simple::Header::Dumper>,
released C<$Date: 2009-04-12 06:04:24 +0900 (日, 12 4 2009) $>.
