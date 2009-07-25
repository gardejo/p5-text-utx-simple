package Text::UTX::Simple::Body::Dumper;


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
use Carp qw(croak);
use List::MoreUtils qw(uniq);
use Readonly;
use Scalar::Util qw(looks_like_number);
use Storable qw(dclone);


# ****************************************************************
# package global symbols
# ****************************************************************

our $VERSION = '0.02_00';   # $Rev: 61 $


# ****************************************************************
# class constants
# ****************************************************************

Readonly my $COMMENT_SIGN
    => __PACKAGE__->get_comment_sign();
Readonly my $DELIMITER_OF_COLUMNS
    => __PACKAGE__->get_delimiter_of_columns();
Readonly my $VOID_VALUE
    => __PACKAGE__->get_void_value();


# ****************************************************************
# dumper (public method)
# ****************************************************************

# ================================================================
# Purpose    : dumpe the body (entries) of the dictionary
# Usage      : 1) $dumped = $self->dump(\%option)
#            : 2) $dumped = $self->dump(\%option, [@rows])
#            : 3) $dumped = $self->dump([@rows])
# Parameters : *1) HASHREF  option
#            : *2) ARRAYREF queried rows
# Returns    : ARRAYREF results
# Throws     : no exceptions
# Comments   : without "\n" at this stage
# See Also   : n/a
# ----------------------------------------------------------------
sub dump : Public {
    my ($self, $option, $row_query) = @_;

    return
        unless $self->get_line_of_entries();

    # get HASH to ARRAY (and selection)
    my $entries_ref
        = dclone( defined $row_query ? $self->_select_rows($row_query)
                                     : $self->{entries}                );

    # convert "HASH to ARRAY" into "ARRAY to ARRAY",
    # and complement comment sign
    $self->_regularize_dumped_array($entries_ref);

    # projection
    if (defined $option && defined $option->{columns}) {
        $self->_project_columns($entries_ref, $option->{columns});
    }

    # complement void value
    $self->_complement_void_value($entries_ref);

    # return on demand
    return   ! defined $option     ?                        $entries_ref
           : $option->{scalar}     ? $self->_as_string     ($entries_ref)
           : $option->{scalar_ref} ? $self->_as_string     ($entries_ref)
           : $option->{hash}       ? $self->_as_hash       ($entries_ref)
           : $option->{hash_ref}   ? $self->_as_hash       ($entries_ref)
           : $option->{consult}    ? $self->_as_equivalents($entries_ref)
           # means $option->{list} or $option->{array} or $option->{array_ref}
           :                                                $entries_ref;
}


# ****************************************************************
# private methods
# ****************************************************************

# ================================================================
# Purpose    : selection (extraction) from rows
# Usage      : $selected_entries = $self->_select_rows(
# Parameters : ARRAYREF index numbers or entry strings of entries
# Returns    : ARRAYREF selected entries
# Throws     : no exceptions
# Comments   : get slices from $self->{entries} (ARRAY ref)
# See Also   : _rows_to_indexes, _project_columns
# ----------------------------------------------------------------
sub _select_rows : Private {
    my ($self, $rows) = @_;

    return [ @{ $self->{entries} }[ @{ $self->_rows_to_indexes($rows) } ] ];
}

