#!/usr/bin/perl -w

use strict;
use warnings;

use Error qw(:try);
use Yaffas;
use Yaffas::Product;
use Yaffas::Module::Setup;
use Yaffas::Module::ChangePW;
use Yaffas::UGM;
use Yaffas::Service qw(NSCD GOGGLETYKE WINBIND WEBMIN STOP START RESTART SAMBA ZARAFA_SERVER POSTFIX USERMIN);
use Yaffas::Module::Mailsrv::Postfix qw(set_accept_domains set_smarthost);

Yaffas::init_webmin();

ReadParse();

header();

try {
	my $pw1 = $main::in{admin_password1};
	my $pw2 = $main::in{admin_password2};

	throw Yaffas::Exception("err_password") unless ($pw1 eq $pw2 and length($pw1) > 0);
	throw Yaffas::Exception("err_domainname") unless (Yaffas::Check::domainname($main::in{mailserver_domain}));

	Yaffas::Module::ChangePW::change_admin_password($pw1);

	if (Yaffas::Product::check_product("zarafa")) {
		eval "use Yaffas::Module::ZarafaConf;";
		Yaffas::Module::ZarafaConf::set_zarafa_database($main::in{mysql_host}, $main::in{mysql_database}, $main::in{mysql_user}, $main::in{mysql_password});
	}

	if ($main::in{mailserver_domain}) {
		set_accept_domains($main::in{mailserver_domain});
	}

	if ($main::in{mailserver_smarthost}) {
		set_smarthost($main::in{mailserver_smarthost}, $main::in{mailserver_smarthost_user}, $main::in{mailserver_smarthost_password})
	}

	if ($main::in{user_login}) {
		_set_local_auth();

		Yaffas::UGM::add_user($main::in{user_login}, $main::in{user_email}, $main::in{user_firstname}, $main::in{user_surname});
		Yaffas::UGM::password($main::in{user_login}, $main::in{user_password});
	}

	Yaffas::Module::Setup::hide();
}
catch Yaffas::Exception with {
	print Yaffas::UI::all_error_box(shift);
};

footer();

sub _set_local_auth {
	# copied code from /authsrv/check_local_ldap.cgi
	try {
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

		Yaffas::Module::AuthSrv::auth_srv_ldap( ( $ldap ? 'activate' : 'deactivate' ) );
		Yaffas::Module::AuthSrv::auth_srv_pdc( ( $pdc ? 'activate' : 'deactivate' ) );

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
		system(Yaffas::Constant::APPLICATION->{zarafa_admin}, "-s");
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
