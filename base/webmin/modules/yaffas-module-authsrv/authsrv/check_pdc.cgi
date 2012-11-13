#!/usr/bin/perl -w
use strict;
use warnings;

use Yaffas;
use Yaffas::UI qw(ok_box error_box all_error_box);
use CGI::Carp qw(fatalsToBrowser warningsToBrowser);
use Yaffas::Exception;
use Yaffas::Module::AuthSrv;
use Yaffas::Service qw(control START STOP RESTART NSCD WINBIND GOGGLETYKE SAMBA ZARAFA_SERVER USERMIN WEBMIN POSTFIX);
use Error qw(:try);
use Yaffas::UGM;
use Yaffas::Constant;

require "./forms.pl";

Yaffas::init_webmin();
ReadParse();
header();

# switch to pdc
my $pdc = $main::in{'pass_pdc'};
my $dom_name = $main::in{dom_name};
my $dom_adm = $main::in{dom_adm};
my $dom_pass1 = $main::in{dom_pass1};
my $printop_group = $main::in{printop_group};
my $type = $main::in{'pdc_type'};
try {
	Yaffas::Service::control(NSCD, STOP) unless Yaffas::Constant::OS =~ m/RHEL\d/ ;
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
	my @pdcs = split(/\s{0,}[;,\s]\s{0,}/, $pdc);
	Yaffas::Module::AuthSrv::set_pdc( \@pdcs, $dom_name, $dom_adm, $dom_pass1, "samba", );
	Yaffas::Module::AuthSrv::mod_nsswitch();

	Yaffas::Service::control(SAMBA, RESTART);
	Yaffas::Service::control(WINBIND, RESTART);

	sleep 7;

	if (Yaffas::Product::check_product("fax") || Yaffas::Product::check_product("pdf")) {
		my $all = undef;
		if (defined $main::in{'wipe_faxconf'}) {
			$all = "all";
		}
		Yaffas::Module::AuthSrv::clean_ug_data($oldusers,$oldgroups,$all);
		Yaffas::UGM::set_print_operators_group($printop_group, $dom_adm, $dom_pass1);
	}

	Yaffas::Service::control(NSCD, START) unless Yaffas::Constant::OS =~ m/RHEL\d/ ;
	Yaffas::Service::control(GOGGLETYKE, START);
	Yaffas::Service::control(SAMBA, RESTART);
	Yaffas::Service::control(ZARAFA_SERVER, RESTART) if Yaffas::Product::check_product("zarafa");
	system(Yaffas::Constant::APPLICATION->{zarafa_admin}, "-s");
	Yaffas::Service::control(USERMIN, RESTART);
	Yaffas::Service::control(POSTFIX, RESTART);
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
catch Yaffas::Exception with {
	Yaffas::Service::control(NSCD, START) unless Yaffas::Constant::OS =~ m/RHEL\d/ ;
	Yaffas::Service::control(GOGGLETYKE, START);
	print Yaffas::UI::all_error_box(shift);
	pdc();

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
