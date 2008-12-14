#! /usr/bin/perl -w
use lib '../lib';
use strict;
use Test::More tests => 100;

use_ok('Locale::Maketext::Extract');
my $Ext = Locale::Maketext::Extract->new();
isa_ok($Ext => 'Locale::Maketext::Extract');

extract_ok('_("123")'                      => 123,             'Simple extraction');

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


#### BEGIN TT TESTS ############
SKIP: { skip('Template.pm unavailable', 46) unless eval { require Template };

extract_ok(<<'__EXAMPLE__'                 => 'foo bar baz', 'trim the string (tt)');
[% |loc -%]
foo bar baz
[%- END %]
__EXAMPLE__

write_po_ok(q([% l(string) %])             => '', 'TT l function - no string');

write_po_ok(q([% l('string') %])           => <<'__EXAMPLE__', 'TT l function - no arg');
#: :1
msgid "string"
msgstr ""
__EXAMPLE__

write_po_ok(q([% l('string',arg) %])       => <<'__EXAMPLE__', 'TT l function - variable arg');
#. (arg)
#: :1
msgid "string"
msgstr ""
__EXAMPLE__

write_po_ok(q([% l('string','arg') %])     => <<'__EXAMPLE__', 'TT l function - literal arg');
#. ("arg")
#: :1
msgid "string"
msgstr ""
__EXAMPLE__

write_po_ok(q([% string | l %])            => '', 'TT l inline filter - no string');

write_po_ok(q([% 'string' | l %])          => <<'__EXAMPLE__', 'TT l inline filter - no arg');
#: :1
msgid "string"
msgstr ""
__EXAMPLE__

write_po_ok(q([% 'string' | l('arg')  %])  => <<'__EXAMPLE__', 'TT l inline filter - literal arg');
#. ("arg")
#: :1
msgid "string"
msgstr ""
__EXAMPLE__

write_po_ok(q([% 'string' | l(arg)  %])    => <<'__EXAMPLE__', 'TT l inline filter - variable arg');
#. (arg)
#: :1
msgid "string"
msgstr ""
__EXAMPLE__

write_po_ok(q([% |l %][% string %][% END %])    => '', 'TT l block filter - no string');

SKIP: {
    skip "Can't handle directive embedded in text blocks",1;

    write_po_ok(q([% |l %] string [% var %][% END %])    => '', 'TT l block filter - embedded directive');
}

write_po_ok(q([% |l %]string[% END %])     => <<'__EXAMPLE__', 'TT l block filter - no arg');
#: :1
msgid "string"
msgstr ""
__EXAMPLE__

write_po_ok(q([% |l('arg') %]string[% END %]) => <<'__EXAMPLE__', 'TT l block filter - literal arg');
#. ("arg")
#: :1
msgid "string"
msgstr ""
__EXAMPLE__

write_po_ok(q([% |l(arg) %]string[% END %])   => <<'__EXAMPLE__', 'TT l block filter - variable arg');
#. (arg)
#: :1
msgid "string"
msgstr ""
__EXAMPLE__


write_po_ok(q([% FILTER l(arg) %]string[% END %])   => <<'__EXAMPLE__', 'TT block FILTER - variable arg');
#. (arg)
#: :1
msgid "string"
msgstr ""
__EXAMPLE__


# Use just the TT2 parser, otherwise loc() throws false positives in the Perl plugin
my $Old_Ext = $Ext;
$Ext = Locale::Maketext::Extract->new(plugins=>{tt2 => '*'});

write_po_ok(q([% loc('string',arg) %])       => <<'__EXAMPLE__', 'TT loc function - variable arg');
#. (arg)
#: :1
msgid "string"
msgstr ""
__EXAMPLE__

write_po_ok(q([% 'string' | loc('arg')  %])  => <<'__EXAMPLE__', 'TT loc inline filter - literal arg');
#. ("arg")
#: :1
msgid "string"
msgstr ""
__EXAMPLE__

$Ext = $Old_Ext;

write_po_ok(<<'__TT__'  => <<'__EXAMPLE__', 'TT multiline filter');
[% | l(arg1,arg2) %]
my string
[% END %]
__TT__
#. (arg1, arg2)
#: :1
msgid ""
"\n"
"my string\n"
msgstr ""
__EXAMPLE__

write_po_ok(<<'__TT__'  => <<'__EXAMPLE__', 'TT multiline filter with chomp');
[%- | l(arg1,arg2) -%]
my string
[%- END -%]
__TT__
#. (arg1, arg2)
#: :3
msgid "my string"
msgstr ""
__EXAMPLE__

extract_ok(q([% l('catted ' _ 'string') %]) => "catted string",       "TT catted string");
extract_ok(q([% l('catted ' _ string) %]) => "",                      "TT catted dir 1");
extract_ok(q([% l('catted ' _ string) %]) => "",                      "TT catted dir 2");

extract_ok(q([% l("embedded ${string}") %]) => "",                    "TT embedded string 1");
extract_ok(q([% l("embedded \${string}") %]) => 'embedded ${string}', "TT embedded string 2");
extract_ok(q([% l('embedded ${string}') %]) => 'embedded ${string}',  "TT embedded string 3");

write_po_ok(<<'__TT__'  => <<'__EXAMPLE__', 'TT quoted - 1');
[% l('my \ string', 'my \ string') %]
[% l('my \\ string', 'my \\ string') %]
[% l("my \\ string", "my \\ string") %]
__TT__
#. ("my \\ string")
#: :1 :2 :3
msgid "my \\ string"
msgstr ""
__EXAMPLE__

write_po_ok(<<'__TT__'  => <<'__EXAMPLE__', 'TT quoted - 2');
[% l('my str\'ing','my str\'ing') %]
__TT__
#. ("my str'ing")
#: :1
msgid "my str'ing"
msgstr ""
__EXAMPLE__

write_po_ok(<<'__TT__'  => <<'__EXAMPLE__', 'TT quoted - 3');
[% l('my string"','my string"') %]
__TT__
#. ("my string\"")
#: :1
msgid "my string\""
msgstr ""
__EXAMPLE__

write_po_ok(<<'__TT__'  => <<'__EXAMPLE__', 'TT quoted - 4');
[% l("my string'","my string'") %]
__TT__
#. ("my string'")
#: :1
msgid "my string'"
msgstr ""
__EXAMPLE__

write_po_ok(<<'__TT__'  => <<'__EXAMPLE__', 'TT quoted - 5');
[% l("my \nstring","my \nstring") %]
__TT__
#. ("my \nstring")
#: :1
msgid ""
"my \n"
"string"
msgstr ""
__EXAMPLE__

write_po_ok(<<'__TT__'  => <<'__EXAMPLE__', 'TT quoted - 6');
[% l('my \nstring','my \nstring') %]
__TT__
#. ("my \\nstring")
#: :1
msgid "my \\nstring"
msgstr ""
__EXAMPLE__

write_po_ok(<<'__TT__'  => <<'__EXAMPLE__', 'TT quoted - 7');
[% 'my \ string'  | l('my \ string') %]
[% 'my \\ string' | l('my \\ string') %]
[% "my \\ string" | l("my \\ string") %]
__TT__
#. ("my \\ string")
#: :1 :2 :3
msgid "my \\ string"
msgstr ""
__EXAMPLE__

write_po_ok(<<'__TT__'  => <<'__EXAMPLE__', 'TT quoted - 8');
[% 'my str\'ing' | l('my str\'ing') %]
__TT__
#. ("my str'ing")
#: :1
msgid "my str'ing"
msgstr ""
__EXAMPLE__

write_po_ok(<<'__TT__'  => <<'__EXAMPLE__', 'TT quoted - 9');
[% 'my string"' | l('my string"') %]
__TT__
#. ("my string\"")
#: :1
msgid "my string\""
msgstr ""
__EXAMPLE__

write_po_ok(<<'__TT__'  => <<'__EXAMPLE__', 'TT quoted - 10');
[% "my string'" |l("my string'") %]
__TT__
#. ("my string'")
#: :1
msgid "my string'"
msgstr ""
__EXAMPLE__

write_po_ok(<<'__TT__'  => <<'__EXAMPLE__', 'TT quoted - 11');
[% "my \nstring" |l("my \nstring") %]
__TT__
#. ("my \nstring")
#: :0
msgid ""
"my \n"
"string"
msgstr ""
__EXAMPLE__

write_po_ok(<<'__TT__'  => <<'__EXAMPLE__', 'TT quoted - 12');
[% 'my \nstring' |l('my \nstring') %]
__TT__
#. ("my \\nstring")
#: :1
msgid "my \\nstring"
msgstr ""
__EXAMPLE__

write_po_ok(<<'__TT__'  => <<'__EXAMPLE__', 'TT quoted - 13');
[% | l('my \ string') %]my \ string[% END %]
[% | l('my \\ string') %]my \\ string[% END %]
__TT__
#. ("my \\ string")
#: :1
msgid "my \\ string"
msgstr ""

#. ("my \\ string")
#: :2
msgid "my \\\\ string"
msgstr ""
__EXAMPLE__

write_po_ok(<<'__TT__'  => <<'__EXAMPLE__', 'TT quoted - 14');
[% | l('my str\'ing') %]my str'ing[% END %]
__TT__
#. ("my str'ing")
#: :1
msgid "my str'ing"
msgstr ""
__EXAMPLE__

write_po_ok(<<'__TT__'  => <<'__EXAMPLE__', 'TT quoted - 15');
[% | l('my str\'ing') %]my str\'ing[% END %]
__TT__
#. ("my str'ing")
#: :1
msgid "my str\\'ing"
msgstr ""
__EXAMPLE__


write_po_ok(<<'__TT__'  => <<'__EXAMPLE__', 'TT quoted - 16');
[% | l("my str\"ing") %]my str"ing[% END %]
__TT__
#. ("my str\"ing")
#: :1
msgid "my str\"ing"
msgstr ""
__EXAMPLE__

write_po_ok(<<'__TT__'  => <<'__EXAMPLE__', 'TT quoted - 17');
[% | l("my str\"ing") %]my str\"ing[% END %]
__TT__
#. ("my str\"ing")
#: :1
msgid "my str\\\"ing"
msgstr ""
__EXAMPLE__

write_po_ok(<<'__TT__'  => <<'__EXAMPLE__', 'TT quoted - 18');
[% |l("my \nstring") %]my
string[% END %]
__TT__
#. ("my \nstring")
#: :1
msgid ""
"my\n"
"string"
msgstr ""
__EXAMPLE__

write_po_ok(<<'__TT__'  => <<'__EXAMPLE__', 'TT quoted - 19');
[% |l('my \nstring') %]my \nstring[% END %]
__TT__
#. ("my \\nstring")
#: :1
msgid "my \\nstring"
msgstr ""
__EXAMPLE__


write_po_ok(<<'__TT__'  => <<'__EXAMPLE__', 'TT key values');
[% l('string', key1=>'value',key2=>value, key3 => value.method) %]
__TT__
#. ({ 'key1' => 'value', 'key2' => value, 'key3' => value.method })
#: :1
msgid "string"
msgstr ""
__EXAMPLE__

write_po_ok(<<'__TT__'  => <<'__EXAMPLE__', 'TT complex args');
[% l('string',b.method.$var(arg),c('arg').method.5) %]
__TT__
#. (b.method.$var(arg), c("arg").method.5)
#: :1
msgid "string"
msgstr ""
__EXAMPLE__

#### END TT TESTS ############
}

