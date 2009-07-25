package Text::UTX::Simple::Header::Validator;


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
# use Locale::Country qw(all_country_codes);
use Locale::Country qw(code2country);
# use Locale::Language qw(all_language_codes);
use Locale::Language qw(code2language);
use Readonly;
use Regexp::Common qw(time);
use Scalar::Util qw(blessed);
use Storable qw(dclone);
use Tie::IxHash;


# ****************************************************************
# package global symbols
# ****************************************************************

our $VERSION = '0.02_00';   # $Rev: 60 $


# ****************************************************************
# class constants
# ****************************************************************

# Readonly my %LOCALE => (            # lookup table
#     language => { do { map {    $_ => undef; } all_language_codes(); } },
#     region   => { do { map { uc $_ => undef; } all_country_codes();  } },
# );
Readonly my @ORDER_OF_VALIDATION => qw(
    version specification alignment source target last_updated column
);
Readonly my %PATTERN => (
    # 2009-04-31, 2009-02-29, 2008-02-30 are match...
    # "eval { DateTime->new(...) }; die if $EVAL_ERROR" ?
    last_updated => $RE{time}{tf}{-pat => 'yyyy-mm-dd(?:Thh:mm:ss(?:tz)?)?'},
);


# ****************************************************************
# interface to validator (protected methods)
# ****************************************************************

# ================================================================
# Purpose    : validate a syntax of fields on the header
# Usage      : $self->validate(\%suspicious_field, \%delimiter)
# Parameters : 1) HASHREF property
#            :    kind(mandatory/optional) => { attribute => value }
#            :    fill-in valid field if $if_validate_itself
#            : 2) HASHREF delimiter
# Returns    : HASHREF valid property
# Throws     : 1) if source/target locale isn't valid format
#            : 2) to do: date/time isn't valid format
#            : 3) validate itself if called by new() or clone(),
#            :    otherwise validate specified field
#            : 4) to do: pluggable validation
# Comments   : someday improve a validation
# See Also   : parse
# ----------------------------------------------------------------
sub validate : Protected {
    my ($self, $suspicious_field, $delimiter) = @_;

    # validate itself or parsed fields
    (my $caller = (caller(1))[3]) =~ s{ \A .+ :: }{}xms;
    my $if_validate_itself = $caller eq 'initialize';

    my $attributes = $self->_get_validation_order($suspicious_field);
    my %valid_field;            # fill-in valid field if $if_validate_itself
    $valid_field{miscellany} = Tie::IxHash->new();
    if (exists $suspicious_field->{original_miscellany}) {  # from clone()
        $valid_field{miscellany}->Push
            ( $suspicious_field->{original_miscellany}->Splice(0) );
        delete $suspicious_field->{original_miscellany};
    }

    ATTRIBUTE:
    foreach my $attribute (@$attributes) {
        my $value  = $suspicious_field->{$attribute};
        my $method = '_validate_' . $attribute;
        if ($self->can($method)) {
            $self->$method
                ($value, $if_validate_itself, \%valid_field, $delimiter);
        }
        elsif (
            $attribute !~ m{
                \A
                (?: text | file | index_to_name | name_to_index )
                \z
            }xms
        ) {
            $self->_validate_miscellany
                ([{$attribute => $value}],
                    $if_validate_itself, \%valid_field, $delimiter);
        }
    }

    return \%valid_field;
}


# ****************************************************************
# parts of comparison (protected methods)
# ****************************************************************

# ================================================================
# Purpose    : return true if $self is same specification as $other,
#            : otherwise false
# Usage      : 1) if ($self->is_same_specification_as($other)  ) { ... }
#            : 2) if ($self->is_same_specification_as('FOOBAR')) { ... }
# Parameters : 1) Text::UTX::Simple::Version::Header::V***) instance
#            :    or STR
# Returns    : BOOL
# Throws     : no exceptions
# Comments   : none
# See Also   : n/a
# ----------------------------------------------------------------
sub is_same_specification_as : Protected {
    my ($self, $other) = @_;

    return $self->get_specification()
            eq (blessed $other ? $other->get_specification() : $other);
}

# ================================================================
# Purpose    : return true if $self has same column as $other, otherwise false
# Usage      : if ($self->has_same_columns_as($other)) {...}
# Parameters : 1) other Text::UTX::Simple::Version::Header::V***) instance
# Returns    : BOOL
# Throws     : no exceptions
# Comments   : none
# See Also   : n/a
# ----------------------------------------------------------------
sub has_same_columns_as : Protected {
    return ( join q{}, @{ $_[0]->get_columns()} ) eq
           ( join q{}, @{ $_[1]->get_columns()} );
}


