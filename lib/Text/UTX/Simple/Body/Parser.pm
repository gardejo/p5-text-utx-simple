package Text::UTX::Simple::Body::Parser;


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

use base qw(Text::UTX::Simple::Body::Base);


# ****************************************************************
# dependencies
# ****************************************************************

use Attribute::Util qw(Abstract Alias Protected);
use Carp qw(carp croak);
use Readonly;
use Scalar::Util qw(looks_like_number);


# ****************************************************************
# package global symbols
# ****************************************************************

our $VERSION = '0.02_00';   # $Rev: 59 $


# ****************************************************************
# class constants
# ****************************************************************

Readonly my $COMMENT_SIGN         => __PACKAGE__->get_comment_sign();
Readonly my $DELIMITER_OF_COLUMNS => __PACKAGE__->get_delimiter_of_columns();
Readonly my $VOID_VALUE           => __PACKAGE__->get_void_value();
Readonly my $MAX_RECURSION        => 3;     # stack level (until "N in array")
Readonly my $INEFFECTIVE_VALUE    => q{-};  # explicit null


# ****************************************************************
# parser
# ****************************************************************

# ================================================================
# Purpose    : parse the body on the dictionary
# Usage      : 1) $body = $self->parse(ARRAYREF, HASHREF)
#            : 2) $body = Text::UTX::Simple::Body->parse(ARRAYREF, HASHREF)
# Parameters : 1)  ARRAYREF(ARRAYREF(STR or SCALARREF(STR)))
#            :       lines of formatted text
#            : *2) HASHREF option
# Returns    : *ARRAYREF: parsed data structure (columns array in rows array)
# Throws     : no exceptions
# Comments   : 1) "body" are 3rd and after lines of the formatted strings
#            : 2) "body" are 2nd and after lines until UTX-S 0.90
# See Also   : n/a
# ----------------------------------------------------------------
sub parse : Public {
    my ($self, $elements, $option) = @_;

    my $parsed_rows = $self->get_parsed_rows($elements, $option);
    $self->{entries} = $parsed_rows;    # overwrite (doesn't CORE::push)
    $self->index_entries();

    return;
}

# ================================================================
# Purpose    : get parsed rows
# Usage      : $parsed_rows = $self->get_parsed_rows
#            :                  (\@elements, \%option, $recursion_count)
# Parameters : 1) ARRAYREF UTX-Simple formatted text line(s) (from parse())
#            :    or some DATAREF (from push(), pop(), splice())
#            : 2) HASHREF  option
#            : 3) INT      recursion count (how often have DATA been refer?)
# Returns    : ARRAYREF cloned rows (have ARRAYREF columns)
# Throws     : no exceptions
# Comments   : none
# See Also   : n/a
# ----------------------------------------------------------------
sub get_parsed_rows : Public {
    my ($self, $elements, $option, $recursion) = @_;

    my $rows = $option->{from_parse}
                ? $self->_parse_string($elements, $option)
                : $self->_parse_element
                    ( (scalar @$elements > 1 ? $elements : $elements->[0]),
                      $option,
                      $recursion );

    return $self->_parse_rows($rows, $option);
}


# ****************************************************************
# private methods
# ****************************************************************

# ================================================================
# Purpose    : parse element(s)
# Usage      : $attempted_parsed_rows
#            :  = $self->_parse_element(\@elements, \%option, $recursion_count)
# Parameters : same as get_parsed_rows()
# Returns    : ARRAYREF attempted parsed rows
# Throws     : if 
# Comments   : none
# See Also   : n/a
# ----------------------------------------------------------------
sub _parse_element : Private {
    my ($self, $element, $option, $recursion) = @_;

    if (! exists $option->{parent_class}) {
        $option->{parent_class} = ref $self->{parent};
    }
    my $type = ref $element;

      $type eq 'ARRAY'                 ? return $self->_parse_arrayref
                                                ($element, $option, $recursion)
    : $type eq 'HASH'                  ? return $self->_parse_hashref
                                                ($element)
    : $type eq $option->{parent_class} ? return $self->_parse_instance
                                                ($element)
    : croak "Can't parse an entry: ",
            "argument's class ($type) differs from ",
            "original's class ($option->{parent_class})";
}