#### BEGIN YAML TESTS ############
SKIP: { skip('YAML.pm unavailable', 7) unless eval { require YAML };

extract_ok(qq(key: _"string"\n)               => "string",       "YAML double quotes");
extract_ok(qq(key: _'string'\n)               => "string",       "YAML single quotes");
extract_ok(qq(key: _"str"ing"\n)              => 'str"ing',      "YAML embedded double quote");

extract_ok(qq( key: { s1: _"string_1", s2: _'string_2', s3: _'string'3'}\n)
    => q(string_1string'3string_2), 'YAML inline hash');


extract_ok(qq( - _"string_1"\n - _'string_2'\n - _'string'3'\n)
    => q(string_1string'3string_2), 'YAML array');

extract_ok(qq(key: [ _"string_1", _'string_2', _'string'3' ]\n)
    => q(string_1string'3string_2), 'YAML Inline arrays'   );

write_po_ok(qq(---\nkey: _"string"\n---\nkey2: _"string2"\n)   => <<'__EXAMPLE__', 'YAML multiple docs');
#: :2
msgid "string"
msgstr ""

#: :3
msgid "string2"
msgstr ""
__EXAMPLE__

}

#### END YAML TESTS ############


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
#. (20)
#: :1
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
#. (15)
#: :1
msgid ""
"example %1\n"
"with multilines\n"
msgstr ""
__EXPECTED__

write_po_ok(<<'__EXAMPLE__'                => <<'__EXPECTED__', "null terminator with end after the heredoc with args (heredoc)");
_(<<"", 10)
example %1

__EXAMPLE__
#. (10)
#: :1
msgid "example %1\n"
msgstr ""
__EXPECTED__

write_po_ok(<<'__EXAMPLE__'                => <<'__EXPECTED__', "two _() calls (heredoc)");
_(<<"", 10)
example1 %1

_(<<"", 5)
example2 %1

__EXAMPLE__
#. (10)
#: :1
msgid "example1 %1\n"
msgstr ""

#. (5)
#: :4
msgid "example2 %1\n"
msgstr ""
__EXPECTED__

write_po_ok(<<'__EXAMPLE__'                => <<'__EXPECTED__', "concat (heredoc)");
_('exam'.<<"", 10)
ple1 %1

__EXAMPLE__
#. (10)
#: :1
msgid "example1 %1\n"
msgstr ""
__EXPECTED__

write_po_ok(<<'__EXAMPLE__'                => <<'__EXPECTED__', "two _() calls with concat over multiline (heredoc)");
_('example' .
<<"", 10)
1 %1

_(<<"", 5)
example2 %1

__EXAMPLE__
#. (10)
#: :1
msgid "example1 %1\n"
msgstr ""

#. (5)
#: :5
msgid "example2 %1\n"
msgstr ""
__EXPECTED__

write_po_ok(<<'__EXAMPLE__'                => <<'__EXPECTED__', "i can concat the world!");
_(
'\$foo'
."\$bar"
.<<''
\$baz

)
__EXAMPLE__
#: :2
msgid "\\$foo$bar\\$baz\n"
msgstr ""
__EXPECTED__

## Wrapping

write_po_ok(<<'__EXAMPLE__' => <<'__EXPECTED__', "wrap off");
_('string');
_('string');
__EXAMPLE__
#: :1 :2
msgid "string"
msgstr ""
__EXPECTED__

$Ext->{wrap} = 1;
write_po_ok(<<'__EXAMPLE__' => <<'__EXPECTED__', "wrap on");
_('string');
_('string');
__EXAMPLE__
#: :1
#: :2
msgid "string"
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

