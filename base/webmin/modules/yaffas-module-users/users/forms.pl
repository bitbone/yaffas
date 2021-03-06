# file bbnetauth-forms.pl
# for all my bbnetauth forms
use strict;
use warnings;

use CGI::Carp qw(fatalsToBrowser warningsToBrowser);
use Sort::Naturally;

use Yaffas::UGM qw(get_users get_groups gecos name get_uid_by_username get_username_by_uid get_suppl_groupnames get_email);
use Yaffas::UI qw($Cgi section section_button table yn_confirm creating_cache_finish creating_cache_start checkbox textfield);
use Yaffas::UI::TablePaging qw(show_page match);
use Yaffas::Module::Users;
use Yaffas::Product qw(check_product);
use Carp qw(cluck);
use Sort::Naturally;
use Yaffas::Constant;
use Yaffas::Auth;
use Yaffas::Fax;
use Text::Iconv;
use Encode;
use JSON;
my $HAVE_MAIL_ALIASES = eval "use Yaffas::Module::Mailalias; 1;";

## prototypes ##
sub _edit_user($$\@\@;$);

sub _edit_user($$\@\@;$){
	my $uid = shift;
	my $size = shift;
	my $existing_groups = shift;
	my $mailusers = shift;
	my $take_vars_from_me = shift;

	my ($login, $givenname, $surname, $is_mailuser, @usergroups, $msg, $email, $filetype, @aliases, $zarafaquota, $zarafaadmin, $zarafashared, $zarafahide, %avalues);

	if ($take_vars_from_me) {
			$login = $take_vars_from_me->{"login"};
			$msg = $main::text{lbl_changeuser} . ": " . $login;
			$givenname = $take_vars_from_me->{"givenname"};
			$surname = $take_vars_from_me->{"surname"};
			@usergroups = @{ $take_vars_from_me->{"group"} };
			$is_mailuser = $take_vars_from_me->{"mailgroup"};
			$email = $take_vars_from_me->{"email"};
			$filetype = $take_vars_from_me->{"filetype"};
			@aliases = @{$take_vars_from_me->{"aliases"}};
			$zarafaquota = $take_vars_from_me->{"zarafaquota"};
			$zarafaadmin = $take_vars_from_me->{"zarafaadmin"};
			$zarafashared = $take_vars_from_me->{"zarafashared"};
			$zarafahide = $take_vars_from_me->{"zarafahide"};

			$avalues{businessphone} = $take_vars_from_me->{"businessphone"};
			$avalues{location} = $take_vars_from_me->{"location"};
			$avalues{faxnumber} = $take_vars_from_me->{"faxnumber"};
			$avalues{department} = $take_vars_from_me->{"department"};
	} else {
		if ($uid) {
			$login = get_username_by_uid($uid);
			$msg = $main::text{lbl_changeuser} . ": " . $login;
			($givenname, $surname) = name($login);
			@usergroups = get_suppl_groupnames ( $login );
			$is_mailuser = _in_group($login, $mailusers);
			$email = get_email($login);
			$filetype = Yaffas::UGM::get_hylafax_filetype($login, 'user');

			if ($HAVE_MAIL_ALIASES) {
				my $a = Yaffas::Module::Mailalias->new();
				@aliases = $a->get_user_aliases($login);
			}
			$zarafaquota = Yaffas::Mail::get_zarafa_quota($login);
			$zarafaadmin = Yaffas::Module::Users::get_zarafa_admin($login);
			$zarafashared = Yaffas::Module::Users::get_zarafa_shared($login);
			$zarafahide = Yaffas::Module::Users::get_zarafa_hidden($login);

			$avalues{businessphone} = Yaffas::UGM::get_additional_value($login, $Yaffas::Module::Users::ADDITIONAL_VALUES->{businessphone});
			$avalues{location} = Yaffas::UGM::get_additional_value($login, $Yaffas::Module::Users::ADDITIONAL_VALUES->{location});
			$avalues{faxnumber} = Yaffas::UGM::get_additional_value($login, $Yaffas::Module::Users::ADDITIONAL_VALUES->{faxnumber});
			$avalues{department} = Yaffas::UGM::get_additional_value($login, $Yaffas::Module::Users::ADDITIONAL_VALUES->{department});
		} else {
			$msg = $main::text{lbl_adduser};
			$login = $main::in{login_};
			$givenname = $main::in{givenname_};
			$surname = $main::in{surname_};
			@usergroups = split /\0/, $main::in{group_};
			$is_mailuser = $main::in{mailgroup_};
			$email = $main::in{email_};
			$filetype = $main::in{filetype_};
			@aliases = split /\0/, $main::in{alias_};
			$zarafaquota = $main::in{zarafaquota_};
			$zarafaadmin = $main::in{zarafaadmin_};
			$zarafashared = $main::in{zarafashared_};
			$zarafahide = $main::in{zarafahide_};

			$avalues{businessphone} = $main::in{"businessphone_"};
			$avalues{location} = $main::in{"location_"};
			$avalues{faxnumber} = $main::in{"faxnumber_"};
			$avalues{department} = $main::in{"department_"};
		}
	}

    my @users = Yaffas::UGM::get_users();
    my @groups = Yaffas::UGM::get_groups();

    my ($sendas_users, $sendas_groups) = Yaffas::UGM::get_send_as($login);

	print section(
				  $msg,
                  $Cgi->hidden({-id=>"uid", -value=>$uid}),
				  $Cgi->table(
							  $Cgi->Tr([
										$Cgi->td([
												  $main::text{lbl_userlogin}.":",
												  $Cgi->textfield(
																  -name => "login_" . $uid,
																  -default => $login,
																  -maxlength => 100,
																  -style => "width: 20em",
																  (defined($uid) && $uid =~ m/^\d+$/) ? "readonly = \"readonly\"" : ''
																 )
												 ]),
										$Cgi->td([
												  $main::text{lbl_givenname}.":",
												  $Cgi->textfield(
																  -name => "givenname_" . $uid,
																  -default => $givenname,
																  -maxlength => 100,
																  -style => "width: 20em"
																 ),
												 ]),
										$Cgi->td([
												  $main::text{lbl_surname}.":",
												  $Cgi->textfield(
																  -name => "surname_" . $uid,
																  -default => $surname,
																  -maxlength => 100,
																  -style => "width: 20em"
																 ),
												 ]),
										(check_product("fax") || check_product('pdf') || Yaffas::Auth::is_auth_srv() || check_product('zarafa')) ?
										(
                                            $Cgi->td([
                                                    $main::text{lbl_email}.":",
                                                    $Cgi->table({-style=>"margin: 0px !important;"},
                                                        $Cgi->Tr(
                                                            $Cgi->td(
                                                                $Cgi->textfield({ -id => "new_email" }),
                                                                $Cgi->button( { -name => "email_add", -value => $main::text{lbl_add} } )
                                                            )
                                                        ),
                                                        $Cgi->Tr(
                                                            $Cgi->td(
                                                                $Cgi->scrolling_list(
                                                                    -id => "email",
                                                                    -default => $email,
                                                                    -labels => {$email => $email." (default)", map {$_ => $_} @aliases},
                                                                    -values => [grep {$_} ($email ? $email : undef), @aliases],
                                                                    -maxlength =>  90,
                                                                    -style => "width: 20em",
                                                                    -multiple => 1,
                                                                    -size => 5,
                                                                )
                                                            ),
                                                        ),
                                                        $Cgi->Tr(
                                                            $Cgi->td({-style => "margin-left: auto; margin-right: auto;"},
                                                                $Cgi->button( { -name => "email_modify", -value=>$main::text{lbl_modify} } ),
                                                                $Cgi->button( { -name => "email_remove", -value=>$main::text{lbl_remove} } ),
                                                                $Cgi->button( { -name => "email_default", -value=>$main::text{lbl_default} } ),
                                                            )

                                                        )
                                                    )
                                                ]),
										) : "", ## end if

										$Cgi->td([
												  $main::text{lbl_userpass1}.":",
												  $Cgi->password_field(
																	   -name => "userpass_" . $uid,
																	   -maxlength => 100,
																	   -style => "width: 20em"
																	  ),
												 ]),
										$Cgi->td([
												  $main::text{lbl_userpass2}.":",
												  $Cgi->password_field(
																	   -name => "userpass2_" . $uid,
																	   -maxlength => 100,
																	   -style => "width: 20em"
																	  ),
												 ]),
                                             #$Cgi->td([
										     #		 $main::text{lbl_alias}.":",
										     #		 $Cgi->textfield({
										     #						 -name=>"alias_$uid",
										     #						 -value=>join (", ", @aliases),
										     #						 -maxlength => 100,
										     #						 -style => "width: 20em"
										     #						 })
										     #		 ]),
                                        (map {
										$Cgi->td([
												  $main::text{"lbl_".$_}.":",
												  $Cgi->textfield(
																	   -name => $_."_" . $uid,
																	   -maxlength => 100,
																	   -style => "width: 20em",
                                                                       -default => $avalues{$_},
																	  ),
												 ]),
                                         } sort keys %{$Yaffas::Module::Users::ADDITIONAL_VALUES}),
										$Cgi->td([
												  $main::text{lbl_groups}.":",
												  $Cgi->scrolling_list(
																	   -name => "group_" . $uid,
																	   -size => $size,
																	   -values => $existing_groups,
																	   -default => \@usergroups,
																	   -multiple => 1,
																	   -style => "width: 20em",

																	  )
												 ]),
										((check_product("mail") || Yaffas::Auth::is_auth_srv()) && !check_product("zarafa")) ?
										$Cgi->td([
												  $main::text{lbl_mailuser}.":",
												  $Cgi->checkbox("mailgroup_" . $uid, $is_mailuser, "yes", "")

												 ])
										: "", ## end if

										(check_product("zarafa") || Yaffas::Auth::is_auth_srv()) ? (
										$Cgi->td([
												  $main::text{lbl_zarafaquota}.":",
												  textfield({
																  -name=>"zarafaquota_" . $uid,
																  -value=>$zarafaquota,
																  -maxlength=>5,
																  -size=>5,
																  })." MB"
												 ]) ,
										$Cgi->td([
												  $main::text{lbl_zarafaadmin}.":",
												  checkbox({
																  -name=>"zarafaadmin_" . $uid,
																  -checked=>$zarafaadmin,
																  -value=>"yes",
																  -label=>"",
																  })
												 ]) ,
										$Cgi->td([
												  $main::text{lbl_zarafashared}.":",
												  checkbox({
																  -name=>"zarafashared_" . $uid,
																  -checked=>$zarafashared,
																  -value=>"yes",
																  -label=>"",
																  }),
												 ]),
										$Cgi->td([
												  $main::text{lbl_zarafahide}.":",
												  checkbox({
																  -name=>"zarafahide_" . $uid,
																  -checked=>$zarafahide,
																  -value=>"yes",
																  -label=>"",
																  }),
												 ]),
										$Cgi->td([
												  $main::text{lbl_zarafafeatures}.":",
												  _features_table($uid)
												 ])
										) : "", ## end if
										check_product("fax") ?
										(
										$Cgi->td([
												  $main::text{lbl_filetype}.":",
												  $Cgi->scrolling_list({
														-name=>"filetype_" . $uid,
														-values=>["pdf", "ps", "tif", "gif", "jpg"],
														-labels=>{
															pdf=>"PDF",
															ps=>"PS",
															tif=>"TIF",
															gif=>"GIF",
															jpg=>"JPG",
														},
														-default=>$filetype,
														-size=>1
													})
												 ]),
										) : "", ## end if
									   ])
							 ),
							 $Cgi->h2($main::text{lbl_sendas}),
							 $Cgi->table(
								 $Cgi->Tr([
									 $Cgi->td([
										 $main::text{lbl_sendas_user}.":",
										 $Cgi->scrolling_list(
											 -name => "sendas_user_" . $uid,
											 -id => "sendas_user_",
											 -size => 5,
											 -values => [grep {$_ ne $login} @users],
											 -default => $sendas_users,
											 -multiple => 1,
											 -style => "width: 20em",

										 )
										 ]),
									 $Cgi->td([
										 $main::text{lbl_sendas_group}.":",
										 $Cgi->scrolling_list(
											 -name => "sendas_group_" . $uid,
											 -id => "sendas_group_",
											 -size => 5,
											 -values => \@groups,
											 -default => $sendas_groups,
											 -multiple => 1,
											 -style => "width: 20em",

										 )
										 ]),
									 ])
							 ),
						 );

}

