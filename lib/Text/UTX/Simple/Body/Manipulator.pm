package Text::UTX::Simple::Body::Manipulator;


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

use base qw(Text::UTX::Simple::Body::Parser);


# ****************************************************************
# dependencies
# ****************************************************************

use Attribute::Util qw(Abstract Alias Protected);
use Carp qw(carp croak);
use English;
use Scalar::Util qw(looks_like_number);


# ****************************************************************
# package global symbols
# ****************************************************************

our $VERSION = '0.02_00';   # $Rev: 61 $


# ****************************************************************
# manipulators
# ****************************************************************

# ================================================================
# Purpose    : splice entry/entries together the dictionary
# Usage      : $spliced = $self->splice($offset, $length, @elements)
# Parameters : 1)  INT  starting offset of removing
#            : *2) INT  length number of removing
#            : *3) LIST additional elements
# Returns    : *Text::UTX::Simple object (includes removed entry/entries)
# Throws     : no exceptions
# Comments   : same as CORE::splice
# See Also   : _complement_offset, _get_number_of_manipulating_entries,
#            : _complement_remove_length, index_entries
# ----------------------------------------------------------------
sub splice : Public {
    my ($self, $offset, $remove_length, $additional_elements) = @_;

    # complement arugments
    my $number_of_entries;
    eval {
        $offset
            = $self->_complement_offset($offset);
        $number_of_entries
            = $self->_get_number_of_manipulating_entries($offset);
        $remove_length
            = $self->_complement_remove_length
                ($offset, $remove_length, $number_of_entries);
    };
    if ($EVAL_ERROR) {
        carp $EVAL_ERROR;
        return;
    };
    return
        if $remove_length < 0;

    # update itself
    my @removed_entries
        = splice @{ $self->{entries} }, $offset, $remove_length,
            (defined $additional_elements ? @$additional_elements : ());
    $self->index_entries();
    return
        if ! defined wantarray
        || ! @removed_entries;

    # return removed entries as a new Text::UTX::Simple instance
    my $removed_instance = $self->{parent}->clone();
    $removed_instance->clear();
    # $removed_instance->push(\@removed_entries);
    $removed_instance->{body}{entries} = \@removed_entries;
    $removed_instance->{body}->index_entries();

    return $removed_instance;
}

# ================================================================
# Purpose    : sort entries on the dictionary
# Usage      : $self->sort()
# Parameters : none
# Returns    : none
# Throws     : always throws (not implemented at this time)
# Comments   : 1) *** UNCOMPLETELY IMPLEMENTED ***
#            :    temporary implementation now
#            : 2) call with CODE reference? $self->sort(\&sort_routine)
# See Also   : n/a
# ----------------------------------------------------------------
sub sort : Public {
    my $self = shift;

    # my @sorted_rows = map {     # get sorted rows by Schwartz conversion
    #     $_->[0];
    # } sort {
    #     $a->[1] cmp $b->[1];    # or, use your favorite sort routine here
    # } map {
    #     [ $_, $_->[0] ];        # $_->[0] means first column (headword)
    # } @{ $self->dump({array_ref => 1}) };   # all entries

    @{ $self->{entries} } = map {
        $_->[0];
    } sort {
        $a->[1] cmp $b->[1] ||
        # undefined "tgt" column is always complemented by q{}!
        # defined $a->[2] && defined $b->[2] && $a->[2] cmp $b->[2]
        $a->[2] cmp $b->[2]
    } map {
        [ $_, $_->{columns}[0], $_->{columns}[1] ];
    } @{ $self->{entries} };

    $self->index_entries();

    return;
}

# ================================================================
# Purpose    : clear all entries on the dictionary
# Usage      : $self->clear()
# Parameters : none
# Returns    : none
# Throws     : no exceptions
# Comments   : none
# See Also   : n/a
# ----------------------------------------------------------------
sub clear : Public {
    my $self = shift;

    $self->{entries} = [];
    $self->{entry}   = {};

    return;
}


# ****************************************************************
# private methods
# ****************************************************************

