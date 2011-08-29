#!/usr/bin/perl -w
use warnings;
use strict;

use CGI::Carp qw(fatalsToBrowser warningsToBrowser);
use Yaffas::Constant;
use Yaffas::UI::TablePaging qw(show_page match);
use Yaffas::UI qw(section section_button all_error_box start_section end_section textfield password_field);
use Yaffas::Product qw(check_product);
use Yaffas::Exception;
use Error qw(:try);
use Yaffas::Module::Users;
use Yaffas::Auth;
use Yaffas::Auth::Type qw(:standard);
use Yaffas::Module::About;
use Yaffas::Module::AuthSrv;
use Sort::Naturally;
use Yaffas::UGM qw(get_print_operators_group);

our $cgi = $Yaffas::UI::Cgi;

sub pdc()
{
	my $info = Yaffas::Auth::get_pdc_info();

	$Yaffas::UI::Print_inner_div = 0;
	print $cgi->start_form(-name => 'autocheck', -action => 'check_pdc.cgi', -method => 'post');

	print start_section($main::text{'lbl_pdc'});

	print $cgi->div(
		$cgi->table(
			$cgi->Tr(
				$cgi->td( $main::text{'lbl_pdc_server'}.":" ),
				$cgi->td(
					textfield(
						-name => 'pass_pdc',
						-size => 20,
						-value => ( $main::in{'pass_pdc'} )?( $main::in{'pass_pdc'} ):( $info->{host} ),
					),
				),
			),
			$cgi->Tr(
				$cgi->td( $main::text{lbl_dom_name}.":" ),
				$cgi->td( 
					textfield(
						-name => 'dom_name',
						-size => 20,
						-value => ( $main::in{'dom_name'} )?( $main::in{'dom_name'} ):( $info->{domain} )
					),
				),
			),
			$cgi->Tr(
				$cgi->td( $main::text{lbl_dom_adm}.":" ),
				$cgi->td( 
					textfield(
						-name => 'dom_adm',
						-size => 20,
						-value => $main::in{'dom_adm'}
					),
				),
			),
			$cgi->Tr(
				$cgi->td( $main::text{lbl_dom_pass1}.":" ),
				$cgi->td( 
					password_field(
					-name => 'dom_pass1',
					-size => 20,
					),
				),
			),
			( Yaffas::Product::check_product("fax") || Yaffas::Product::check_product("pdf") ?
				$cgi->Tr(
					$cgi->td( $main::text{lbl_printop_group}.":" ),
					$cgi->td(
						textfield(
						-name => 'printop_group',
						-size => 20,
						-value => ( $main::in{'printop_group'} ? $main::in{'printop_group'} : get_print_operators_group() )
						),
					),
			) : ''),
		),
	);
	print choose_del_faxconf();
	print end_section();

	
	print section_button($cgi->submit({-name => 'switch', -value => $main::text{'lbl_apply'}}));
	print $cgi->end_form();
}

