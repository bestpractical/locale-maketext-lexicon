#! /usr/bin/perl -w
use lib '../lib';
use strict;
use Test::More tests => 43;

use_ok('Locale::Maketext::Extract');
my $Ext = Locale::Maketext::Extract->new;
isa_ok($Ext => 'Locale::Maketext::Extract');

extract_ok('_("123")'                      => 123,                  'Simple extraction');

extract_ok('_("[_1] is happy")'            => '%1 is happy',   '[_1] to %1');
extract_ok('_("%1 is happy")'              => '%1 is happy',   '%1 verbatim', 1);

extract_ok('_("[*,_1] counts")'            => '%*(%1) counts', '[*,_1] to %*(%1)');
extract_ok('_("%*(%1) counts")'            => '%*(%1) counts', '%*(%1) verbatim', 1);

extract_ok('_("[*,_1,_2] counts")'         => '%*(%1,%2) counts',
'[*,_1,_2] to %*(%1,%2)');
extract_ok('_("[*,_1,_2] counts")'         => '[*,_1,_2] counts',
'[*,_1,_2] verbatim', 1);

extract_ok(q(_('foo\$bar'))                => 'foo\\$bar',   'Escaped \$ in q');
extract_ok(q(_("foo\$bar"))                => 'foo$bar',     'Normalized \$ in qq');

extract_ok(q(_('foo\x20bar'))              => 'foo\\x20bar', 'Escaped \x in q');
extract_ok(q(_("foo\x20bar"))              => 'foo bar',     'Normalized \x in qq');

extract_ok(q(_('foo\nbar'))                => 'foo\\nbar',   'Escaped \n in qq');
extract_ok(q(_("foo\nbar"))                => "foo\nbar",    'Normalized \n in qq');
extract_ok(qq(_("foo\nbar"))               => "foo\nbar",    'Normalized literal \n in qq');

extract_ok(q(_("foo\nbar"))                => "foo\nbar",    'Trailing \n in qq');
extract_ok(qq(_("foobar\n"))               => "foobar\n",    'Trailing literal \n in qq');

extract_ok(q(_('foo\bar'))                 => 'foo\\bar',    'Escaped \ in q');
extract_ok(q(_('foo\\\\bar'))              => 'foo\\bar',    'Normalized \\\\ in q');
extract_ok(q(_("foo\bar"))                 => "foo\bar",     'Interpolated \b in qq');

extract_ok(q([% loc( 'foo "bar" baz' ) %]) => 'foo "bar" baz', 'Escaped double quote in text');

extract_ok(q( _(q{foo bar}))               => "foo bar",     'No escapes');
extract_ok(q(_(q{foo\bar}))                => 'foo\\bar',    'Escaped \ in q');
extract_ok(q(_(q{foo\\\\bar}))             => 'foo\\bar',    'Normalized \\\\ in q');
extract_ok(q(_(qq{foo\bar}))               => "foo\bar",          'Interpolated \b in qq');

# HTML::FormFu test
extract_ok('    content_loc: foo bar'          => "foo bar",    "html-formfu extraction");

extract_ok(
    q(my $x = loc('I "think" you\'re a cow.') . "\n";) => 'I "think" you\'re a cow.', 
    "Handle escaped single quotes"
);

extract_ok(
    q(my $x = loc("I'll poke you like a \"cow\" man.") . "\n";)
        => 'I\'ll poke you like a "cow" man.',
    "Handle escaped double quotes"
);

extract_ok(q(_("","car"))                  => '',            'ignore empty string');
extract_ok(q(_("0"))                       => '',            'ignore zero');

extract_ok(<<'__EXAMPLE__'                 => 'foo bar baz',   'trim the string (tt)');
[% |loc -%]
foo bar baz
[%- END %]
__EXAMPLE__

extract_ok(<<'__EXAMPLE__'                 => "123\n",       "Simple extraction (heredoc)");
_(<<__LOC__);
123
__LOC__
__EXAMPLE__

extract_ok(<<'__EXAMPLE__'                 => "foo\\\$bar\\\'baz\n", "No escaped of \$ and \' in singlequoted terminator (heredoc)");
_(<<'__LOC__');
foo\$bar\'baz
__LOC__
__EXAMPLE__

extract_ok(<<'__EXAMPLE__'                 => "foo\$bar\n",  "Normalized \$ in doublequoted terminator (heredoc)");
_(<<"__LOC__");
foo\$bar
__LOC__
__EXAMPLE__

extract_ok(<<'__EXAMPLE__'                 => "foo\nbar\n",  "multilines (heredoc)");
_(<<__LOC__);
foo
bar
__LOC__
__EXAMPLE__

extract_ok(<<'__EXAMPLE__'                 => "example\n",   "null identifier (heredoc)");
_(<<"");
example

__EXAMPLE__

extract_ok(<<'__EXAMPLE__'                 => "example\n",   "end() after the heredoc (heredoc)");
_(<<__LOC__
example
__LOC__
);
__EXAMPLE__

write_po_ok(<<'__EXAMPLE__'                => <<'__EXPECTED__', "null identifier with end after the heredoc (heredoc)");
_(<<""
example

);
__EXAMPLE__
#: :1
msgid "example\n"
msgstr ""
__EXPECTED__

write_po_ok(<<'__EXAMPLE__'                => <<'__EXPECTED__', "q with multilines with args");
_(q{example %1
with multilines
},20);
__EXAMPLE__
#: :1
#. (20)
msgid ""
"example %1\n"
"with multilines\n"
msgstr ""
__EXPECTED__

write_po_ok(<<'__EXAMPLE__'                => <<'__EXPECTED__', "null terminator with multilines with args (heredoc)");
_(<<"", 15)
example %1
with multilines

__EXAMPLE__
#: :1
#. (15)
msgid ""
"example %1\n"
"with multilines\n"
msgstr ""
__EXPECTED__

write_po_ok(<<'__EXAMPLE__'                => <<'__EXPECTED__', "null terminator with end after the heredoc with args (heredoc)");
_(<<"", 10)
example %1

__EXAMPLE__
#: :1
#. (10)
msgid "example %1\n"
msgstr ""
__EXPECTED__

write_po_ok(<<'__EXAMPLE__'                => <<'__EXPECTED__', "two _() calls (heredoc)");
_(<<"", 10)
example1 %1

_(<<"", 5)
example2 %1

__EXAMPLE__
#: :1
#. (10)
msgid "example1 %1\n"
msgstr ""

#: :4
#. (5)
msgid "example2 %1\n"
msgstr ""
__EXPECTED__

sub extract_ok {
    my ($text, $expected, $info, $verbatim) = @_;
    $Ext->extract('' => $text);
    $Ext->compile($verbatim);
    my $result =  join('', %{$Ext->lexicon});
    is($result, $expected, $info );
    $Ext->clear;
}

sub write_po_ok {
    my ($text, $expected, $info, $verbatim) = @_;
    my $po_file = 't/5-extract.po';

    # create .po
    $Ext->extract('' => $text);
    $Ext->compile($verbatim);
    $Ext->write_po($po_file);

    # read .po
    open(my $po_handle,'<',$po_file) or die("Cannot open $po_file: $!");
    local $/ = undef;
    my $result = <$po_handle>;
    close($po_handle);
    unlink($po_file) or die("Cannot unlink $po_file: $!");

    # cut the header from result
    my $start_expected = length($Ext->header);
    $start_expected++  if( $start_expected < length($result) );

    # check result vs expected
    is(substr($result, $start_expected), $expected, $info );
    $Ext->clear;
}