# ================================================================
# Purpose    : complement splice()'s offset
# Usage      : $self->_complement_offset($offset)
# Parameters : *INT offset value
# Returns    : INT  offset value
# Throws     : offset does not look like number
# Comments   : same as CORE::splice
# See Also   : splice
# ----------------------------------------------------------------
sub _complement_offset : Private {
    my ($self, $offset) = @_;

    $offset = defined $offset ? $offset : 0;

    croak "Can't splice entries: argument offset ($offset) isn't numeric"
        if ! looks_like_number($offset)
        || $offset =~ m{\A Inf(?:inity)? \z}xmsi;

    return $offset;
}

# ================================================================
# Purpose    : get number of entries on the dictionary
# Usage      : $self->_get_number_of_manipulating_entries($offset)
# Parameters : INT offset value
# Returns    : INT number of entries
# Throws     : absolute value of offset is more than number of entries
# Comments   : same as CORE::splice
# See Also   : splice
# ----------------------------------------------------------------
sub _get_number_of_manipulating_entries : Private {
    my ($self, $offset) = @_;

    my $number_of_entries = $self->get_line_of_entries();

    croak "Can't splice entries: offset past end of array"
            if $offset > $number_of_entries;
    croak "Can't splice entries: ",
          "modification of non-creatable array value attempted"
            if abs $offset > $number_of_entries;

    return $number_of_entries;
}

# ================================================================
# Purpose    : complement splice()'s removing length
# Usage      : $self->_complement_remove_length($offset, $length, $number)
# Parameters : 1) INT offset value
#            : 2) INT removing length
#            : 3) INT number of entries
# Returns    : INT removing length
# Throws     : offset does not look like number
# Comments   : same as CORE::splice
# See Also   : splice
# ----------------------------------------------------------------
sub _complement_remove_length : Private {
    my ($self, $offset, $remove_length, $number_of_entries) = @_;

    if (! defined $remove_length) {
        $remove_length = $offset >= 0 ? scalar $number_of_entries - $offset
                       :                abs                         $offset;
    }

    croak "Can't splice entries: ",
          "argument length ($remove_length) isn't numeric"
            if ! looks_like_number($remove_length)
            || $remove_length =~ m{\A Inf(?:inity)? \z}xmsi;

    return $remove_length;
}


1; # magic true value required at end of module
__END__

=head1 NAME

Text::UTX::Simple::Body::Manipulator - internal: manipulate UTX-Simple entries

=head1 SYNOPSIS

    package Text::UTX::Simple::Body::YourInheritance;

    # FOR INTERNAL USE ONLY
    use Text::UTX::Simple::Body::Manipulator;


=head1 DESCRIPTION

=head2 FOR INTERNAL USE ONLY

This class is part of
L<Text::UTX::Simple::Body|Text::UTX::Simple::Body> class.


=head1 METHODS

=head2 Manipulators

All methods of manipulators are I<protected>.

=head3 C<< splice($offset, $remove_length, $additional_elements) >>

Splices entries.

See L<< Text::UTX::Simple::push($entries)|
Text::UTX::Simple/push($entries) >>,
L<< Text::UTX::Simple::pop()|
Text::UTX::Simple/pop() >>,
L<< Text::UTX::Simple::unshift($entries)|
Text::UTX::Simple/unshift($entries) >>,
L<< Text::UTX::Simple::shift()|
Text::UTX::Simple/shift() >>, and
L<< Text::UTX::Simple::splice($offset, $length, $entries)|
Text::UTX::Simple/splice($offset,_$length,_$entries) >>
for further details of usage.

=head3 C<< sort() >>

Sorts entries.

See L<< Text::UTX::Simple::sort()|
Text::UTX::Simple/sort() >>
for further details of usage.

=head3 C<< clear() >>

Clears all entries.

See L<< Text::UTX::Simple::clear()|
Text::UTX::Simple/clear() >>
for further details of usage.


=head1 DIAGNOSTICS

Please refer to
L<the Text::UTX::Simple::Manual::Diagnostics documentation|
Text::UTX::Simple::Manual::Diagnostics>
for the explanation of all error messages.


=head1 CONFIGURATION AND ENVIRONMENT

C<Text::UTX::Simple::Body::Manipulator>
requires no configuration files or environment variables.


=head1 DEPENDENCIES

C<Text::UTX::Simple::Body::Manipulator>
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

L<English|English>
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
C<Text::UTX::Simple::Body::Manipulator>
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
C<Text::UTX::Simple::Body::Manipulator>,
released C<$Date: 2009-04-16 01:51:54 +0900 (木, 16 4 2009) $>.
