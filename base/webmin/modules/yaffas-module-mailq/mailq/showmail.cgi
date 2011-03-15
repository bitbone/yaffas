#!/usr/bin/perl
# showmail.Cgi

use strict;
use warnings;

use CGI;
use CGI::Carp qw(fatalsToBrowser);
use Yaffas;
use Yaffas::UI;
use Yaffas::File;
use Yaffas::Constant;

my $pfcat = Yaffas::Constant::APPLICATION->{pfcat};

Yaffas::init_webmin();
ReadParse();

header();

my @mails = split /\0/, $main::in{mailid};

foreach my $mailid (@mails) {
    print Yaffas::UI::start_section($main::text{lbl_show}.": ".$mailid);
	if ($mailid =~ /\.\./) {
		print"Wrong file!!<br>\n";
	}
	else {
		foreach (Yaffas::do_back_quote($pfcat, "$mailid")) {
			$_ = CGI::escapeHTML ($_);
			print "$_", $Cgi->br, "\n";
		}
	}
	print Yaffas::UI::end_section();
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