sub ads()
{
	my $info = Yaffas::Auth::get_pdc_info();
	my $ads_user = $main::in{'ads_user'};
	if (Yaffas::Auth::get_auth_type() eq ADS) {
		unless ((defined $ads_user) && (length($ads_user) > 0)) {
			$ads_user = Yaffas::Module::AuthSrv::get_ldap_settings()->{'BINDDN'};
		}#endif $ads_user not defined or empty
	}#endif ADS

	$Yaffas::UI::Print_inner_div = 0;
	print $cgi->start_form(-name => 'autocheck', -action => 'check_ads.cgi', -method => 'post');

	print start_section($main::text{'lbl_ad'});

	print $cgi->div(
		$cgi->table(
			$cgi->Tr(
				$cgi->td( $main::text{'lbl_pdc_server'}.":" ),
				$cgi->td( 
					textfield(
						-name => 'pass_pdc', 
						-size => 20,
						-value => ( $main::in{'pass_pdc'} )?( $main::in{'pass_pdc'} ):( $info->{host} ),
					),
				),
			),
			$cgi->Tr(
				$cgi->td( $main::text{lbl_dom_name}.":" ),
				$cgi->td( 
					textfield(
						-name => 'dom_name',
						-size => 20,
						-value => ( $main::in{'dom_name'} )?( $main::in{'dom_name'} ):( $info->{domain} )
					),
				),
			),
			$cgi->Tr(
				$cgi->td( $main::text{lbl_dom_adm}.":" ),
				$cgi->td( 
					textfield(
						-name => 'dom_adm',
						-size => 20,
						-value => $main::in{'dom_adm'}
					),
				),
			),
			$cgi->Tr(
				$cgi->td( $main::text{lbl_dom_pass1}.":" ),
				$cgi->td( 
					password_field(
					-name => 'dom_pass1',
					-size => 20,
					),
				),
			),
			( Yaffas::Product::check_product("fax") || Yaffas::Product::check_product("pdf") ?
				$cgi->Tr(
					$cgi->td( $main::text{lbl_printop_group}.":" ),
					$cgi->td(
						textfield(
						-name => 'printop_group',
						-size => 20,
						-value => ( $main::in{'printop_group'} ? $main::in{'printop_group'} : get_print_operators_group() )
						),
					),
				) : ''),
		),
	);
		print $cgi->h2($main::text{'lbl_ads_user'});
		print $cgi->div(
			$cgi->table(
				$cgi->Tr(
					$cgi->td( $main::text{'lbl_username_dn'}.":" ),
					$cgi->td( 
						textfield(
							-name => 'ads_user', 
							-size => 60,
							-value => ( $ads_user )?( $ads_user ): ""
						),
					),
				),
				$cgi->Tr(
					$cgi->td( $main::text{lbl_dom_pass1}.":" ),
					$cgi->td( 
						password_field(
							-name => 'ads_user_pass1',
							-size => 20,
						),
					),
				),
			),
		);

	print choose_del_faxconf();
	print end_section();


	print $cgi->hidden("noencryption_confirmed",( $main::in{'noencryption_confirmed'} ? $main::in{'noencryption_confirmed'} : "no"));
	print section_button($cgi->submit({-name => 'switch', -value => $main::text{'lbl_apply'}}));
	print $cgi->end_form();
}

sub test_pdc_connection()
{
	return $Cgi->h2($main::text{lbl_test_pdc_con}),
		Yaffas::UI::section_button($cgi->button({-id=>"testdc", -label=>$main::text{'lbl_apply'}}));
}

sub show_pdc_checks() {
	my $ping = Yaffas::Module::AuthSrv::check_pdc_ping();
	my $trust = Yaffas::Module::AuthSrv::check_pdc_trust();
	my @users = Yaffas::Module::AuthSrv::show_pdc_users();

	$Yaffas::UI::Print_inner_div = 0;
	print Yaffas::UI::section($main::text{lbl_test_pdc_con},
							  $cgi->h2($main::text{lbl_pdc_ping}),
							  $Cgi->p($ping ? $ping : ""),
							  $cgi->h2($main::text{lbl_pdc_trust}),
							  $Cgi->p($trust ? $trust : ""),
							  $cgi->h2($main::text{lbl_pdc_users}),
							  $Cgi->p(@users ? @users : ""),
							 );
}

sub choose_auth()
{
	my @auth_methodes = ( "local_auth", "yaffas_ldap", "ldap", "ads" );

	# TODO: implement other auth methods for RHEL5
#	@auth_methodes = ( "files", "ads", "yaffas_ldap", "ldap" ) if Yaffas::Constant::OS eq 'RHEL5';

	# Figure out the current authentication mechanism and set it as default value of the popup menu
	my $default;
	($default = "local_auth" ) if (Yaffas::Auth::get_auth_type() eq LOCAL_LDAP);
	($default = "ldap" ) if (Yaffas::Auth::get_auth_type() eq REMOTE_LDAP);
	($default = "pdc") if (Yaffas::Auth::get_auth_type() eq PDC);
	($default = "ads") if (Yaffas::Auth::get_auth_type() eq ADS);
	($default = "files") if (Yaffas::Auth::get_auth_type() eq FILES);

	print $cgi->start_form( {-action=>"index.cgi", -id=>"choose_auth"} );
	print Yaffas::UI::section($main::text{lbl_auth},
							  $Cgi->p($cgi->popup_menu(-name=>'auth_methode',
							  					-id=>"selectauth",
											   -values=>\@auth_methodes,
											   -default => $default,
											   -labels=>{
												   local_auth=>$main::text{lbl_local_auth},
											 	   yaffas_ldap=>$main::text{lbl_bk_ldap},
											 	   ldap=>$main::text{lbl_ldap},
												   pdc=>$main::text{lbl_samba_pdc},
												   ads=>$main::text{lbl_ad},
												   files=>$main::text{lbl_files_auth},
											   }
											  )
											  )
							 );

	print Yaffas::UI::section_button($cgi->button({ -id => "chooseauth", -label=>$main::text{'lbl_change'}}));
	print $cgi->end_form();
}

