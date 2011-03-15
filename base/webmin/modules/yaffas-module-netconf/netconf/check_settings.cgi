#!/usr/bin/perl

use strict;
use warnings;

use Yaffas;
use Yaffas::UI;
use Yaffas::Exception;
use Yaffas::Module::Netconf;
use Error qw(:try);
use Data::Dumper;

use CGI::Carp qw(warningsToBrowser fatalsToBrowser);

require "forms.pl";

my $DEBUG = 0;

Yaffas::init_webmin();

ReadParse();

header();

my $mode = "save";

try {
	print $Cgi->pre(Dumper \%main::in) if ($DEBUG);

	foreach (keys %main::in) {
		if ($_ eq "new-ip") {
			virtual_card_form($main::in{'new-ip'});
			return;
		}
		elsif ($_ eq "delete-device") {
			delete_virtual_card_form($main::in{'delete-device'});
			return;
		}
	}

	if (defined($main::in{mode})) {
		$mode = $main::in{mode};
	}

	my $conf = Yaffas::Module::Netconf->new();

	if ($mode eq "new") {
		my $dev = $conf->add_virtual_device($main::in{device});
		my $exception = Yaffas::Exception->new();

		try {
			$dev->set_ip($main::in{"new-ipaddr"}, $main::in{"new-netmask"});
		} catch Yaffas::Exception with {
			$exception->append(shift);
		};

		try {
			$dev->set_gateway($main::in{"new-gateway"});
		} catch Yaffas::Exception with {
			$exception->append(shift);
		};

		try {
			$dev->set_dns([$main::in{"new-dns"}, $main::in{"new-dns-1"},$main::in{"new-dns-2"},]);
		} catch Yaffas::Exception with {
			$exception->append(shift);
		};

		try {
			$dev->set_search([$main::in{"new-search"}, $main::in{"new-search-1"},$main::in{"new-search-2"}]);
		} catch Yaffas::Exception with {
			$exception->append(shift);
		};

		throw $exception if $exception;
	}
	elsif ($mode eq "delete") {
		$conf->delete_virtual_device($main::in{device});
	}
	else {
		my %devs = map { /(.*?)-.*/; $1=>"" } grep {/-/} keys %main::in;

		my $exception = Yaffas::Exception->new();
		foreach my $dev (keys %devs) {
			try {
				$conf->device($dev)->enable($main::in{$dev."-enabled"});
			} catch Yaffas::Exception with {
				$exception->append(shift);
			};

			try {
				$conf->device($dev)->set_ip($main::in{$dev."-ipaddr"}, $main::in{$dev."-netmask"});
			} catch Yaffas::Exception with {
				$exception->append(shift);
			};

			try {
				$conf->device($dev)->set_gateway($main::in{$dev."-gateway"});
			} catch Yaffas::Exception with {
				$exception->append(shift);
			};

			try {
				$conf->device($dev)->set_dns([$main::in{$dev."-dns"}, $main::in{$dev."-dns-1"}, $main::in{$dev."-dns-2"}]);
			} catch Yaffas::Exception with {
				$exception->append(shift);
			};

			try {
				$conf->device($dev)->set_search([$main::in{$dev."-search"}, $main::in{$dev."-search-1"}, $main::in{$dev."-search-2"}]);
			} catch Yaffas::Exception with {
				$exception->append(shift);
			};
		}
		$conf->hostname($main::in{hostname});
		$conf->domainname($main::in{domain});
		$conf->workgroup($main::in{workgroup});


		print $Cgi->pre(Dumper $conf) if ($DEBUG);
		throw $exception if $exception;
	}

	print $Cgi->pre(Dumper $conf) if ($DEBUG);

	$conf->save();

	print Yaffas::UI::ok_box();
} catch Yaffas::Exception with {
	print Yaffas::UI::all_error_box(shift);
	if ($mode eq "new") {
		virtual_card_form();
	}
	else {
		net_conf_form();
	}
} otherwise {
	print Yaffas::UI::error_box(shift);
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
