#!/usr/bin/perl -w
# import.cgi
# Import Signed Certificates and Keys
use strict;
use warnings;
require "./forms.pl";
use Yaffas;
use Error qw(:try);
use Yaffas::Exception;
use Yaffas::UI;

Yaffas::init_webmin();
header($main::text{'import_title'}, "");

if ( $ENV{'QUERY_STRING'}){
	try {
		ReadParseMime();
		show_import_ok_err();
		print Yaffas::UI::ok_box();
	} catch Yaffas::Exception with {
		print Yaffas::UI::all_error_box(shift);
		show_import();
	};
} else {
	ReadParse();
	show_import();
}

footer();

# ensure connection termination, even with keep-alive, to force the client
# to reconnect and use the new SSL certificate; our CGIs usually run
# in the webmin connection-specific process, and not in their own, that's
# why this works
exit 0;

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
