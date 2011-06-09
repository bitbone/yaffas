#!/usr/bin/perl
# file bbmailsrv-forms.pl
# for all my bbmailsrv forms

use strict;
use warnings;

use CGI::Carp qw(fatalsToBrowser warningsToBrowser);
use Yaffas::Module::Mailsrv::Postfix
  qw(get_accept_domains get_accept_relay get_smarthost get_mailserver
  get_verify_rcp get_mailsize get_smarthost_routing get_archive get_zarafa_admin);
use Yaffas::UI qw($Cgi section section_button value_add_del_form);
use Yaffas::Product qw(check_product);
use Yaffas::Module::Users;
use Yaffas::UGM;
use Yaffas::Service qw(/.+/);
use Yaffas::Module::Secconfig;

sub base_settings_form() {
	$Yaffas::UI::Print_inner_div = 0;
	my %cfg = ();
	$cfg{mailservername} = get_mailserver();
	( $cfg{verify_action}, $cfg{mailadmin} ) = get_verify_rcp();
	$cfg{mailsize}     = get_mailsize();
	$cfg{zarafa_admin} = get_zarafa_admin();
	my %tlsstatus = Yaffas::Module::Secconfig::get_tls_status();

	foreach (qw(mailservername mailadmin mailsize verify_action zarafa_admin)) {
		if ( defined( $main::in{$_} ) ) {
			$cfg{$_} = $main::in{$_};
		}
	}

	my @zarafaadmins = (
		"",
		grep { $_ }
		  map { Yaffas::Module::Users::get_zarafa_admin($_) ? $_ : "" }
		  Yaffas::UGM::get_users()
	);

	print $Cgi->start_form( 'post', 'check_baseconfig.cgi' );
	print section(
		$main::text{lbl_baseconfig},
		$Cgi->table(
			$Cgi->Tr(
				[
					$Cgi->td(
						[
							$main::text{lbl_mailserver_name} . ":",
							$Cgi->textfield(
								'mailservername', $cfg{mailservername}
							)
						]
					),
					$Cgi->td(
						[
						$main::text{lbl_mailsize} . ":",
						$Cgi->textfield( 'mailsize', $cfg{mailsize},
							15 )
						. " MB",
						]
					),

					check_product("mail")
					? (
						$Cgi->td(
							[
								$main::text{lbl_unknown_rcp} . ":",
								$Cgi->scrolling_list(
									-id       => 'verify_action',
									-name     => 'verify_action',
									-size     => 1,
									-multiple => 0,
									-default  => $cfg{verify_action}
									? $cfg{verify_action}
									: 'delete',
									-values =>
									  [ 'refuse', 'delete', 'mailadmin' ],
									-labels => {
										refuse => $main::text{lbl_refuse_mail},
										delete => $main::text{lbl_delete_mail},
										mailadmin =>
										  $main::text{lbl_sendto_mailadmin},
									},
									-onChange => "javascript:toggle_mailadmin()"
									
								),
							]
						),
						$Cgi->td({-class=>"mailadmin", -style=>"display: none"},
							[
								$main::text{lbl_mailadmin} . ":",
								$Cgi->textfield( 'mailadmin', $cfg{mailadmin} )
							]
						),
						$Cgi->td(
							[
								$main::text{lbl_disable_client_tls} . ":",
								$Cgi->checkbox(
									{
										-name  => "client_tls",
										-value => "1",
										-label => "",
										defined( $tlsstatus{client} )
										? ( -checked => 1 )
										: ( -checked => "" ),
									}
								)
							]
						),
						$Cgi->td(
							[
								$main::text{lbl_disable_server_tls} . ":",
								$Cgi->checkbox(
									{
										-name  => "server_tls",
										-value => "1",
										-label => "",
										defined( $tlsstatus{server} )
										? ( -checked => 1 )
										: ( -checked => "" )
									}
								)
							]
						)
					  )
					: undef,
				]
			)
		),
        #check_product("zarafa")
		0
		? (
			$Cgi->h2( $main::text{lbl_only_for_public} ),
			$Cgi->table(
				$Cgi->Tr(
					[
						$Cgi->td(
							[
								$main::text{lbl_username} . ":",
								$Cgi->scrolling_list(
									-name     => "zarafa_admin",
									-multiple => 0,
									-default  => $cfg{zarafa_admin},
									-values   => \@zarafaadmins,
									-size     => 1,
								)
							]
						),
						$Cgi->td(
							[
								$main::text{lbl_password} . ":",
								$Cgi->password_field( { -name => "password" } )
							]
						)
					]
				)
			),
		  )
		: ()

	);
	print section_button( $Cgi->submit( "submit", $main::text{lbl_save} ), );
	print $Cgi->end_form();
	$Yaffas::UI::Print_inner_div = 1;
}

