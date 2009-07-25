package Text::UTX::Simple::Version::Header::V0_90;


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
use List::MoreUtils qw(apply);
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
    mandatory => [qw(specification version alignment last_updated)],
    optional  => [qw(user_defined_columns)],
);
Readonly my %DELIMITER => (
    elements            => q{ },    # "UTX-S 0.90 en-US/ja-JP"
    padding             => undef,   # not for use
    spec_and_version    => undef,   # not for use
    locales             => q{/},    # "en-US/ja-JP"
    language_and_region => q{-},    # "en-US"
    attribute_and_value => undef,   # not for use
    columns             => q{/},    # "source:foo/bar" (user defined columns)
    language_and_column => q{:},    # "src:pos" (not for use)
);
Readonly my $NEED_FOR_REGULARIZE    => 1;
# Readonly my $NUMBER_OF_HEADER_LINES => 1;
Readonly my $UTX_VERSION            => '0.90';


# ****************************************************************
# accessors for class variables (protected methods)
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

    # my @header_lines = splice @$lines_ref, 0, $NUMBER_OF_HEADER_LINES;
    my $header_string = shift @$lines_ref;
    $self->remove_decorations_of_line(\$header_string);

    return [$header_string];
}

# ================================================================
# Purpose    : regularize user defined columns
# Usage      : $self->regularize_user_defined_columns(...)
# Parameters : 1) ARRAYREF       [qw(source:foo        bar target:baz)]
#            : 2...) (ellipsis)
# Returns    : none (param #1 is [qw(source:foo source:bar target:baz)] )
# Throws     : if language not defined
# Comments   : 1) complement language to each column names
#            : 2) throw exception if language is not defind
# See Also   : Text::UTX::Simple::Header::Parser::parse_user_defined_columns
# ----------------------------------------------------------------
sub regularize_user_defined_columns {
    my ($self, $user_defined_columns, $delimiter) = @_;

    my $language;           # for displaying
    my $internal_language;  # for storing
    my %regularized_value_of = (
        source => 'src',
        target => 'tgt',
    );

    my @regularized_user_defined_columns;

    DEFINITION:
    foreach my $user_defined_column (@$user_defined_columns) {
        if (
            $user_defined_column =~ m{
                \A
                (source | target)
                [$delimiter->{language_and_column}]
                (
                    [^$delimiter->{language_and_column}]+ |
                    [ ]*
                )
                \z
            }xms
        ) {
            ($language, $user_defined_column) = ($1, $2);
            $internal_language = $regularized_value_of{$language};
            # for "source: foo/bar/baz" (it is not "source:foo/bar/baz")
            next DEFINITION
                if $user_defined_column =~ m{\A [ ]* \z}xms;
        }
        croak "Can't parse the header: ",
              "language for user defined column's definition isn't defined"
                unless $internal_language;  # undef and q{} (and 0)
        push @regularized_user_defined_columns,
            join $delimiter->{language_and_column},
                $internal_language, $user_defined_column;
    }

    @$user_defined_columns = @regularized_user_defined_columns;

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

    return [
        do {
            join $DELIMITER{elements}, (
                $self->get_specification(),
                $self->get_version(),
                $self->get_alignment(),
                $self->set_last_updated($option),   # update if xxxx
            );
        } . $self->dump_columns($option)
    ];
}

# ================================================================
# Purpose    : dump user defined columns (version < 0.91)
# Usage      : $string_of_user_defined_columns = $self->dump_columns()
# Parameters : none
# Returns    : STR: formatted string of user defined columns on the dictionary
# Throws     : no exceptions
# Comments   : convert qw(source:foo source:bar target:baz target:quz)
#            :    into q( source:foo/bar/target:baz/qux)
# See Also   : dump
# ----------------------------------------------------------------
sub dump_columns {
    my $self = shift;

    my $language_of_previous_column = q{};
    my @user_defined_columns;

    foreach my $user_defined_column (
        @{ $self->get_user_defined_columns() }
    ) {
        $user_defined_column
            = $self->localize_column_names($user_defined_column);
        my ($language, $column_name)
            = split $DELIMITER{language_and_column}, $user_defined_column;
        push @user_defined_columns,
            $language eq $language_of_previous_column ? $column_name
                                                      : $user_defined_column;
        $language_of_previous_column = $language;
    }

    return @user_defined_columns
        ?     $DELIMITER{elements}
            . join $DELIMITER{columns}, @user_defined_columns
        : q{};
}


# ****************************************************************
# parts of converter (protected methods)
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
sub localize_column_names {
    return $_[0]->_regularize_column_names($_[1], 1);
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
sub canonize_column_names {
    return $_[0]->_regularize_column_names($_[1], 0);
}


# ****************************************************************
# private methods
# ****************************************************************

# ================================================================
# Purpose    : regularize column names (for backward compatibility)
# Usage      : 1) $regularized_cols = $self->regularize_column_names(\@cols)
#            : 2) $regularized_col  = $self->regularize_column_names( $col )
# Parameters : ARRAYREF list of column names
# Returns    : ARRAYREF list of regularized column names
# Throws     : no exceptions
# Comments   : none
# See Also   : dump
# ----------------------------------------------------------------
sub _regularize_column_names {
    my ($self, $column, $is_localize) = @_;

    my $is_list = ref $column eq 'ARRAY';
    my @columns = $is_list ? @$column : $column;

    my @regularized_columns
        = $is_localize ?    apply { # don't use map (don't overwrite)
                                $_ =~ s{ \A src           }{source}xms;
                                $_ =~ s{ \A tgt           }{target}xms;
                                $_ =~ s{ \A source:pos \z }{pos}xms;
                                $_;
                            } @columns
                       :    apply {
                                $_ =~ s{ \A source    }{src}xms;
                                $_ =~ s{ \A target    }{tgt}xms;
                                $_ =~ s{ \A pos    \z }{src:pos}xms;
                                $_;
                            } @columns;

    return $is_list ? \@regularized_columns
                    :  $regularized_columns[0];
}


1; # magic true value required at end of module
__END__

=head1 NAME

Text::UTX::Simple::Version::Header::V0_90 - internal: treat header of UTX-Simple 0.90


=head1 SYNOPSIS

    # FOR INTERNAL USE ONLY
    use Text::UTX::Simple::Version::Header::V0_90;


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

=head3 C<< localize_column_names($canonical_column_name) >>

Converts canonical column names into local ones.

=head3 C<< canonize_column_names($local_column_name) >>

Converts local column names into canonical ones.


=head1 DIAGNOSTICS

Please refer to
L<the Text::UTX::Simple::Manual::Diagnostics documentation|
Text::UTX::Simple::Manual::Diagnostics>
for the explanation of all error messages.


=head1 CONFIGURATION AND ENVIRONMENT

C<Text::UTX::Simple::Version::Header::V0_90>
requires no configuration files or environment variables.


=head1 DEPENDENCIES

C<Text::UTX::Simple::Version::Header::V0_90>
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

=item L<Text::UTX::Simple|
        Text::UTX::Simple>

xxx

=item L<Text::UTX::Simple::Header|
        Text::UTX::Simple::Header>

User interface class.

=back


=head1 AUTHOR

=over 4

=item MORIYA Masaki

E<lt>moriya at ermitejo.comE<gt>,
L<http://ttt.ermitejo.com/>

=back

is responsible for
C<Text::UTX::Simple::Version::Header::V0_90>
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
C<Text::UTX::Simple::Version::Header::V0_90>,
released C<$Date: 2009-04-12 06:04:24 +0900 (日, 12 4 2009) $>.
