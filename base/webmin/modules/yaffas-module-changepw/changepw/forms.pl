# file changepw-forms.pl
# for all my changepw forms

use strict;

use Yaffas::UI;
use Yaffas::Product;
use Yaffas::Constant;

sub change_admin_pass {
	my @ret;
	push @ret, $Cgi->start_form( {-action=>"check_adminpass.cgi",-method=>"post"} ); 
	push @ret, Yaffas::UI::section( $main::text{lbl_adminpass},
									$Cgi->table($Cgi->Tr(
														 [
														 $Cgi->td(
																   [
																   $main::text{lbl_pass},
																   $Cgi->password_field( {-name=>"pass1", -size=>30, -maxlength=>90} ),
																   ]),
														 $Cgi->td([
																  $main::text{lbl_pass2},
																  $Cgi->password_field( {-name=>"pass2", -size=>30, -maxlength=>90} )
																  ])
														 ]
														)
												)
			);
	push @ret, Yaffas::UI::section_button($Cgi->submit({-class=>"sbutton",-value=>$main::text{'lbl_save'}}));
	push @ret, $Cgi->end_form();
	return @ret;

}

sub change_root_pass {
	my @ret;
	push @ret, $Cgi->start_form( {-action=>"check_rootpass.cgi",-method=>"post"} ); 
	push @ret, Yaffas::UI::section( $main::text{lbl_rootpass},
									$Cgi->table($Cgi->Tr(
														 [
														 $Cgi->td(
																   [
																   $main::text{lbl_pass},
																   $Cgi->password_field( {-name=>"pass1", -size=>30, -maxlength=>90} ),
																   ]),
														 $Cgi->td([
																  $main::text{lbl_pass2},
																  $Cgi->password_field( {-name=>"pass2", -size=>30, -maxlength=>90} )
																  ])
														 ]
														)
											   )
								  );
	push @ret, Yaffas::UI::section_button($Cgi->submit({-class=>"sbutton",-value=>$main::text{lbl_save}}));
	push @ret, $Cgi->end_form();
	return @ret;
}

sub the_passwords {
	print change_admin_pass();
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
