#!/usr/bin/perl -w
use strict;
use warnings;

use CGI::Carp qw(fatalsToBrowser warningsToBrowser);
use Yaffas;
use Yaffas::Check;
use Yaffas::UI;
use Yaffas::Module::Group;
use Yaffas::Auth;
use Yaffas::Auth::Type;
use Error qw(:try);
require "./forms.pl";

Yaffas::init_webmin();
header($main::text{'check_newgroup_header'}, "");
ReadParse();

my $groupname = $main::in{groupname};
my $filetype = $main::in{filetype};
my $mail = $main::in{mail};

try {
	Yaffas::Exception->throw('err_no_local_auth') unless ( Yaffas::Auth::auth_type eq Yaffas::Auth::Type::LOCAL_LDAP or
							       Yaffas::Auth::auth_type eq Yaffas::Auth::Type::FILES );

	if (defined $mail && $mail ne '') {
		unless (Yaffas::Check::email($mail)) {
			throw Yaffas::Exception("err_invalid_email");
		}
		Yaffas::Module::Group::add_groups($filetype, $groupname);
		Yaffas::UGM::set_email($groupname, $main::in{mail}, "group");
	} else {
		Yaffas::Module::Group::add_groups($filetype, $groupname);
	}
	print Yaffas::UI::ok_box();
} catch Yaffas::Exception with {
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
