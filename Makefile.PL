#!/usr/bin/perl

use 5.005;
use inc::Module::Install;

author          'Audrey Tang <cpan@audreyt.org>';
abstract        'Use other catalog formats in Maketext';
name            'Locale-Maketext-Lexicon';
license         'MIT';
perl_version    '5.005';
all_from        'lib/Locale/Maketext/Lexicon.pm';
install_script  'script/xgettext.pl';
requires        'Locale::Maketext' => '0.01';
recommends      'Template'  => '2.20';
recommends      'YAML' => '0.66';
include_deps    'Test::More';

WriteAll;
