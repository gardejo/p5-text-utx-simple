package Text::UTX::Simple::Header::Column;


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
use Carp qw(croak);
use Readonly;
use Scalar::Util qw(looks_like_number);


# ****************************************************************
# package global symbols
# ****************************************************************

our $VERSION = '0.02_00';   # $Rev: 59 $


# ****************************************************************
# class constants
# ****************************************************************

# to do: changeable
Readonly my $COMPLEMENT_OF_UNDEFINED_COLUMN => q{(UNDEFINED)};


# ****************************************************************
# accessor for instance (public method)
# ****************************************************************

# ================================================================
# Purpose    : get number of columns on the dictionary
# Usage      : $number_of_columns = $self->get_number_of_columns()
# Parameters : none
# Returns    : NUM: number of columns on the dictionary
# Throws     : no exceptions
# Comments   : FOR INTERNAL USE ONLY
# See Also   : n/a
# ----------------------------------------------------------------
sub get_number_of_columns : Public {
    return scalar @{ $_[0]->{index_to_name} };
}


# ****************************************************************
# converters (public methods)
# ****************************************************************

# ================================================================
# Purpose    : get a column index from the specified column name
# Usage      : 1) $column_index       = $self->name_to_index(STR)
#            : 2) $column_indexes_ref = $self->name_to_index(ARRAYREF)
# Parameters : HASHREF
#            :   STR or ARRAYREF(STR) column_name: column name(s) on the dict.
# Returns    : NUM or ARRAYREF(NUM): column index(es) on the dictionary
# Throws     : 1) if $option->{column_name} undefined
#            : 2) if $option->{column_name}'s type isn't ARRAYREF or SCALAR
# Comments   : 1) FOR INTERNAL USE ONLY
#            : 2) convert ['src', 'tgt', 'src:pos'] into [0, 1, 2]
# See Also   : _name_to_index, index_to_name
# ----------------------------------------------------------------
sub name_to_index : Public {
    my ($self, $option) = @_;

    croak "Can't convert column name into column index: ",
          "column name isn't defined"
            unless defined $option->{column_name};

    my $type = ref $option->{column_name};

      $type eq 'ARRAY' ? return $self->_name_to_index
                            ({ %$option,
                               array_ref  => 1 })
    : $type eq q{}     ? return $self->_name_to_index
                            ({column_name => [$option->{column_name}],
                              array_ref   => 0})
    :                    croak "Can't convert column name into column index: ",
                               "type of column name (",
                                ref($option->{column_name}), ") isn't valid";
}

# ================================================================
# Purpose    : get a column name from the specified column index
# Usage      : 1) $column_name      = $utx->index_to_name(NUM)
#            : 2) $column_names_ref = $utx->index_to_name(ARRAYREF)
# Parameters : HASHREF
#            :   STR or ARRAYREF(STR) column_index: column index(es) on the d.
#            :   BOOL is_defined_column_only: "true" has undefined column name
# Returns    : NUM or ARRAYREF(NUM): column index(es) on the dictionary
# Throws     : if $option->{column_index} undefined
# Comments   : 1) FOR INTERNAL USE ONLY
#            : 2) convert [0, 1, 2] into ['src', 'tgt', 'src:pos']
# See Also   : _index_to_name, name_to_index
# ----------------------------------------------------------------
sub index_to_name : Public {
    my ($self, $option) = @_;

    croak "Can't convert column index into column name: ",
          "column index isn't defined"
            unless defined $option->{column_index};

    my $type = ref $option->{column_index};

      $type eq 'ARRAY' ? return $self->_index_to_name
                            ({ %$option,
                               array_ref  => 1 })
    : $type eq q{}     ? return $self->_index_to_name
                            ({ %$option,
                               column_index => [$option->{column_index}],
                               array_ref    => 0})
    :                    croak "Can't convert column index into column name: ",
                               "type of column index (",
                               ref($option->{column_index}), ") isn't valid";
}

