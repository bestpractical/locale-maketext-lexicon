package Locale::Maketext::Extract::Plugin::Perl;

use strict;

use base qw(Locale::Maketext::Extract::Plugin::Base);

=head1 NAME

Locale::Maketext::Extract::Plugin::Perl - Perl format parser

=head1 SYNOPSIS

    $plugin = Locale::Maketext::Extract::Plugin::Perl->new(
        $lexicon            # A Locale::Maketext::Extract object
        @file_types         # Optionally specify a list of recognised file types
    )

    $plugin->extract($filename,$filecontents);

=head1 DESCRIPTION

Extracts strings to localise (including HEREDOCS) from Perl code

=head1 SHORT PLUGIN NAME

    perl

=head1 VALID FORMATS

Valid localization function names are:

=over 4

=item translate

=item maketext

=item gettext

=item loc

=item x

=item _

=item __

=back

=head1 KNOWN FILE TYPES

=over 4

=item .pm

=item .pl

=item .cgi

=back

=cut

use constant NUL  => 0;
use constant BEG  => 1;
use constant PAR  => 2;
use constant HERE => 10;
use constant QUO1 => 3;
use constant QUO2 => 4;
use constant QUO3 => 5;
use constant QUO4 => 6;
use constant QUO5 => 7;
use constant QUO6 => 8;
use constant QUO7 => 9;

sub file_types {
    return qw( pm pl cgi );
}

sub extract {
    my $self = shift;
    local $_ = shift;

    local $SIG{__WARN__} = sub {die @_};

    # Perl code:
    my ( $state, $str, $vars, $quo, $heredoc ) = (0);
    my $orig = 1 + ( () = ( ( my $__ = $_ ) =~ /\n/g ) );

PARSER: {
        $_ = substr( $_, pos($_) ) if ( pos($_) );
        my $line = $orig - ( () = ( ( my $__ = $_ ) =~ /\n/g ) );

        # various ways to spell the localization function
        $state == NUL
            && m/\b(translate|maketext|gettext|__?|loc(?:ali[sz]e)?|x)/gc
            && do { $state = BEG; redo };
        $state == BEG && m/^([\s\t\n]*)/gc && redo;

        # begin ()
        $state == BEG
            && m/^([\S\(])\s*/gc
            && do { $state = ( ( $1 eq '(' ) ? PAR : NUL ); redo };

        # begin or end of string
        $state == PAR && m/^(\')/gc && do { $state = $quo = QUO1; redo };
        $state == QUO1 && m/^([^'\\]+)/gc   && do { $str .= $1; redo };
        $state == QUO1 && m/^((?:\\.)+)/gcs && do { $str .= $1; redo };
        $state == QUO1 && m/^\'/gc && do { $state = PAR; redo };

        $state == PAR && m/^\"/gc && do { $state = $quo = QUO2; redo };
        $state == QUO2 && m/^([^"\\]+)/gc   && do { $str .= $1; redo };
        $state == QUO2 && m/^((?:\\.)+)/gcs && do { $str .= $1; redo };
        $state == QUO2 && m/^\"/gc && do { $state = PAR; redo };

        $state == PAR && m/^\`/gc && do { $state = $quo = QUO3; redo };
        $state == QUO3 && m/^([^\`]*)/gc && do { $str .= $1; redo };
        $state == QUO3 && m/^\`/gc && do { $state = PAR; redo };

        $state == PAR && m/^qq\{/gc && do { $state = $quo = QUO4; redo };
        $state == QUO4 && m/^([^\}]*)/gc && do { $str .= $1; redo };
        $state == QUO4 && m/^\}/gc && do { $state = PAR; redo };

        $state == PAR && m/^q\{/gc && do { $state = $quo = QUO5; redo };
        $state == QUO5 && m/^([^\}]*)/gc && do { $str .= $1; redo };
        $state == QUO5 && m/^\}/gc && do { $state = PAR; redo };

        # find heredoc terminator, then get the
        #heredoc and go back to current position
        $state == PAR
            && m/^<<\s*\'/gc
            && do { $state = $quo = QUO6; $heredoc = ''; redo };
        $state == QUO6 && m/^([^'\\\n]+)/gc && do { $heredoc .= $1; redo };
        $state == QUO6 && m/^((?:\\.)+)/gc  && do { $heredoc .= $1; redo };
        $state == QUO6
            && m/^\'/gc
            && do { $state = HERE; $heredoc =~ s/\\\'/\'/g; redo };

        $state == PAR
            && m/^<<\s*\"/gc
            && do { $state = $quo = QUO7; $heredoc = ''; redo };
        $state == QUO7 && m/^([^"\\\n]+)/gc && do { $heredoc .= $1; redo };
        $state == QUO7 && m/^((?:\\.)+)/gc  && do { $heredoc .= $1; redo };
        $state == QUO7
            && m/^\"/gc
            && do { $state = HERE; $heredoc =~ s/\\\"/\"/g; redo };

        $state == PAR
            && m/^<<(\w*)/gc
            && do { $state = HERE; $quo = QUO7; $heredoc = $1; redo };

        # jump ahaid and get the heredoc, then s/// also
        # resets the pos and we are back at the current pos
        $state == HERE
            && m/^.*\r?\n/gc
            && s/\G(.*?\r?\n)$heredoc(\r?\n)//s
            && do { $state = PAR; $str .= $1; redo };

        # end ()
        #

        $state == PAR && m/^\s*[\)]/gc && do {
            $state = NUL;
            $vars =~ s/[\n\r]//g if ($vars);
            if ($quo) {
                if ( ( $quo == QUO1 ) || ( $quo == QUO5 ) ) {
                    $str =~ s/\\([\\'])/$1/g if ($str);  # normalize q strings
                }
                elsif ( $quo != QUO6 ) {
                    $str =~ s/(\\(?:[0x]..|c?.))/"qq($1)"/eeg
                        if ($str);    # normalize qq / qx strings
                }
            }
            # heredoc loosing the terminating line,
            #so decrement one more line for heredoc
            $self->add_entry( $str,
                           $line - ( () = $str =~ /\n/g ) - defined($heredoc),
                           $vars )
                if ($str);
            undef $str;
            undef $vars;
            undef $heredoc;
            redo;
        };

        # a line of vars
        $state == PAR && m/^([^\)]*)/gc && do { $vars .= "$1\n"; redo };
    }
}

=head1 SEE ALSO

=over 4

=item L<xgettext.pl>

for extracting translatable strings from common template
systems and perl source files.

=item L<Locale::Maketext::Lexicon>

=item L<Locale::Maketext::Plugin::Base>

=item L<Locale::Maketext::Plugin::FormFu>

=item L<Locale::Maketext::Plugin::TT2>

=item L<Locale::Maketext::Plugin::YAML>

=item L<Locale::Maketext::Plugin::Mason>

=item L<Locale::Maketext::Plugin::TextTemplate>

=item L<Locale::Maketext::Plugin::Generic>

=back

=head1 AUTHORS

Audrey Tang E<lt>cpan@audreyt.orgE<gt>

=head1 COPYRIGHT

Copyright 2002-2008 by Audrey Tang E<lt>cpan@audreyt.orgE<gt>.

This software is released under the MIT license cited below.

=head2 The "MIT" License

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.

=cut

1;
