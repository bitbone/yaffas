#!/usr/bin/perl -w
use strict;
use warnings;
use CGI::Carp qw(warningsToBrowser fatalsToBrowser);
use Yaffas;
use Yaffas::UI qw(ok_box all_error_box);
use Yaffas::Service qw(/.+/);
use Yaffas::Module::Service;
use Yaffas::Exception;
use Error qw(:try);
require './forms.pl';

Yaffas::init_webmin();

header();

ReadParse();

my $service = $main::in{service};
my $action  = $main::in{action};
my %services;

try {
	my $installed_services = Yaffas::Service::installed_services();

	my $bke = Yaffas::Exception->new();
	$SIG{TERM} = 'IGNORE'
	  ; # if webmin will be restartet pls let us work and give at OK msg to the user.

	## start / stop / restart services
	unless ( $action eq "empty" ) {
		if ( grep { $_ eq $action }
			@{ $installed_services->{$service}->{'allow'} } )
		{
			my $action_method;

			$action_method = RESTART() if ( $action eq "restart" );
			$action_method = START()   if ( $action eq "start" );
			$action_method = STOP()    if ( $action eq "stop" );

			unless (
				control(
					$installed_services->{$service}->{'constant'},
					$action_method
				)
			  )
			{
				my $msg = $Yaffas::Service::Message;
				$msg =~ s/\n/<br \/>/g;
				$bke->add( "err_" . $services{$service}->{action},
					$service . ": " . $msg );
			}
			else {
				sleep(2);
			}
		}
		else {
			## method not allowed
			$bke->add(
				"err_" . $services{$service}->{action},
				$service . ": "
				  . $main::text{ "dis_" . $services{$service}->{action} }
			);
		}
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
