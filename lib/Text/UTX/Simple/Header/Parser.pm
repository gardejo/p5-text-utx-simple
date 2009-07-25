package Text::UTX::Simple::Header::Parser;


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
    Text::UTX::Simple::Header::Validator
    Text::UTX::Simple::Header::Base
);


# ****************************************************************
# dependencies
# ****************************************************************

use Attribute::Util qw(Abstract Alias Protected);
use Carp qw(croak);
use List::MoreUtils qw(any apply mesh notall);
use List::Util qw(first);


# ****************************************************************
# package global symbols
# ****************************************************************

our $VERSION = '0.02_00';   # $Rev: 59 $


# ****************************************************************
# interface to parser (protected methods)
# ****************************************************************

# ================================================================
# Purpose    : parse the header on the dictionary
# Usage      : $self->parse(\@lines)
# Parameters : ARRAYREF: target strings of parsing (lines of text)
# Returns    : none
# Throws     : if strings aren't defined
# Comments   : 1) FOR INTERNAL USE ONLY
#            : 2) header is the first (and more) line of the formatted strings
#            : 3) attribute_has_cap : 0.90 is true, 0.91+ are false
#            : 4) Template Method for Factory Method pattern
#            : 5) create parse object??
# See Also   : _validate
# ----------------------------------------------------------------
sub parse : Public {
    my ($self, $lines_ref) = @_;
    croak "Can't parse the header: header strings isn't defined"
        unless defined $lines_ref;      # can't happen

    # there is difference between versions of the UTX-Simple specification
    my ($general_header, $column_header)
        = @{ $self->get_header_lines($lines_ref) };

    my $new_version = $self->guess_version($general_header);
    $self->validate_version_kind($new_version);     # try numeric checking
    croak "Can't parse the header: ",
          "attempt to parse incompatible version ($new_version) string ",
          "with the version (", $self->{version}, ") dictionary"
            unless $self->is_compatible_with($new_version);
    if ($self->{version} != $new_version) {
        $self = $self->re_bless($new_version);
    }

    my $attribute = $self->get_attribute();
    my $delimiter = $self->get_delimiter();

    # get fields on header line
    my $suspicious_field = $self->_get_suspicious_field({
        header_string     => $general_header,
        attribute         => $attribute,
        attribute_has_cap => scalar @{ $attribute->{optional} },
        delimiter         => $delimiter,
    });
    if ($column_header) {
        $suspicious_field->{user_defined_columns} = $column_header;
    }
    if (defined $suspicious_field->{user_defined_columns}) { # always exists
        $self->parse_user_defined_columns($suspicious_field, $delimiter);
    }

    # overwrite field by valid field
    %$self = (%$self, %{ $self->validate($suspicious_field, $delimiter) });
    $self->index_columns();

    return;
}


# ****************************************************************
# parts of parser (protected methods)
# ****************************************************************

# ================================================================
# Purpose    : parse user defined columns on the dictionary
# Usage      : 1) $self->parse_user_defined_columns
#            :    (\A # src \t tgt \t src:pos \t src:foo tgt:bar baz \r?\n? \z)
#            : 2) $self->parse_user_defined_columns
#            :    ([qw( src    tgt    src:pos    src:foo tgt:bar baz)])
#            : 3) $self->parse_user_defined_columns
#            :    ([qw(                          src:foo tgt:bar baz)])
# Parameters : 1) STR or ARRAYREF (basic and) user defined columns
# Returns    : none
# Throws     : xxxx
# Comments   : 1) undef takes no effect
#            : 2) empty takes no effect at child subroutine,
#            : 3) 0 is invalid, throws exception at child subroutine
# See Also   : n/a
# ----------------------------------------------------------------
sub parse_user_defined_columns : Protected {
    my ($self, $suspicious_field, $delimiter) = @_;

    my $definition = $suspicious_field->{user_defined_columns};

    croak "Can't parse the header: ",
          "user defined column is specified, but isn't defined"
            unless defined $definition;
    croak "Can't parse the header: ",
          "user defined column is specified, but isn't filled"
            if $definition eq q{};
    croak "Can't parse the header: ",
          "type of user defined column isn't a SCALAR or an ARRAY reference"
            if ref $definition ne ''
            && ref $definition ne 'ARRAY';

    my $basic_column          = $self->get_default_field()->{column}{basic};
    my %reversed_basic_column = reverse %$basic_column;           # 0 => 'src'
    my $basic_index           = (scalar keys %$basic_column) - 1; # 2 (fixed)
    my $definition_is_string  = ref $definition eq '';

    croak "Can't parse the header: ",
          "definition list has undefined element"
            if ! $definition_is_string
            && notall { defined $_ } @$definition;

    my @user_defined_columns
        = $definition_is_string ? split $delimiter->{columns}, $definition
                                : @$definition;
    $self->regularize_user_defined_columns
        (\@user_defined_columns, $delimiter, \%reversed_basic_column,
            $basic_index, $definition_is_string);

    $suspicious_field->{column} = {
        basic => $basic_column,
        user  => $self->_index_user_defined_columns
                    (\@user_defined_columns, $basic_index),
    };
    delete $suspicious_field->{user_defined_columns};

    return;
}

