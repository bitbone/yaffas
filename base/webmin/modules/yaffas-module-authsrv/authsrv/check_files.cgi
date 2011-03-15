#!/usr/bin/perl

use strict;
use warnings;

use Yaffas;
use Yaffas::Module::AuthSrv;
use Yaffas::UI;
use Yaffas::Exception;
use Error qw(:try);
use CGI::Carp qw(fatalsToBrowser warningsToBrowser);
use Yaffas::Service qw(control START STOP RESTART NSCD WINBIND GOGGLETYKE SAMBA ZARAFA_SERVER USERMIN);
use Yaffas::UGM;

require './forms.pl';

Yaffas::init_webmin();
ReadParse();
my $host = $main::in{host};
my $basedn = $main::in{basedn};
my $binddn = $main::in{binddn};
my $bindpw = $main::in{bindpw};
my $userdn = $main::in{userdn};
my $groupdn = $main::in{groupdn};
my $printop_group = $main::in{printop_group};
my $usersearch = $main::in{usersearch};
my $ldap_encryption = undef;
my $noencryption_confirmed = $main::in{'noencryption_confirmed'};

header();

try {
	Yaffas::Module::AuthSrv::set_files_auth();
	print Yaffas::UI::ok_box();
}
catch Yaffas::Exception with
{
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
