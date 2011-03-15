#!/usr/bin/perl
use warnings;
use strict;

use CGI::Carp qw(fatalsToBrowser warningsToBrowser);
use Yaffas::Mail::Mailalias qw(list_alias);
use Yaffas::UI::TablePaging qw(show_page);
use Yaffas::UI qw($Cgi section section_button table);
use Yaffas::Constant;
use Text::Iconv;

# mailaliases
sub mailaliases {
	print section($main::text{lbl_mailalias},
		$Cgi->div({-id=>"table"}, ""),
		$Cgi->div({-id=>"menu"}, ""),
	);
	return;
}

sub edit_alias {
	_display_alias_edit_begin();
	_display_alias_edit(@_);
	_display_alias_edit_end();
}

sub new_alias {
	_display_alias_for_begin();
	_display_alias_for(@_);
	_display_alias_for_end();
}

sub _display_alias_for_begin(){
	print $Cgi->start_form(
						   -method=>'post',
						   -action=>"add.cgi",
						  );
}

sub _display_alias_for_end(){
	print $Cgi->div({-class=>"sbutton"},
					[
					 $Cgi->submit(-value => $main::text{save})
					]
				   );
	print $Cgi->end_form();
}

# FROM, TO, SELECTED_FOLDERS, SECTION HEADER, DO_EDIT

sub _display_alias_for {
	my $from = shift;
	my $to = shift;
	my $selected_folder_alias = shift;
	$selected_folder_alias = [] unless ref $selected_folder_alias;

	my $section_header = shift || $main::text{lbl_addalias};

	my $edit = shift;

	my @folder_alias = ();
	if (Yaffas::Product::check_product('mail') and not Yaffas::Product::check_product("zarafa")) {
		my $sf = Yaffas::Constant::MISC()->{sharedfolder};
		## alle folder die mit "shared folder" beginnen aber nicht der virtuelle "shared folder" selbst.
		@folder_alias = grep {$_} map {
			if ($_ ne $sf and index($_, $sf) == 0) {
				s/^$sf\///;
				$_
			}else {
				undef;
			}
		} Yaffas::Mail::get_mailboxes();
	}
	if (Yaffas::Product::check_product('zarafa')) {
		my $converter = Text::Iconv->new("iso-8859-15", "utf-8");
		@folder_alias = map {$converter->convert($_)} Yaffas::Mail::get_mailboxes();
		$selected_folder_alias = [map {$converter->convert($_)} @{$selected_folder_alias}];
	}

	my $user_aliases = Yaffas::Mail::Mailalias->new();
	my @user_alias = $user_aliases->get_alias_destination($from);

	print section(
				  $section_header,
				  $Cgi->table(
							  $Cgi->Tr([
										$Cgi->td([
												  $main::text{lbl_mailalias} . ":",
												  (
												   $edit
												   ?
												   $from . $Cgi->hidden({-id=>"from", -name=>"from", -value=>$from})
												   :
												   $Cgi->textfield(
																   -name => "from",
																   -value => $from,
																  )
												  )
												 ]),
										Yaffas::UI::small_form({
																input_name => 'to',
																input_value => $to,
																input_label => $main::text{lbl_destination_usr} . ":",
																del_label => $main::text{lbl_del} . ": ",
																del_name => "del_to",
																content => \@user_alias,
																hide_add => scalar @user_alias ? 0 : 1
															   }),

#										$Cgi->td($Cgi->b("-- ".$main::text{lbl_or}." --")),
#										(Yaffas::Product::check_product("zarafa") and scalar Yaffas::Mail::get_mailboxes() == 0) ?
#										(
#										 $Cgi->td({-colspan=>2}, $main::text{lbl_no_zarafa_public_folders}),
#										)
#										: 
#										(
#										 $Cgi->td([
#												  $main::text{lbl_destination_dir} . ":",
#												  $Cgi->scrolling_list(
#																	   -name=>'folders',
#																	   -values=> \@folder_alias,
#																	   -defaults => $selected_folder_alias,
#																	   -size=>5,
#																	  ),
#												  ])
#										)
#										,
										]),
							 ),
				 );

}

sub _display_alias_edit_end(){
	_display_alias_for_end();
}

sub _display_alias_edit_begin(){
	print $Cgi->start_form(
						   -method=>'post',
						   -action=>"edit.cgi",
	);
}

sub _display_alias_edit ($){
	my $from = shift;

	my $dir_aliases = Yaffas::Mail::Mailalias->new("DIR");
	my @dir_to = $dir_aliases->get_alias_destination($from);
	$Cgi->hidden("edit",$from);

	_display_alias_for($from, "", \@dir_to, $main::text{lbl_changealias}.": $from", 1);
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
