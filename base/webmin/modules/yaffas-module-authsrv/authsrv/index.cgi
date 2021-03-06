#!/usr/bin/perl
use strict;
use warnings;

use Yaffas;
use Yaffas::UI qw(yn_confirm error_box);
use Yaffas::Product;
use Yaffas::Exception;
use Error qw(:try);
use CGI::Carp qw(fatalsToBrowser warningsToBrowser);
use Yaffas::Constant;
use Yaffas::Auth::Type qw(:standard);

require './forms.pl';

Yaffas::init_webmin();
ReadParse();
my $method = $main::in{auth};

header();

if ( $main::in{auth} ) {
	if ( $method eq "ldap" ) {
		remote_ldap();
	}
	elsif ( $method eq "yaffas_ldap" ) {
		remote_ldap("yaffas");
	}
	elsif ( $method eq "local_auth" ) {
		local_ldap();
	}
	elsif ( $method eq "pdc" ) {
		if ( Yaffas::Product::check_product("zarafa") ) {
			print Yaffas::UI::error_box( $main::text{'err_with_zarafa'} );
		}
		else {
			pdc();
		}
	}
	elsif ( $method eq "ads" ) {
		ads();
	}
	elsif ( $method eq "files" ) {
		files();
	}
}
else {
	status();
	if ( Yaffas::Auth::get_auth_type() ne LOCAL_LDAP ) {
		if (Yaffas::Product::check_product("pdf") || Yaffas::Product::check_product("fax") || Yaffas::Product::check_product("file")) {
			printops_group();
		}
	}
	
	choose_auth();
}

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
