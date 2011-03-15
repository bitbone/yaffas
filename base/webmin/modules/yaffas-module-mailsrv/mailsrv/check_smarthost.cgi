#! /usr/bin/perl -w

use strict;
use warnings;
use Yaffas;
use Yaffas::Module::Mailsrv::Postfix qw(set_smarthost rm_smarthost set_smarthost_routing);
use Yaffas::Service qw(POSTFIX RESTART control);
use Yaffas::UI;
use Yaffas::Exception;

use CGI::Carp qw(fatalsToBrowser warningsToBrowser);
use Error qw(:try);

require "./forms.pl";

Yaffas::init_webmin();
ReadParse();

header($main::text{'index_header'}, "");

my $smarthost = $main::in{'smarthost'};
my $username = $main::in{'username'};
my $pass = $main::in{'password'};
my $old_smarthost = $main::in{'old_smarthost'};
my $route_all = $main::in{route_all};
my $rewrite_domain = $main::in{rewrite_domain};

try {
	throw Yaffas::Exception('err_no_entrys') unless (defined $smarthost and defined $username);

	if ($smarthost) {
		## add mode
		set_smarthost($smarthost, $username, ($pass? $pass : ""));
		if (defined($main::in{route_all})) {
			# enable BBroute_all
			set_smarthost_routing($route_all, $rewrite_domain);
		} else {
			# disable BBroute_all
			set_smarthost_routing(0, undef);
		}
	} else {
		## del mode
		rm_smarthost($old_smarthost);
		# also disable BBroute_all
		set_smarthost_routing(0, undef);
	}
	control(POSTFIX() ,RESTART());
	print Yaffas::UI::ok_box();
} catch Yaffas::Exception with {
	print Yaffas::UI::all_error_box(shift);
	smarthost_form();
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