# ****************************************************************
# private methods
# ****************************************************************

# ================================================================
# Purpose    : get order of validation
# Usage      : $attributes = $self->_get_validation_order(\%suspicious_field)
# Parameters : HASHREF  suspicious field
# Returns    : ARRAYREF attributes (ordered)
# Throws     : no exceptions
# Comments   : "while (my ($attribute, $value) = each %$suspicious_field)"
#            : is indefinite validation
# See Also   : n/a
# ----------------------------------------------------------------
sub _get_validation_order : Private {
    my ($self, $suspicious_field) = @_;

    if (exists $suspicious_field->{alignment}) {
        delete @$suspicious_field{qw(source target)};
    }

    my @attributes = grep {
        exists $suspicious_field->{$_};
    } @ORDER_OF_VALIDATION;

    my %seen;
    @seen{@attributes} = ();
    push @attributes, grep {
        ! exists $seen{$_};
    } keys %$suspicious_field;

    return \@attributes;
}

# ================================================================
# Purpose    : validate $suspicious_field->{version}
# Usage      : ???
# Parameters : ???
# Returns    : ???
# Throws     : ??? / no exceptions
# Comments   : none
# See Also   : n/a
# ----------------------------------------------------------------
sub _validate_version : Private {
    my ($self, $suspicious_value,
        $if_validate_itself, $valid_field, $delimiter) = @_;

    $self->regularize_version(\$suspicious_value);
    croak "Can't parse the header: ",
          "version ($self->{version}) ",
          "isn't compatible with $suspicious_value"
            if defined $self->{version} # from clone()
            && ! $self->is_compatible_with($suspicious_value);

    $valid_field->{version} = $suspicious_value;

    return;
}

# ================================================================
# Purpose    : validate $suspicious_field->{specification}
# Usage      : ???
# Parameters : ???
# Returns    : ???
# Throws     : ??? / no exceptions
# Comments   : none
# See Also   : n/a
# ----------------------------------------------------------------
sub _validate_specification : Private {
    my ($self, $suspicious_value,
        $if_validate_itself, $valid_field, $delimiter) = @_;

    croak "Can't parse the header: ",
          "specification isn't defined"
            unless defined $suspicious_value;

    if ($if_validate_itself) {
        my $default_specification = $self->get_default_value('specification');
        croak "Can't parse the header: ",
              "specification ($suspicious_value) ",
              "isn't valid specification"
                if $suspicious_value ne $default_specification;
    }
    else {
        croak "Can't parse the header: ",
              "specification ($suspicious_value) ",
              "isn't same as $self->{specification}"
                unless $self->is_same_specification_as($suspicious_value);
    }

    $valid_field->{specification} = $suspicious_value;

    return;
}

# ================================================================
# Purpose    : validate $suspicious_field->{alignment}
# Usage      : ???
# Parameters : ???
# Returns    : ???
# Throws     : ??? / no exceptions
# Comments   : $valid->{alignment} is useless
# See Also   : n/a
# ----------------------------------------------------------------
sub _validate_alignment : Private {
    my ($self, $suspicious_value,
        $if_validate_itself, $valid_field, $delimiter) = @_;

    # split source/target (multilingual) or source (monolingual)
    my ($source, $target) = split $delimiter->{locales},
                                  $suspicious_value,
                                  2; # source(1)/target(2)

    $self->_validate_locale('source', $source, $valid_field, $delimiter);
    if (defined $target) {
        $self->_validate_locale('target', $target, $valid_field, $delimiter);
    }
    else {
        $valid_field->{'target'} = $target; # undef
    }

    return;
}

# ================================================================
# Purpose    : validate $suspicious_field->{source}
# Usage      : ???
# Parameters : ???
# Returns    : ???
# Throws     : ??? / no exceptions
# Comments   : none
# See Also   : n/a
# ----------------------------------------------------------------
sub _validate_source : Private {
    my ($self, $suspicious_value,
        $if_validate_itself, $valid_field, $delimiter) = @_;

    $valid_field->{target} = undef;

    return $self->_validate_locale
                    ('source', $suspicious_value, $valid_field, $delimiter);
}

# ================================================================
# Purpose    : validate $suspicious_field->{target}
# Usage      : ???
# Parameters : ???
# Returns    : ???
# Throws     : ??? / no exceptions
# Comments   : none
# See Also   : n/a
# ----------------------------------------------------------------
sub _validate_target : Private {
    my ($self, $suspicious_value,
        $if_validate_itself, $valid_field, $delimiter) = @_;
    return
        unless defined $suspicious_value;

    return $self->_validate_locale
                    ('target', $suspicious_value, $valid_field, $delimiter);
}

