#!/usr/bin/perl

use strict;
use warnings;

use Yaffas;
use Yaffas::UI;
use Yaffas::Exception;
use Yaffas::Module::ZarafaResources;
use Yaffas::Module::Users;
use Error qw(:try);
use CGI::Carp qw(warningsToBrowser fatalsToBrowser);

Yaffas::init_webmin();

require './forms.pl';

ReadParse();

header();

try {
	Yaffas::Module::ZarafaResources::create_resource(
		$main::in{name},             $main::in{description},
		$main::in{decline_conflict}, $main::in{decline_recurring}
	);
	print Yaffas::UI::ok_box ();
}
catch Yaffas::Exception with {
	print Yaffas::UI::all_error_box(shift);
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