sub local_ldap() {
	my @values = (
		$main::text{lbl_this_auth_src_ldap},
	);

	push @values, $main::text{lbl_this_auth_src_pdc} if (Yaffas::Product::check_product_license("fileserver"));

	my @default;
	Yaffas::Product::check_product("auth")
	  && push( @default, $main::text{lbl_this_auth_src_ldap} );
	Yaffas::Module::AuthSrv::auth_srv_pdc()
	  && push( @default, $main::text{lbl_this_auth_src_pdc} );

	print $cgi->start_form( { -action => "check_local_ldap.cgi" } );
	print Yaffas::UI::section(
		$main::text{lbl_local_auth},
		$cgi->p($cgi->checkbox_group(
			-name      => 'auth_srv',
			-values    => \@values,
			-default   => \@default,
			-linebreak => 'true'
		)),
		choose_del_faxconf()
	);


	print Yaffas::UI::section_button(
		$cgi->submit( "auth", $main::text{'lbl_apply'} ) );
	print $cgi->end_form();
}

sub remote_ldap(;$)
{
	my $method = shift;

	my $values = Yaffas::Auth::get_bk_ldap_auth();


	print $cgi->start_form( {-action=>"check_ldap.cgi"} );
	print Yaffas::UI::section($method eq "yaffas" ? $main::text{lbl_bk_ldap} : $main::text{lbl_ldap},
							  
							  $Cgi->h2($main::text{lbl_info}),
							  
							  $Cgi->p($main::text{lbl_need_schema},
								  $cgi->ul(
										   [
										   $cgi->li($cgi->a({-href=>"/authsrv/dlschema.cgi?file=samba"}, "Samba Schema")),
										   ]
										  )),
							  
							  $cgi->table(
										  $cgi->Tr(
												   $cgi->td($main::text{lbl_host} . ":"),
												   $cgi->td( 
												   		textfield(
															"host",
															( $main::in{'host'} )?( $main::in{'host'} ):( $values->{host} ),
															40,
															150
														)
													)
												  ),
										  $cgi->Tr(
												   $cgi->td($main::text{lbl_basedn} . ":"),
												   $cgi->td(
														textfield(
															"basedn",
															( $main::in{'basedn'} )?( $main::in{'basedn'} ):( $values->{base} ),
															40,
															150
														)
													)
												  ),
										  $cgi->Tr(
												   $cgi->td($main::text{lbl_user_base} . ":"),
												   $cgi->td($method ne "yaffas" ?
															(
															textfield("userdn", $main::in{userdn} ? $main::in{userdn} : $values->{userdn}, 40, 150)
															)
															:
															(
															$cgi->hidden("userdn", "ou=People"),
															"ou=People"
															)
										  )
												  ),
										  $cgi->Tr(
												   $cgi->td($main::text{lbl_user_attribute} . ":"),
												   $cgi->td($method ne "yaffas" ?
															(
															 textfield("usersearch",
																			 $main::in{usersearch} ? $main::in{usersearch} : $values->{usersearch},
																			 40,
																			 150
																			)
															)
															:
															(
															 $cgi->hidden("usersearch", "uid"),
															 "uid"
															)
														   )
												  ),
										  $cgi->Tr(
												   $cgi->td($main::text{lbl_email} . ":"),
												   $cgi->td($method ne "yaffas" ?
															(
															 textfield("email", $main::in{email} ? $main::in{email} : $values->{email}, 40, 150)
															)
															:
															(
															 $cgi->hidden("email", "mail"),
															 "mail"
															)
														)
												  ),
										  $cgi->Tr(
												   $cgi->td($main::text{lbl_group_base} . ":"),
												   $cgi->td($method ne "yaffas" ?
															(
															textfield("groupdn", $main::in{groupdn} ? $main::in{groupdn} : $values->{groupdn}, 40, 150)
															)
															:
															(
															$cgi->hidden("groupdn", "ou=Group"),
															"ou=Group"
															)
														   )
												  ),
										( Yaffas::Product::check_product("fax") || Yaffas::Product::check_product("pdf") ?
											$cgi->Tr(
												$cgi->td($main::text{lbl_printop_group}.":" ),
												$cgi->td($method ne "yaffas" ?
													(
														textfield(
															-name => "printop_group",
															-value => ($main::in{'printop_group'} ? $main::in{'printop_group'} : get_print_operators_group()),
															-size => 40,
															-maxlength => 150
														)
													)
													:
													(
														$cgi->hidden(
															-name => "printop_group",
															-default => ["Print Operators"]
														),
														"Print Operators"
													)
												)
										) : ''),
										  $cgi->Tr(
												   $cgi->td($main::text{lbl_binddn} . ":"),
												   $cgi->td(
												   		textfield(
															"binddn",
															( $main::in{'binddn'} )?( $main::in{'binddn'} ):( $values->{binddn} ),
															40,
															150
														)
													)
												  ),
										  $cgi->Tr(
												   $cgi->td($main::text{lbl_bindpw} . ":"),
												   $cgi->td(password_field("bindpw", '', 40, 150))
												  ),
											),
										choose_del_faxconf()
							  );


	print $cgi->hidden("noencryption_confirmed",( $main::in{'noencryption_confirmed'} ? $main::in{'noencryption_confirmed'} : "no"));
	print Yaffas::UI::section_button($cgi->submit("auth", $main::text{'lbl_apply'}));
	print $cgi->end_form();
}

