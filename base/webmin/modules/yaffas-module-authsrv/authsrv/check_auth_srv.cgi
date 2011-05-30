#!/usr/bin/perl
# check_auth_srv.cgi

use strict;
use warnings;

use Yaffas;
use Yaffas::Module::AuthSrv;
use Yaffas::UI;
use Yaffas::Exception;
use Error qw(:try);
use CGI::Carp qw(fatalsToBrowser warningsToBrowser);

require './forms.pl';

Yaffas::init_webmin();
ReadParse();
my $auth = defined($main::in{auth_srv}) ? $main::in{auth_srv} : "deactivate";

header();

try
{
	Yaffas::Module::AuthSrv::auth_srv($auth);
	print Yaffas::UI::ok_box();
}
catch Yaffas::Exception with
{
	print Yaffas::UI::all_error_box(shift);
};

footer("index.cgi?auth=1&auth_methode=yaffas_ldap", $main::text{lbl_bk_ldap});

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
