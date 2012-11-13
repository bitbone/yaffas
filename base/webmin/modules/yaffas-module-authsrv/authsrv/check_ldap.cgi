#!/usr/bin/perl

use strict;
use warnings;

use Yaffas;
use Yaffas::Module::AuthSrv;
use Yaffas::UI;
use Yaffas::Exception;
use Error qw(:try);
use CGI::Carp qw(fatalsToBrowser warningsToBrowser);
use Yaffas::Service qw(control START STOP RESTART NSCD WINBIND GOGGLETYKE SAMBA ZARAFA_SERVER USERMIN WEBMIN POSTFIX);
use Yaffas::UGM;
use Yaffas::Constant;

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
my $email = $main::in{email};
my $ldap_encryption = undef;
my $noencryption_confirmed = $main::in{'ldaps'};
my $sambasid = exists $main::in{'sambasid'} ? $main::in{'sambasid'} : undef;

header();

try {
	throw Yaffas::Exception("err_miss_host") unless $host;
	$host =~ s/^\s+//;
	my @hosts = split(/\s{0,}[;,\s\0]\s{0,}/, $host);
	my $test_ldaps = 0;
	foreach (@hosts) {
		if(Yaffas::Module::AuthSrv::test_ldaps($_)) {
			$test_ldaps += 1;
		}
	}
	if($test_ldaps >= scalar @hosts) {
		$ldap_encryption = 1;
	}

	if ((defined $ldap_encryption) || ($noencryption_confirmed eq "1")) {
		my $sambasids_available = {};
		foreach (@hosts) {
			my $available_sids = Yaffas::Module::AuthSrv::get_all_sambasid ($_, $basedn, $binddn, $bindpw, $ldap_encryption);
			my %tmp_sids = (%$sambasids_available, %$available_sids);
			$sambasids_available = \%tmp_sids;
		}
		my @tmp = keys %$sambasids_available;
		if ((not $sambasid) && scalar (@tmp) == 1) {
			$sambasid = $tmp[0];
		}

		if (defined $sambasid || not scalar (@tmp)) {
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
			Yaffas::Module::AuthSrv::set_bk_ldap_auth(\@hosts, $basedn, $binddn, $bindpw, $userdn, $groupdn, $usersearch, $email, $ldap_encryption, $sambasid);
			Yaffas::Module::AuthSrv::mod_nsswitch();
			if (Yaffas::Product::check_product("fax") || Yaffas::Product::check_product("pdf")) {
				my $all = undef;
				if (defined $main::in{'wipe_faxconf'}) {
					$all = "all";
				}
				Yaffas::Module::AuthSrv::clean_ug_data($oldusers,$oldgroups,$all);
				Yaffas::UGM::set_print_operators_group($printop_group);
			}
			Yaffas::Service::control(SAMBA, RESTART);
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
		} else {
			remote_ldap_confirm_sambasid ($sambasids_available);
		}
	}
	else {
		$main::in{'noencryption_confirmed'} = "yes";
		print Yaffas::UI::yn_confirm({
			-action => "check_ldap.cgi",
			-hidden => [%main::in],
			-title => $main::text{'lbl_title_woe'},
			-yes => $main::text{'lbl_yes'},
			-no => $main::text{'lbl_no'},
			},
			$main::text{'lbl_ldap_without_enc'}
		);
	}
}
catch Yaffas::Exception with
{
	Yaffas::Service::control(NSCD, START) unless Yaffas::Constant::OS =~ m/RHEL\d/ ;
	Yaffas::Service::control(GOGGLETYKE, START);
	print Yaffas::UI::all_error_box(shift);
	remote_ldap();
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
