#!/usr/bin/perl

use 5.005;
use inc::Module::Install;

author          'Audrey Tang <cpan@audreyt.org>';
abstract        'Use other catalog formats in Maketext';
name            'Locale-Maketext-Lexicon';
license         'MIT';
all_from        'lib/Locale/Maketext/Lexicon.pm';
install_script  'script/xgettext.pl';
requires        'Locale::Maketext' => '0.01';
include_deps    'Test::More';

WriteAll( sign => 1, meta => 1);
