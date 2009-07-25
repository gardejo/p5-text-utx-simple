package Text::UTX::Simple;


# ****************************************************************
# pragmas
# ****************************************************************

use 5.008_001;
use strict;
use warnings;
use utf8;


# ****************************************************************
# delegates
# ****************************************************************

use Text::UTX::Simple::Header::Factory;
use Text::UTX::Simple::Body;


# ****************************************************************
# dependencies
# ****************************************************************

use Attribute::Util qw(Abstract Alias Protected);
use Carp qw(carp croak);
# use Encode::Guess;
use English;
use File::Slurp qw(read_file write_file);
use List::MoreUtils qw(none);
use Scalar::Util qw(blessed);
use Storable qw(dclone);


# ****************************************************************
# package global symbols
# ****************************************************************

our $VERSION = '0.02_00';   # $Rev: 61 $


# ****************************************************************
# class variables
# ****************************************************************

my $DEFINED_COLUMN_ONLY = 0;


# ****************************************************************
# constructors (public methods)
# ****************************************************************

# ================================================================
# Purpose    : constructor, create a new Text::UTX::Simple object
# Usage      : $utx = Text::UTX::Simple->new(HASHREF)
# Parameters : HASHREF option
# Returns    : a Text::UTX::Simple object
# Throws     : if option is invalid type
# Comments   : none
# See Also   : $utx->clone, $self->_fetch_method_by,
#            : Text::UTX::Simple::Header->new, Text::UTX::Simple::Body->new
# ----------------------------------------------------------------
sub new : Public {
    my ($class, $option) = @_;

    croak "Can't create a new object: ",
          "$class is not a class (you must use clone())"
            if blessed $class;

    $option = defined $option ? $option : {};
    croak "Can't create an object: option isn't a HASH reference"
        if ref $option ne 'HASH';

    my $self = bless {
        header => Text::UTX::Simple::Header::Factory->new($option),
    }, $class;
    $self->{body}
        = Text::UTX::Simple::Body->new({%$option, parent => $self});

    if (%$option) {
        $self->_fetch_method_by($option);
    }
    else {
        # disuse Mediator methods, _header() and _body(), for optimization
        $self->{header}->index_columns();
        $self->{body}->index_entries();
    }

    return $self;
}

# ================================================================
# Purpose    : clone specified object
# Usage      : $clone = $utx->clone(HASHREF)
# Parameters : n/a
# Returns    : a Text::UTX::Simple object
# Throws     : if option isn't HASHREF
# Comments   : none
# See Also   : Text::UTX::Simple->new, $header->clone, $body->clone
# ----------------------------------------------------------------
sub clone : Public {
    my ($self, $option) = @_;

    croak "Can't clone an object: ",
          "$self is not an object (you must use new())"
            unless blessed $self;

    $option = defined $option ? $option : {};
    croak "Can't clone an object: option isn't a HASH reference"
        if ref $option ne 'HASH';

    my $clone = bless {
        header => $self->{header}->clone($option),
    }, ref $self;
    $clone->{body}
        = $self->{body}->clone({%$option, parent => $clone});

    return $clone;
}


# ****************************************************************
# accessor/mutator for class variable (public methods)
# ****************************************************************

# ================================================================
# Purpose    : get/set $DEFINED_COLUMN_ONLY flag
# Usage      : 1) Text::UTX::Simple->is_defined_column_only(BOOL)
#            : 2) $flag = Text::UTX::Simple->is_defined_column_only()
# Parameters : *BOOL:
# Returns    : *BOOL: true:regard / false:ignore
# Throws     : no exceptions
# Comments   : (true:regard / false:ignore) excess columns
# See Also   : n/a
# ----------------------------------------------------------------
sub is_defined_column_only : Public {
    if (defined $_[1]) {
        $DEFINED_COLUMN_ONLY = $_[1];
        return unless defined wantarray;
    }
    else {
        if (! defined wantarray) {
            carp "Useless use private variable in void context";
            return;
        }
    }

    return $DEFINED_COLUMN_ONLY;
}


# ****************************************************************
# parser/reader (public methods)
# ****************************************************************

# ================================================================
# Purpose    : parse header and body
# Usage      : 1) $utx->parse(LIST)
#            : 2) $utx->parse(ARRAYREF)
# Parameters : LIST/ARRAYREF: lines of formatted strings
# Returns    : none
# Throws     : if STR of @lines aren't defined
# Comments   : line => 1 : number of header line
# See Also   : $utx->read
# ----------------------------------------------------------------
sub parse : Public {
    my ($self, @lines) = @_;

    croak "Can't parse strings: strings aren't defined"
        if ! @lines
        || ! defined $lines[0]
        || $lines[0] eq q{};

    # validate and regularize argument @lines
    my $lines_ref;
      $#lines eq 0 && ref $lines[0] eq q{ARRAY}         # ARRAYREF
        ? $lines_ref =                        $lines[0]
    : $#lines eq 0 && ref $lines[0] eq q{}              # STR
        ? $lines_ref = [ split m{\r?\n}xms,   $lines[0]  ]
    : $#lines eq 0 && ref $lines[0] eq q{SCALAR}        # SCALARREF?
        ? $lines_ref = [ split m{\r?\n}xms, ${$lines[0]} ]
    : ref $lines[0] eq q{}                              # LIST(splitted STR)
        ? $lines_ref =                       \@lines
    :
          croak "Can't parse strings: ",
                "element of lines (", ref $lines[0], ") isn't valid type";

    $lines_ref = dclone $lines_ref;         # preserve arguments
    $self->clear();

    # parse header (first element, or first and second elements of @lines)
    $self->{header}->parse($lines_ref);

    # parse body (rest elements of @lines)
    if (@$lines_ref) {
        $self->{body}->parse($lines_ref, {line => 1, from_parse => 1});
    }

    return;
}