# der returnte skalar wird verwendet als zeichen in der tabelle fuer admins.
# zusaetzlich returnt es "true" fuer admins, und "false" fuer nicht admins.
sub _in_group($\@){
	my $username = shift;
	my $admins = shift;
	my $found = 0;
	for (@$admins) {
		if ($username eq $_) {
			$found++;
			last;
		}
	}
	if ($found) {
		return "X";
	}else {
		return "";
	}
}

sub _in_group_lc($\@){
	my $username = shift;
	my $admins = shift;
	my $found = 0;
	for (@$admins) {
		if (lc($username) eq lc($_)) {
			$found++;
			last;
		}
	}
	if ($found) {
		return "X";
	}else {
		return "";
	}
}

sub show_users {
	print section(
		$main::text{lbl_usermanagment},
		$Cgi->div({-id=>"data"}, ""),
		$Cgi->div({-id=>"usersmenu"}, ""),
	);
}

sub show_edit_user(@) {
	unless (@_) {
		print Yaffas::UI::error_box($main::text{err_no_user_selected});
		return;
	}
	my @existing_groups = get_groups();
	my @mail = Yaffas::UGM::get_users();
	my $size;
	$size = scalar @existing_groups;
	$size = 2 if $size < 2;
	$size = 5 if $size >= 4;

	print $Cgi->start_form("post", "check_edituser.cgi");

	my $btn = 0;
	foreach my $uid (@_){
		next if ($uid < Yaffas::Constant::MISC->{min_uid});
		_edit_user($uid, $size, @existing_groups, @mail);
		$btn = 1;
	}

	if ($btn) {
		print section_button($Cgi->submit($main::text{lbl_changeuser}));
	} else {
		print Yaffas::UI::error_box($main::text{err_no_user_selected});
	}
	print $Cgi->end_form();
}

