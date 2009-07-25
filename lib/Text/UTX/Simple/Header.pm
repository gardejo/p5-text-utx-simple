package Text::UTX::Simple::Header;


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
    Text::UTX::Simple::Header::Column
    Text::UTX::Simple::Header::Parser
    Text::UTX::Simple::Header::Dumper
);


# ****************************************************************
# dependencies
# ****************************************************************

use Attribute::Util qw(Abstract Alias Protected);
# use Carp;
use DateTime;
use DateTime::TimeZone;
use List::MoreUtils qw(apply none);
use Readonly;
use Scalar::Util qw(blessed);


# ****************************************************************
# package global symbols
# ****************************************************************

our $VERSION = '0.02_00';   # $Rev: 60 $


# ****************************************************************
# class constants
# ****************************************************************

Readonly my %SECONDS => (
    per_minute => 60,
    per_hour   => 60 * 60,
);


# ****************************************************************
# accessors for instance variables (public methods)
# ****************************************************************

# ================================================================
# Purpose    : get a specification name on the dictionary
# Usage      : $spec = $self->get_specification()
# Parameters : none
# Returns    : STR: specification name
# Throws     : no exceptions
# Comments   : FOR INTERNAL USE ONLY
# See Also   : n/a
# ----------------------------------------------------------------
sub get_specification : Public {
    return blessed $_[0] ? $_[0]->{specification}
                         : $_[0]->get_default_value('specification');
}

# ================================================================
# Purpose    : get string of the source locale on the dictionary
# Usage      : $source = $self->get_source()
# Parameters : none
# Returns    : STR: source locale on the dictionary
# Throws     : no exceptions
# Comments   : 1) FOR INTERNAL USE ONLY
#            : 2) to do: return locale and region individually
# See Also   : get_target
# ----------------------------------------------------------------
sub get_source : Public {
    return $_[0]->{source};
}

# ================================================================
# Purpose    : get string of the target locale on the dictionary
# Usage      : $target = $self->get_target()
# Parameters : none
# Returns    : STR: target locale on the dictionary
# Throws     : no exceptions
# Comments   : 1) FOR INTERNAL USE ONLY
#            : 2) to do: return locale and region individually
# See Also   : get_target
# ----------------------------------------------------------------
sub get_target : Public {
    return $_[0]->{target};
}

# ================================================================
# Purpose    : get strings of alignment of locale of the dictionary
# Usage      : $alignment = $self->get_alignment()
# Parameters : none
# Returns    : STR: source/target locale
# Throws     : no exceptions
# Comments   : FOR INTERNAL USE ONLY
# See Also   : get_source, get_target
# ----------------------------------------------------------------
sub get_alignment : Public {
    my $target = $_[0]->get_target();

    return defined $target
        ? $_[0]->get_source() . ${$_[0]->get_delimiter()}{locales} . $target
        : $_[0]->get_source();
}

# ================================================================
# Purpose    : get strings of the last updated date/time of the dictionary
# Usage      : $last_updated = $self->get_last_updated()
# Parameters : none
# Returns    : STR: the last updated date/time of the dictionary
# Throws     : no exceptions
# Comments   : FOR INTERNAL USE ONLY
# See Also   : ISO 8601
# ----------------------------------------------------------------
sub get_last_updated : Public {
    return $_[0]->{last_updated};
}

# ================================================================
# Purpose    : get strings of the specified miscellious attribute
#            : or get miscellious columns
# Usage      : 1) $value      = $self->get_miscellany($miscellany)
#            : 2) $values_ref = $self->get_miscellany()
#            : 3) %values     = $self->get_miscellany()
# Parameters : 1*) attribute
# Returns    : a) STR     : attribute value, called by Usage(1)
#            : b) HASHREF : attributes, called by Usage(2)
#            : c) HASH    : attributes, called by Usage(3)
# Throws     : no exceptions
# Comments   : 1) FOR INTERNAL USE ONLY
#            : 2) dare I do not use Contextual::Return
# See Also   : n/a
# ----------------------------------------------------------------
sub get_miscellany : Public {
    my ($self, $attribute) = @_;

    if (defined $attribute) {
        return $self->{miscellany}->FETCH($attribute);
    }
    else {
        my %miscellany;
        @miscellany{$self->{miscellany}->Keys()}
            = $self->{miscellany}->Values();

        return wantarray ?  %miscellany
                         : \%miscellany;
    }
}

