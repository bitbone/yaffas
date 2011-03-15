#!/usr/bin/perl
# index.cgi

use strict;
use warnings;

use Yaffas;
use Yaffas::Module::Mailq;
use Yaffas::UI;
use Yaffas::Exception;
use Yaffas::Constant;
use Error qw(:try);

Yaffas::init_webmin();
ReadParse();

my $tmpid = $main::in{'mailid'};
my @mailids = ($tmpid ? sort split(/\0/, $tmpid) : ());
my $postsuper = Yaffas::Constant::APPLICATION->{postsuper};

header();

if (! scalar @mailids) {
	print Yaffas::UI::error_box($main::text{'err_nothingtodo'});
}
else {
	my $mailids = join (", ", @mailids);
	Yaffas::do_back_quote($postsuper, "-r", @mailids);
	if ($?) {
		print Yaffas::UI::error_box("$mailids: $main::text{'err_exim_dequeued'}");
	}
	else {
		print Yaffas::UI::ok_box("$mailids: $main::text{'suc_dequeued'}");
	}
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
