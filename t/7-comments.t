#!/usr/bin/perl -w
#
# Check that comments in PO files are correctly parsed
#

use strict;
use Test::More tests => 6;

use_ok('Locale::Maketext::Extract');

my $msgid = 'A random string to check that comments work';
my $lex = Locale::Maketext::Extract->new();
ok( $lex, 'Locale::Maketext::Extract object created');

$lex->read_po('t/comments.po');

# Here '#' and newlines are kept together with the comment
# Don't know if it's correct or elegant
is(
    $lex->msg_comment($msgid),
    'Some user comment' . "\n"
);

$lex->write_po('t/comments_out.po');

$lex->clear();

is(
    $lex->msg_comment($msgid),
    undef,
    'Comment should be gone with clear()'
);

# Read back the new po file and check that
# the comment is readable again
$lex->read_po('t/comments_out.po');

is(
    $lex->msg_comment($msgid),
    'Some user comment' . "\n"
);

ok(unlink('t/comments_out.po'));
