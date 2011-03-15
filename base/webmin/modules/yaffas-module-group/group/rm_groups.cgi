#!/usr/bin/perl
use strict;
use warnings;

use CGI::Carp qw(fatalsToBrowser warningsToBrowser);
use Yaffas;
use Yaffas::UI;
use Yaffas::Module::Group;
use Yaffas::Auth;
use Yaffas::Auth::Type;
use Error qw(:try);

Yaffas::init_webmin();
header($main::text{'check_editgroup_header'}, "");
ReadParse();

my $groups = $main::in{"groups"};
my @tmp = split /\0/, $groups;

try {
	Yaffas::Exception->throw('err_no_local_auth') unless ( Yaffas::Auth::auth_type eq Yaffas::Auth::Type::LOCAL_LDAP or
							       Yaffas::Auth::auth_type eq Yaffas::Auth::Type::FILES );

	Yaffas::Module::Group::del_groups(@tmp);
	print Yaffas::UI::ok_box();
} catch Yaffas::Exception with {
	my $e = shift;
	print Yaffas::UI::all_error_box($e);

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