# ================================================================
# Purpose    : validate $suspicious_field->{$locale}
# Usage      : $self->_validate_locale('source', $source)
# Parameters : 1) STR: locale key
#            : 2) STR: locale value
# Returns    : none
# Throws     : 1) if language code isn't valid as ISO 639-1 format
#            : 2) if region(country) code isn't valid as ISO 3166 format
# Comments   : none
# See Also   : _is_valid_language, _is_valid_region
# ----------------------------------------------------------------
sub _validate_locale : Private {
    my ($self, $locale_key, $locale_value, $valid_field, $delimiter) = @_;
    croak "Can't parse the header: $locale_key locale isn't defined"
        unless defined $locale_value;

    my ($language, $region)
        = split $delimiter->{language_and_region}, $locale_value;
    croak "Can't parse the header: ",
          "$locale_key language ($language) isn't valid as ISO 639-1 format"
            unless $self->_is_valid_language($language);
    croak "Can't parse the header: ",
          "$locale_key region ($region) isn't valid as ISO 3166 format"
            if defined $region
            && ! $self->_is_valid_region($region);

    $valid_field->{$locale_key} = $locale_value;

    return;
}

# ================================================================
# Purpose    : validate $suspicious_field->{last_updated}
# Usage      : ???
# Parameters : ???
# Returns    : ???
# Throws     : ??? / no exceptions
# Comments   : 2009-13-32 is invalid,
#            : but 2009-02-29 and 2009-04-31 is unexpectedly valid!
# See Also   : ISO 8601
# ----------------------------------------------------------------
sub _validate_last_updated : Private {
    my ($self, $suspicious_value,
        $if_validate_itself, $valid_field, $delimiter) = @_;
    croak "Can't parse the header: last updated date/time isn't defined"
        unless defined $suspicious_value;

    croak "Can't parse the header: ",
          "last updated date/time isn't valid as ISO 8601 format"
            unless $suspicious_value =~ $PATTERN{last_updated};

    $valid_field->{last_updated} = $suspicious_value;

    return;
}

# ================================================================
# Purpose    : validate $suspicious_field->{*} (miscellany)
# Usage      : ???
# Parameters : ???
# Returns    : ???
# Throws     : ??? / no exceptions
# Comments   : can not $method (optional attributes)
# See Also   : n/a
# ----------------------------------------------------------------
sub _validate_miscellany : Private {
    my ($self, $suspicious_value,
        $if_validate_itself, $valid_field, $delimiter) = @_;

    croak "Can't parse the header: ",
          "type of miscellany (", ref($suspicious_value),
          ") isn't an ARRAY reference and isn't a Tie::IxHash"
            if ref $suspicious_value ne 'ARRAY'
            && (   ! blessed $suspicious_value
                || ! $suspicious_value->isa('Tie::IxHash') );

    my $query;
    if (blessed $suspicious_value) {
        $query = $suspicious_value;
    }
    else {
        $query = Tie::IxHash->new();
        foreach my $miscellany_item (@$suspicious_value) {
            croak "Can't parse the header: ",
                  "type of miscellany item (", ref($miscellany_item),
                  ") isn't a HASH reference"
                    if ref $miscellany_item ne 'HASH';
            croak "Can't parse the header: ",
                  "miscellany item has more than 1 key"
                    if scalar keys %$miscellany_item > 1;
            my ($miscellany_key, $miscellany_value) = each %$miscellany_item;
            croak "Can't parse the header: ",
                  "miscellious attribute ($miscellany_key) is duplicated"
                    if $query->EXISTS($miscellany_key);
            $query->Push($miscellany_key => $miscellany_value);
        }
    }

    foreach my $miscellany_key ($query->Keys()) {
        my $miscellany_value = $query->FETCH($miscellany_key);
        if (defined $miscellany_value) {
            $valid_field->{miscellany}->Push
                ($miscellany_key => $miscellany_value);
        }
        elsif ($valid_field->{miscellany}->EXISTS($miscellany_key)) {
            $valid_field->{miscellany}->DELETE($miscellany_key);
        }
    }

    return;
}

# ================================================================
# Purpose    : validate $suspicious_field->{column}
# Usage      : ???
# Parameters : ???
# Returns    : ???
# Throws     : ??? / no exceptions
# Comments   : none
# See Also   : n/a
# ----------------------------------------------------------------
sub _validate_column : Private {
    my ($self, $suspicious_value,
        $if_validate_itself, $valid_field, $delimiter) = @_;

    foreach my $user_defined_column (keys %{$suspicious_value->{user}}) {
        croak "Can't parse the header: ",
              "user defined column ($user_defined_column) is duplicated"
                if exists $suspicious_value->{basic}{$user_defined_column};
    }

    $self->_validate_basic_columns
        ($suspicious_value->{basic},
            $if_validate_itself, $valid_field, $delimiter);
    $self->_validate_user_defined_columns
        ($suspicious_value->{user},
            $if_validate_itself, $valid_field, $delimiter);

    $valid_field->{column} = $suspicious_value;

    return;
}