sub remote_ldap_confirm_sambasid ($) {
	my $sambasids_available = shift;
	my %labels;
	foreach my $sid ( keys %$sambasids_available ) {
		my $domains = $sambasids_available->{$sid};
		my $str     = $sid . ' (';
		if ( scalar @$domains ) {
			$str = $str . join( ', ', sort @$domains );
		}
		else {
			$str = $str . $main::text{'err_no_domain_found'};
		}
		$str = $str . ')';
		$labels{$sid} = $str;
	}

	print $Cgi->start_div({-id=>"siddialog"});

	print $Cgi->div({-class=>"hd"},$main::text{'lbl_confirm_sambasid'});
	print $Cgi->div({-class=>"bd"}, $cgi->scrolling_list (
		-id => 'sambasid',
		-name     => 'sambasid',
		-values   => [ keys %labels ],
		-labels   => \%labels,
		-size     => 5
	)
	);

	print $Cgi->end_div();
}

sub status(){
	try{
		my $authtype = Yaffas::Auth::get_auth_type();
		if( $authtype eq LOCAL_LDAP ) {
			my $auth_srv = $main::text{"lbl_no"};
			my @methods;

			Yaffas::Product::check_product("auth")  && push( @methods, "LDAP" );
			Yaffas::Module::AuthSrv::auth_srv_pdc() && push( @methods, "PDC" );

			if( scalar @methods ){
				$auth_srv = $main::text{"lbl_yes"} . " (" . join(', ', @methods) . ")";
			}
			print(
				Yaffas::UI::section(
					$main::text{lbl_status},
					$cgi->table(
						$cgi->Tr(
							$cgi->td( $main::text{lbl_local_auth} ),
						),
						$cgi->Tr(
							$cgi->td( $main::text{lbl_auth_srv} . ": " . $auth_srv )
						)
					)
				)
			);
		}
		elsif( $authtype eq FILES) {
			print(
				Yaffas::UI::section(
					$main::text{lbl_status},
					$cgi->table(
						$cgi->Tr(
							$cgi->td( $main::text{lbl_files_auth} ),
						),
						$cgi->Tr(
							$cgi->td([$main::text{lbl_printop_group} . ":", get_print_operators_group()])
						)
					)
				)
			);
		}
		elsif( $authtype eq REMOTE_LDAP ){
			my $info = Yaffas::Auth::get_bk_ldap_auth();
			print( 
				Yaffas::UI::section(
					$main::text{lbl_status},
					$cgi->table(
						$cgi->Tr(
							$cgi->td( $main::text{lbl_ldap} ),
							$cgi->td( '&nbsp' )
						),
						$cgi->Tr(
							$cgi->td( $main::text{lbl_host} . ":" ),
							$cgi->td( $info->{host}  )
						),
						$cgi->Tr(
							$cgi->td( $main::text{lbl_basedn} . ":" ),
							$cgi->td( $info->{base} )
						),
						$cgi->Tr(
							$cgi->td( $main::text{lbl_binddn} . ":" ),
							$cgi->td( $info->{binddn} )
						),
						$cgi->Tr(
							$cgi->td( $main::text{lbl_printop_group} . ":" ),
							$cgi->td( get_print_operators_group() )
						),
					)
				)
			);
		}
		elsif( ($authtype eq PDC) ||
		       ($authtype eq ADS) ){
			my $info = Yaffas::Auth::get_pdc_info();
			print(
				Yaffas::UI::section(
					$main::text{lbl_status},
					$cgi->table(
						$cgi->Tr([
							$cgi->td([$authtype, '&nbsp']),
							$cgi->td([$main::text{lbl_pdc} . ":" , $info->{host}]),
							$cgi->td([$main::text{lbl_dom_name} . ":",  $info->{domain}]),
							$cgi->td([$main::text{lbl_printop_group} . ":", get_print_operators_group()])
						])
					),
					test_pdc_connection()
				)
			);
			# for debugging
			if(0) {
				my $wbinfo_list = join "<br>", Yaffas::do_back_quote("/usr/bin/wbinfo", "-D", $info->{domain});
				print $cgi->div({ -style=> "position:fixed; right:100px; bottom:50px" }, "$wbinfo_list");
			}

		}
	}
	catch Yaffas::Exception with
	{
		print Yaffas::UI::all_error_box(shift);
	};
}

