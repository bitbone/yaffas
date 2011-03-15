#!/usr/bin/perl
# index.cgi

use strict;
use warnings;

use Yaffas;
use CGI::Carp qw(warningsToBrowser fatalsToBrowser);
use Yaffas::Exception;
use Error qw(:try);
use Yaffas::Module::SNMPConf;

require './forms.pl';

Yaffas::init_webmin();
ReadParse();

header();

my @footer = ("", $main::text{BBMODULEDESC});

try {
	if (exists $main::in{save}) {
		my $enabled = defined($main::in{enabled}) ? 1 : 0;
		Yaffas::Module::SNMPConf::set_snmp_config($enabled, $main::in{community}, $main::in{network});
		print Yaffas::UI::ok_box();
	} else {
		show_snmp_conf();
		@footer = ();
	}
} catch Yaffas::Exception with {
	print Yaffas::UI::all_error_box(shift);
	show_snmp_conf();
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
