#!/usr/bin/perl
use strict;
use warnings;
use Yaffas;
use Yaffas::Constant;
use Error qw(:try);
use Yaffas::Exception;

require './forms.pl';

Yaffas::init_webmin();
ReadParse();

my @loginnames = split /\0/, $main::in{loginnames};

header();

try {
	system(Yaffas::Constant::APPLICATION->{zarafa_admin},
		"--force-resync", @loginnames);
	if ($? != 0) {
		print Yaffas::UI::error_box(
			$main::text{'err_zarafa_admin_force_resync_failed'} . ' '. $?);
	} else {
		print Yaffas::UI::ok_box();
	}
} catch Yaffas::Exception with {
	print Yaffas::UI::all_error_box(shift);
} otherwise {
	print Yaffas::UI::error_box(shift);
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
