#!/usr/bin/perl -w
use strict;
use warnings;
use CGI::Carp qw(warningsToBrowser fatalsToBrowser);
use Yaffas;
use Yaffas::UI qw(ok_box all_error_box);
use Yaffas::Service;
use Yaffas::Module::Service;
use Yaffas::Exception;
use Error qw(:try);
require './forms.pl';

Yaffas::init_webmin();

header();

ReadParse();

my $service = $main::in{service};
my $value   = $main::in{value};
my %services;

try {
	my $installed_services = Yaffas::Service::installed_services();

	if ($value) {
		print "adding to runlevel";
		Yaffas::Service::add_to_runlevel(
			$installed_services->{$service}->{'constant'} );
	}
	else {
		print "removing from runlevel";
		Yaffas::Service::rm_from_runlevel(
			$installed_services->{$service}->{'constant'} );
	}
	Yaffas::Service::control(Yaffas::Service::GOGGLETYKE(), Yaffas::Service::RESTART());
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