# ================================================================
# Purpose    : parse string
# Usage      : $parsed_entries = $self->parse(\@entries)
# Parameters : 1)  ARRAYREF elements (rows have STR line)
#            : *2) HASHREF  option
# Returns    : ARRAYREF rows (have ARRAYREF columns)
# Throws     : no exceptions
# Comments   : 2-arguments split() is invalid once in a while
#            : (when q{} at filal column). Therefore, I use 3-arguments
# See Also   : get_parsed_rows
# ----------------------------------------------------------------
sub _parse_string : Private {
    my ($self, $elements_ref, $option) = @_;

    my @rows;

    LINE:
    foreach my $line (@$elements_ref) {
        # always defined
        # next LINE
        #     if ! defined $line;
        # ignore undefined element and empty line
        chomp $line;
        next LINE
            if $line eq q{};

        # is comment line?
        my $is_comment = ($line =~ s{ \A [$COMMENT_SIGN] }{}xms);

        # get max column offset + 1 (difference between offset and number)
        my $number_of_columns
            = scalar( () = $line =~ m{$DELIMITER_OF_COLUMNS}g ) + 1;

        # build columns from strings of line
        push @rows, {
            is_comment => $is_comment,
            columns    => [
                split $DELIMITER_OF_COLUMNS, $line, $number_of_columns
            ]
        };
    }

    return \@rows;
}

# ================================================================
# Purpose    : parse arrayref(s) and build rows
# Usage      : $parsed_entries
#            :  = $self->_parse_arrayref(\@elements, \%option, $recursion)
# Parameters : 1) ARRAYREF elements (rows or columns)
#            : 2) HASHREF  option
#            : 3) INT      recursion count (how often have DATA been refer?)
# Returns    : ARRAYREF rows (have ARRAYREF columns)
# Throws     : if recursion count exceeds the $MAX_RECURSION
# Comments   : none
# See Also   : _parse_element
# ----------------------------------------------------------------
sub _parse_arrayref : Private {
    my ($self, $elements, $option, $recursion) = @_;

    croak "Can't parse elements: deep recursion"
        if ++ $recursion > $MAX_RECURSION;

    if (ref $elements->[0] eq q{}) {
        return [$elements];
    }

    my @rows;

    foreach my $element (@$elements) {
        push @rows, @{
            ref $element eq 'ARRAY'
                ? $self->_parse_arrayref($element, $option, $recursion)
                : $self->_parse_element ($element, $option, $recursion)
        };
    }

    return \@rows;
}

# ================================================================
# Purpose    : parse hashref and build rows
# Usage      : $rows = $self->_parse_hashref({column => value})
# Parameters : HASHREF  entry/entries as hash
# Returns    : ARRAYREF rows (have ARRAYREF columns)
# Throws     : no exceptions
# Comments   : none
# See Also   : _parse_element
# ----------------------------------------------------------------
sub _parse_hashref : Private {
    my ($self, $column_hashes_ref) = @_;

    return [ $self->{parent}->hash_to_array($column_hashes_ref) ];
}

# ================================================================
# Purpose    : parse instance and build rows
# Usage      : $rows = $self->_parse_instance($instance)
# Parameters : Text::UTX::Simple::Body instance
# Returns    : ARRAYREF rows (have ARRAYREF columns)
# Throws     : if specified instance's class differ from $self's class
# Comments   : none
# See Also   : n/a
# ----------------------------------------------------------------
sub _parse_instance : Private {
    my ($self, $instance) = @_;

    croak "Can't splice entries: argument's columns ",
          "(", (join ', ', @{ $instance->get_columns()       } ), ") ",
          "differ from original's columns ",
          "(", (join ', ', @{ $self->{parent}->get_columns() } ), ")"
            unless $self->{parent}->is_same_format_as($instance);

    return $instance->dump_body({array_ref => 1});
}

