package Text::UTX::Simple::Header::Base;


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
    Text::UTX::Simple::Version
    Text::UTX::Simple::Auxiliary::Factory
);


# ****************************************************************
# dependencies
# ****************************************************************

use Attribute::Util qw(Abstract Alias Protected);
use Carp qw(croak);
use Readonly;


# ****************************************************************
# package global symbols
# ****************************************************************

our $VERSION = '0.02_00';   # $Rev: 56 $


# ****************************************************************
# class constants
# ****************************************************************

Readonly my $COMMENT_SIGN => q{#};


# ****************************************************************
# class variables
# ****************************************************************

# A "readonly" multiple layer hash has a problem at Test::More::is_deeply().
# Regardless of existance, it returns next layer entry only.
# For example, $utx->{header}{column}{basic}{src} returns 0,
#          but $utx->{header}{column}{basic}      returns {}.
# Therefore, I don't want use Readonly my %DEFAULT_FIELD => {...}.
my %DEFAULT_FIELD = (
    specification => q{UTX-S},  # fixed
    version       => __PACKAGE__->get_latest_version(),
    source        => q{en},
    target        => undef,
    column        => {
        basic => {
            'src'     => 0,     # headword of source language
            'tgt'     => 1,     # target language's equivalent for 'src'
            'src:pos' => 2,     # part-of-speech of 'src'
        },
        user  => {},            # user defined columns
    },
);


# ****************************************************************
# accessors for class constants/variables (protected methods)
# ****************************************************************

# ================================================================
# Purpose    : get default field
# Usage      : $default = $invocant->get_default_field()
# Parameters : none
# Returns    : HASHREF default field
# Throws     : no exceptions
# Comments   : none
# See Also   : n/a
# ----------------------------------------------------------------
sub get_default_field : Protected {
    return \%DEFAULT_FIELD;
}

# ================================================================
# Purpose    : get value from default field by specified key
# Usage      : $foo = $invocant->get_default_value('foo')
# Parameters : STR key
# Returns    : ANY default value of default field
# Throws     : no exceptions
# Comments   : none
# See Also   : n/a
# ----------------------------------------------------------------
sub get_default_value : Protected {
    return $DEFAULT_FIELD{$_[1]};
}


# ****************************************************************
# dynamic loader (protected method)
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
sub re_bless : Protected {
    my ($self, $new_version) = @_;

    # because internal method, optimizing is useless
    # croak "Can't re-bless (internal error): ",
    #       "attempt to call at void context"
    #         unless defined wantarray;

    my $new_class = $self->get_version_distinct_class('Header', $new_version);
    $new_class->load_module_dynamically($new_class);

    return bless $self, $new_class;
}


# ****************************************************************
# indexer (public method)
# ****************************************************************

# ================================================================
# Purpose    : build/rebuild index (lookup table)
# Usage      : $self->index_columns()
# Parameters : none
# Returns    : none
# Throws     : no exceptions
# Comments   : "index" is "column index to column name", and the contrary
# See Also   : index_columns_recursive
# ----------------------------------------------------------------
sub index_columns : Public {
    my $self = shift;

    $self->{name_to_index} = {};
    $self->{index_to_name} = [];

    while (my ($column_type, $columns) = each %{$self->{column}}) {
        while (my ($column_name, $column_index) = each %$columns) {
            $self->{name_to_index}{$column_name}  = $column_index;
            $self->{index_to_name}[$column_index] = $column_name;
        }
    }

    return;
}


# ****************************************************************
# modifiers (protected methods)
# ****************************************************************

# ================================================================
# Purpose    : add comment sign "#" for specified text
# Usage      : 1)                   $invocant->comment_out(\$string)
#            : 2) $comment_string = $invocant->comment_out( $string)
# Parameters : SCALARREF(STR) or STR : string
# Returns    : none or STR : string with comment sign (if parameter is STR)
# Throws     : no exceptions
# Comments   : none
# See Also   : n/a
# ----------------------------------------------------------------
sub comment_out : Protected {
    my ($invocant, $lines_ref) = @_;

    return [
        map {
            $COMMENT_SIGN . $_;
        } @$lines_ref
    ];
}

# ================================================================
# Purpose    : remove comment sign "#" on the head of line, and chomp line
# Usage      : $self->remove_decorations_of_line(\$header_string)
# Parameters : SCALARREF header string
# Returns    : none
# Throws     : if line starting without a hashmark ("#")
# Comments   : none
# See Also   : n/a
# ----------------------------------------------------------------
sub remove_decorations_of_line : Protected {
    my ($self, $header_string_ref) = @_;

    croak "Can't parse the header: ",
          "comment sign doesn't exist"
            unless $$header_string_ref =~ s{
                \A
                [$COMMENT_SIGN]
                \s*
            }{}xms;
    chomp $$header_string_ref;

    return;
}


1; # magic true value required at end of module
__END__

=head1 NAME

Text::UTX::Simple::Header::Base - internal: base class for header of UTX-Simple


=head1 SYNOPSIS

    package Text::UTX::Simple::Header::YourInheritance;

    # FOR INTERNAL USE ONLY
    use base qw(Text::UTX::Simple::Header::Base);


=head1 DESCRIPTION

=head2 FOR INTERNAL USE ONLY

This class is part of
L<Text::UTX::Simple::Header|Text::UTX::Simple::Header> class.


=head1 METHODS

All methods are I<protected>.

=head2 Accessors for class constants/variables

=head3 C<< get_default_field() >>

Returns default field of UTX-S header.

=head3 C<< get_default_value($attribute) >>

Returns default value of C<$attribute> in default field of UTX-S header.


=head2 Dynamic loader

=head3 C<< re_bless($version) >>

Blesses again C<$self> for concrete classs of specified C<$version>.


=head2 Indexer

=head3 C<< index_columns() >>

Builds/Rebuilds index (lookup table).


=head2 Modifiers

=head3 C<< comment_out($string) >>

Adds comment sign C<#> for specified text.

=head3 C<< remove_decorations_of_line(\$string) >>

Removes comment sign C<#> on the head of line, and chomp line.


=head1 DIAGNOSTICS

Please refer to
L<the Text::UTX::Simple::Manual::Diagnostics documentation|
Text::UTX::Simple::Manual::Diagnostics>
for the explanation of all error messages.


=head1 CONFIGURATION AND ENVIRONMENT

C<Text::UTX::Simple::Header::Base>
requires no configuration files or environment variables.


=head1 DEPENDENCIES

C<Text::UTX::Simple::Header::Base>
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
C<Text::UTX::Simple::Header::Base>
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

This document describes version 0.02_00 ($Rev: 56 $) of
C<Text::UTX::Simple::Header::Base>,
released C<$Date: 2009-04-11 01:53:04 +0900 (土, 11 4 2009) $>.
