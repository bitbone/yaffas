#!/usr/bin/perl -w
use strict;
use warnings;

use Yaffas;
use Yaffas::UI qw(ok_box error_box all_error_box);
use CGI::Carp qw(fatalsToBrowser warningsToBrowser);
use Yaffas::Exception;
use Yaffas::Module::AuthSrv;
use Error qw(:try);
use Yaffas::UGM;
use Yaffas::Constant;
use JSON;

require "./forms.pl";

Yaffas::init_webmin();
ReadParse();

Yaffas::json_header();


try {
	my $ldap_encryption = Yaffas::Module::AuthSrv::test_ldaps($main::in{'pdc'});
	print to_json({ldaps => $ldap_encryption ? 1 : 0});
} catch Yaffas::Exception with {
	print all_error_box(shift);
}

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