# ================================================================
# Purpose    : parse strings in specified file
# Usage      : $utx->read(STR)
# Parameters : STR: filename
# Returns    : none
# Throws     : if $filename isn't defined or is empty
# Comments   : 1) this is a wrapper method around Text::UTX::Simple->parse
#            : 2) Are users requesting encoding other than UTF-8?
# See Also   : $utx->parse
# ----------------------------------------------------------------
sub read : Public {
    my ($self, $filename) = @_;
    # my ($self, $filename, @users_favorite_encodings) = @_;        # comment 2

    croak "Can't read the dictionary: ",
          "filename isn't defined or is empty"
            if ! defined $filename
            || $filename eq q{};

    my $file_contents;
    eval {
        $file_contents = read_file($filename, array_ref => 1);
        # $file_contents = read_file($filename, scalar_ref => 1);   # comment 2
    };
    if ($EVAL_ERROR) {
        (my $error_message = $EVAL_ERROR) =~ s{\A .+? - \s }{}xms;
        croak "Can't read the file ($filename): $error_message";
    }

    # comment 2: rescue text from invalid encoding
    # if (@users_favorite_encodings) {
    #     my $encoding_of_file
    #         = guess_encoding($$file_contents, @users_favorite_encodings);
    #     croak "Can't guess encoding: $encoding_of_file"
    #         unless ref $encoding_of_file;
    #     if ($encoding_of_file->name() ne 'utf8') {
    #         $$file_contents = $encoding_of_file->decode($$file_contents);
    #     }
    # }

    $self->parse($file_contents);

    return;
}


# ****************************************************************
# dumpers (public methods)
# ****************************************************************

# ================================================================
# Purpose    : get Text::UTX::Simple text as strings
# Usage      : $string = $utx->as_string(HASHREF)
# Parameters : *HASHREF: draw option
# Returns    : STR/SCALARREF(STR): dictionary as strings
# Throws     : no exceptions
# Comments   : none
# See Also   : $utx->_dump
# ----------------------------------------------------------------
sub as_string : Public {
    my ($self, $option) = @_;

    if (! defined wantarray) {
        carp "Useless use private variable in void context";
        return;
    }
    $self->_validate_type_of($option);

    my $string
        = $self->_dump({scalar_ref => 1, time_zone => $option->{time_zone}});
    $$string .= "\n";   # it is necessary to "\n" also to the final line

    return   $option->{scalar_ref} ?  $string
           :                         $$string;
}

# ================================================================
# Purpose    : dump the header of the dictionary
# Usage      : $header_text = $utx->dump_header(HASHREF)
# Parameters : HASHREF: option
# Returns    : STR or LIST(STR) or ARRAYREF(STR): dumpped header strings
# Throws     : no exceptions
# Comments   : none
# See Also   : $header->dump, $self->dump_body
# ----------------------------------------------------------------
sub dump_header : Public Alias(
         header
) {
    my ($self, $option) = @_;

    if (! defined wantarray) {
        carp "Useless use private variable in void context";
        return;
    }
    $self->_validate_type_of($option);

    return $self->_adapt_returns_to_context(
        $self->{header}->dump($option),
        $option
    );
}

# ================================================================
# Purpose    : dump the body of the dictionary
# Usage      : $body_text = $utx->dump_body(HASHREF)
# Parameters : HASHREF: option
# Returns    : STR or LIST(STR) or ARRAYREF(STR): dumpped body strings
# Throws     : no exceptions
# Comments   : none
# See Also   : $body->dump, $self->dump_header
# ----------------------------------------------------------------
sub dump_body : Public Alias(
         body,
    dump_entries,
         entries
) {
    my ($self, $option, $row_query) = @_;

    if (! defined wantarray) {
        carp "Useless use private variable in void context";
        return;
    }

    if (defined $option && ref $option eq 'ARRAY') {
        ($option, $row_query) = (undef, $option);   # query -> undef, query
    }
    $self->_validate_type_of($option);

    my $dumped_body = $self->{body}->dump($option, $row_query);

    return
        unless defined $dumped_body;

    return $self->_adapt_returns_to_context($dumped_body, $option);
}

# ================================================================
# Purpose    : consult the meaning of specified body on the dictionary
# Usage      : 1) $target_entry   = $utx->consult($source_entry)
#            : 2) @target_entries = $utx->consult($source_entry)
# Parameters : STR source entry
# Returns    : 
# Throws     : no exceptions
# Comments   : syntax sugar to $self->dump_body
#            :          ({scalar => 1, columns => [1]}, [qw($entry)])
# See Also   : dump_entries
# ----------------------------------------------------------------
sub consult : Public {
    my ($self, $entry) = @_;

    # column 1 is 'tgt' (target language)
    return $self->dump_body({consult => 1, columns => [1]}, [$entry]);
}


# ****************************************************************
# writer (public methods)
# ****************************************************************

# ================================================================
# Purpose    : generate and write UTX-Simple formatted text to specified file
# Usage      : $utx->write(STR, HASHREF)
# Parameters : STR: filename
#            : HASHREF: option
# Returns    : none
# Throws     : $filename isn't defind or is empty
# Comments   : default is overwrite existant file, to protect,
#            : turn $option->{protect} on.
# See Also   : n/a
# ----------------------------------------------------------------
sub write : Public {
    my ($self, $filename, $option) = @_;

    croak "Can't write a dictionary: filename isn't defined or is empty"
        if ! defined $filename
        || $filename eq q{};

    $option = defined $option ? $option : {};
    return
        if $option->{protect}
        && -f $filename;

    write_file(
        $filename,
        $self->as_string
            ({scalar_ref => 1, time_zone  => $option->{time_zone}}),
    );

    return;
}


# ****************************************************************
# accessors for the header of the dictionary (public methods)
# ****************************************************************

sub get_columns : Public Alias(
        columns
) { return $_[0]->{header}->get_columns(); }

sub get_specification : Public Alias(
        specification,
        spec
) { return $_[0]->{header}->get_specification(); }

sub get_version : Public Alias(
        version
) { return $_[0]->{header}->get_version(); }

sub guess_version : Public Alias(
    guess
) { return $_[0]->{header}->guess_version(); }

sub get_source : Public Alias(
        source
) { return $_[0]->{header}->get_source(); }

sub get_target : Public Alias(
        target
) { return $_[0]->{header}->get_target(); }

sub get_alignment : Public Alias(
        alignment
) { return $_[0]->{header}->get_alignment(); }