# ================================================================
# Purpose    : ???
# Usage      : ???
# Parameters : ???
# Returns    : ???
# Throws     : ??? / no exceptions
# Comments   : for 0.91+
# See Also   : n/a
# ----------------------------------------------------------------
sub remove_basic_columns_from : Protected {
    my ($self, $mixed_columns, $basic_column, $basic_index,
        $definition_is_string) = @_;

    my @removed_columns = splice @$mixed_columns, 0, $basic_index + 1;
    if ($definition_is_string) {
        # croak "$_" for first { .... } ...
        my $index_of_invalid_column = first {
            $removed_columns[$_] ne $basic_column->{$_};
        } (0 .. $basic_index);
        croak "Can't parse the header: ",
              "column ($index_of_invalid_column) isn't basic column"
                if defined $index_of_invalid_column;
    }
    elsif (
        any {
            $removed_columns[$_] ne $basic_column->{$_};
        } (0 .. $basic_index)
    ) {
        unshift @$mixed_columns, @removed_columns;
    }

    return;
}

# ================================================================
# Purpose    : ???
# Usage      : ???
# Parameters : ???
# Returns    : ???
# Throws     : ??? / no exceptions
# Comments   : Override it when 0.91+ (it is not abstract method)
# See Also   : n/a
# ----------------------------------------------------------------
sub regularize_mandatory_properties : Protected {
    return;
}


# ****************************************************************
# private methods
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
sub _get_suspicious_field : Private {
    my ($self, $option) = @_;

    my $header_property = $self->_delimit_properties($option);
    $self->regularize_mandatory_properties($header_property, $option);
    $self->_regularize_optional_properties($header_property, $option);

    return {
        %{ $header_property->{mandatory} },
        ( exists $header_property->{optional}
                ? %{ $header_property->{optional} }
                : () )
    };
}

