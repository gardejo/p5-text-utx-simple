package Text::UTX::Simple::Auxiliary::Factory;


# ****************************************************************
# pragmas
# ****************************************************************

use 5.008_001;
use strict;
use warnings;
use utf8;


# ****************************************************************
# dependencies
# ****************************************************************

use Attribute::Util qw(Abstract Alias Protected);
use Carp qw(croak);
use Class::Inspector;
use English;


# ****************************************************************
# package global symbols
# ****************************************************************

our $VERSION = '0.02_00';   # $Rev: 59 $


# ****************************************************************
# loader (protected method)
# ****************************************************************

# ================================================================
# Purpose    : load subclass dynamically
# Usage      : $my_class->load_module_dynamically(@target_classes)
# Parameters : LIST modules (subclasses)
# Returns    : none
# Throws     : 1) if requre throws exception
#            : 2) if module is not defined
# Comments   : none
# See Also   : Catalyst::Utils->ensure_class_loaded()
# ----------------------------------------------------------------
sub load_module_dynamically : Protected {
    my ($invocant, @modules) = @_;

    MODULE:
    foreach my $module (@modules) {
        next MODULE
            if Class::Inspector->loaded($module);

        # avoid 'redefine' warning if test with Devel::Cover
        # my $filename = Class::Inspector->filename($module);
        (my $filename = $module . '.pm') =~ s{::}{/}xmsg;

        my $error;
        {
            local $EVAL_ERROR;
            eval {
                require $filename;
            };
            $error = $EVAL_ERROR;
        }
        croak $error    # Can't locate XXX in @INC (@INC contains: ...)
            if $error;
        # can't happen? (Class::Inspector->loaded() is finally check %INC)
        # croak "Can't load module: ",
        #       "file ($filename) was loaded, ",
        #       "but package ($module) isn't defined"
        #         unless Class::Inspector->loaded($module);
    }

    return;
}

1; # magic true value required at end of module
__END__

=head1 NAME

Text::UTX::Simple::Auxiliary::Factory - internal: abstract factory of header and body on UTX-Simple


=head1 SYNOPSIS

    package Text::UTX::Simple::Header::YourInheritance;

    # FOR INTERNAL USE ONLY
    use base qw(Text::UTX::Simple::Auxiliary::Factory);


=head1 DESCRIPTION

=head2 FOR INTERNAL USE ONLY

This class is part of
L<Text::UTX::Simple::Header|Text::UTX::Simple::Header> and
L<Text::UTX::Simple::Body|Text::UTX::Simple::Body> classes.


=head1 METHODS

=head2 Loader

This method is I<protected>.

=head3 C<< load_module_dynamically(\@modules) >>

Load specified module(s) dynamically.

B<< CAVEAT: dynamically loaded classes cannnot use attributes provided by
L<Attribute::Protected|Attribute::Protected> >>.


=head1 DIAGNOSTICS

Please refer to
L<the Text::UTX::Simple::Manual::Diagnostics documentation|
Text::UTX::Simple::Manual::Diagnostics>
for the explanation of all error messages.


=head1 CONFIGURATION AND ENVIRONMENT

C<Text::UTX::Simple::Auxiliary::Factory>
requires no configuration files or environment variables.


=head1 DEPENDENCIES

C<Text::UTX::Simple::Auxiliary::Factory>
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

L<Class::Inspector|Class::Inspector>
- core module

=item *

L<English|English>
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

=back


=head1 AUTHOR

=over 4

=item MORIYA Masaki

E<lt>moriya at ermitejo.comE<gt>,
L<http://ttt.ermitejo.com/>

=back

is responsible for
C<Text::UTX::Simple::Auxiliary::Factory>
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
C<Text::UTX::Simple::Auxiliary::Factory>,
released C<$Date: 2009-04-12 06:04:24 +0900 (日, 12 4 2009) $>.