# ================================================================
# Purpose    : parse rows
# Usage      : $parsed_rows = $self->_parse_rows(\@rows, \%option)
# Parameters : 1) ARRAYREF raw rows (have ARRAYREF raw columns)
#            : 2) HASHREF  option
# Returns    : ARRAYREF parsed rows (have ARRAYREF parsed columns)
# Throws     : no exceptions
# Comments   : none
# See Also   : get_parsed_rows, _complement_undefined_value
# ----------------------------------------------------------------
sub _parse_rows : Private {
    my ($self, $rows_ref, $option) = @_;

    my $number_of_lines = exists $option->{line} ? $option->{line} : 0;
    my @parsed_entries;

    ROW:
    foreach my $rows (@$rows_ref) {
        my $columns    = ref $rows eq 'HASH' ? $rows->{columns} : $rows;
        $self->_complement_undefined_value($columns);
        my $is_comment = ref $rows eq 'HASH'
            ? $rows->{is_comment}
            : ($columns->[0] =~ s{ \A [$COMMENT_SIGN] }{}xms);

        if (
            $columns->[0] eq $VOID_VALUE        ||
            $columns->[0] eq $INEFFECTIVE_VALUE
        ) {
            carp "Can't parse an entry: headword (first column) ",
                 "is void or is ineffective, therefore, specified ",
                 ( $option->{from_parse}
                        ? ("line (", $number_of_lines + 1, ") ")
                        : ("element ($number_of_lines) "       ) ),
                 "was skipped";
            next ROW;
        }

        if (
            looks_like_number($columns->[0])           &&
            $columns->[0] !~ m{\A Inf(?:inity)? \z}xmsi
        ) {
            carp "Can't parse an entry: headword (first column) ",
                 "looks like number, therefore, specified ",
                 ( $option->{from_parse}
                        ? ("line (", $number_of_lines + 1, ") ")
                        : ("element ($number_of_lines) "       ) ),
                 "was skipped";
            next ROW;
        }

        push @parsed_entries, {
            columns    => $columns,
            is_comment => $is_comment,
        };
        $number_of_lines++;     # line 2 .. N
    }

    return \@parsed_entries;
}

# ================================================================
# Purpose    : complement undefined value
# Usage      : $self->_complement_undefined_value(\@columns)
# Parameters : ARRAYREF columns have STR column value
# Returns    : none
# Throws     : no exceptions
# Comments   : always run (regardless of value of $COMPLEMENT_OF_VOID_VALUE)
# See Also   : _parse_rows
# ----------------------------------------------------------------
sub _complement_undefined_value : Private {
    my ($self, $columns) = @_;

    foreach my $column (@$columns) {
        if (! defined $column) {
            $column = $VOID_VALUE;
        }
    }

    return;
}

1; # magic true value required at end of module
__END__

=head1 NAME

Text::UTX::Simple::Body::Parser - internal: parse entries of UTX-Simple


=head1 SYNOPSIS

    package Text::UTX::Simple::Body::YourInheritance;

    # FOR INTERNAL USE ONLY
    use Text::UTX::Simple::Body::Parser;


=head1 DESCRIPTION

=head2 FOR INTERNAL USE ONLY

This class is part of
L<Text::UTX::Simple::Body|Text::UTX::Simple::Body> class.


=head1 METHODS

=head2 Parser

=head3 C<< parse(\@elements, \%option) >>

Parses formatted lines of the entries on the dictionary.

See L<< Text::UTX::Simple::dump_body($utx_formatted_text)|
Text::UTX::Simple/parse($utx_formatted_text) >>
for further details of usage.

=head3 C<< get_parsed_rows(\@elements, \%option) >>

Parses any data-types and returns ARRAY to ARRAY for C<parse()>.
This method is I<protected>.


=head1 DIAGNOSTICS

Please refer to
L<the Text::UTX::Simple::Manual::Diagnostics documentation|
Text::UTX::Simple::Manual::Diagnostics>
for the explanation of all error messages.


=head1 CONFIGURATION AND ENVIRONMENT

C<Text::UTX::Simple::Body::Parser>
requires no configuration files or environment variables.


=head1 DEPENDENCIES

C<Text::UTX::Simple::Body::Parser>
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
C<Text::UTX::Simple::Body::Parser>
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

This document describes version 0.02_00 ($Rev: 59 $) of
C<Text::UTX::Simple::Body::Parser>,
released C<$Date: 2009-04-12 06:04:24 +0900 (日, 12 4 2009) $>.
