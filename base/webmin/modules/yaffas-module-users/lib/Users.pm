#! /usr/bin/perl
# file bbnetauth-mylib.pl
# lib that can be called also from external scripts
package Yaffas::Module::Users;
use strict;
use warnings;
use File::Samba;
use Yaffas::Check;
use Yaffas::Constant;
use Yaffas::Conf;
use Yaffas::Conf::Function;
use Yaffas::Auth;
use Yaffas::Auth::Type qw(:standard);
use Yaffas::LDAP;
use Yaffas::Service qw/HYLAFAX RESTART SAMBA/;
use Yaffas::Product;
use Yaffas::Exception;
use Error qw(:try);
use Encode;
use Yaffas::UGM qw(get_users get_suppl_groupnames);

our @ISA = qw(Yaffas::Module);

our $ADDITIONAL_VALUES = {
    "businessphone" => "telephoneNumber",
    "faxnumber" => "facsimileTelephoneNumber",
    "location" => "physicalDeliveryOfficeName",
    "department" => "departmentNumber"
};

sub conf_dump() {
}

sub get_zarafa_admin($) {
	my $login = shift;
	if (Yaffas::Auth::get_auth_type() eq LOCAL_LDAP()) {
		return (Yaffas::LDAP::search_entry("uid=$login", "zarafaAdmin"))[0];
	}
	else {
		# FIXME: dirty evil solution
		# Yaffas::LDAP should really be fixed, so it can handle also ADS and REMOTE_LDAP
		return `/usr/bin/zarafa-admin --details $login | awk -F: '/^Administrator/{ ORS=""; gsub(/[[:space:]]*/, "", \$2); print \$2; }'` eq "yes";
	}
}

sub set_zarafa_admin($$) {
	my $login = shift;
	my $activate = shift;
	my $ret;

	if ($activate) {
		$ret = Yaffas::LDAP::replace_entry($login, "zarafaAdmin", 1);
		throw Yaffas::Exception("err_ldap_save", $ret) if ($ret);
	} else {
		$ret = Yaffas::LDAP::replace_entry($login, "zarafaAdmin", 0);
		throw Yaffas::Exception("err_ldap_save", $ret) if ($ret);
	}
	return 1;
}

sub get_zarafa_shared($) {
	my $login = shift;
	return (Yaffas::LDAP::search_entry("uid=$login", "zarafaSharedStoreOnly"))[0];
}

sub set_zarafa_shared($$) {
	my $login = shift;
	my $activate = shift;
	my $ret;

	if ($activate) {
		$ret = Yaffas::LDAP::replace_entry($login, "zarafaSharedStoreOnly", 1);
		throw Yaffas::Exception("err_ldap_save", $ret) if ($ret);
	} else {
		$ret = Yaffas::LDAP::replace_entry($login, "zarafaSharedStoreOnly", 0);
		throw Yaffas::Exception("err_ldap_save", $ret) if ($ret);
	}
	return 1;
}

sub check_reasonable_mail($$@) {
	#$email is reference!
	my ($user, $email, @aliases) = @_;
	my $e = new Yaffas::Exception();
	if ($$email) {
		Yaffas::Check::email($$email) or $e->add("err_email");
		$e && $e->throw ();

		if(Yaffas::Product::check_product('zarafa')) {
			$$email =~ /^(.*)@(.*)$/;
			my $localpart = $1;
			my $domain = $2;
			my @domains;
			if(Yaffas::Constant::OS eq 'RHEL5') {
				push @domains, $domain;
			}
			else {
				require Yaffas::Module::Mailsrv;
				@domains = Yaffas::Module::Mailsrv::get_accept_domains();
			}
			if(defined(Yaffas::Check::is_localhost($domain))) {
				$e->add("err_mail_loc_host");
			}
			elsif( (scalar @domains < 1) or ( ! grep (/^$domain$/, @domains ))){
				$e->add("err_unknown_domain",$domain);
			}
			if( ($localpart ne $user) && (! grep(/^$localpart$/, @aliases)) ){
				$e->add('err_missing_alias',$localpart);
			}
		}
	}
	else {
		if(Yaffas::Product::check_product('zarafa')) {
			$e->add("err_no_email");
		}
		else {
			$$email = $user . '@localhost';
		}
	}

	throw $e if $e;
}

#check if store for given user was created
sub check_zarafa_store($) {
	my $username = shift;
	my $out = Yaffas::do_back_quote(Yaffas::Constant::APPLICATION->{'zarafa_admin'},"--details",$username);
	if ($out eq "") {
		throw Yaffas::Exception("err_create_store")
	}
	return 1;
}

sub get_zarafa_stores(){
	my @stores;
	if (Yaffas::Product::check_product('zarafa')) {
		my @out = Yaffas::do_back_quote(Yaffas::Constant::APPLICATION->{'zarafa_admin'},"-l");
		my $body = 0;
		foreach my $line (@out) {
			if($body) {
				if ($line =~ m/^\s+([^\s]+)\s*/ && $body) {
					my $val = $1;
					Encode::from_to($val, "iso-8859-15", "utf-8");
					push @stores, $val;
				}
			} else {
				if ($line =~ m/^\s+-+$/) {
					# end of header
					$body = 1;
				}
			}
		}
	}
	return @stores;
}

sub get_default_features() {
	my $f = Yaffas::File::Config->new(Yaffas::Constant::FILE->{zarafa_server_cfg},
		{
			-SplitPolicy => 'custom',
			-SplitDelimiter => '\s*=\s*'
		}
	);

	my $values = $f->get_cfg_values();

	my %ret;

	if (exists $values->{disabled_features}) {
		%ret = ("imap" => "on", "pop3" => "on");
		foreach my $v (split /\s+/, $values->{disabled_features}) {
			$ret{$v} = "off";
		}
	}
	else {
		%ret = ("imap" => "off", "pop3" => "off");
	}

	return \%ret;
}

sub get_features($) {
	my $uid = shift;

	my @enabled = Yaffas::LDAP::search_entry("uidNumber=$uid", "zarafaEnabledFeatures");
	my @disabled = Yaffas::LDAP::search_entry("uidNumber=$uid", "zarafaDisabledFeatures");

	my %ret = ("imap" => "default", "pop3" => "default");

	foreach my $v (@enabled) {
		$ret{$v} = "on";
	}
	foreach my $v (@disabled) {
		$ret{$v} = "off";
	}

	return \%ret;
}

sub set_features($$) {
	my $user = shift;
	my $features = shift;

	my @enabled;
	my @disabled;

	foreach my $v (keys %{$features}) {
		if ($features->{$v} eq "on") {
			push @enabled, $v;
		}
		elsif ($features->{$v} eq "off") {
			push @disabled, $v;
		}
	}

	Yaffas::LDAP::replace_entries($user, [replace => ["zarafaEnabledFeatures" => \@enabled]]);
	Yaffas::LDAP::replace_entries($user, [replace => ["zarafaDisabledFeatures" => \@disabled]]);

	system(Yaffas::Constant::APPLICATION->{zarafa_admin}, "--sync");
}

return 1;
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
