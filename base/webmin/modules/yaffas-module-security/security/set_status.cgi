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

my $service = $main::in{service};
my $action  = $main::in{status};

try {
	throw Yaffas::Exception("Undefined service") unless defined $service;
	throw Yaffas::Exception("Undefined state") unless defined $action;
	throw Yaffas::Exception("Undefined state") if $action !~ m#^[01]+\z#;

	if($service eq 'policy'){
		if($action == 1){ 
			Yaffas::Module::Security::enable_policy();
		} else {
			Yaffas::Module::Security::disable_policy();
		}
	} elsif($service eq 'spam'){
		if($action == 1){
			Yaffas::Module::Security::enable_spamassassin();
		} else {
			Yaffas::Module::Security::disable_spamassassin();
		}
	} elsif($service eq 'antivirus'){
		if($action == 1){
			Yaffas::Module::Security::enable_clamav();
		} else {
			Yaffas::Module::Security::disable_clamav();
		}
	} else {
		throw Yaffas::Exception("Unknown service");
	}

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