# ================================================================
# Purpose    : get {column => value} hash from column values
# Usage      : $hash_ref = $self->array_to_hash(ARRAYREF)
# Parameters : HASHREF
#            :   ARRAYREF entry_array: column definition(s)
#            :   BOOL is_defined_column_only: "true" has undefined column name
# Returns    : HASHREF(STR key => STR value): alignments of entry columns
# Throws     : 1) if $option->{entry_array} undefined
#            : 2) if $option->{entry_array}'s type isn't ARRAYREF
#            : 3) if detected column name isn't defined on header,
#            :    when is_defined_column_only(1)
# Comments   : 1) FOR INTERNAL USE ONLY
#            : 2) convert [value0, value1]
#            :    into {column0=>value0, column1=>value1}
# See Also   : hash_to_array
# ----------------------------------------------------------------
sub array_to_hash : Public {
    my ($self, $option) = @_;

    croak "Can't convert entry array into entry hash: ",
          "entry array isn't defined"
            unless defined $option->{entry_array};
    croak "Can't convert entry array into entry hash: ",
          "type of entry array ",
          "(", $option->{entry_array}, ") isn't an ARRAY reference"
            if ref $option->{entry_array} ne 'ARRAY';

    my %entry_hash;

    foreach my $column_index (0 .. $#{ $option->{entry_array} }) {
        my $column_name = $self->{index_to_name}[$column_index];
        if (! defined $column_name) {
            if ($option->{is_defined_column_only}) {
                croak "Can't convert entry array into entry hash: ",
                      "column index ($column_index) isn't defined on header";
            }
            else {
                $column_name
                    = $self->_complement_undefined_column_name($column_index);
            }
        }
        $entry_hash{$self->localize_column_names($column_name)}
            = $option->{entry_array}[$column_index];
    }

    return \%entry_hash;
}

# ================================================================
# Purpose    : get column values from {column => value} hash
# Usage      : $array_ref = $self->hash_to_array(HASHREF)
# Parameters : HASHREF
#            :   HASHREF entry_hash: column definition(s)
# Returns    : ARRAYREF(STR value): values of entry columns
# Throws     : 1) if $option->{entry_hash} undefined
#            : 2) if $option->{entry_hash}'s type isn't HASHREF
#            : 3) if detected column name isn't defined on header
# Comments   : 1) FOR INTERNAL USE ONLY
#            : 2) conver {column0=>value0, column1=>value1}
#            :    into [value0, value1]
# See Also   : array_to_hash
# ----------------------------------------------------------------
sub hash_to_array : Public {
    my ($self, $option) = @_;

    croak "Can't convert entry hash into entry array: ",
          "entry hash isn't defined"
            unless defined $option->{entry_hash};
    croak "Can't convert entry hash into entry array: ",
          "type of entry hash ",
          "(", $option->{entry_hash}, ") isn't a HASH reference"
            if ref $option->{entry_hash} ne 'HASH';

    my @entry_array;

    while (
        my ($column_name, $column_value)
            = each %{ $option->{entry_hash} }
    ) {
        my $canonized_column_name
            = $self->canonize_column_names($column_name);
        my $column_index = $self->{name_to_index}{$canonized_column_name};
        if (defined $column_index) {
            $entry_array[$column_index] = $column_value;
        }
        else {
            croak "Can't convert entry hash into entry array: ",
                  "column name ($column_name) isn't defined on header";
        }
    }

    return \@entry_array;
}


# ****************************************************************
# parts of converters (protected methods)
# ****************************************************************

# ================================================================
# Purpose    : ???
# Usage      : ???
# Parameters : ???
# Returns    : ???
# Throws     : ??? / no exceptions
# Comments   : Override it when 0.90 (it is not abstract method)
# See Also   : n/a
# ----------------------------------------------------------------
sub canonize_column_names : Protected {
    return $_[1];
}

# ================================================================
# Purpose    : ???
# Usage      : ???
# Parameters : ???
# Returns    : ???
# Throws     : ??? / no exceptions
# Comments   : Override it when 0.90 (it is not abstract method)
# See Also   : n/a
# ----------------------------------------------------------------
sub localize_column_names : Protected {
    return $_[1];
}


