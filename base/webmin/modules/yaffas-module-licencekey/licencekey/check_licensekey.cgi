#!/usr/bin/perl

use strict;
use warnings;
use Error qw(:try);

use Yaffas;
use Yaffas::UI;
use Yaffas::Exception;
use Yaffas::Product;
use Yaffas::Module::FaxLicense;

use File::Temp ();

Yaffas::init_webmin();
header($main::text{'lbl_licensekey'}, "");
ReadParseMime();

my $tmpfile = File::Temp->new(TEMPLATE => "tempXXXXXX",
							  DIR => "/tmp/",
							  SUFFIX => ".license",
							 );
my $newlicense = $tmpfile->filename();

print $tmpfile $main::in{license};
close(OUTPUT);

try {
	my $product = Yaffas::Product::new_license($newlicense);

	if ($product eq "fax") {
		Yaffas::Module::FaxLicense::check_rm_unlicensed_controller();
	}

	print Yaffas::UI::ok_box();
} catch Yaffas::Exception with {
	print Yaffas::UI::all_error_box(shift);
} otherwise {
	print shift;
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