sub choose_del_faxconf()
{

	return undef unless (Yaffas::Product::check_product("fax") || Yaffas::Product::check_product("pdf"));
	my $checked = $main::in{'wipe_faxconf'};
	return $cgi->h2($main::text{lbl_del_faxconf}),
	$cgi->p($cgi->checkbox("wipe_faxconf", $checked,  "yes", " $main::text{lbl_expl_del_faxconf}"));
}

sub files() {
	print $cgi->start_form( {-action=>"check_files.cgi"} );
	print Yaffas::UI::section($main::text{lbl_files},
			$cgi->table(
						$cgi->Tr(
								$cgi->td($main::text{'lbl_using_files'}),
								),
#						$cgi->Tr(
#								$cgi->td([$main::text{'lbl_printop_group'}.":", get_print_operators_group()]),
#								),
				),
			choose_del_faxconf()
			);


	print Yaffas::UI::section_button($cgi->submit("auth", $main::text{'lbl_apply'}));
	print $cgi->end_form();

}

sub printops_group {
	my $printop_group;
	if(defined $_[0]) {
		$printop_group = $_[0];
	}
	else {
		$printop_group = Yaffas::UGM::get_print_operators_group();
	}
	my $admin = "";
	if(defined $_[1]) {
		$admin = $_[1];
	}
	print $cgi->start_form( {-action => "check_printop_group.cgi" } );
	print Yaffas::UI::section($main::text{'lbl_change_printop_group'},
		$cgi->table(
				$cgi->Tr(
					$cgi->td( $main::text{'lbl_printop_group'}.":" ),
					$cgi->td(
#						$cgi->textfield(
#							-name => 'printop_group',
#							-size => 40,
#							-value => $printop_group ? $printop_group : ""
#						),
						$cgi->popup_menu(
							-name => 'printop_group',
							-values => [ Yaffas::UGM::get_groups() ],
							-default => (defined $printop_group ? $printop_group : ()),
						),
					),
				),
				$cgi->Tr(
					$cgi->td( $main::text{'lbl_admin'}.":" ),
					$cgi->td(
						textfield(
							-name => 'admin',
							-size => 20,
							-default => $admin,
						),
					),
				),
				$cgi->Tr(
					$cgi->td( $main::text{'lbl_adminpw'}.":" ),
					$cgi->td(
						password_field(
							-name => 'adminpw',
							-size => 20,
						),
					),
				),
			),
		);

	print Yaffas::UI::section_button($cgi->submit("apply_printop_group", $main::text{'lbl_apply'}));
	print $cgi->end_form();
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
