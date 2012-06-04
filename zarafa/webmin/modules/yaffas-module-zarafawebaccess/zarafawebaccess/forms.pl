#!/usr/bin/perl -w

use strict;
use warnings;

use Yaffas::UI qw/textfield/;
use Yaffas::Auth::Type qw(:standard);
use Yaffas::Mail;
use Yaffas::Module::ZarafaWebaccess qw(get_theme_color get_color_labels);

sub show_options() {
	print Yaffas::UI::section($main::text{lbl_webaccess_options},
		$Cgi->div({-id=>"options"}, "")
	);

}

sub show_theme_color() {
	my $color_labels = get_color_labels();
	my $colors = map {$_ => $main::text{$color_labels->{$_}}} keys %{$color_labels};
	print $Cgi->start_form({-action => "theme_color.cgi"});
	print Yaffas::UI::section($main::text{lbl_theme_color}, 
		$Cgi->p(
			$Cgi->table(
				$Cgi->Tr([
						$main::text{lbl_theme_color}.": ",
						$Cgi->scrolling_list(-name => 'theme_color',
							-values => [keys %{$color_labels}],
							-labels => $colors,
							-default => get_theme_color(),
							-size => 1),
					])
			)
		)
	);
	print Yaffas::UI::section_button($Cgi->submit({-name=>"savecolor", -value=>$main::text{'lbl_save'}}));
	print $Cgi->end_form();
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