# ================================================================
# Purpose    : get list of strings of columns on the dictionary
# Usage      : 1) @columns     = $self->get_columns()
#            : 2) $columns_ref = $self->get_columns()
# Parameters : none
# Returns    : LIST(STR) or ARRAYREF(STR): column names
# Throws     : no exceptions
# Comments   : FOR INTERNAL USE ONLY
# See Also   : is_same_format_as, dump_columns
# ----------------------------------------------------------------
sub get_columns : Public {
    if ( $_[0]->need_for_regularize() ) {
        my $regularized_columns
            = $_[0]->localize_column_names($_[0]->{index_to_name});
        return @$regularized_columns if wantarray;
        return  $regularized_columns;
    }
    else {
        return @{$_[0]->{index_to_name}} if wantarray;
        return   $_[0]->{index_to_name};
    }
}


# ****************************************************************
# comparator (public method)
# ****************************************************************

# ================================================================
# Purpose    : return true if $self and $other format are the same,
#            : otherwise false
# Usage      : if ($self_header->is_same_format_as($other_header)) { ... }
# Parameters : Text::UTX::Simple::Header instance
# Returns    : BOOL: true:is same format / false:is not same format
# Throws     : no exceptions
# Comments   : 1) FOR INTERNAL USE ONLY
#            : 2) this comparison ignore "alignment" and "last_updated"
# See Also   : n/a
# ----------------------------------------------------------------
sub is_same_format_as : Public {
    return $_[0]->is_same_specification_as($_[1]) &&    # specification
           $_[0]->is_compatible_with      ($_[1]) &&    # version
           $_[0]->has_same_columns_as     ($_[1]);      # columns
}


# ****************************************************************
# parts of constructors (protected methods)
# ****************************************************************

# ================================================================
# Purpose    : initialize a created instance
# Usage      : $self->initialize(\%option)
# Parameters : HASHREF option
# Returns    : none
# Throws     : no exceptions
# Comments   : Template Method for Concrete Creator classes
# See Also   : n/a
# ----------------------------------------------------------------
sub initialize : Protected {
    my ($self, $option) = @_;

    my $delimiter = $self->get_delimiter();

    if (exists $option->{user_defined_columns}) {
        $self->parse_user_defined_columns($option, $delimiter);
    }

    %$self = (%$self, %{$self->validate($option, $delimiter)});
    # $self->set_last_updated($option);
    $self->index_columns();

    return;
}

# ================================================================
# Purpose    : get "now" date/time to use last_updated
# Usage      : 1) $now = $class->get_now();
#            : 2) $now = $class->get_now(\%option);
# Parameters : *HASHREF : time_zone (for DateTime::TimeZone's parameter)
# Returns    : STR: now date/time as ISO 8601 format
# Throws     : no exceptions
# Comments   : none
# See Also   : set_last_updated
# ----------------------------------------------------------------
sub get_now : Protected {
    my ($invocant, $option) = @_;

    my $date_time = DateTime->now(
        time_zone =>
            DateTime::TimeZone->new
                ( name =>   $option->{time_zone} ? $option->{time_zone}
                          :                        'local'              ),
    );

    return $date_time->datetime()
         . $invocant->_get_time_zone_conversion_from($date_time);
}


# ****************************************************************
# mutator for instance variable (protected method)
# ****************************************************************