# ================================================================
# Purpose    : projection columns (get columns)
# Usage      : $entries = $self->_project_columns($entries, \@columns)
# Parameters : 1) ARRAYREF entries (rows have ARRAY columns)
#            : 2) ARRAYREF columns (STR and/or INT)
# Returns    : none
# Throws     : if maximum index of query past end of array
# Comments   : none
# See Also   : _columns_to_indexes, _select_rows
# ----------------------------------------------------------------
sub _project_columns : Private {
    my ($self, $entries_ref, $columns_ref) = @_;

    if (! @$columns_ref) {
        foreach my $entry (@$entries_ref) {
            $entry = [];
        }
        return;
    }

    my $column_indexes = $self->_columns_to_indexes($columns_ref);

    # "(-5, 3) = -5", "(-3, 3) = 3"
    my $max_column_index;
    my $max_absolute_index = 0;
    foreach my $column_index (@$column_indexes) {
        my $absolute_index
            = $column_index < 0 ? (abs $column_index) : $column_index + 1;
        if ($max_absolute_index < $absolute_index) {
            $max_absolute_index = $absolute_index;
            $max_column_index   = $column_index;
        }
    }

    foreach my $entry (@$entries_ref) {
        croak "Can't project columns: ",
              "offset ($max_column_index) past end of array"
                unless exists $entry->[$max_column_index];
        @$entry = @{$entry}[@$column_indexes];
    }

    return;
}

# ================================================================
# Purpose    : get row numbers or entries into row indexes
# Usage      : $indexes = $self->_rows_to_indexes(\@rows)
# Parameters : ARRAYREF rows (has INT row number or STR row entriy)
# Returns    : ARRAYREF row indexes (has INT row index)
# Throws     : 1) if row number past end of row array
#            : 2) if row entry isn't found in row hash
# Comments   : none
# See Also   : _select_rows
# ----------------------------------------------------------------
sub _rows_to_indexes : Private {
    my ($self, $rows_ref) = @_;

    my @indexes = map {
        if (looks_like_number($_) && $_ !~ m{\A Inf(?:inity)? \z}xmsi) {
            croak "Can't select rows: offset ($_) past end of array"
                unless exists $self->{entries}[$_];
            $_;
        }
        else {
            croak "Can't select rows: entry ($_) doesn't exist"
                unless exists $self->{entry}{$_};
            @{ $self->{entry}{$_} };
        }
    } @$rows_ref;

    return [ uniq @indexes ];   # don't dare to sort
}

# ================================================================
# Purpose    : get column numbers or column names into column indexes
# Usage      : $indexes = $self->_columns_to_indexes(\@columns)
# Parameters : ARRAYREF columns (has INT column number or STR column name)
# Returns    : ARRAYREF column indexes (has INT columwn index)
# Throws     : no exceptions
# Comments   : none
# See Also   : _project_columns
# ----------------------------------------------------------------
sub _columns_to_indexes : Private {
    my ($self, $columns_ref) = @_;

    my @column_indexes = map {
        looks_like_number($_) && $_ !~ m{\A Inf(?:inity)? \z}xmsi
            ? $_
            : $self->{parent}->name_to_index($_);
    } @$columns_ref;

    return \@column_indexes;
}

# ================================================================
# Purpose    : convert entires's data (HASH to ARRAY) into (ARRAY to ARRAY)
#            : and complement headword by comment sign
# Usage      : $self->_regularize_dumped_array(\@rows)
# Parameters : HASHREF entries (rows have 'is_comment', and 'columns' keys)
# Returns    : ARRAYREF entries (rows have columns)
# Throws     : no exceptions
# Comments   : Can taint (because already dclone()ed!)
# See Also   : dump
# ----------------------------------------------------------------
sub _regularize_dumped_array : Private {
    my ($self, $entries_ref) = @_;

    foreach my $entry (@$entries_ref) {
        if ($entry->{is_comment}) {
            $entry->{columns}[0] = $COMMENT_SIGN . $entry->{columns}[0];
        }
        $entry = $entry->{columns};
    }

    return;
}

# ================================================================
# Purpose    : convert entires's data (ARRAY to ARRAY) into (ARRAY to ARRAY)
# Usage      : $rows = $self->_as_string(\@rows)
# Parameters : ARRAYREF entries (rows have columns)
# Returns    : ARRAYREF entries (rows have joined line)
# Throws     : no exceptions
# Comments   : none
# See Also   : dump
# ----------------------------------------------------------------
sub _as_string : Private {
    my ($self, $entries_ref) = @_;

    foreach my $entry (@$entries_ref) {
        $entry = join $DELIMITER_OF_COLUMNS, @$entry;
    }

    return $entries_ref;
}

