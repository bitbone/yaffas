#!/usr/bin/perl

use strict;
use warnings;

use Yaffas;
use Yaffas::Service qw(control RELOAD ZARAFA_SERVER);
use Yaffas::Module::ZarafaConf;
use Yaffas::Exception;
use Error qw(:try);

Yaffas::init_webmin();
ReadParse();

header();

sub save_features() {
	my $features = Yaffas::Module::ZarafaConf::get_default_features();
	foreach my $feature (keys %{$features}) {
		Yaffas::Module::ZarafaConf::change_default_features(
			$feature,
			defined $main::in{"feature_$feature"} ? 1 : 0);
	}
}

sub save_attachment_size() {
	Yaffas::Module::ZarafaConf::attachment_size($main::in{attachment_size});
}

sub save_default_quota() {
	if (not defined $main::in{quota} or $main::in{quota} eq "") {
		Yaffas::Module::ZarafaConf::set_default_quota(-1);
	} elsif ($main::in{quota} =~ /^\d+$/) {
		Yaffas::Module::ZarafaConf::set_default_quota($main::in{quota});
	} else {
		throw Yaffas::Exception("err_value");
	}
}

sub save_userfilter() {
	if (not defined $main::in{filtertype} or
			not defined $main::in{filtergroup}) {
		return;
	}
	Yaffas::Module::ZarafaConf::zarafa_ldap_filter(
		$main::in{filtertype},
		$main::in{filtergroup}
	);
	control(ZARAFA_SERVER, RELOAD);
}

sub save_softdelete_lifetime_and_purge() {
	my $days = Yaffas::Module::ZarafaConf::softdelete_lifetime(
		$main::in{softdelete_lifetime});
	if (defined $main::in{enforce_softdelete_now}) {
		Yaffas::Module::ZarafaConf::purge_old_items($days);
	}
}

try {
	save_userfilter();
	save_features();
	save_attachment_size();
	save_default_quota();
	save_softdelete_lifetime_and_purge();
	print Yaffas::UI::ok_box();
}
catch Yaffas::Exception with {
	print Yaffas::UI::all_error_box(shift);
};


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
