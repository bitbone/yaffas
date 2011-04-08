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
use Yaffas::Service qw(control START STOP RESTART NSCD WINBIND GOGGLETYKE SAMBA ZARAFA_SERVER USERMIN POSTFIX WEBMIN);
use Yaffas::UGM;
use Yaffas::File;
use Yaffas::Constant;

require './forms.pl';

Yaffas::init_webmin();
ReadParse();
my $auth = $main::in{auth_srv};

header();

try
{
	Yaffas::Service::control(NSCD, STOP);
	Yaffas::Service::control(GOGGLETYKE, STOP);
	if(Yaffas::Service::control(WINBIND, START)) {
		# sleeping some time, so winbind can get all users
		sleep 7;
	}
	my $oldusers = undef; my $oldgroups = undef;
	if (Yaffas::Product::check_product("fax") || Yaffas::Product::check_product("pdf")) {
		$oldusers = Yaffas::Module::AuthSrv::get_sys_and_db_users();
		$oldgroups = Yaffas::Module::AuthSrv::get_sys_and_db_groups();
	}
	Yaffas::Module::AuthSrv::set_local_auth();

	my $ldap = 0;
	my $pdc  = 0;
	if ( defined $auth ) {
		if ( $auth =~ m/$main::text{lbl_this_auth_src_ldap}/ ) {
			$ldap = 1;
		}
		if ( $auth =~ m/$main::text{lbl_this_auth_src_pdc}/ ) {
			$pdc = 1;
		}
	}
	Yaffas::Module::AuthSrv::auth_srv_ldap(
		( $ldap ? 'activate' : 'deactivate' ) );
	Yaffas::Module::AuthSrv::auth_srv_pdc(
		( $pdc ? 'activate' : 'deactivate' ) );

	Yaffas::Module::AuthSrv::mod_nsswitch();
	if (Yaffas::Product::check_product("fax") || Yaffas::Product::check_product("pdf")) {
		my $all = undef;
		if (defined $main::in{'wipe_faxconf'}) {
			$all = "all";
		}
		Yaffas::Module::AuthSrv::clean_ug_data($oldusers,$oldgroups,$all);
	}
	Yaffas::Service::control(SAMBA, RESTART);
	if(Yaffas::Product::check_product("fax") || Yaffas::Product::check_product("pdf")) {
		Yaffas::UGM::set_print_operators_group("Print Operators");
	}
	Yaffas::Service::control(NSCD, START);
	Yaffas::Service::control(GOGGLETYKE, START);
	Yaffas::Service::control(SAMBA, RESTART);
	Yaffas::Service::control(ZARAFA_SERVER, RESTART) if Yaffas::Product::check_product("zarafa");
	Yaffas::Service::control(USERMIN, RESTART);
	Yaffas::Service::control(POSTFIX, RESTART);
	Yaffas::File->new(Yaffas::Constant::FILE->{auth_wizard_lock}, 1)->save();

	# fork, because we have to restart webmin
	my $pid = fork;
	if ($pid == 0) {
		# child
		try {
			Yaffas::Service::control(WEBMIN, RESTART);
		} catch Yaffas::Exception with {
			print Yaffas::UI::all_error_box(shift);
		};
	} else {
		# parent
		wait;
	}

	print Yaffas::UI::ok_box();
}
catch Yaffas::Exception with
{
	Yaffas::Service::control(NSCD, START);
	Yaffas::Service::control(GOGGLETYKE, START);
	print Yaffas::UI::all_error_box(shift);
	local_ldap();
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
