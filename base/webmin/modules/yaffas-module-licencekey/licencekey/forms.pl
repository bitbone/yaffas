# file licensekey-forms.pl
# for all my licensekey forms

use strict;
use warnings;

use Yaffas::Module::License qw(get_key_info);
use Yaffas::Product;
use Yaffas::UI;
use Yaffas::Exception;
use Error qw(:try);

sub licensekey_upload() {
	print $Cgi->start_multipart_form({-action=>"check_licensekey.cgi"});
	print Yaffas::UI::section( $main::text{'lbl_licensekey'},
					$Cgi->filefield('license')
					);
	print Yaffas::UI::section_button($Cgi->submit({-value=>$main::text{'lbl_insert'}}));
	print $Cgi->end_form();
}

sub licensekey_installed() {
	$Yaffas::UI::Print_inner_div = 0;
	print Yaffas::UI::start_section($main::text{lbl_installed_keys});
	my $one_key = 0;

	foreach my $product (Yaffas::Product::get_all_installed_products()) {
		my %key;
		try {
			_print_key_info(get_key_info($product));
			$one_key = 1;
		} catch Yaffas::Exception with {
		};
	}

	unless($one_key) {
		print $Cgi->div($main::text{err_no_key});
	}

	print Yaffas::UI::end_section();
}

sub _print_key_info(%) {
	my %key = @_;
	print $Cgi->h2($main::text{"lbl_product_".$key{product}});

	print Yaffas::UI::table($Cgi->Tr(
									 $Cgi->td({style=>"width: 30%"},
											  $main::text{lbl_customer}.":",
											 ),
									 $Cgi->td({style=>"width: 70%"},
											  $key{c_name}.$Cgi->br(),
											  $key{c_address}.$Cgi->br(),
											  $key{c_plz}." ".$key{c_city}.$Cgi->br(),
											  $key{c_country}.$Cgi->br()
											 ),
									),
							$Cgi->Tr(
									 $Cgi->td(
											  [
											  $main::text{lbl_licensetype}.":",
											  $main::text{"lbl_licensetype_".$key{licencetype}}
											  ]
											  )
									 ),
							$Cgi->Tr(
									 [
									 $key{permanent} ne 1 ?
									 $Cgi->td(
											  [
											  $main::text{lbl_valid_from}.":",
											  $key{valid_from_day}.".".$key{valid_from_month}.".".$key{valid_from_year}
											  ]
											 )
									 : # else
									 "",
									 $Cgi->td(
											  [
											  $main::text{lbl_valid_to}.":",
											  $key{permanent} ne 1 ?
											  $key{valid_to_day}.".".$key{valid_to_month}.".".$key{valid_to_year}
											  : # else
											  $main::text{lbl_unlimited}
											  ]
											 ),
									 ($key{product} eq "fax") ?
									 $Cgi->td(
											  [
											  $main::text{lbl_incmsns}.":",
											  $key{licencetype} == 0 ? $main::text{lbl_unl_in_msn} : $key{licencetype}
											  ]
											 )
									 : # else
									 "",
									 ($key{product} eq "fax") ?
									 $Cgi->td(
											  [
											  $main::text{lbl_anz_cont}.":",
											  $key{max_ctrl}
											  ]
											 )
									 : # else
									 "",
									($key{product} eq "pdf") ?
									($Cgi->td(
											  [
											  $main::text{lbl_printernr}.":",
											  ($key{printernr} == 0 ? $main::text{lbl_unlimited} : $key{printernr})
											  ]
											 ),
									$Cgi->td(
											  [
											  $main::text{lbl_encryption}.":",
											  $key{encryption} > 0 ? $main::text{lbl_enabled} : $main::text{lbl_disabled}
											  ]
											 ),
									$Cgi->td(
											  [
											  $main::text{lbl_notepaper}.":",
											  $key{notepaper} > 0 ? $main::text{lbl_enabled} : $main::text{lbl_disabled}
											  ]
											 ),
									$Cgi->td(
											  [
											  $main::text{lbl_merge}.":",
											  $key{merge} > 0 ? $main::text{lbl_enabled} : $main::text{lbl_disabled}
											  ]
											 )
)
									: # else
									"",
									]
									)
	)

}

return 1;

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