sub get_miscellany : Public Alias(
        miscellany,
        misc
) { return $_[0]->{header}->get_miscellany(@_[1 .. $#_]); }

sub get_last_updated : Public Alias(
        last_updated,
             updated
) { return $_[0]->{header}->get_last_updated(); }


# ****************************************************************
# utilities for the header of the dictionary (public methods)
# ****************************************************************

# ================================================================
# Purpose    : get number of columns on the dictionary
# Usage      : $column_number = $utx->get_number_of_columns()
# Parameters : none
# Returns    : NUM: number of columns on the dictionary
# Throws     : no exceptions
# Comments   : none
# See Also   : $self->get_number_of_entries
# ----------------------------------------------------------------
sub get_number_of_columns : Public Alias(
        number_of_columns
) {
    return $_[0]->{header}->get_number_of_columns();
}

# ================================================================
# Purpose    : return true if $self and $other format is same, otherwise false
# Usage      : if ($utx->is_same_format_as($other_utx)) { ... }
# Parameters : Text::UTX::Simple instance
# Returns    : BOOL: true:is same format / false:is not same format
# Throws     : no exceptions
# Comments   : none
# See Also   : n/a
# ----------------------------------------------------------------
sub is_same_format_as : Public Alias(
    is_same_format
) {
    return $_[0]->{header}->is_same_format_as($_[1]->{header});
}

# ================================================================
# Purpose    : get a column index from the specified column name
# Usage      : 1) $column_index = $utx->name_to_index(STR)
#            : 2) $column_indexes_ref = $utx->name_to_index(ARRAYREF)
# Parameters : STR or ARRAYREF(STR): column name(s) on the dictionary
# Returns    : NUM or ARRAYREF(NUM): column index(es) on the dictionary
# Throws     : if call with LIST
# Comments   : convert ['src', 'tgt', 'src:pos'] into [0, 1, 2]
# See Also   : $utx->index_to_name
# ----------------------------------------------------------------
sub name_to_index : Public {
    croak "Can't convert column name into column index: ",
          "attempt to use LIST as names ",
          "(you should use an ARRAY reference)"
            if $#_ > 1;

    return $_[0]->{header}->name_to_index({
                column_name => $_[1],
           });
}

# ================================================================
# Purpose    : get a column name from the specified column index
# Usage      : 1) $column_name = $utx->name_to_index(NUM)
#            : 2) $column_names_ref = $utx->name_to_index(ARRAYREF)
# Parameters : NUM or ARRAYREF(NUM): column index(es) on the dictionary
# Returns    : STR or ARRAYREF(STR): column name(s) on the dictionary
# Throws     : if call with LIST
# Comments   : convert [0, 1, 2] into ['src', 'tgt', 'src:pos']
# See Also   : $utx->name_to_index
# ----------------------------------------------------------------
sub index_to_name : Public {
    croak "Can't convert column index into column name: ",
          "attempt to use LIST as indexes ",
          "(you should use an ARRAY reference)"
            if $#_ > 1;

    return $_[0]->{header}->index_to_name({
                column_index           => $_[1],
                is_defined_column_only => $DEFINED_COLUMN_ONLY,
           });
}

# ================================================================
# Purpose    : get {column => value} hash from column values
# Usage      : $hash_ref = $utx->array_to_hash(ARRAYREF)
# Parameters : ARRAYREF(STR value): values of entry columns
# Returns    : HASHREF(STR key => STR value): alignments of entry columns
# Throws     : if call with LIST
# Comments   : convert [value0, value1] into {column0=>value0, column1=>value1}
# See Also   : $utx->hash_to_array
# ----------------------------------------------------------------
sub array_to_hash : Public {
    croak "Can't convert entry array into entry hash: ",
          "attempt to use LIST as names ",
          "(you should use an ARRAY reference)"
            if $#_ > 1;

    return $_[0]->{header}->array_to_hash({
                entry_array            => $_[1],
                is_defined_column_only => $DEFINED_COLUMN_ONLY,
           });
}

# ================================================================
# Purpose    : get column values from {column => value} hash
# Usage      : $array_ref = $utx->hash_to_array(HASHREF)
# Parameters : HASHREF(STR key => STR value): alignments of entry columns
# Returns    : ARRAYREF(STR value): values of entry columns
# Throws     : if call with LIST
# Comments   : conver {column0=>value0, column1=>value1} into [value0, value1]
# See Also   : $utx->array_to_hash
# ----------------------------------------------------------------
sub hash_to_array : Public {
    croak "Can't convert entry hash into entry array: ",
          "attempt to use LIST as names ",
          "(you should use an ARRAY reference)"
            if $#_ > 1;

    return $_[0]->{header}->hash_to_array({
                entry_hash => $_[1],
           });
}

# ****************************************************************
# accessor for class variable in the body on the dictionary (public methods)
# ****************************************************************

# ================================================================
# Purpose    : get alternative strings with undefined value on the body
# Usage      : $string = $utx->get_complement_of_void_value()
# Returns    : none
# Returns    : STR: alternative strings with undefined value
# Throws     : no exceptions
# Comments   : none
# See Also   : n/a
# ----------------------------------------------------------------
sub get_complement_of_void_value : Public {
    return $_[0]->{body}->get_complement_of_void_value();
}


# ****************************************************************
# mutator for class variable in the body on the dictionary (public methods)
# ****************************************************************

# ================================================================
# Purpose    : set alternative strings with undefined value on the body
# Usage      : $utx->set_complement_of_void_value(STR)
# Returns    : STR: alternative strings with undefined value
# Returns    : none
# Throws     : no exceptions
# Comments   : none
# See Also   : n/a
# ----------------------------------------------------------------
sub set_complement_of_void_value : Public {
    return $_[0]->{body}->set_complement_of_void_value($_[1]);
}


# ****************************************************************
# utility for the body on the dictionary (public methods)
# ****************************************************************

# ================================================================
# Purpose    : get number of entries on the dictionary
# Usage      : $number = $utx->get_number_of_entries()
# Parameters : none
# Returns    : NUM: number of entries
# Throws     : no exceptions
# Comments   : none
# See Also   : $self->get_number_of_columns
# ----------------------------------------------------------------
sub get_number_of_entries : Public Alias(
        number_of_entries
) {
    return $_[0]->{body}->get_number_of_entries();
}

# ================================================================
# Purpose    : get line of body on the dictionary
# Usage      : $number = $utx->get_line_of_entries()
# Parameters : none
# Returns    : NUM: number of entries
# Throws     : no exceptions
# Comments   : none
# See Also   : $self->get_number_of_columns
# ----------------------------------------------------------------
sub get_line_of_entries : Public Alias(
        line_of_body
) {
    return $_[0]->{body}->get_line_of_entries();
}


# ****************************************************************
# manipulators for the body on the dictionary (public methods)
# ****************************************************************

# ================================================================
# Purpose    : push entry/entries to the dictionary
# Usage      : $number = $utx->push(LIST)
# Parameters : LIST: stacking element(s)
#            :   STR, SCALARREF, ARRAYREF, HASH, HASHREF, Text::UTX::Simple
# Returns    : *NUMBER: number of elements on the dictionary
# Throws     : no exceptions
# Comments   : same as CORE::push
# See Also   : pop, unshift, splice
# ----------------------------------------------------------------
sub push : Public {
    my ($self, @elements) = @_;

    if (@elements) {
        my ($elements_ref, $recursion)
            = $#elements eq 0 ? ([ $elements[0] ], 1) : (\@elements, 0);
        my $parsed_elements_ref
            = $self->{body}->get_parsed_rows
                ($elements_ref, undef, $recursion);
        $self->{body}->splice
            ($self->get_line_of_entries(), 0, $parsed_elements_ref);
    }

    return unless defined wantarray;
    return $self->get_line_of_entries();
}

# ================================================================
# Purpose    : pop one entry from the dictionary
# Usage      : $popped = $utx->pop()
# Parameters : none
# Returns    : *Text::UTX::Simple object (includes removed entry)
# Throws     : no exceptions
# Comments   : same as CORE::pop
# See Also   : push, shift, splice
# ----------------------------------------------------------------
sub pop : Public {
    return unless $_[0]->get_line_of_entries();
    return $_[0]->{body}->splice(-1);
}

# ================================================================
# Purpose    : shift one entry from the dictionary
# Usage      : $shifted = $utx->shift()
# Parameters : none
# Returns    : *Text::UTX::Simple object (includes removed entry)
# Throws     : no exceptions
# Comments   : same as CORE::shift
# See Also   : unshift, pop, splice
# ----------------------------------------------------------------
sub shift : Public {
    return unless $_[0]->get_line_of_entries();
    return $_[0]->{body}->splice(0, 1);
}

# ================================================================
# Purpose    : unshift entry/entries to the dictionary
# Usage      : $number = $utx->unshift(LIST)
# Parameters : LIST: queueing element(s)
#            :   STR, SCALARREF, ARRAYREF, HASH, HASHREF, Text::UTX::Simple
# Returns    : *NUMBER: number of elements on the dictionary
# Throws     : no exceptions
# Comments   : same as CORE::unshift
# See Also   : shift, push, splice
# ----------------------------------------------------------------
sub unshift : Public {
    my ($self, @elements) = @_;

    if (@elements) {
        my ($elements_ref, $recursion)
            = $#elements eq 0 ? ([ $elements[0] ], 1) : (\@elements, 0);
        my $parsed_elements_ref
            = $self->{body}->get_parsed_rows
                ($elements_ref, undef, $recursion);
        $self->{body}->splice(0, 0, $parsed_elements_ref);
    }

    return unless defined wantarray;
    return $self->get_line_of_entries();
}

# ================================================================
# Purpose    : splice entry/entries together the dictionary
# Usage      : $removed = $utx->splice(0, 1, 2, (LIST))
# Parameters : 1)   INT  start offset
#            : *2)  INT  removing length
#            : *3+) LIST adding element(s)
# Returns    : *Text::UTX::Simple object (includes removed entry/entries)
# Throws     : no exceptions
# Comments   : same as CORE::splice
# See Also   : push, pop, unshift, shift, Text::UTX::Simple::Body::splice
# ----------------------------------------------------------------
sub splice : Public {
    my ($self, $offset, $remove_length, @elements) = @_;

    my $parsed_elements_ref;
    if (@elements) {
        my ($elements_ref, $recursion)
            = $#elements eq 0 ? ([ $elements[0] ], 1) : (\@elements, 0);
        $parsed_elements_ref
            = $self->{body}->get_parsed_rows
                ($elements_ref, undef, $recursion);
    }

    return $self->{body}->splice
                            ($offset, $remove_length, $parsed_elements_ref);
}

# ================================================================
# Purpose    : splice entry/entries together the dictionary
# Usage      : *** not implemented ***
# Parameters : *** not implemented ***
# Returns    : *** not implemented ***
# Throws     : none
# Comments   : *** not implemented ***
# See Also   : n/a
# ----------------------------------------------------------------
sub sort : Public {
    return CORE::shift->{body}->sort(@_);
}

# ================================================================
# Purpose    : clear all entries on the dictionary
# Usage      : $utx->clear()
# Parameters : none
# Returns    : none
# Throws     : no exceptions
# Comments   : none
# See Also   : n/a
# ----------------------------------------------------------------
sub clear : Public {
    return $_[0]->{body}->clear();
}


# ****************************************************************
# private methods
# ****************************************************************

# ================================================================
# Purpose    : fetch method by Text::UTX::Simple->new()'s option
# Usage      : $self->_fetch_method_by(HASHREF)
# Parameters : HASHREF: {text => STR(UTX text)} or {file => STR(filename)}
# Returns    : none
# Throws     : if number of behavior keys more than 1
# Comments   : none
# See Also   : Text::UTX::Simple->new
# ----------------------------------------------------------------
sub _fetch_method_by : Private {
    my ($self, $option) = @_;

    croak "Can't create an object: ",
          "option should have only one behavior key"
            if exists $option->{text}
            && exists $option->{file};

    while (my ($attribute, $value) = each %$option) {
        if ($attribute eq 'text') {
            $self->parse($value);
        }
        elsif ($attribute eq 'file') {
            $self->read($value);
        }
    }

    return;
}

# ================================================================
# Purpose    : validate method's option
# Usage      : $self->_validate_type_of($option);
# Parameters : HASHREF: option
# Returns    : none
# Throws     : 1) if option isn't HASAREF
#            : 2) if number of keys, which has true value, more than 1
# Comments   : none
# See Also   : n/a
# ----------------------------------------------------------------
sub _validate_type_of : Private {
    my ($self, $option) = @_;

    return
        unless defined $option;

    croak "Can't validate type: option isn't a HASH reference"
        if ref $option ne 'HASH';

    my @effective_types = grep {
        $option->{$_}   # true (effective) only
    } grep {
        m{
            \A
            (?:
                (?: scalar | array | hash )( _ref )? |
                list
            )
            \z
        }xms
    } keys %$option;

    croak "Can't validate type: type assignment isn't exclusive ",
          "(you ware assined multiple types below, ",
          (join q{, }, @effective_types), ")"
            if $#effective_types > 0;

    return;
}

# ================================================================
# Purpose    : dump the dictionary
# Usage      : $string = $self->_dump(HASHREF)
# Parameters : HASHREF: {scalar_ref => 1, time_zone => $option->{time_zone}}
# Returns    : UTX-Simple formatted string
# Throws     : no exceptions
# Comments   : none
# See Also   : $self->as_string
# ----------------------------------------------------------------
sub _dump : Private {
    my ($self, $option) = @_;

    my @lines = @{ $self->{header}->dump
                    ({array_ref => 1, time_zone => $option->{time_zone}}) };
    if ($self->get_line_of_entries()) {
        CORE::push @lines,
            @{ $self->{body}->dump({scalar => 1}) };
    }

    return $self->_adapt_returns_to_context(\@lines, $option);
}

# ================================================================
# Purpose    : adapt return value to caller's context
# Usage      : $result = $self->_adapt_returns_to_context(ARRAYREF, HASHREF)
# Parameters : ARRAYREF: dump results as ARRAYREF
#            : *HASHREF option
# Returns    : STR or LIST(STR) or ARRAYREF or...
# Throws     : no exceptions
# Comments   : CAVEAT: "hash" returns a LIST (not a HASH), and
#            : "hashref returns an ARRAY reference (not a HASH reference)!
# See Also   : n/a
# ----------------------------------------------------------------
sub _adapt_returns_to_context : Private {
    my ($self, $dumped_lines, $option) = @_;

    if (defined $option) {
        if ($option->{'say'}) {
            croak "Can't dump the dictionary: ",
                  "can't use 'say' option with 'hash' or 'hash_ref' option"
                    if $option->{hash_ref}
                    || $option->{hash};
            if ($option->{scalar_ref} || $option->{scalar}) {
                CORE::push @$dumped_lines, q{};
            }
            else {
                @$dumped_lines = map { $_ . "\n" } @$dumped_lines;
            }
        }

        return   $option->{consult}    ? wantarray ?      @$dumped_lines
                                                   :       $dumped_lines->[0]
               : $option->{scalar_ref} ? \do { join "\n", @$dumped_lines }
               : $option->{scalar}     ?       join "\n", @$dumped_lines
               : $option->{array_ref}  ?                   $dumped_lines
               : $option->{array}      ?                  @$dumped_lines
               : $option->{list}       ?                  @$dumped_lines
               : $option->{hash_ref}   ?                   $dumped_lines
               : $option->{hash}       ?
                    (caller(1))[3] eq __PACKAGE__ . '::dump_header'
                                                        ? %$dumped_lines
                                                        : @$dumped_lines
               : wantarray             ?                  @$dumped_lines
               :                                           $dumped_lines;
    }
    else {
        return   wantarray             ?                  @$dumped_lines
               :                                           $dumped_lines;
    }
}


1; # magic true value required at end of module
__END__

=head1 NAME

Text::UTX::Simple - abstract layer(parser/writer) for UTX-Simple


=head1 VERSION

This document describes version 0.02_00 ($Rev: 61 $) of
C<Text::UTX::Simple>,
released C<$Date: 2009-04-16 01:51:54 +0900 (木, 16 4 2009) $>.

Other language edition of this document is available at:

=over 4

=item Japanese

L<Text::UTX::Simple_JA|
  Text::UTX::Simple_JA>

=back


=head1 SYNOPSIS

    use Text::UTX::Simple;

    my $utx = Text::UTX::Simple->new({filename => $filename});
    my $string = $utx->as_string(); # get string as UTX-Simple format
    $utx->clear();                  # clear all entries

    $utx = Text::UTX::Simple->new({text => $utx_formatted_text});
    $utx->push([$row0, $row1]);     # stack dictionary with array-to-array
    $utx->write($filename);         # write file with UTX-Simple format


=head1 DESCRIPTION

B<< THIS POD IS STUB. PLEASE REFERE TO THE JAPANESE VERSION.
L<Text::UTX::Simple_JA|Text::UTX::Simple_JA> >>

This C<Text::UTX::Simple> module provides facilities for the parsing,
reading, dumping, and writing of UTX-Simple formatted strings and files.
The interface to this module is object-oriented.

=head2 Concept

=head3 This module is:

=over 4

=item *

Abstract layer to reading/writing UTX-Simple formatted files/strings.

=back

=head3 This module is capable of:

=over 4

=item *

Mostly, providing infrastructure for an dictionary converter.
This module can be used as a parser and a reader.

=item *

Validating files/strings as UTX-Simple format.

=item *

Consulting an UTX-S dictionary for the target-language's equivalent
of source-language's headword.

=item *

Manipulating (adding, removing, sorting) entries on an UTX-Simple dictionary.

=back

=head3 This module is NOT:

=over 4

=item *

Interactive converter between UTX-Simple dictionaries and
unique user dictionaries of translation software.
This function is provided by other class under development.

=back


=head2 What is UTX/UTX-Simple?

UTX (Universal Terminology eXchange) is open standard
for machine translation user dictionary.

UTX has two specifications.
The one is UTX-XML and the other is UTX-Simple.
AAMT will eventually establish UTX-XML,
however, it has started by creating UTX-Simple.

UTX-Simple is simple implementation of UTX,
it consists tab-delimited text (TSV: tab-separated value) format.

The specification of UTX is being examined by AAMT
(Asia-Pacific Association for Machine Translation).

See on the website of AAMT for further details.


=head2 Compliance

This module is based on UTX-S 0.90 (UTX-Simple specification, version 0.90).

CAVEAT: You must be careful that this module B<DOES NOT SUPPORT UTX-S 0.91
(UTX-Simple specification, version 0.91) AND OVER AT PRESENT>.


=head2 The header and the body on UTX-Simple

The UTX-Simple specification treats the first line as a header line,
and treats all rest lines as body (entry lines).


=head2 Format of the header on UTX-Simple

B<This section has not been translated yet.>


=head2 Format of the body on UTX-Simple

B<This section has not been translated yet.>


=head1 METHODS


=head2 Constructors

=head3 C<< new >>

=head4 C<< new() >>

Creates a new C<Text::UTX::Simple> instance (dictionary object).
Returns an empty dictionary, with header specified basic columns
(source language, target language, part-of-speech of source language),
without a headword.

=head4 C<< new({text => $text}) >>

Creates a new C<Text::UTX::Simple> instance (dictionary object).
And what's more, modifies the dictionary
by results of parsing about specified strings of C<$text>.
This code:

    $utx = Text::UTX::Simple->new({text => $text});

is same as below:

    $utx = Text::UTX::Simple->new();    # creates a new object
    $utx->parse({text => $text});       # parse UTX-Simple strings

See C<parse()> for further details.

=head4 C<< new({file => $filename}) >>

Creates a new C<Text::UTX::Simple> instance (dictionary object).
And what's more, reads the file specified by C<$filename>,
finally, modifies the dictionary by results of parsing
about specified strings of C<$text>.
This code:

    $utx = Text::UTX::Simple->new({text => $text});

is same as below:

    $utx = Text::UTX::Simple->new();    # creates a new object
    $utx->read({file => $filename});    # read and parse UTX-Simple strings

See C<read()> for further details.

=head4 C<< new(\%option) >>

Creates a new C<Text::UTX::Simple> instance (dictionary object).
And what's more, set attributes specified C<\%option> hash reference
to the header of the dictionary.
The specifiable alignment of C<< ( attribute_key => attribute_value ) >>
is below.
As for an attribute not specified, an initial value is used.
See <parse()> for further details of description method about each attributes.

=over 4

=item C<< version => STR >>

    my $one_dictionary   = Text::UTX::Simple->new({ version => 3.14 });
    $one_dictionary->push($same_entry);
    my $other_dictionary = Text::UTX::Simple->new(); # version => 0.90
    $other_dictionary->push($same_entry);

    # instance of 3.14 (1 entry)
    my $popped_dictionary = $one_dictionary->pop();
    $other_dictionary->push($popped_dictionary);     # exception! 3.14 vs. 0.90

...

    # continuation
    # 1 entry (it is not an instance. it is array(columns) to array(rows).
    my $popped_entry = $popped_dictionary->dump_entries();
    $other_dictionary->push($popped_entry);          # no exception

=item C<< source => STR >>

=item C<< target => STR >>

=item C<< column => STR >>

=item C<< time_zone => STR >>

=back

For example:

    my $utx = Text::UTX::Simple->new({
        source    => 'en-US',
        target    => 'ja-JP',
        time_zone => 'Asia/Tokyo',
        column    => [qw(src:plural src:3sp src:past src:pastp tgt)],
    });

=head3 C<< clone >>

=head4 C<< clone() >>

=head4 C<< clone(\%option) >>

    my $one_dictionary   = Text::UTX::Simple->new({ source => 'en', target => 'ja' });
    my $other_dictionary = $one_dictionary->clone({ source => 'eo' });
    # source => 'eo', target => 'ja'


=head2 Accessor/mutator for class variable

=head3 C<< is_defined_column_only >>

=head4 C<< is_defined_column_only() >>

=head4 C<< is_defined_column_only(BOOL) >>


=head2 Parser/Reader

=head3 C<< parse($utx_formatted_text) >>

=over 4

=item C<SCALAR>

=item C<SCALARREF>

=item C<LIST>

=item C<ARRAYREF>

=back

    $utx = Text::UTX::Simple->new({ text => $text });
    $utx->parse($additional_entries); # error! overwrite
    $utx->push($additional_entries);  # append

=head3 C<< read($filename) >>

=head2 Dumpers/Writer

=head3 C<< as_string >>

=head4 C<< as_string() >>

=head4 C<< as_string({ scalar_ref => 1 }) >>

=head3 C<< write >>

=head4 C<< write($filename) >>

=head4 C<< write($filename, { protect => 1 }) >>

=head3 C<< dump_header >>

=head4 C<< dump_header() >>

=head4 C<< dump_header(\%option) >>

=head3 C<< dump_body >>

=head4 C<< dump_body() >>

Returns the body of specified row(,column) of the dictionary

    use YAML::Syck;
    my $utx = Text::UTX::Simple->new();
    $utx->push([ [qw(foo bar noun)],
                 [qw(baz qux verb)], ]);
    print Dump $utx->dump_body();

such test's result is:

    --- 
    - foo
    - bar
    - noun
    --- 
    - baz
    - qux
    - verb

=head4 C<< dump_body(\@rows) >>

=head4 C<< dump_body(\%option) >>

=head4 C<< dump_body(\@rows, \%option) >>

=head3 C<< consult($entry) >>

=head2 Options of dumpers

=head3 With or without new line (C<\n>)

=over 4

=item C<< say => BOOL >>

=back

=head3 Data-types

=over 4

=item C<< scalar => BOOL >>

=item C<< scalar_ref => BOOL >>

=item C<< list => BOOL >>

=item C<< array_ref => BOOL >>

=item C<< hash => BOOL >>

Passes the test blow:

    use Test::More;
    my $utx = Text::UTX::Simple->new();
    $utx->push([ [qw(foo bar noun)],
                 [qw(baz qux verb)], ]);
    is_deeply( [ $utx->dump_body({ hash => 1 }) ],
               [ [ { 'src' => 'foo', 'tgt' => 'bar', 'src:pos' => 'noun' } ],
                 [ { 'src' => 'baz', 'tgt' => 'qux', 'src:pos' => 'verb' } ], ],
               'hash' );

=item C<< hash_ref => BOOL >>

Same as C<hash>, blah blah blah.

Passes the test blow:

    is_deeply( $utx->dump_body({ hash_ref => 1 }),
               [ [ { 'src' => 'foo', 'tgt' => 'bar', 'src:pos' => 'noun' } ],
                 [ { 'src' => 'baz', 'tgt' => 'qux', 'src:pos' => 'verb' } ], ],
               'hash_ref' );

=back

=head3 Column projection

=over 4

=item C<< columns => \@columns >>

=back

=head3 Multiple assignment

You can use those options together,
about C<say>, group of data-types, and C<columns>.

    my $header_lines = $utx->dump_header({
        say        => 1,
        scalar_ref => 1,
        columns    => [qw(src tgt)]
    });

But, you can not use multiple data-types.
For example, in this case throws exception:

    my $header_lines = $utx->dump_header({
        say        => 1,
        scalar_ref => 1,
        array_ref  => 1,
        columns    => [qw(src tgt)]
    });

=head2 Accessors for the header

=head3 C<< get_columns() >>

=head3 C<< get_specification() >>

Returns a specification name of the dictionary as string (C<STR>).
Because a specification name is fixed,
this method is going to return "UTX-S", this stands for UTX-Simple.

=head3 C<< get_version() >>

Returns a version number of the UTX(-Simple) specification of the dictionary.

=head3 C<< guess_version() >>

=head3 C<< get_source() >>

Returns a source language of the dictionary as ISO 639-1 code or
combination of ISO 639-1 and ISO 3166 codes.

For example: 'en', 'en-US', 'ja', 'ja-JP', etc.

CAVEAT: The UTX-Simple specification is incomplete. In this case,
"The language name" is dubious description. The description equates
"The language name" with "ISO 639", but the example is "en-US". Therefore,
the method returns a language code (ISO 639-1) or a combination of
language code and country code (ISO 3166). The examples of the former are
'en', 'ja', etc. Then, the later are 'en-US', 'ja-JP', etc.


=head3 C<< get_target() >>

The method is similar to C<get_source>. This returns a target language
(object language) of the dictionary if defined, otherwise returns C<undef>.

In case of a monolingual dictionary, the target language is omitted.

=head3 C<< get_alignment() >>

Returns a combination of results of C<get_source()> and C<get_target()>.
If target language not defined, returns is the same of as C<get_source()>.

=head3 C<< get_miscellany() >>

=head3 C<< get_last_updated() >>

Returns the last updated date/time of the dictionary as ISO 8601 code.

CAVEAT: The specification of UTX-Simple 0.90 has erratum about the time zone
conversions. This describes "2007-12-03T14:28:00Z+09:00", but the "Z" sign
(stands on UTC) and "+/-HH(:MM)" specification can be exclusively used.


=head2 Utilities for the header

=head3 C<< get_number_of_columns() >>

=head3 C<< is_same_format_as($instance) >>

    if ($one_dictionary->is_same_format_as($other_dictionary)) { ... }

=head3 C<< index_to_name($column_indexes) >>

=head3 C<< name_to_index($column_names) >>

=head3 C<< array_to_hash($entry_array) >>

=head3 C<< hash_to_array($entry_hash) >>


=head2 Accessor for the body

=head3 C<< get_complement_of_void_value() >>


=head2 Mutator for the body

=head3 C<< set_complement_of_void_value($string) >>


=head2 Utility for entries

=head3 C<< get_number_of_entries() >>

=head3 C<< get_line_of_entries() >>


=head2 Manipulators for entries

=head3 C<< push($entries) >>

Treats $utx as a stack, and pushes the values of ARRAYREF or LIST or
$additional_utx_entries onto the end of $utx. The length of entries
($utx->get_number_of_entries) increases by the length of LIST, or list of
ARRAYREF, or the length of entries
($additional_utx_entries->get_number_of_columns).

=head3 C<< pop() >>

=head3 C<< shift() >>

=head3 C<< unshift($entries) >>

=head3 C<< splice($offset, $length, $entries) >>

=head3 C<< sort() >>

=head3 C<< clear() >>


=head2 Additional entries

B<This section has not been translated yet.>

=over 4

=item parsing strings (C<STR>)

=item such reference (C<SCALARREF>)

=item C<Text::UTX::Simple> instance

=item array reference (C<ARRAYREF>) of each column's value

    $utx->push([qw(source_language target_language noun)]);

=item hash reference (C<HASHREF>) of each column's key and value

    $utx->push({            # row 0
        'src'     => 'foo',     # col 0
        'tgt'     => 'bar',     # col 1
        'src:pos' => 'noun',    # col 2
    });

=item list (C<LIST>) of such data-types

=item array reference (C<ARRAYREF>) of such data-types

    $utx->push([
        #   col 0  col 1  col 2
        [qw(foo    bar    noun)],   # row 0
        [qw(baz    qux    verb)],   # row 1
    ]);

=back

If value is C<undef>, C<Text::UTX::Simple> object converts the value
into blank character (C<q{}>) at parsing, and keep it.
If value is C<q{}>, object does not convert.
If you want complement blank character at dumping,
use L<set_complement_of_void_value()|set_complement_of_void_value()> method
and switch class variable.


=head2 Syntax sugars

B<This section has not been translated yet.>

=over 4

=item *

C<< header() >>

=item *

C<< entries() >>

=item *

C<< columns() >>

=item *

C<< specification() >>

=item *

C<< spec() >>

=item *

C<< version() >>

=item *

C<< source() >>

=item *

C<< target() >>

=item *

C<< alignment() >>

=item *

C<< last_updated() >>

=item *

C<< updated() >>

=item *

C<< miscellany() >>

=item *

C<< misc() >>

=item *

C<< number_of_columns() >>

=item *

C<< number_of_entries() >>

=back


=head1 DIAGNOSTICS

See L<Text::UTX::Simple::Manual::Diagnostics|
Text::UTX::Simple::Manual::Diagnostics>.


=head1 CONFIGURATION AND ENVIRONMENT

C<Text::UTX::Simple>
requires no configuration files or environment variables.


=head1 DEPENDENCIES

C<Text::UTX::Simple> and it's related classes included in
C<Text-UTX-Simple> distribution depend on:

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
- CPAN module

=item *

L<DateTime|DateTime>
- CPAN module

=item *

L<DateTime::TimeZone|DateTime::TimeZone>
- CPAN module

=item *

L<Encode|Encode>
- core module

=item *

L<English|English>
- core module

=item *

L<File::Slurp|File::Slurp>
- CPAN module

=item *

L<List::MoreUtils|List::MoreUtils>
- CPAN module

=item *

L<List::Util|List::Util>
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

L<Test::Exception|Test::Exception>
- CPAN module (for test)

=item *

L<Test::Harness|Test::Harness>
- core module (for test)

=item *

L<Test::More|Test::More>
- core module (for test)

=item *

L<Test::Warn|Test::Warn>
- CPAN module (for test)

=item *

L<Tie::IxHash|Tie::IxHash>
- CPAN module

=back

C<Text::UTX::Simple> has delegation classes shown below:

=over 4

=item *

L<Text::UTX::Simple::Header|Text::UTX::Simple::Header>

=item *

L<Text::UTX::Simple::Body|Text::UTX::Simple::Body>

=back


=head1 INCOMPATIBILITIES

None reported.

B<HOWEVER, THIS LIBRARY IS IN ITS ALPHA QUALITY>.
B<THE API MAY CHANGE IN THE FUTURE>.


=head1 BUGS AND LIMITATIONS

=head2 Bugs

No bugs have been reported.


=head2 Limitations

B<This section has not been translated yet.>

=head3 Headword only of the numerical value cannnot be used

See B<looks_like_number> section of L<perlapi|perlapi>.

=head3 Blank lines are not saved


=head2 Making suggestions and reporting bugs

Please report any found bugs, feature requests, and ideas for improvements
to C<bug-text-utx-simple at rt.cpan.org>,
or through the web interface
at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Text-UTX-Simple>.
I will be notified, and then you'll automatically be notified of progress
on your bugs/requests as I make changes.

When reporting bugs, if possible,
please add as small a sample as you can make of the code
that produces the bug.
And of course, suggestions and patches are welcome.


=head1 SUPPORT

You can find documentation for this module with the C<perldoc> command.

    perldoc Text::UTX::Simple

You can also look for information at:

=over 4

=item RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Text-UTX-Simple>

=item AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Text-UTX-Simple>

=item Search CPAN

L<http://search.cpan.org/dist/Text-UTX-Simple>

=item CPAN Ratings

L<http://cpanratings.perl.org/d/Text-UTX-Simple>

=back


=head1 CODE COVERAGE

B<This section has not been translated yet.>

I use L<Devel::Cover|Devel::Cover> to test the code coverage of my tests,
below is the B<Devel::Cover> summary report on this library's test suite.

  ---------------------------- ------ ------ ------ ------ ------ ------ ------
  File                           stmt   bran   cond    sub    pod   time  total
  ---------------------------- ------ ------ ------ ------ ------ ------ ------
  blib/lib/Text/UTX/Simple.pm   100.0  100.0  100.0  100.0  100.0    9.7  100.0
  ...mple/Auxiliary/Factory.pm  100.0  100.0    n/a  100.0    n/a    2.7  100.0
  ...b/Text/UTX/Simple/Body.pm  100.0  100.0    n/a  100.0  100.0    1.0  100.0
  ...t/UTX/Simple/Body/Base.pm  100.0  100.0    n/a  100.0  100.0    1.2  100.0
  ...UTX/Simple/Body/Dumper.pm  100.0  100.0  100.0  100.0  100.0    2.7  100.0
  ...imple/Body/Manipulator.pm  100.0  100.0  100.0  100.0  100.0    1.7  100.0
  ...UTX/Simple/Body/Parser.pm  100.0  100.0  100.0  100.0  100.0    3.2  100.0
  ...Text/UTX/Simple/Header.pm  100.0  100.0  100.0  100.0  100.0   10.4  100.0
  ...UTX/Simple/Header/Base.pm  100.0  100.0    n/a  100.0  100.0    5.1  100.0
  ...X/Simple/Header/Column.pm  100.0  100.0  100.0  100.0  100.0    1.0  100.0
  ...X/Simple/Header/Dumper.pm  100.0  100.0  100.0  100.0  100.0    0.5  100.0
  .../Simple/Header/Factory.pm  100.0  100.0  100.0  100.0  100.0    5.1  100.0
  ...X/Simple/Header/Parser.pm  100.0  100.0  100.0  100.0  100.0    9.0  100.0
  ...imple/Header/Validator.pm  100.0  100.0  100.0  100.0    n/a   35.4  100.0
  ...ext/UTX/Simple/Version.pm  100.0  100.0  100.0  100.0  100.0    9.5  100.0
  ...e/Version/Header/V0_90.pm  100.0  100.0    n/a  100.0  100.0    1.0  100.0
  ...e/Version/Header/V0_91.pm  100.0  100.0    n/a  100.0  100.0    0.7  100.0
  ...e/Version/Header/V0_92.pm  100.0  100.0    n/a  100.0  100.0    0.2  100.0
  Total                         100.0  100.0  100.0  100.0  100.0  100.0  100.0
  ---------------------------- ------ ------ ------ ------ ------ ------ ------

Full report on B<the latest version>'s code coverage is available at
L<http://perl.ermitejo.com/Text-UTX-Simple/coverage.html>.


=head1 TO DO

B<This section has not been translated yet.>

=over 4

=item *

To support UTX-Simple specification version 0.91 and over.

=item *

To enhance the English translation of the document.

=item *

To improve tests (more, more!).

=item *

To segregate developer and user tests. (I<Perl Hacks #62>)

=item *

To run tests under C<-T> switch (tainting check mode).

=item *

To display the file name and the number of lines appropriately
when an exception is sent.

=item *

To implement C<each()> method by the Iterator Pattern.

=item *

To specify entries by option same as C<push()>
when object creation at C<new()>.

=item *

To complement the rest columns by blank character or specified character
when C<push()>, C<unshift()>, C<read()>, C<parse()>,
if a column alone that doesn't come up to the column provided
for by the header is given.

=item *

To specify option for L<File::Slurp|File::Slurp> at C<read()>, for C<binmode>.
Or to adopt option, that sets encoding of inputs,
into C<read()> and C<parse()>.

=item *

To implement operator-overload for C<as_string()>, C<push()>, etc..

=item *

To preserve the comment line of input text of C<parse()>.
It is being disregarded now.

=item *

To optimize some processes.

=item *

To make other sample "translator" modules.
Those modules convert original format into UTX-Simple format,
with this module.
For example,
C<Text::UTX::Simple::Translator::Eijiro>
( for L<http://www.eijiro.jp/> ),
C<Text::UTX::Simple::Translator::EPWING>
( for L<http://www.epwing.or.jp/> ),
C<Text::UTX::Simple::Translator::PDIC>
( for L<http://homepage3.nifty.com/TaN/> ),
etc.

=back


=head1 SEE ALSO

=over 4

=item Official page of the UTX simple specification (English)

L<http://www.aamt.info/english/utx/>

=item Official page of the UTX simple specification (Japanese)

L<http://www.aamt.info/japanese/utx/>

=item L<Text::CSV_XS|Text::CSV_XS>

For universal operation of xSV

=back


=head1 AUTHOR

=over 4

=item MORIYA Masaki

E<lt>moriya at ermitejo.comE<gt>,
L<http://ttt.ermitejo.com/>

=back

is responsible for
C<Text::UTX::Simple>
module.

The UTX specification and the UTX-Simple specification
are results of examination by AAMT
(Asia-Pacific Association for Machine Translation, L<http://www.aamt.info/>);
and all rights are reserved by AAMT.

Furthermore, author belong to the AAMT,
but AAMT has no concern with this module.

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2008-2009, MORIYA Masaki E<lt>moriya at ermitejo.comE<gt>.
All rights reserved.

This is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
See L<perlgpl|perlapi> and L<perlartistic|perlartistic>.


=head2 Note: about deliverables

Rights about deliverables by this module (such as generated dictionaries),
in other words, outputted data, is the same as inputted data.
For example, when you convert your user dictionary by which you reserved rights,
into UTX-S formatted dictionary,
generated dictionary's rights also reserved by you.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.


=head2 Note: about specification

It is escaped that not only author's responsibility about this module,
but also formulator (AAMT)'s responsibility.


=head1 ACKNOWLEDGEMENTS

There are many people who helped bring this module about.
I extend my gratitude to:

=over 4

=item Sharing/Standardization Working Group, MT Research Committee, AAMT, L<http://www.aamt.info/english/utx/>

For many advice to release this module.
Additionally, 

=item Francis Bond, L<http://www2.nict.go.jp/x/x161/en/member/bond/index.html>

For many information and advice of the UTX-Simple specification.
Additionally, he adjusted affairs at AAMT to release this module.
Moreover, he read this module's codes before release.

=back
