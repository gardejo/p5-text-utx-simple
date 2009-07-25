package Text::UTX::Simple::Body::Base;


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
use Readonly;


# ****************************************************************
# package global symbols
# ****************************************************************

our $VERSION = '0.02_00';   # $Rev: 61 $


# ****************************************************************
# class constants
# ****************************************************************

Readonly my $COMMENT_SIGN         => q{#};
Readonly my $DELIMITER_OF_COLUMNS => qq{\t};
Readonly my $VOID_VALUE           => q{};   # implicit null


# ****************************************************************
# class variables
# ****************************************************************

my $COMPLEMENT_OF_VOID_VALUE = q{};         # void value into any string


# ****************************************************************
# accessor for class variable (public method)
# ****************************************************************

# ================================================================
# Purpose    : get $COMPLEMENT_OF_VOID_VALUE
# Usage      : $string = $self->get_complement_of_void_value()
# Parameters : none
# Returns    : STR: alternative strings with undefined value
# Throws     : no exceptions
# Comments   : none
# See Also   : n/a
# ----------------------------------------------------------------
sub get_complement_of_void_value : Public {
    return $COMPLEMENT_OF_VOID_VALUE;
}


# ****************************************************************
# mutator for class variable (public method)
# ****************************************************************

# ================================================================
# Purpose    : set $COMPLEMENT_OF_VOID_VALUE
# Usage      : $self->set_complement_of_void_value(STR)
# Parameters : STR: alternative strings with undefined value
# Returns    : none
# Throws     : no exceptions
# Comments   : none
# See Also   : n/a
# ----------------------------------------------------------------
sub set_complement_of_void_value : Public {
    $COMPLEMENT_OF_VOID_VALUE = defined $_[1] ? $_[1] : q{};

    return;
}


# ****************************************************************
# accessors for instance variables (public methods)
# ****************************************************************

# ================================================================
# Purpose    : get number of entries on the dictionary
# Usage      : $number = $self->get_number_of_entries()
# Parameters : none
# Returns    : NUM: number of entries
# Throws     : no exceptions
# Comments   : none
# See Also   : n/a
# ----------------------------------------------------------------
sub get_number_of_entries : Public {
    my $number = 0;

    foreach my $lines (values %{ $_[0]->{entry} }) {
        $number += scalar @$lines;
    }

    return $number;
}

# ================================================================
# Purpose    : get number of lines in body on the dictionary
# Usage      : $number = $self->get_line_of_entries()
# Parameters : none
# Returns    : NUM: number of line in body
# Throws     : no exceptions
# Comments   : none
# See Also   : n/a
# ----------------------------------------------------------------
sub get_line_of_entries : Public {
    return scalar @{ $_[0]->{entries} };
}


# ****************************************************************
# indexer (public method)
# ****************************************************************

# ================================================================
# Purpose    : (re)index entries
# Usage      : $self->index_entries()
# Parameters : none
# Returns    : none
# Throws     : no exceptions
# Comments   : I don't dare to use reference to $self->{entries},
#            : because $self->{entry} has ARRAYREF immediately
# See Also   : n/a
# ----------------------------------------------------------------
sub index_entries : Public {
    my $self = shift;

    $self->{entry} = {};    # to warrant unique key

    foreach my $index (0 .. $#{$self->{entries}}) {
        my $entry = $self->{entries}[$index];
        if (! $entry->{is_comment}) {
            push @{ $self->{entry}{ $entry->{columns}[0] } }, $index;
        }
    }

    return;
}


# ****************************************************************
# accessors to for class constants (protected methods)
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
sub get_comment_sign : Protected {
    return $COMMENT_SIGN;
}

# ================================================================
# Purpose    : ???
# Usage      : ???
# Parameters : ???
# Returns    : ???
# Throws     : ??? / no exceptions
# Comments   : none
# See Also   : n/a
# ----------------------------------------------------------------
sub get_delimiter_of_columns : Protected {
    return $DELIMITER_OF_COLUMNS;
}

# ================================================================
# Purpose    : ???
# Usage      : ???
# Parameters : ???
# Returns    : ???
# Throws     : ??? / no exceptions
# Comments   : none
# See Also   : n/a
# ----------------------------------------------------------------
sub get_void_value : Protected {
    return $VOID_VALUE;
}

1; # magic true value required at end of module
__END__

=head1 NAME

Text::UTX::Simple::Body::Base - internal: base class for Text::UTX::Simple::Body


=head1 SYNOPSIS

    package Text::UTX::Simple::Body::YourInheritance;

    # FOR INTERNAL USE ONLY
    use base qw(Text::UTX::Simple::Body::Base);


=head1 DESCRIPTION

=head2 FOR INTERNAL USE ONLY

This class is part of
L<Text::UTX::Simple::Body|Text::UTX::Simple::Body> class.


=head1 METHODS

=head2 Accessor for class variable

=head3 C<< get_complement_of_void_value() >>

Returns complement of void (C<q{}>) value.


=head2 Mutator for class variable

=head3 C<< set_complement_of_void_value() >>

Sets complement of void (C<q{}>) value.


=head2 Accessors for instance variables

=head3 C<< get_number_of_entries() >>

Returns number of lines of body, I<includes> commented out entries.

=head3 C<< get_line_of_entries() >>

Returns number of lines of body, I<excludes> commented out entries.


=head2 Indexer

=head3 C<< index_entries() >>

Index entries (again).


=head2 Accessors for instance constants

All accessors for instance constants are I<protected>.

=head3 C<< get_comment_sign() >>

Returns comment sign: C<q{#}>.

=head3 C<< get_delimiter_of_columns() >>

Returns delimiter of columns: C<qq{\t}>.

=head3 C<< get_void_value() >>

Returns complement of undefined value: C<q{}>.


=head1 DIAGNOSTICS

Please refer to
L<the Text::UTX::Simple::Manual::Diagnostics documentation|
Text::UTX::Simple::Manual::Diagnostics>
for the explanation of all error messages.


=head1 CONFIGURATION AND ENVIRONMENT

C<Text::UTX::Simple::Body::Base>
requires no configuration files or environment variables.


=head1 DEPENDENCIES

C<Text::UTX::Simple::Body::Base>
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

L<Readonly|Readonly>
- CPAN module

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

=item L<Text::UTX::Simple::Body|Text::UTX::Simple::Body>

Inherited class.

=back


=head1 AUTHOR

=over 4

=item MORIYA Masaki

E<lt>moriya at ermitejo.comE<gt>,
L<http://ttt.ermitejo.com/>

=back

is responsible for
C<Text::UTX::Simple::Body::Base>
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
C<Text::UTX::Simple::Body::Base>,
released C<$Date: 2009-04-16 01:51:54 +0900 (木, 16 4 2009) $>.
