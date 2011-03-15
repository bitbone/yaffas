#!/usr/bin/perl

use Yaffas;
use Yaffas::UI;
use Yaffas::Module::ZarafaLicence;
use CGI::Carp qw(warningsToBrowser fatalsToBrowser);
use Yaffas::Exception;
use Error qw(:try);

Yaffas::init_webmin();

require './forms.pl';

use CGI::Carp qw(fatalsToBrowser);
use strict;
use warnings;

ReadParse();

header();

try {
	if ( $main::in{quota} eq "yesquota" ) {
		if ( $main::in{limit} =~ /\d+/ ) {
			Yaffas::Module::ZarafaConf::set_default_quota( $main::in{limit} );
			print Yaffas::UI::ok_box();
		}
	}
	elsif ( $main::in{quota} eq "noquota" ) {
		$main::in{limit} = -1;
		Yaffas::Module::ZarafaConf::set_default_quota( $mail::in{limit} );
		print Yaffas::UI::ok_box();
	}
	else {
		throw Yaffas::Exception("err_value");
	}
}
catch Yaffas::Exception with {
	print Yaffas::UI::all_error_box(shift);
	defaultquota_form();
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
