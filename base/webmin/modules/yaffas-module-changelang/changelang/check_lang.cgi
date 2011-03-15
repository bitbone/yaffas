#!/usr/bin/perl
# check_lang.cgi
# check which lang user wants 

use Yaffas;
use Yaffas::Module::ChangeLang;
use Yaffas::Exception;
use Yaffas::UI;
use Error qw(:try);
use CGI::Carp qw(fatalsToBrowser warningsToBrowser);

my $error;

# load web-lib manually to execute ReadParse before header()
require "../web-lib.pl";
ReadParse();

my $lang = $in{'lang'};

try {
	Yaffas::Module::ChangeLang::set_lang($lang);
	$error = undef;
} catch Yaffas::Exception with {
	$error = shift;
};

Yaffas::init_webmin();


header($text{'lbl_index_header'}, "");


if (defined($error)) {
	print Yaffas::UI::all_error_box($error);
} else {
	print Yaffas::UI::ok_box();
}

footer();

=pod

=head1 COPYRIGHT

This file is part of yaffas.

yaffas is free software: you can redistribute it and/or modify it
under the terms of the GNU Affero General Public License as published
by the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

yaffas is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Affero General Public
License for more details.

You should have received a copy of the GNU Affero General Public
License along with yaffas.  If not, see
<http://www.gnu.org/licenses/>.