sub smarthost_form ($$) {
	$Yaffas::UI::Print_inner_div = 0;
	my ( $smarthost, $username ) = get_smarthost();
	print $Cgi->start_form( "post", "check_smarthost.cgi" );
	my ( $routeing, $maildomain ) = get_smarthost_routing();

	if ( defined( $main::in{smarthost} ) ) {
		$smarthost = $main::in{smarthost};
	}

	if ( defined( $main::in{username} ) ) {
		$username = $main::in{username};
	}

	if ( defined( $main::in{rewrite_domain} ) ) {
		$maildomain = $main::in{rewrite_domain};
	}

	if ( defined( $main::in{route_all} ) ) {
		$routeing = 1;
	}
	print section(
		$main::text{lbl_smarthost},
		$Cgi->table(
			$Cgi->Tr(
				[
					$Cgi->td(
						[
							$main::text{lbl_smarthost_name} . ":",
							$Cgi->textfield( "smarthost", $smarthost )
						]
					),
					$Cgi->td(
						[
							$main::text{lbl_username} . ":",
							$Cgi->textfield( "username", $username )
						]
					),
					$Cgi->td(
						[
							$main::text{lbl_password} . ":",
							$Cgi->password_field("password"),
						]
					)
				]
			),
		),
		$Cgi->hidden( "old_smarthost", $smarthost ),
	);
	print section_button( $Cgi->submit( "submit", $main::text{lbl_save} ) );
	print $Cgi->end_form();
	$Yaffas::UI::Print_inner_div = 1;
}

sub accept_domains_form {
	return if get_smarthost_routing();

	my @tmp = get_accept_domains();
	print $Cgi->start_form( "post", 'check_domains.cgi' );
	print value_add_del_form(
		{
			-header_name => $main::text{lbl_acceptdomains},
			-input_name  => 'domain',
			-del_name    => 'del',
			-content     => \@tmp,
			-del_label   => $main::text{lbl_del} . ":",
			-input_label => $main::text{lbl_maildomain} . ":"
		}
	);
	print $Cgi->end_form();
}

sub accept_relay_form {
	return if get_smarthost_routing();

	my @tmp = get_accept_relay();

	print $Cgi->start_form( "post", 'check_relay.cgi' );
	print value_add_del_form(
		{
			-header_name => $main::text{lbl_acceptrelay},
			-input_name  => 'ipaddr',
			-del_name    => 'del',
			-content     => \@tmp,
			-del_label   => $main::text{lbl_del} . ":",
			-input_label => $main::text{lbl_ip} . ":"
		}
	);
	print $Cgi->end_form();
}

sub archive_mails_form {
	my $archive_dest = get_archive();

	if ( defined( $main::in{archive_dest} ) ) {
		$archive_dest = $main::in{archive_dest};
	}

	print $Cgi->start_form( "post", 'check_archive.cgi' );
	print section(
		$main::text{lbl_archive},
		$Cgi->table(
			$Cgi->Tr(
				[
					$Cgi->td(
						[
							$main::text{lbl_enable_archive} . ":",
							$Cgi->checkbox(
								{
									-name  => "archive",
									-value => "",
									-label => "",
									(
										defined($archive_dest)
										? ( -checked => 1 )
										: ( -checked => 0 )
									),
								}
							)
						]
					),
					$Cgi->td(
						[
							$main::text{lbl_archive_destination} . ":",
							$Cgi->textfield(
								{
									-name  => "archive_dest",
									-value => $archive_dest,
								}
							),
						]
					)
				]
			)
		)
	);
	print section_button(
		$Cgi->submit( { -name => "submit", -value => $main::text{lbl_apply} } )
	);
	print $Cgi->end_form();
}

sub features_form {
	print Yaffas::UI::section(
		$main::text{lbl_mailsec},
		$Cgi->div( { -id => "table" }, "" ),
		$Cgi->div( { -id => "menu" },  "" )
	);
	return;
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
