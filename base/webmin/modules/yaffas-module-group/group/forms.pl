#!/usr/bin/perl
use warnings;
use strict;
use CGI::Carp qw(fatalsToBrowser warningsToBrowser);
use Yaffas::UGM qw(get_users get_groups get_email);
use Yaffas::UI qw(section $Cgi section_button);
use Yaffas::UI::TablePaging qw(show_page);
use Yaffas::Fax;
use Yaffas::Product;
use Sort::Naturally;
use Yaffas::Auth;
use Text::Iconv;
use Yaffas::Constant;

sub add_group_form(@) {
	my $show_filetype = 0;

	return if (Yaffas::Auth::auth_type() ne Yaffas::Auth::LOCAL_LDAP());

	if (Yaffas::Product::check_product("fax")) {
		$show_filetype = 1;
	}

    print $Cgi->start_form("POST", "add_groups.cgi");
    print section($main::text{lbl_create_group_header},
		  $Cgi->table(
			      $Cgi->Tr([
					$Cgi->td([
						  $main::text{lbl_groupname} . ":",
						  $Cgi->textfield({name=>"groupname", value=>join ", ", @_})
						 ]),
					# if $show_filetype
					# then
					($show_filetype
					 ?
					 $Cgi->td([
						   $main::text{lbl_filetype} . ":",
						   $Cgi->scrolling_list(
									{
									 -name=>"filetype",
									 -values=>["pdf", "ps", "tif", "gif", "jpg"],
									 -labels=>{
										   pdf=>"PDF",
										   ps=>"PS",
										   tif=>"TIF",
										   gif=>"GIF",
										   jpg=>"JPG",
										  },
									 -default=>Yaffas::UGM::get_hylafax_filetype($_, "g"),
									 -size=>1
								      }
								       )
						  ])
					 :
					 # else ... nothing
					 ""
					),
				       ]),
			     ),
		 );
    print section_button($Cgi->submit("submit", $main::text{lbl_group_add}));
    print $Cgi->end_form();
}

sub list_group_form() {
	print section(
		  $main::text{lbl_groups},
		  $Cgi->div({-id=>"table"}, ""),
		  $Cgi->div({-id=>"menu"}, "")
		 );
}

sub show_edit_groups {
    my $groups = shift;
    my %hash;

    my $email;
    my @sendas;

    my $i = 0;
    print $Cgi->start_form({
			    -method => "POST",
			    -action => "edit_groups.cgi",
			   });

    $Yaffas::UI::Print_inner_div = 0;
    print section($main::text{lbl_edit}.": ".$groups->[0],
		  map {
              @sendas = Yaffas::UGM::get_send_as($_, "group");
              $email = get_email($_, "group");
		      #$Cgi->h2($main::text{lbl_groupname} . ": " . $_) .
		      $Cgi->hidden("groups", $_) .
		      $Cgi->table(
				  $Cgi->Tr([ Yaffas::Product::check_product("fax") ? ( $Cgi->td([
							$main::text{lbl_filetype} . ":",
							$Cgi->scrolling_list(
									     {
									      -name=>"filetype",
									      -values=>["pdf", "ps", "tif", "gif", "jpg"],
									      -labels=>{
											pdf=>"PDF",
											ps=>"PS",
											tif=>"TIF",
											gif=>"GIF",
											jpg=>"JPG",
										       },
									      -default=>Yaffas::UGM::get_hylafax_filetype($_, "g"),
									      -size=>1
									     }
									    )
						       ])
					    ) : undef, 
                        $Cgi->td([
                            $main::text{lbl_email}.":",
                            $Cgi->input({-name=>"mail", -value => $email}),
                            ]),
						# disable this for now until zarafa says if this is possible
						#$Cgi->td([
                        #    $main::text{lbl_sendas}.":",
                        #    $Cgi->scrolling_list(
                        #        -name => "sendas",
                        #        -id => "sendas",
                        #        -size => 5,
                        #        -values => [Yaffas::UGM::get_users()],
                        #        -default => \@sendas,
                        #        -multiple => 1,
                        #        -style => "width: 20em",

                        #    )
                        #    ]),
                        ]),
				 );
		  } @$groups
		 );
    $Yaffas::UI::Print_inner_div = 1;
    print section_button(
			 $Cgi->hidden("mode", $main::text{lbl_save}),
			 $Cgi->submit("submit", $main::text{lbl_save})
			);
    print $Cgi->end_form();
}

sub show_filetype(@) {
    my @groups = @_;

    print $Cgi->start_form({-action=>"set_filetype.cgi"});

    $Yaffas::UI::Print_inner_div = 0;
    print section($main::text{lbl_set_filetype},
		  Yaffas::UI::table($Cgi->Tr([
					      $Cgi->th([$main::text{lbl_group}, $main::text{lbl_filetype}]),
					      map {
						  $Cgi->td([ $_,
							     $Cgi->scrolling_list(
										  {
										   -name=>"filetype_".$_,
										   -values=>["pdf", "ps", "tif", "gif", "jpg"],
										   -labels=>{
											     pdf=>"PDF",
											     ps=>"PS",
											     tif=>"TIF",
											     gif=>"GIF",
												 jpb=>"JPG",
											    },
										   -default=>Yaffas::UGM::get_hylafax_filetype($_, "g"),
										   -size=>1
										  }
										 ).
							     $Cgi->hidden({-name=>"groups", -value=>$_})
							   ])
					      } @groups
					     ]
					    )
				   )
		 );

    print section_button($Cgi->submit({-name=>"submit", -value=>$main::text{lbl_save}}));

    print $Cgi->end_form();
}

sub _match {
    my $value = shift;
    my $term = shift;		#searchterm
    my $regex;
    return 1 unless $term;
    return 1 unless $value;
    $term =~ s/[^\w*?]//g;
    $regex = $term;
    $regex = "*" if $term eq "";
    $regex =~ s/\*/\.\*/g;
    $regex =~ s/\?/\./g;

    return $value =~ m/$regex/;
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
