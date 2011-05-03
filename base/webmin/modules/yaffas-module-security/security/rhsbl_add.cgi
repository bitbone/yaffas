#!/usr/bin/perl
use strict;
use warnings;
use Yaffas;
use Yaffas::Module::Security;
use CGI::Carp qw(warningsToBrowser fatalsToBrowser);
use Yaffas::UI qw(ok_box all_error_box);
use Yaffas::Exception;
use Error qw(:try);

Yaffas::init_webmin();

header();
ReadParse();

my $host	= $main::in{'rhsbl_host'};	throw Yaffas::Execption('No value set for host') unless defined $host;
my $hit		= $main::in{'rhsbl_hit'};	throw Yaffas::Execption('No value set for hit')  unless defined $hit;
my $miss	= $main::in{'rhsbl_miss'};	throw Yaffas::Execption('No value set for miss') unless defined $miss;
my $log		= $main::in{'rhsbl_log'};	throw Yaffas::Execption('No value set for log')  unless defined $log;

try {
	Yaffas::Module::Security::policy_rhsbl($host, $hit, $miss, $log);
	print Yaffas::UI::ok_box();
}
catch Yaffas::Exception with {
	print Yaffas::UI::all_error_box(shift);
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