# ================================================================
# Purpose    : convert entries' data (HASH to ARRAY) into (HASH to ARRAY)
# Usage      : $rows = $self->_as_hash(\@rows)
# Parameters : ARRAYREF entries (rows have columns)
# Returns    : ARRAYREF entries (rows have {column => value} hashes)
# Throws     : no exceptions
# Comments   : none
# See Also   : dump
# ----------------------------------------------------------------
sub _as_hash : Private {
    my ($self, $entries_ref) = @_;

    foreach my $entry (@$entries_ref) {         # row = ARRAY ref(columns)
        $entry = $self->{parent}->array_to_hash($entry);
    }

    return $entries_ref;
}

# ================================================================
# Purpose    : convert entries' data (ARRAY to ARRAY) into (STR to ARRAY)
# Usage      : $rows = $self->_as_equivalents(\@rows)
# Parameters : ARRAYREF entries (rows have columns)
# Returns    : ARRAYREF entries (rows have target language equivalents)
# Throws     : no exceptions
# Comments   : none
# See Also   : dump
# ----------------------------------------------------------------
sub _as_equivalents : Private {
    my ($self, $entries_ref) = @_;

    foreach my $entry (@$entries_ref) {
        $entry = $entry->[0];                   # always $#{$entry} == 0
    }

    return $entries_ref;
}

# ================================================================
# Purpose    : complement undefined value
# Usage      : $self->_complement_void_value(\@rows)
# Parameters : ARRAYREF: index numbers or column names of header
# Returns    : none
# Throws     : no exceptions
# Comments   : none
# See Also   : dump
# ----------------------------------------------------------------
sub _complement_void_value : Private {
    my ($self, $rows_ref) = @_;

    my $complement_of_void_value = $self->get_complement_of_void_value();
    return
        if $complement_of_void_value eq q{};

    foreach my $columns (@$rows_ref) {
        foreach my $column (@$columns) {
            if ($column eq $VOID_VALUE) {
                $column = $complement_of_void_value;
            }
        }
    }

    return;
}

1; # magic true value required at end of module
__END__

=head1 NAME

Text::UTX::Simple::Body::Dumper - internal: dump entries of UTX-Simple


=head1 SYNOPSIS

    package Text::UTX::Simple::Body::YourInheritance;

    # FOR INTERNAL USE ONLY
    use Text::UTX::Simple::Body::Dumper;


=head1 DESCRIPTION

=head2 FOR INTERNAL USE ONLY

This class is part of
L<Text::UTX::Simple::Body|Text::UTX::Simple::Body> class.


=head1 METHODS

=head2 Dumper

All methods of dumpers are I<protected>.

=head3 C<< dump(\%option) >>

Dumps(generates) formatted lines of the header on the dictionary.

See L<< Text::UTX::Simple::dump_body()|
Text::UTX::Simple/dump_body >>
for further details of usage.


=head1 DIAGNOSTICS

Please refer to
L<the Text::UTX::Simple::Manual::Diagnostics documentation|
Text::UTX::Simple::Manual::Diagnostics>
for the explanation of all error messages.


=head1 CONFIGURATION AND ENVIRONMENT

C<Text::UTX::Simple::Body::Dumper>
requires no configuration files or environment variables.


=head1 DEPENDENCIES

C<Text::UTX::Simple::Body::Dumper>
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

L<List::MoreUtils|List::MoreUtils>
- CPAN module

=item *

L<Readonly|Readonly>
- CPAN module

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
C<Text::UTX::Simple::Body::Dumper>
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
C<Text::UTX::Simple::Body::Dumper>,
released C<$Date: 2009-04-16 01:51:54 +0900 (木, 16 4 2009) $>.
