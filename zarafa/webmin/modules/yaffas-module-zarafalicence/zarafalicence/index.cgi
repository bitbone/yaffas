#!/usr/bin/perl

use Yaffas;
use Yaffas::UI;
use Yaffas::Module::ZarafaLicence;
use CGI::Carp qw(warningsToBrowser fatalsToBrowser);
use Yaffas::Exception;
use Error qw(:try);

Yaffas::init_webmin();

require './forms.pl';

use CGI::Carp qw(fatalsToBrowser);
use strict;
use warnings;

ReadParse();

header();

my @footer;
try {
	if (defined($main::in{license})) {
		Yaffas::Module::ZarafaLicence::install($main::in{license});
		print Yaffas::UI::ok_box();
		push @footer, "", $main::text{BBMODULEDESC};
    }
    else {
		show_installed_licences();
		show_baselicense_form();
		show_log();
	}
} catch Yaffas::Exception with {
	print Yaffas::UI::all_error_box(shift);
};

footer(@footer);
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