# ================================================================
# Purpose    : validate $suspicious_field->{column}{basic}
# Usage      : $self->_validate_basic_columns()
# Parameters : none
# Returns    : none
# Throws     : no exceptions
# Comments   : none
# See Also   : n/a
# ----------------------------------------------------------------
sub _validate_basic_columns : Private {
    return;
}

# ================================================================
# Purpose    : validate $suspicious_field->{column}{user}
# Usage      : ???
# Parameters : ???
# Returns    : ???
# Throws     : ??? / no exceptions
# Comments   : ought to be valid (because already parsed)
# See Also   : n/a
# ----------------------------------------------------------------
sub _validate_user_defined_columns : Private {
    return;
}

# ================================================================
# Purpose    : return true if specified region is valid as ISO 639-1 code
# Usage      : if ($self->_is_valid_language()) { ... }
# Parameters : STR: language code
# Returns    : BOOL: true:valid code / false:invalid code
# Throws     : no exceptions
# Comments   : none
# See Also   : _validate_locale, Locale::Language, ISO 639-1
# ----------------------------------------------------------------
sub _is_valid_language : Private {
    # return exists $LOCALE{language}{$_[1]};
    return defined code2language($_[1]);
}

# ================================================================
# Purpose    : return true if specified region is valid as ISO 3166 alpha-2 code
# Usage      : if ($self->_is_valid_region(STR)) { ... }
# Parameters : STR: region code
# Returns    : BOOL: true:valid code / false:invalid code
# Throws     : no exceptions
# Comments   : none
# See Also   : _validate_locale, Locale::Country, ISO 3166
# ----------------------------------------------------------------
sub _is_valid_region : Private {
    # return exists $LOCALE{region}{$_[1]};
    return defined code2country($_[1]);
}


1; # magic true value required at end of module
__END__

=head1 NAME

Text::UTX::Simple::Header::Validator - internal: validate and complement attributes of header on the UTX-Simple


=head1 SYNOPSIS

    package Text::UTX::Simple::Header::YourInheritance;

    # FOR INTERNAL USE ONLY
    use Text::UTX::Simple::Header::Validator;


=head1 DESCRIPTION

=head2 FOR INTERNAL USE ONLY

This class is part of
L<Text::UTX::Simple::Header|Text::UTX::Simple::Header> class.


=head1 METHODS

=head2 Validator

This method is I<protected>.

=head3 C<< validate(\%suspicious_field, \%delimiter) >>

Validates a syntax of fields on the header (interface method).
Returns C<\%valid_field> to overwrite field of C<$self>.


=head2 Parts of comparison

All parts of comparison are I<protected>.

=head3 C<< is_same_specification_as >>

Returns true if C<$self>'s specification is same
with C<$other>'s specification, otherwise false.

=head4 C<< is_same_specification_as($other_instance) >>

Specified other instance.

=head4 C<< is_same_specification_as($specification_string) >>

Specified string.

=head3 C<< has_same_columns_as($other_instance) >>

Returns true if C<$self>'s columns is same
with C<$other>'s columns, otherwise false.


=head1 DIAGNOSTICS

Please refer to
L<the Text::UTX::Simple::Manual::Diagnostics documentation|
Text::UTX::Simple::Manual::Diagnostics>
for the explanation of all error messages.


=head1 CONFIGURATION AND ENVIRONMENT

C<Text::UTX::Simple::Header::Validator>
requires no configuration files or environment variables.


=head1 DEPENDENCIES

C<Text::UTX::Simple::Header::Validator>
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

L<Locale::Country|Locale::Country>
- core module

=item *

L<Locale::Language|Locale::Language>
- core module

=item *

L<Readonly|Readonly>
- CPAN module

=item *

L<Regexp::Common::time|Regexp::Common::time>
- CPAN module

=item *

L<Scalar::Util|Scalar::Util>
- core module

=item *

L<Storable|Storable>
- core module

=item *

L<Tie::IxHash|Tie::IxHash>
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

User intarface class.

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
C<Text::UTX::Simple::Header::Validator>
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

This document describes version 0.02_00 ($Rev: 60 $) of
C<Text::UTX::Simple::Header::Validator>,
released C<$Date: 2009-04-13 06:26:16 +0900 (月, 13 4 2009) $>.
