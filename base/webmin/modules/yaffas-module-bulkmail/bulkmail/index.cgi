#!/usr/bin/perl
use strict;
use warnings;
require './forms.pl';
use Yaffas;
use Yaffas::Check;
use Yaffas::Module::Bulkmail;


Yaffas::init_webmin();
header($main::text{'index_header'}, "");
ReadParse();

if( defined($main::in{from}) || defined($main::in{subject}) || defined($main::in{message}) ) {
	my $from = $main::in{'from'};
	my $subject = $main::in{'subject'};
	my $message = $main::in{'message'};

	if(Yaffas::Check::email($from) and ($subject && $message && $from)) {
		Yaffas::Module::Bulkmail::send_bulk_mail($from, $subject, $message);
		print Yaffas::UI::ok_box($main::text{lbl_send_success});
		footer("", $main::text{BBMODULEDESC});
	} else {
		print Yaffas::UI::error_box($main::text{err_error});
		show_dialog();
		footer();
	}
} else {
	show_dialog();
	footer();
}

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
