#!/usr/bin/perl -w
package Yaffas::Module::License;

use warnings;
use strict;

sub BEGIN {
	use Exporter;
	our @ISA = qw(Exporter Yaffas::Module);
	our @EXPORT_OK = qw(get_key_info);
}

use Yaffas::Product;

=pod

=head1 NAME

Yaffas::Module::License

=head1 DESCRIPTION

This Modules provides functions for the licensekey module

=head1 FUNCTIONS

=over

=item get_key_info ( PRODUCT )

Returns all infos from key for PRODUCT

=cut

sub get_key_info($) {
	my $product = shift;
	my %key;

	throw Yaffas::Exception("err_product") unless Yaffas::Product::check_product($product);

	if (Yaffas::Product::get_license_info($product, "test") == 1
		&& ! Yaffas::Product::get_license_info($product, "initial")) {

		$key{c_name} = Yaffas::Product::get_license_info($product, "customer_name");
		$key{c_address} = Yaffas::Product::get_license_info($product, "customer_adress");
		$key{c_plz} = Yaffas::Product::get_license_info($product, "customer_plz");
		$key{c_city} = Yaffas::Product::get_license_info($product, "customer_city");
		$key{c_country} = Yaffas::Product::get_license_info($product, "customer_country");

		$key{valid_from_year} = Yaffas::Product::get_license_info($product, "valid_year_from");
		$key{valid_from_year} =~ s/\s+$//;

		$key{valid_from_month} = Yaffas::Product::get_license_info($product, "valid_month_from");
		$key{valid_from_month} =~ s/\s+$//;

		$key{valid_from_day} = Yaffas::Product::get_license_info($product, "valid_day_from");
		$key{valid_from_day} =~ s/\s+$//;

		$key{valid_to_year} = Yaffas::Product::get_license_info($product, "valid_year_to");
		$key{valid_to_year} =~ s/\s+$//;

		$key{valid_to_month} = Yaffas::Product::get_license_info($product, "valid_month_to");
		$key{valid_to_month} =~ s/\s+$//;

		$key{valid_to_day} = Yaffas::Product::get_license_info($product, "valid_day_to");
		$key{valid_to_day} =~ s/\s+$//;

		$key{permanent} = Yaffas::Product::get_license_info($product, "valid_permanent");
		$key{permanent} =~ s/\s+$//;

		$key{unl_msn} = Yaffas::Product::get_license_info($product, "unlimited_in_msn");
		$key{lfdnr} = Yaffas::Product::get_license_info($product, "lfdnr");
		$key{max_ctrl} = Yaffas::Product::get_license_info($product, "i_ab");
		$key{product} = Yaffas::Product::get_license_info($product, "c_aa");
		$key{printernr} = Yaffas::Product::get_license_info($product, "printernr");
		$key{encryption} = Yaffas::Product::get_license_info($product, "encryption");
		$key{notepaper} = Yaffas::Product::get_license_info($product, "notepaper");
		$key{merge} = Yaffas::Product::get_license_info($product, "i_ba");
		if (Yaffas::Product::get_license_info($product, "i_aa") == -1)
		{
			$key{licencetype} = Yaffas::Product::get_license_info($product, "i_ad");
		}
		else
		{
			if (Yaffas::Product::get_license_info($product, "i_aa") == 1)
			{
				$key{licencetype} = 0;
			}
			else
			{
				$key{licencetype} = 10;
			}
		}
	} else {
		throw Yaffas::Exception("err_key_test");
	}
	return %key;
}

sub conf_dump() {
    1;
}

1;

=back

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
