#!/usr/bin/perl
use warnings;
use strict;

use CGI::Carp qw(fatalsToBrowser warningsToBrowser);
use Yaffas::Mail::Mailalias qw(list_alias);
use Yaffas::UI::TablePaging qw(show_page);
use Yaffas::UI qw($Cgi section section_button table scrolling_list);
use Yaffas::Constant;

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
	my $section_header = shift || $main::text{lbl_addalias};

	my $edit = shift;

	my $aliases;
	my (@user_alias, @mail_alias, @dir_alias);
	if ($edit) {
		$aliases = Yaffas::Mail::Mailalias->new("USER");
		@user_alias = $aliases->get_alias_destination($from);
		$aliases = Yaffas::Mail::Mailalias->new("MAIL");
		@mail_alias = $aliases->get_alias_destination($from);
		$aliases = Yaffas::Mail::Mailalias->new("DIR");
		@dir_alias = $aliases->get_alias_destination($from);
	}

    my (%hide_mail, %hide_user, %hide_dir);
	%hide_mail = %hide_user = %hide_dir = (-style => "display:none;");
    
	my $type;
	if (!$edit || @user_alias) {
		$type = "USER";
		%hide_user = ();
	} elsif (@mail_alias) {
		$type = "MAIL";
		%hide_mail = ();
	} elsif (@dir_alias) {
		$type = "DIR";
		%hide_dir = ();
	}

    print section(
        $section_header,
        $Cgi->table(
            $Cgi->Tr(
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
                    ])
            ),
            $Cgi->Tr(
                $Cgi->td([
                        $main::text{lbl_alias_type}.":",
                        scrolling_list({ -id=> "aliastype", -name=> "type", -size => 1, -default => lc $type, -values=>[qw(user mail dir)], -labels => { map { $_ => $main::text{"lbl_alias_type_".$_} } qw(user mail)}, -onChange => "module.changeAliasType()"}),
                    ]),
            ),
            $Cgi->Tr({-id => "row-user", %hide_user},
                $Cgi->td([
                        $main::text{lbl_destination_usr}.":",
                        scrolling_list( { -name => "to", -size => 5, -multiple => 'true', -values => [Yaffas::UGM::get_users()], -default => \@user_alias } ),
                ]),
            ),
            $Cgi->Tr({-id => "row-mail", %hide_mail },
                $Cgi->td([
                        $main::text{lbl_recipient}.":",
                        $Cgi->textfield({ -name => "recipient", -size=> 80, -value => join(", ", @mail_alias)}),
                    ]),
            ),
			$Cgi->Tr({-id => "row-dir", %hide_dir },
				$Cgi->td([
						$main::text{lbl_destination_dir}.":",
						scrolling_list({ -name => "dir", -size => 5, -values => [_get_public_folders()], -default => \@dir_alias}),
					]),
			),
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
	$Cgi->hidden("edit", $from);
	_display_alias_for($from, "", $main::text{lbl_changealias}.": $from", 1);
}

sub _get_public_folders() {
	# returns all Zarafa public folders
	my @lines = Yaffas::do_back_quote(Yaffas::Constant::APPLICATION->{zarafa_public_folder_script});
	map { chomp } @lines;
	return @lines;
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