# ****************************************************************
# private mehods
# ****************************************************************

# ================================================================
# Purpose    : practical process of $self->_name_to_index
# Usage      : 1) $column_index       = $self->_name_to_index(HASHREF)
#            : 2) $column_indexes_ref = $self->_name_to_index(HASHREF)
# Parameters : HASHREF
#            :   ARRAYREF column_name: column name(s)
#            :   BOOL array_ref: true: returns ARRAYREF(NUM) / returns NUM
# Returns    : NUM(Param=NUM) or ARRAYREF(NUM; Param=ARRAYREF): column index(es)
# Throws     : 1) if column name isn't defined
#            : 2) if column name doesn't exist on the header
# Comments   : none
# See Also   : name_to_index
# ----------------------------------------------------------------
sub _name_to_index : Private {
    my ($self, $option) = @_;

    my @column_indexes;

    # my %column_name
    #     = mesh @{ $option->{column_name} },
    #            @{ $self->canonize_column_names($option->{column_name}) };
    # while (
    #     my ($specified_column_name, $canonized_column_name)
    #         = each %column_name
    # )
    foreach my $column_name (@{ $option->{column_name} }) {
        croak "Can't convert column name into column index: ",
              "column name at argument's offset ",
              "(", (scalar @column_indexes), ") isn't defined"
                unless defined $column_name;

        my $column_index
            = $self->{name_to_index}
                {$self->canonize_column_names($column_name)};
        if (defined $column_index) {
            push @column_indexes, $column_index;
        }
        else {
            croak "Can't convert column name into column index: ",
                  "column name ($column_name) isn't defined on header";
        }
    }

    return   $option->{array_ref} ? \@column_indexes
           :                         $column_indexes[0];
}

# ================================================================
# Purpose    : practical process of $self->_index_to_name
# Usage      : 1) $column_name      = $self->_index_to_name(HASHREF)
#            : 2) $column_names_ref = $self->_index_to_name(HASHREF)
# Parameters : HASHREF
#            :   ARRAYREF column_index: column index(es)
#            :   BOOL array_ref: true: returns ARRAYREF(STR) / returns STR
# Returns    : STR(Param=STR) or ARRAYREF(STR; Param=ARRAYREF): column names
# Throws     : 1) if column index isn't defined
#            : 2) if column index doesn't look like number
#            : 3) if column index as negative value past end of array
#            : 4) if detected column name isn't defined on the header,
#            :    when is_defined_column_only(1)
# Comments   : none
# See Also   : index_to_name
# ----------------------------------------------------------------
sub _index_to_name : Private {
    my ($self, $option) = @_;

    my @column_names;

    foreach my $column_index (@{ $option->{column_index} }) {
        croak "Can't convert column index into column name: ",
              "column index at argument's offset ",
              "(", (scalar @column_names), ") isn't defined"
                unless defined $column_index;
        croak "Can't convert column index into column name: ",
              "column index ($column_index) isn't number"
                if ! looks_like_number($column_index)
                || $column_index =~ m{\A Inf(?:inity)? \z}xmsi;
        croak "Can't convert column index into column name: ",
              "column index ($column_index) past end of array"
                if - $column_index >= $self->get_number_of_columns();

        my $column_name = $self->{index_to_name}[$column_index];
        if (! defined $column_name) {
            if ($option->{is_defined_column_only}) {
                croak "Can't convert column index into column name: ",
                      "column index ($column_index) isn't defined on header";
            }
            else {
                $column_name = $column_index
                    = $self->_complement_undefined_column_name($column_index);
            }
        }
        push @column_names,
            $self->localize_column_names($column_name);
    }

    return   $option->{array_ref} ? \@column_names
           :                         $column_names[0];
}

# ================================================================
# Purpose    : complement undefined column name
# Usage      : $column_name = $self->_complement_undefined_column_name(NUM)
# Parameters : NUM: column index
# Returns    : STR: complemented column name
# Throws     : no exceptions
# Comments   : none
# See Also   : array_to_hash, index_to_name
# ----------------------------------------------------------------
sub _complement_undefined_column_name : Private {
    return $_[1] . $COMPLEMENT_OF_UNDEFINED_COLUMN;
}


