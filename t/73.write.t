use strict;
use warnings;
# use utf8;
use lib 't/lib';

use Test::More tests => 33;
use Test::Exception;
# use Test::Warn;
use Test::Text_UTX_Simple qw(:DEFAULT get_dictionary_path);

use Text::UTX::Simple;


my %Path = get_dictionary_path();


# ================================================================
# subroutine for test
# [ 9 tests or 3 tests ]
# ----------------------------------------------------------------
sub test_write {
    my $test_case = shift;

    my $version = $test_case->{version};

    if ($test_case->{exception}) {  # 1 test
        my $utx = Text::UTX::Simple->new($test_case->{query}{new});
        throws_ok( sub { $utx->write($test_case->{query}{write}); },
                   qr{$test_case->{result}},
                   $test_case->{name} );
        return;
    }

    my ($old_path, $new_path) = @Path{($version . '_old', $version . '_new')};

    # write the dictionary to new file
    my $old_dictionary = Text::UTX::Simple->new({
        version => $version,
        file    => $old_path,
    });
    pass(      $old_dictionary->write($new_path) );

    # dictionary from written new file is same as from old file
    my $new_dictionary = Text::UTX::Simple->new({
        version => $version,
        file    => $new_path,
    });
    ok(        $new_dictionary->is_same_format_as($old_dictionary),
               'same format' );
    is_deeply( $new_dictionary->dump_body({array_ref => 1}),
               $old_dictionary->dump_body({array_ref => 1}),
               'same entreis' );

    # allow overwrite(default) exsistant file or protect one
    my ($before, $after);
    $before = $new_dictionary->get_number_of_entries();             # 7
    $new_dictionary->clear();                                       # 7->0
    pass(      $new_dictionary->write($new_path) );                 # overwrite
    $new_dictionary->read($new_path);
    $after  =  $new_dictionary->get_number_of_entries();            # 0
    isnt(      $before,
               $after,
               'ovewritten' );

    $new_dictionary = $old_dictionary->clone();
    $new_dictionary->write($new_path);

    # don't overwrite, if protect => 1
    $before = $new_dictionary->get_number_of_entries();             # 7
    $new_dictionary->clear();                                       # 7->0
    pass(      $new_dictionary->write($new_path, {protect => 1}) ); # no-op
    $new_dictionary->read($new_path);
    $after  = $new_dictionary->get_number_of_entries();             # 7
    is(        $before,
               $after,
               'protected overwrite' );

    $new_dictionary = $old_dictionary->clone();
    unlink $new_path;

    # simply write, if file does not exist, and protect => 1
    $before = $new_dictionary->get_number_of_entries();             # 7
    $new_dictionary->clear();                                       # 7->0
    pass(      $new_dictionary->write($new_path, {protect => 1}) ); # write
    $new_dictionary->read($new_path);
    $after  = $new_dictionary->get_number_of_entries();             # 0
    isnt(      $before,
               $after,
               'write unexistant file' );

    unlink $new_path;

    return;
}


# ================================================================
# write
# [ 18+6 = 42 tests ]
# ----------------------------------------------------------------
foreach my $version (@Versions) {
    my %version_definition = ( version => $version );

    # normal : 9subtests * 1kinds * 3versions = 27tests
    test_write({
        name    => "normal : write, version $version",
        version => $version,
    });

    # exceptions: 1subtest * 2kinds * 3versions = 6tests
    # invalid option
    test_write({
        name      => "exception (filename isn't defined) : version $version",
        exception => 1,
        query     => {
            new   => \%version_definition,
            write => undef,
        },
        result    => q{Can't write a dictionary: }
                   . q{filename isn't defined or is empty},
        version   => $version,
    });
    test_write({
        name      => "exception (filename is empty) : version $version",
        exception => 1,
        query     => {
            new   => \%version_definition,
            write => q{},
        },
        result    => q{Can't write a dictionary: }
                   . q{filename isn't defined or is empty},
        version   => $version,
    });
}
