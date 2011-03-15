#!/usr/bin/perl

use strict;
use warnings;

use Yaffas;
use Yaffas::UI;
use Yaffas::Exception;
use Error qw(:try);
use CGI::Carp qw(fatalsToBrowser warningsToBrowser);
use Yaffas::Service qw(control START STOP RESTART NSCD WINBIND SAMBA);
use Yaffas::UGM;

require './forms.pl';

Yaffas::init_webmin();
ReadParse();
my $printop_group = $main::in{printop_group};
my $admin = $main::in{admin};
my $adminpw = $main::in{adminpw};

header();

try {
	Yaffas::UGM::set_print_operators_group($printop_group, $admin, $adminpw);
	Yaffas::Service::control(SAMBA, RESTART);
	print Yaffas::UI::ok_box();
}
catch Yaffas::Exception with
{
	print Yaffas::UI::all_error_box(shift);
	printops_group($printop_group, $admin);
};

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
