#!/usr/bin/perl -w
use strict;
use warnings;

use Yaffas;
use Yaffas::UI qw(ok_box error_box all_error_box);
use CGI::Carp qw(fatalsToBrowser warningsToBrowser);
use Yaffas::Exception;
use Yaffas::Module::AuthSrv;
use Yaffas::Service qw(control START STOP RESTART NSCD WINBIND GOGGLETYKE SAMBA ZARAFA_SERVER USERMIN POSTFIX);
use Error qw(:try);
use Yaffas::UGM;
use Yaffas::Constant;

require "./forms.pl";

Yaffas::init_webmin();
ReadParse();
header();

# switch to ads
my $pdc = $main::in{'pass_pdc'};
my $dom_name = $main::in{dom_name};
my $dom_adm = $main::in{dom_adm};
my $dom_pass1 = $main::in{dom_pass1};
my $printop_group =$main::in{printop_group};
my $type = "win";
my $ads_user = $main::in{'ads_user'};
my $ads_user_pass1 = $main::in{'ads_user_pass1'};
my $ldap_encryption = undef;
my $noencryption_confirmed = $main::in{'noencryption_confirmed'};
$noencryption_confirmed = "yes";

try {
	my $exception = Yaffas::Exception->new();
	$exception->add('err_pdc_missing') unless $pdc;
	throw $exception if $exception;
	$ldap_encryption = Yaffas::Module::AuthSrv::test_ldaps($pdc);

	if ((defined $ldap_encryption) || ($noencryption_confirmed eq "yes")) {
		control(NSCD, STOP) unless Yaffas::Constant::OS eq "RHEL5";
		control(GOGGLETYKE, STOP);
		control(WINBIND, START);

		my $oldusers = undef;
		my $oldgroups = undef;

		if (Yaffas::Product::check_product("fax") || Yaffas::Product::check_product("pdf")) {
			$oldusers = Yaffas::Module::AuthSrv::get_sys_and_db_users();
			$oldgroups = Yaffas::Module::AuthSrv::get_sys_and_db_groups();
		}
		Yaffas::Module::AuthSrv::set_pdc( $pdc, $dom_name, $dom_adm, $dom_pass1, $type, $ads_user, $ads_user_pass1, $ldap_encryption );
		Yaffas::Module::AuthSrv::mod_nsswitch();

		control(SAMBA, RESTART);
		if(control(WINBIND, RESTART)) {
			# sleeping some time, so winbind can get all users
			sleep 7;
		}
		if (Yaffas::Product::check_product("fax") || Yaffas::Product::check_product("pdf")) {
			Yaffas::Module::AuthSrv::clean_ug_data($oldusers,$oldgroups, defined($main::in{wipe_faxconf}) ? "all" : undef);
			Yaffas::UGM::set_print_operators_group($printop_group, $dom_adm, $dom_pass1);
		}

		control(NSCD, START) unless Yaffas::Constant::OS eq "RHEL5";
		control(GOGGLETYKE, START);
		control(ZARAFA_SERVER, RESTART) if Yaffas::Product::check_product("zarafa");
		system(Yaffas::Constant::APPLICATION->{zarafa_admin}, "-s");
		control(USERMIN, RESTART);
		control(POSTFIX, RESTART);

		print Yaffas::UI::ok_box();
	}
}
catch Yaffas::Exception with {
	Yaffas::Service::control(NSCD, START) unless Yaffas::Constant::OS eq "RHEL5";
	Yaffas::Service::control(GOGGLETYKE, START);
	print Yaffas::UI::all_error_box(shift);
	ads();
};

footer("ads_help");
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