# ================================================================
# Purpose    : set "now" to last updated date/time on the dictionary
# Usage      : 1) $last_updated = $self->set_last_updated()
#            : 2) $last_updated = $self->set_last_updated(HASHREF)
#            : 3) $self->set_last_updated()
#            : 4) $self->set_last_updated(HASHREF)
# Parameters : *HASHREF: time_zone (for DateTime::TimeZone's parameter)
# Returns    : STR: last updated date/time as ISO 8601 format
# Throws     : no exceptions
# Comments   : always returns value
# See Also   : new, clone, dump, ISO 8601,
#            : Regexp::Common::time, Date::ISO8601, DateTime::Format::ISO8601,
#            : Time::Format
# ----------------------------------------------------------------
sub set_last_updated : Protected {
    my ($self, $option) = @_;

    $self->{last_updated} = $self->get_now($option);

    return $self->{last_updated};
}


# ****************************************************************
# parts of dumper (protected methods)
# ****************************************************************

# ================================================================
# Purpose    : get list of strings of user defined columns on the dictionary
# Usage      : $columns_ref = $self->get_user_defined_columns()
# Parameters : none
# Returns    : ARRAYREF: user defined column names
# Throws     : no exceptions
# Comments   : none
# See Also   : Text::UTX::Simple::Version::Header::V0_90::dump_columns()
# ----------------------------------------------------------------
sub get_user_defined_columns : Protected {
    my $self = shift;

    my $offset  = scalar keys %{$self->{column}{basic}}; # starting index (3)
    my @columns = @{ $self->{index_to_name} };

    return [ @columns[$offset .. $#columns] ];
}

# ================================================================
# Purpose    : get miscellious columns (as dumped ARRAY)
# Usage      : $values_ref = $self->get_miscellany_as_arrayref()
# Parameters : none
# Returns    : a) ARRAYREF : attribute value, called by Usage(1)
#            : b) LIST     : attributes, called by Usage(2)
# Throws     : no exceptions
# Comments   : none
# See Also   : n/a
# ----------------------------------------------------------------
sub get_miscellany_as_arrayref : Protected {
    my $self = shift;

    my @result;
    my @keys      = $self->{miscellany}->Keys();
    my @values    = $self->{miscellany}->Values();
    my $delimiter = $self->get_delimiter()->{attribute_and_value}
                  . $self->get_delimiter()->{padding};

    foreach my $index (0 .. $#keys) {
        push @result, (join $delimiter, $keys[$index], $values[$index]);
    }

    return \@result;
}


# ****************************************************************
# abstract methods
# ****************************************************************

sub get_version         : Abstract;
sub need_for_regularize : Abstract;


# ****************************************************************
# private methods
# ****************************************************************

# ================================================================
# Purpose    : get time zone conversion from offset seconds for UTC
# Usage      : $conversion = $self->_get_time_zone_conversion_from(DateTime)
# Parameters : DateTime object
# Returns    : STR: time zone conversion ('Z', '+09:00', '-11:00', etc.)
# Throws     : no exceptions
# Comments   : GMT is '+00:00' (isn't 'Z', this is UTC)
# See Also   : set_last_updated
# ----------------------------------------------------------------
sub _get_time_zone_conversion_from : Private {
    my ($invocant, $date_time) = @_;

    return 'Z'
        if $date_time->time_zone->is_utc();

    my $offset = $date_time->offset();
    my $hour
        = sprintf "%0.2d",
            int ($offset / $SECONDS{per_hour});
    my $minute
        = sprintf "%0.2d",
            int ($offset % $SECONDS{per_hour} / $SECONDS{per_minute});

    return   ($hour >= 0 ? '+' . $hour : $hour)
           . ':'
           . $minute;
}


1; # magic true value required at end of module
__END__

=head1 NAME

Text::UTX::Simple::Header - internal: parse/dump UTX-Simple header


=head1 SYNOPSIS

    package Text::UTX::Simple::YourInheritance;

    # FOR INTERNAL USE ONLY
    use Text::UTX::Simple::Header;


=head1 DESCRIPTION

=head2 FOR INTERNAL USE ONLY

This class is part of L<Text::UTX::Simple|Text::UTX::Simple> class.
This class behaves itself like a delegation of C<Text::UTX::Simple>,
and treats the header of the dictionary.

This is I<Abstract Product> class in I<Factory Method> pattern.


=head1 METHODS

=head2 Accessors for instance variables

=head3 C<< get_specification() >>

Returns specification string.

See L<< Text::UTX::Simple::get_specification()|
Text::UTX::Simple/get_specification() >>
for further details of usage.

=head3 C<< get_source() >>

Returns source locale.

See L<< Text::UTX::Simple::get_source()|
Text::UTX::Simple/get_source() >>
for further details of usage.

=head3 C<< get_target() >>

Returns target locale.

See L<< Text::UTX::Simple::get_target()|
Text::UTX::Simple/get_target() >>
for further details of usage.

=head3 C<< get_alignment() >>

Returns source locale and target locale.

See L<< Text::UTX::Simple::get_alignment()|
Text::UTX::Simple/get_alignment() >>
for further details of usage.

=head3 C<< get_last_updated() >>

Returns last updated date/time.

See L<< Text::UTX::Simple::get_last_updated()|
Text::UTX::Simple/get_last_updated() >>
for further details of usage.

=head3 C<< get_miscellany() >>

Returns miscellious propaty/properties.

See L<< Text::UTX::Simple::get_miscellany()|
Text::UTX::Simple/get_miscellany() >>
for further details of usage.

=head3 C<< get_columns() >>

Returns mandatory and user defined columns.

See L<< Text::UTX::Simple::get_columns()|
Text::UTX::Simple/get_columns >>
for further details of usage.


=head2 Comparator

=head3 C<< is_same_format_as($other) >>

Compares specification, version compatibility, and user defined columns
of both instances.
And returns true if C<$self>'s format is same with <$other>'s specification,
otherwise false.

See L<< Text::UTX::Simple::is_same_format_as($other)|
Text::UTX::Simple/is_same_format_as($other) >>
for further details of usage.


=head2 Parts of constructors

All parts of constructors are I<protected>.

=head3 C<< initialize(\%option) >>

Initializes option for constructors.

=head3 C<< get_now() >>

Returns now date/time.


=head2 Mutator for class variable

This method is I<protected>.

=head3 C<< set_last_updated(\%option) >>

Sets last updated date/time.


=head2 Parts of dumper

All parts of dumper are I<protected>.

=head3 C<< get_user_defined_columns() >>

Returns user defined columns as an ARRAY reference.

=head3 C<< get_miscellany_as_arrayref() >>

Returns miscellious properties as an ARRAY reference.


=head2 Abstract methods

Methods shown below should be override in
C<Text::UTX::Simple::Version::Header::V*> concrete classes. 

=head3 C<< get_version() >>

Returns version number.

=head3 C<< need_for_regularize() >>

Returns true if instance has user interface of localized column name,
otherwise false.


=head1 DIAGNOSTICS

Please refer to
L<the Text::UTX::Simple::Manual::Diagnostics documentation|
Text::UTX::Simple::Manual::Diagnostics>
for the explanation of all error messages.


=head1 CONFIGURATION AND ENVIRONMENT

C<Text::UTX::Simple::Header>
requires no configuration files or environment variables.


=head1 DEPENDENCIES

C<Text::UTX::Simple::Header>
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

L<DateTime|DateTime>
- CPAN module

=item *

L<DateTime::TimeZone|DateTime::TimeZone>
- CPAN module

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

=over 4

=item *

To improve functions of C<get_source()> and C<get_target()>
(return C<locale> and C<region> attributes individually).

=item *

To implement a validation for C<last_updated> attribute
in C<validate()>.

=back


=head1 SEE ALSO

=over 4

=item L<Text::UTX::Simple|Text::UTX::Simple>

User intarface class.

=back


=head1 AUTHOR

=over 4

=item MORIYA Masaki

E<lt>moriya at ermitejo.comE<gt>,
L<http://ttt.ermitejo.com/>

=back

is responsible for C<Text::UTX::Simple::Header> module.

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

This document describes version 0.02_00 ($Rev: 60 $) of
C<Text::UTX::Simple::Header>,
released C<$Date: 2009-04-13 06:26:16 +0900 (月, 13 4 2009) $>.