1; # magic true value required at end of module
__END__

=head1 NAME

Text::UTX::Simple::Header::Column - internal: treat columns on header of UTX-Simple


=head1 SYNOPSIS

    package Text::UTX::Simple::Header::YourInheritance;

    # FOR INTERNAL USE ONLY
    use base qw(Text::UTX::Simple::Header::Column);


=head1 DESCRIPTION

=head2 FOR INTERNAL USE ONLY

This class is part of
L<Text::UTX::Simple::Header|Text::UTX::Simple::Header> class.


=head1 METHODS

Please refer to
L<the document of Text::UTX::Simple|Text::UTX::Simple>
for the explanation of all the public methods.

=head2 Accessor

=head3 C<< get_number_of_columns() >>

Returns number of columns.

See L<< Text::UTX::Simple::get_number_of_columns()|
Text::UTX::Simple/get_number_of_columns() >>
for further details of usage.


=head2 Converters

All converters are I<protected>.

=head3 C<< name_to_index(\%option) >>

Converts column name(s) into column index(es).

    my $column_name = $utx->name_to_index('src');
    # 0, if UTX-S 0.91+

See L<< Text::UTX::Simple::name_to_index($column_names)|
Text::UTX::Simple/name_to_index($column_names) >>
for further details of usage.

=head3 C<< index_to_name(\%option) >>

Converts column index(es) into column name(s).

    my $column_index = $utx->index_to_name(0);
    # 'src', if UTX-S 0.91+

See L<< Text::UTX::Simple::index_to_name($column_indexes)|
Text::UTX::Simple/index_to_name($column_indexes) >>
for further details of usage.

=head3 C<< array_to_hash(\%option) >>

Converts column value(s) as an ARRAY reference into a HASH reference.

    my $columns_as_hash = $utx->array_to_hash([qw(foo bar)]);
    # { 'src' => 'foo', 'tgt' => 'bar' }, if UTX-S 0.91+

See L<< Text::UTX::Simple::array_to_hash($entry_array)|
Text::UTX::Simple/array_to_hash($entry_array) >>
for further details of usage.

=head3 C<< hash_to_array(\%option) >>

Converts column value(s) as a HASH reference into an ARRAY reference.

    my $columns_as_array = $utx->hash_to_array({ 'src' => 'foo' });
    # [qw(foo)], if UTX-S 0.91+

See L<< Text::UTX::Simple::hash_to_array($entry_hash)|
Text::UTX::Simple/hash_to_array($entry_hash) >>
for further details of usage.


=head2 Parts of convertes

=head3 C<< canonize_column_names($column_names) >>

Converts local column names into canonical column names.

Note: This method implemented by this class has no operation.
This method may be override in concrete class(es).
For example,
L<Text::UTX::Simple::Version::Header::V0_90|
  Text::UTX::Simple::Version::Header::V0_90>
is overrides it.

=head3 C<< localize_column_names($column_names) >>

Converts cjanonical column names into local column names.

Note: This method implemented by this class has no operation.
This method may be override in concrete class(es).
For example,
L<Text::UTX::Simple::Version::Header::V0_90|
  Text::UTX::Simple::Version::Header::V0_90>
is overrides it.


=head1 DIAGNOSTICS

Please refer to
L<the Text::UTX::Simple::Manual::Diagnostics documentation|
Text::UTX::Simple::Manual::Diagnostics>
for the explanation of all error messages.


=head1 CONFIGURATION AND ENVIRONMENT

C<Text::UTX::Simple::Header::Column>
requires no configuration files or environment variables.


=head1 DEPENDENCIES

C<Text::UTX::Simple::Header::Column>
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

=over 4

=item *

To changeable class constant C<$COMPLEMENT_OF_UNDEFINED_COLUMN>.

=back


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
C<Text::UTX::Simple::Header::Column>
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
C<Text::UTX::Simple::Header::Column>,
released C<$Date: 2009-04-12 06:04:24 +0900 (日, 12 4 2009) $>.
