#!/usr/bin/perl
# setproxy.cgi

use strict;
use warnings;
use CGI::Carp qw(fatalsToBrowser warningsToBrowser);
use Error qw(:try);
use Yaffas;
use Yaffas::UI;
use Yaffas::Exception;
use Yaffas::Module::Proxy;
require './forms.pl';

Yaffas::init_webmin;
ReadParse();

my $proxy = $main::in{'proxy'};
my $port = $main::in{'port'};
my $user = $main::in{'user'};
my $pass = $main::in{'pass'};

header();

try {
	Yaffas::Module::Proxy::set_proxy($user, $pass, $proxy, $port);
	print Yaffas::UI::ok_box();
} catch Yaffas::Exception with {
	print Yaffas::UI::all_error_box (shift);

	show_proxy($user, $pass, $proxy, $port);
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
