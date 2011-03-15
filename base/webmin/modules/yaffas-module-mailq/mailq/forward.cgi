#!/usr/bin/perl
# send_custom.cgi

use strict;
use warnings;

use Yaffas;
use Yaffas::Module::Mailq;
use Yaffas::UI;
use Yaffas::Check;
use Yaffas::Exception;
use Error qw(:try);
use CGI::Carp qw(fatalsToBrowser warningsToBrowser);

Yaffas::init_webmin();
ReadParse();


my @mailids = sort split(/\0/, $main::in{'mailid'});
my $email = $main::in{'mail'};
my $page = $main::in{'page'};

header($main::text{'lbl_index_header'}, "");

if (Yaffas::Check::email($email)) {
	try	{
		Yaffas::Module::Mailq::forward_mail($email, @mailids);
		print Yaffas::UI::ok_box();
	}
	catch Yaffas::Exception with {
		print Yaffas::UI::all_error_box(shift);
	};
}
else {
	print Yaffas::UI::error_box($main::text{'err_no_good_mail'});
}

footer("index.cgi?page=$page", $main::text{BBMODULEDESC});

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