# ================================================================
# Purpose    : ???
# Usage      : ???
# Parameters : ???
# Returns    : ???
# Throws     : ??? / no exceptions
# Comments   : Because "user defined columns" on UTX-S 0.90 allow including
#            : white-space, @all_values must determine max index. Therefore,
#            : length of @all_values is always (same with | less than)
#            : length of @mandatory_attributes + @optional_attributes!
# See Also   : n/a
# ----------------------------------------------------------------
sub _delimit_properties : Private {
    my ($self, $option) = @_;

    my @mandatory_attributes           = @{ $option->{attribute}{mandatory} };
    my @optional_attributes            = @{ $option->{attribute}{optional}  };
    my $length_of_mandatory_attributes = scalar @mandatory_attributes;

    # my @all_values;
    # if ($option->{attribute_has_cap}) {
    #     @all_values = split $option->{delimiter}{elements},
    #                         $option->{header_string};
    # }
    # else {
    #     @all_values = split $option->{delimiter}{elements},
    #                         $option->{header_string},
    #                         $length_of_mandatory_attributes + 1; # optional
    # }
    my @all_values = split $option->{delimiter}{elements},
                           $option->{header_string},
                           $length_of_mandatory_attributes + 1;
                           # +1 is columns(0.90) or miscellany(0.91+)
    @all_values = apply {
        $_ =~ s{ \A \s* | \s* \z }{}xmsg;
    } @all_values;
    my $length_of_parsed_attributes = scalar @all_values;
    croak "Can't parse the header: ",
          "string lacks mandatory header properties ",
          "($length_of_parsed_attributes attributes is smaller than ",
          "$length_of_mandatory_attributes mandatory attributes)"
            if $length_of_parsed_attributes < $length_of_mandatory_attributes;

    my $optional_property;
    if ($option->{attribute_has_cap}) {
        # always pass
        # croak "Can't parse the header: ",
        #       "string has $length_of_parsed_attributes attributes, ",
        #       "but it is larger than ",
        #       "$length_of_mandatory_attributes mandatory ",
        #       "(and ", scalar(@optional_attributes), " optional) attributes"
        #         if $length_of_parsed_attributes
        #             > $length_of_mandatory_attributes
        #                 + scalar @optional_attributes;
        $optional_property = {          # solo optional property
            mesh @optional_attributes,
                 @{[
                    @all_values[$length_of_mandatory_attributes .. $#all_values
                 ]]}
        };
    }
    elsif ($#mandatory_attributes < $#all_values) {
        # skip "#UTX-S 0.91; en; 2009-01-01" & "#UTX-S 0.91; en; 2009-01-01;"
        $optional_property = $all_values[-1];   # miscellany
    }

    return {
        mandatory => {
            mesh @mandatory_attributes,
                 @{[ @all_values[0 .. $#mandatory_attributes] ]}
        },
        optional  => $optional_property,
    };
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
sub _regularize_optional_properties : Private {
    my ($self, $header_property, $option) = @_;

    return
        if $option->{attribute_has_cap};

    if (! defined $header_property->{optional}) {
        delete $header_property->{optional};
        return;
    }

    my @optional_properties = split $option->{delimiter}{elements},
                                    $header_property->{optional};
    delete $header_property->{optional};

    foreach my $optional_property (@optional_properties) {
        my ($attribute, $value)
            = split $option->{delimiter}{attribute_and_value},
              $optional_property,
              2;    # attribute(1) => value(2)
        $attribute =~ s{ \A \s* | \s* \z }{}xmsg;
        $value     =~ s{ \A \s* | \s* \z }{}xmsg;
        push @{ $header_property->{optional}{miscellany} },
                {$attribute => $value};
    }

    return;
}

# ================================================================
# Purpose    : index user defined columns
# Usage      : $hashref = $self->_index_user_defined_columns($arrayref)
# Parameters : 1) ARRAYREF [qw(src:foo     src:bar     tgt:baz     qux)]
#            : 2) NUM index (fixed = 3, based on scalar @basic_columns)
# Returns    : 1) HASHREF  {   src:foo=>3, src:bar=>4, tgt:baz=>5, qux=>6 }
# Throws     : ??? / no exceptions
# Comments   : none
# See Also   : n/a
# ----------------------------------------------------------------
sub _index_user_defined_columns : Private {
    my ($self, $user_defined_columns, $index) = @_;

    my %user_defined_column;
    foreach my $user_defined_column (@$user_defined_columns) {
        croak "Can't parse the header: ",
              "user defined column ($user_defined_column) is duplicated",
                if exists $user_defined_column{$user_defined_column};
        $user_defined_column{$user_defined_column} = ++ $index;
    }

    return \%user_defined_column;
}


# ****************************************************************
# abstract methods
# ****************************************************************

sub get_header_lines         : Abstract;
sub get_attribute            : Abstract;
sub get_delimiter            : Abstract;
sub split_user_defind_column : Abstract;


1; # magic true value required at end of module
__END__

=head1 NAME

Text::UTX::Simple::Header::Parser - internal: parse header of UTX-Simple


=head1 SYNOPSIS

    package Text::UTX::Simple::Header::YourInheritance;

    # FOR INTERNAL USE ONLY
    use base qw(Text::UTX::Simple::Header::Parser);


=head1 DESCRIPTION

=head2 FOR INTERNAL USE ONLY

This class is part of
L<Text::UTX::Simple::Header|Text::UTX::Simple::Header> class.


=head1 METHODS

For internal use only.


=head2 Interface to parser

=head3 C<< parse(\%suspicious_field, \%delimiter) >>

Validates a syntax of fields on the header.
Returns C<\%valid_field> to overwrite field of C<$self>.

See L<< Text::UTX::Simple::parse()|
Text::UTX::Simple/parse >>
for further details of usage.


=head2 Parts of parser

All methods of parts are I<protected>.

=head3 C<< parse_user_defined_columns(\%suspicious_field, \%delimiter) >>

Parses user defined columns.

=head3 C<< remove_basic_columns_from(\@mixed_columns, \%basic_column, $basic_index, $definition_is_string) >>

Removes basic columns from mixed columns.

=head3 C<< regularize_mandatory_properties() >>

Regularizes mandatory properties.

Note: This method implemented by this class has no operation.
This method may be override in concrete class(es).
For example,
L<Text::UTX::Simple::Version::Header::V0_90|
  Text::UTX::Simple::Version::Header::V0_90>
is overrides it.


=head2 Abstract methods

Method shown below should be override in
C<Text::UTX::Simple::Version::Header::V*> classes.

=head3 C<< get_header_lines >>

Returns header line(s).

=head3 C<< get_attribute >>

Returns attributes (class variable) provides by concrete class.

=head3 C<< get_delimiter >>

Returns delimiters (class variable) provides by concrete class.

=head3 C<< split_user_defind_column >>

Splits user defined columns from specified string.


=head1 DIAGNOSTICS

Please refer to
L<the Text::UTX::Simple::Manual::Diagnostics documentation|
Text::UTX::Simple::Manual::Diagnostics>
for the explanation of all error messages.


=head1 CONFIGURATION AND ENVIRONMENT

C<Text::UTX::Simple::Header::Parser>
requires no configuration files or environment variables.


=head1 DEPENDENCIES

C<Text::UTX::Simple::Header::Parser>
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

L<Carp|Carp>
- core module

=item *

L<List::MoreUtils|List::MoreUtils>
- CPAN module

=item *

L<List::Util|List::Util>
- core module

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
C<Text::UTX::Simple::Header::Parser>
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
C<Text::UTX::Simple::Header::Parser>,
released C<$Date: 2009-04-12 06:04:24 +0900 (日, 12 4 2009) $>.