sub show_new_user(){
	my @existing_groups = get_groups();

	return if (Yaffas::Auth::get_auth_type() ne Yaffas::Auth::LOCAL_LDAP);

#	wir brauchen die 2 arrays eigentlich nicht, lassen wir sie leer.
# 	my @mail = Yaffas::UGM::get_users("mail");
	my @mail;

	my $size;
	$size = scalar @existing_groups;
	$size = 2 if $size < 2;
	$size = 5 if $size >= 4;

	print $Cgi->start_form("post", "check_newuser.cgi");
	_edit_user("", $size, @existing_groups, @mail);
	print section_button($Cgi->submit($main::text{lbl_adduser}));
	print $Cgi->end_form();
}

sub show_del_alias($$$$$$$$$) {

	my ($user, $pass1, $pass2, $email, $givenname, $surname, $mail_user,
		$filetype, $group) = @_;

	if ($user) {
		$Yaffas::UI::Convert_nl = 0;
		print yn_confirm({
						-action => "check_newuser.cgi",
						-title => "Alias löschen",
						-no => $main::text{lbl_no},
						-yes => $main::text{lbl_yes},
						-hidden => [ login_ => $user,
										userpass_ => $pass1,
										userpass2_ => $pass2,
										email_ => $email,
										givenname_ => $givenname,
										surname_ => $surname,
										mailgroup_ => $mail_user,
										filetype_ => $filetype,
										group_ => $group,
										delalias => 1
						],
		}, "Es existiert bereits ein Alias mit diesem Namen. Löschen?" . $Cgi->ul($Cgi->li([$user]))
					);
		$Yaffas::UI::Convert_nl = 0;
	}
	else {
		## nothing to do.
		print Yaffas::UI::error_box($main::text{err_no_alias_selected});
	}
}

