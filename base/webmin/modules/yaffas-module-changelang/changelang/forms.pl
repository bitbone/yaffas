# file changelang-forms.pl
# for all my changepw forms

use strict;
use warnings;
use Yaffas::UI;

sub select_lang {
	my $lang = shift;

	$lang = "en" unless (defined($lang));

	print $Cgi->start_form({-action=>"check_lang.cgi", -method=>"post"});
	print Yaffas::UI::section(($main::text{lbl_choose_lang}),
			$Cgi->div(
				$Cgi->radio_group({
					-name=>"lang", 
					-values=>["de", "en"], 
					-labels=>{
						de=>$main::text{lbl_deutsch}, 
						en=>$main::text{lbl_english}
					},
					-linebreak=>"true",
					-default=>$lang
				}
				)
			)
		);
	print $Cgi->submit({-class=>"sbutton", -name=>$main::text{lbl_save}});
	print $Cgi->end_form();
}

1;
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
