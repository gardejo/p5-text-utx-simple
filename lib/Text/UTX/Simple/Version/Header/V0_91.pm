package Text::UTX::Simple::Version::Header::V0_91;


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
    Text::UTX::Simple::Header::Factory
);


# ****************************************************************
# dependencies
# ****************************************************************

# use Attribute::Util qw(Abstract Alias Protected);
use Carp qw(croak);
use Readonly;
use Scalar::Util qw(blessed);


# ****************************************************************
# package global symbols
# ****************************************************************

our $VERSION = '0.01_00';   # $Rev: 59 $


# ****************************************************************
# class constants
# ****************************************************************

Readonly my %ATTRIBUTE => (
    mandatory => [qw(specification alignment last_updated)],
    optional  => [],    # elements are free, accordingly, elements has no cap
);
Readonly my %DELIMITER => (
    elements            => q{;},    # "UTX-S 0.91;en-US/ja-JP"
    padding             => q{ },    # "UTX-S 0.91; en-US/ja-JP"
    spec_and_version    => q{ },    # "UTX-S 0.91"
    locales             => q{/},    # "en-US/ja-JP"
    language_and_region => q{-},    # "en-US"
    attribute_and_value => q{:},    # "copyright: John Doe"
    columns             => qq{\t},  # "src\ttgt\tsrc:pos\tsrc:foo\tbar\tbaz"
    language_and_column => q{:},    # "src:pos" (not for use)
);
Readonly my $NEED_FOR_REGULARIZE    => 0;
Readonly my $NUMBER_OF_HEADER_LINES => 2;
Readonly my $UTX_VERSION            => '0.91';


# ****************************************************************
# accessors for class constants (protected methods)
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
sub get_attribute {
    return \%ATTRIBUTE;
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
sub get_delimiter {
    return \%DELIMITER;
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
sub need_for_regularize {
    return $NEED_FOR_REGULARIZE;
}

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


# ****************************************************************
# parts of parser (protected methods)
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
sub get_header_lines {
    my ($self, $lines_ref) = @_;

    my @header_lines = splice @$lines_ref, 0, $NUMBER_OF_HEADER_LINES;

    foreach my $header_line (@header_lines) {
        $self->remove_decorations_of_line(\$header_line);
    }

    return \@header_lines;
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
sub regularize_mandatory_properties {
    my ($self, $property, $option) = @_;

    ($property->{mandatory}{specification}, $property->{mandatory}{version})
        = split $DELIMITER{spec_and_version},
                $property->{mandatory}{specification},
                2;  # specification(1), version(2)

    return;
}

# ================================================================
# Purpose    : ???
# Usage      : ???
# Parameters : ???
# Returns    : ???
# Throws     : ??? / no exceptions
# Comments   : none
# See Also   : Text::UTX::Simple::Header::Parser::parse_user_defined_columns
# ----------------------------------------------------------------
sub regularize_user_defined_columns {
    my ($self, $user_defined_columns, $delimiter, $basic_column, $basic_index,
        $definition_is_string) = @_;

    if ($definition_is_string) {
        croak "Can't parse the header: ",
              "specified string is lacking in basic columns"
                if $#{$user_defined_columns} < $basic_index;
    }

    # STR always has basic columns / ARRAY may have basic columns
    if ($#{$user_defined_columns} >= $basic_index) {  # may have basic columns
        $self->remove_basic_columns_from
            ($user_defined_columns, $basic_column, $basic_index,
                $definition_is_string);
    }

    return;
}


# ****************************************************************
# parts of dumper (protected methods)
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
# See Also   : n/a
# ----------------------------------------------------------------
sub dump_header {
    my ($self, $option) = @_;

    my @miscellany = @{ $self->get_miscellany_as_arrayref() }; # always exists

    return [
        (
            join $DELIMITER{elements} . $DELIMITER{padding}, (
                (
                      $self->get_specification()
                    . $DELIMITER{spec_and_version}
                    . $self->get_version()
                ),
                $self->get_alignment(),
                $self->set_last_updated($option),   # update if xxxx
                @miscellany
            )
        ),
        $self->dump_columns()
    ];
}

# ================================================================
# Purpose    : dump user defined columns (version >= 0.91)
# Usage      : $string_of_user_defined_columns = $self->dump_columns()
# Parameters : none
# Returns    : STR: formatted string of user defined columns on the dictionary
# Throws     : no exceptions
# Comments   : convert qw(source:foo  source:bar  target:baz  qux)
#            :    into q(#source:foo\tsource:bar\ttarget:baz\tqux)
# See Also   : dump
# ----------------------------------------------------------------
sub dump_columns {
    my $self = shift;

    return join $DELIMITER{columns}, @{ $self->get_columns() };
}


1; # magic true value required at end of module
__END__

=head1 NAME

Text::UTX::Simple::Version::Header::V0_91 - internal: treat header of UTX-Simple 0.91


=head1 SYNOPSIS

    # FOR INTERNAL USE ONLY
    use Text::UTX::Simple::Version::Header::V0_91;


=head1 DESCRIPTION

=head2 FOR INTERNAL USE ONLY

This class is part of
L<Text::UTX::Simple::Header|Text::UTX::Simple::Header> class.


=head2 Don't use attribute provided by L<Attribute::Protected|Attribute::Protected>

Because this class loaded dynamically by
L<Text::UTX::Simple::Auxiliary::Factory|Text::UTX::Simple::Auxiliary::Factory>,
return values of L<Attribute::Handlers|Attribute::Handlers> is imperfect.


=head1 METHODS

=head2 Accessors for class constants

=head3 C<< get_attribute() >>

Returns attributes(properties) as a HASH reference.
Those attributes was changed at UTX-S 0.91.

=head3 C<< get_delimiter() >>

Returns delimiters as a HASH reference.
Those delimiters was changed at UTX-S 0.91.

=head3 C<< need_for_regularize() >>

Returns always true, because column name is canonical.
This behavior was changed at UTX-S 0.91.

=head3 C<< get_version() >>

Returns version number C<0.92>.


=head2 Parts of parser

=head3 C<< get_header_lines(\@lines) >>

Splices specified C<\@lines> and returns removed header lines
as an ARRAY reference.
Those lines is the first two lines on the dictionary
(all subsequent lines are body).

This behavior was changed at UTX-S 0.91.

=head3 C<< regularize_mandatory_properties(\%property, \%option) >>

Split specification and version.

=head3 C<< regularize_user_defined_columns(\@user_defined_columns, \%delimiter, \%basic_column, $basic_index, $definition_is_string) >>

Regularize user defined columns.


=head2 Parts of dumper

=head3 C<< dump_header() >>

Dumps header as an ARRAY reference.

=head3 C<< dump_columns() >>

Dumps basic and user defined columns as SCALAR.


=head1 DIAGNOSTICS

Please refer to
L<the Text::UTX::Simple::Manual::Diagnostics documentation|
Text::UTX::Simple::Manual::Diagnostics>
for the explanation of all error messages.


=head1 CONFIGURATION AND ENVIRONMENT

C<Text::UTX::Simple::Version::Header::V0_91>
requires no configuration files or environment variables.


=head1 DEPENDENCIES

C<Text::UTX::Simple::Version::Header::V0_91>
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
C<Text::UTX::Simple::Version::Header::V0_91>
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
C<Text::UTX::Simple::Version::Header::V0_91>,
released C<$Date: 2009-04-12 06:04:24 +0900 (日, 12 4 2009) $>.