sub show_edit_vacation {
    my $uid = shift;

    my $username = Yaffas::UGM::get_username_by_uid($uid);

    my ($status, $subject, $message) = Yaffas::Module::Users::get_vacation($username);

    print $Cgi->start_form( {-action=>"editvacation.cgi"} );

    print Yaffas::UI::section(
        $main::text{lbl_edit_vacation_msg}.": $username",
        $Cgi->hidden({ -name=>"username", -value=>$username}),
        $Cgi->p(
            $Cgi->radio_group({ -name => "status", -values => [qw(false true)], -labels => {true=>Encode::decode("utf-8", $main::text{lbl_vacation_enabled}), false=>Encode::decode("utf-8", $main::text{lbl_vacation_disabled})}, -default => $status, -linebreak => "true" }),
        ),
        $Cgi->table(
            $Cgi->Tr(
                $Cgi->td(
                    [
                        $main::text{lbl_subject}.":",
                        $Cgi->textfield({ -style => "width: 20em", -name => "subject", -value => $subject, ($status eq "true" ? (undef => undef) : (-disabled => 1)) }),
                    ]
                )
            ),
            $Cgi->Tr(
                $Cgi->td(
                    [
                        $main::text{lbl_message}.":",
                        $Cgi->textarea({ -columns=>80, -rows=>10, -name => "message", -value => $message, ($status eq "true" ? (undef => undef) : (-disabled => 1)) })
                    ]
                )
            )
        )
    );

    print section_button($Cgi->submit({-value => $main::text{lbl_save}}));
    print $Cgi->end_form();
}

