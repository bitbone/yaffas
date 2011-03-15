#!/usr/bin/perl
# view.cgi
# Views certificates and keys in detail
use strict;
use warnings;

use Yaffas;
use Yaffas::UI qw($Cgi yn_confirm);
use Yaffas::Module::Certificate qw(delete_cert);

use Error qw(:try);
use Yaffas::Exception;

require "./forms.pl";

Yaffas::init_webmin();
ReadParse();
header();


my @del = split /\0/, $main::in{'del'};

	try {
		foreach (@del) {
			next if ($_ eq "default.crt");
			delete_cert($_);
		}

	} catch Yaffas::Exception with {
		my $e = shift;
		print Yaffas::UI::all_error_box($e);
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