sub set_user_filetype(@)
{
	my @uids = @_;

	print $Cgi->start_form( {-action=>"set_filetype_ads.cgi"} );

	$Yaffas::UI::Print_inner_div = 0;
	print section($main::text{lbl_filetype},
				  Yaffas::UI::table(
							  $Cgi->Tr(
									   $Cgi->th($main::text{lbl_user}),
									   $Cgi->th($main::text{lbl_filetype})
									  ),
							  map
							  {
								  my $name = get_username_by_uid($_);
								  my $user_ftype = Yaffas::UGM::get_hylafax_filetype($name, 'user');
								  $Cgi->Tr
								  (
								   $Cgi->hidden("user", $name),
								   $Cgi->td($name),
								   $Cgi->td($Cgi->popup_menu(-name=>'ftype',
													-values=>["pdf", "ps", "tif", "gif", "jpg"],
													-default=>$user_ftype,
													),
											),
								  ),
							  } @uids,
							 ),
				 );

	print section_button($Cgi->submit({-value => $main::text{lbl_save}}));
	print $Cgi->end_form();
}

sub _features_table () {
	my $uid = shift;

	my $features = Yaffas::Module::Users::get_features($uid);
	my $default = {"imap" => "off", "pop3" => "off"};
	if (check_product("zarafa")) {
		eval "use Yaffas::Module::ZarafaConf";
		$default = Yaffas::Module::ZarafaConf::get_default_features();
	}

	return $Cgi->table($Cgi->Tr([
			$Cgi->td([
				"IMAP: ",
				$Cgi->radio_group({
						-name=>"zarafaimap_" . $uid,
						-values=>[qw(on off default)],
						-labels=> {
							on => $main::text{lbl_feature_on},
							off => $main::text{lbl_feature_off},
							default => $main::text{"lbl_feature_default_" . $default->{imap}},
						},
						-default => $features->{imap}
					})
				]
			),
			$Cgi->td([
				"POP3: ",
				$Cgi->radio_group({
						-name=>"zarafapop3_" . $uid,
						-values=>[qw(on off default)],
						-labels=> {
							on => $main::text{lbl_feature_on},
							off => $main::text{lbl_feature_off},
							default => $main::text{"lbl_feature_default_" . $default->{imap}},
						},
						-default => $features->{pop3}
					})
				]
			)
		])
	);
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
