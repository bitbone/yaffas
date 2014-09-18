#use strict;

use Yaffas;
use Yaffas::UI qw(start_section end_section section_button textfield radio_group scrolling_list);
use Yaffas::Product;
use Yaffas::Mail::Mailalias;
use Sort::Naturally;
use Sort::Naturally;

my @protocols = qw(pop3 pop2 imap imap-k4 imap-gss apop kpop);

sub show_polls {
	print Yaffas::UI::start_section($main::text{index_title});
	print $Cgi->div( { -id => "menubar" }, "" );
	print $Cgi->div( { -id => "table" },   "" );
	print $Cgi->div( { -id => "menu" },    "" );
	print $Cgi->div( { -style => "width: 500px; display: inline-block;" }, $Cgi->p($main::text{'lbl_check_logs'} ));
	print Yaffas::UI::end_section();
}

sub show_global_settings {
	my $file     = Yaffas::File->new( $main::config{config_file} );
	my $interval = 300;

	foreach my $line ( $file->get_content() ) {
		if ( $line =~ /^\s*set\s+daemon\s+(\d+)/ ) {
			$interval = $1;
			last;
		}
	}
	print $Cgi->start_form( { -action => "save_global.cgi" } );
	print $Cgi->hidden( { -name => "user", -value => $main::in{user} } );

	print Yaffas::UI::section(
		$main::text{lbl_settings},
		$Cgi->table(
			{ -id => "settings" },
			$Cgi->Tr(
				[
					$Cgi->td(
						[
							$main::text{poll_interval} . ":",
							textfield(
								{
									-name  => "interval",
									-value => $interval
								}
							)
						]
					)
				]
			)
		)
	);
	print $Cgi->hidden( { -name => "interface_def", -value => 1 } );
	print section_button(
		$Cgi->submit( { -name => "submit", -value => $main::text{lbl_save} } )
	);

	print $Cgi->end_form();
}

sub show_edit {

	my $new = shift;

	# List of users which won't be displayed in the target list
	my @sysaliases =
	  qw(backup bin cyrus daemon fetchmail ftp games gnats greylist irc list lp mailer-daemon mailflt man mysql news nobody noc postgres proxy security sshd sync sys usenet uucp www www-data Debian-exim mail);

	# create a list of local aliases...
	my $user_alias = Yaffas::Mail::Mailalias::list_alias("USER");
	my $mail_alias = Yaffas::Mail::Mailalias::list_alias("MAIL");
	my $dir_alias  = Yaffas::Mail::Mailalias::list_alias("DIR");
	my %local_aliases = ( %{$user_alias}, %{$mail_alias}, %{$dir_alias} );

	# ... and users
	my %local_users = map( { $_ => $_ } Yaffas::UGM::get_users() );

	# Remove Blacklisted Users and Aliases from the list
	foreach my $delkey (@sysaliases) {
		delete $local_aliases{$delkey};
		delete $local_users{$delkey};
	}

	my $poll = {};
	if ( $new == 0 ) {
		my @conf = &parse_config_file("/etc/fetchmailrc");
		$poll = $conf[ $main::in{'idx'} ];
	}

	my @interface = split( /\//, $poll->{'interface'} );

	print $Cgi->start_form( -action => 'save_poll.cgi', -method => 'post' );

	print start_section( $new ? $main::text{poll_header}: $main::text{poll_edit} ),
	  $Cgi->hidden( 'new',  $new ),
	  $Cgi->hidden( 'idx',  $main::in{'idx'} ),
	  $Cgi->hidden( 'file', $file ),
	  $Cgi->hidden( 'user', $main::in{'user'} ), $Cgi->table(
		$Cgi->Tr(
			{ -style => 'vertical-align: top;' },
			[
				$Cgi->td(
					[
						$main::text{'poll_poll'},
						textfield( 'poll', $poll->{'poll'} )
					]
				),
				$Cgi->td(
					[
						$main::text{'poll_skip'},
						scalar radio_group(
							{
								-name   => "skip",
								-value  => [ 0, 1 ],
								-labels => {
									0 => $main::text{yes},
									1 => $main::text{no}
								},
								-linebreak => 'true',
								-default   => $poll->{skip} ? 1 : 0,
							}
						)
					]
				),
				$Cgi->td(
					[
						$main::text{'poll_via'},
						$Cgi->input(
							{
								-type  => 'radio',
								-name  => 'via_def',
								-value => 1,
								(
									$poll->{'via'} ? ''
									: ( -checked => 'checked' )
								)
							}
						  )
						  . $main::text{'poll_via_def'}
						  . $Cgi->br()
						  . $Cgi->input(
							{
								-type  => 'radio',
								-name  => 'via_def',
								-value => 0,
								(
									$poll->{'via'} ? ( -checked => 'checked' )
									: ''
								)
							}
						  )
						  . textfield( 'via', $poll->{'via'} )
					]
				),
				$Cgi->td(
					[
						$main::text{'poll_proto'},
						scrolling_list(
							{
								-name   => 'proto',
								-size => 1,
								-values => \@protocols,
								-labels => {
									map {
										$_ => (
											!$_ ? $main::text{default}
											: uc($_)
										  )
									  } @protocols
								},
								-default => (
									  $poll->{'proto'} ? lc $poll->{'proto'}
									: $main::text{'default'}
								)
							}
						)
					]
				),
				$Cgi->td(
					[
						$main::text{'poll_port'},
						$Cgi->input(
							{
								-type  => 'radio',
								-name  => 'port_def',
								-value => 1,
								(
									$poll->{'port'} ? ""
									: ( -checked => 'checked' )
								)
							}
						  )
						  . $main::text{'default'}
						  . $Cgi->br()
						  . $Cgi->input(
							{
								-type  => 'radio',
								-name  => 'port_def',
								-value => 0,
								(
									$poll->{'port'} ? ( -checked => 'checked' )
									: ""
								)
							}
						  )
						  . textfield( 'port', $poll->{'port'} )
					]
				),
				$Cgi->td(
					[
						$main::text{'poll_envelope'},
						textfield( 'envelope', $poll->{'envelope'} )
					]
				),
			]
		)
	  );

	my @users;
	@users = @{ $poll->{'users'} } if ( $poll->{users} );
	push( @users, undef );    # if ( $new || $main::in{'edituser'} );
	my $i = 0;

	print $Cgi->h2( $main::text{'poll_uheader'} );

	foreach my $u (@users) {
		my $style = "";
		my $id    = "";
		if ( scalar @users > 1 and not defined $u ) {
			$style = "display: none;";
			$id    = "template-" . $main::in{'idx'};
		}
		if ( scalar @users > 1 && $i == scalar @users - 1 ) {
			$i = "";
		}
		print $Cgi->table(
			{ -style => $style, -id => $id },
			$Cgi->Tr(
				$Cgi->td(
					{ -colspan => 2 },
					$Cgi->hr(
						{
							-style => ( $i == 0 || $i eq "" ) ? "display: none;"
							: ""
						}
					)
				)
			),
			$Cgi->Tr(
				{ -style => 'vertical-align: top;' },
				$Cgi->td( $main::text{'poll_user'} ),
				$Cgi->td( textfield( "user_$i", $u->{'user'} ) ),
			),
			$Cgi->Tr(
				{ -style => 'vertical-align: top;' },
				$Cgi->td( $main::text{'poll_pass'} ),
				$Cgi->td( $Cgi->password_field( "pass_$i", $u->{'pass'} ) ),
			),
			$Cgi->Tr(
				{ -style => 'vertical-align: top;' },
				$Cgi->td( $main::text{'lbl_target'} ),
				$Cgi->td(
					$Cgi->table(
						$Cgi->Tr(
							$Cgi->td(
								$Cgi->input(
									{
										-type  => 'radio',
										-name  => "type_$i",
										-value => 'local_user',
										(
											(
												exists( $local_users{ (Yaffas::LDAP::search_user_by_attribute("email", $u->{'is'}[0]))[0] })
											) ? ( -checked => 'checked' )
											: ('')
										)
									}
								),
								$main::text{'lbl_local_user'} . ": "
							),
							$Cgi->td(
								$Cgi->scrolling_list(
									{
										-size => 1,
										-name    => "local_user_" . $i,
										-values  => [ nsort keys %local_users ],
										-default => Yaffas::LDAP::search_user_by_attribute("email", $u->{'is'}[0]),
									}
								)
							),
						),
						$Cgi->Tr(
							$Cgi->td(
								$Cgi->input(
									{
										-type  => 'radio',
										-name  => "type_$i",
										-value => 'local_alias',
										(
											(
												exists(
													$local_aliases{ $u->{'is'}
														  [0] }
												)
											) ? ( -checked => 'checked' )
											: ('')
										)
									}
								),
								$main::text{'lbl_local_alias'} . ": "
							),
							$Cgi->td(
								scrolling_list(
									{
										-size => 1,
										-name => "alias_" . $i,
										-values =>
										  [ nsort keys %local_aliases ],
										-default => $u->{'is'}[0],
									}
								)
							),
						),
						$Cgi->Tr(
							$Cgi->td(
								$Cgi->input(
									{
										-type  => 'radio',
										-name  => "type_$i",
										-value => 'address',
										(
											(
												!$new &&
												defined($u) &&
												$id !~ /^template-/ &&
												!exists(
													$local_aliases{ $u->{'is'}
														  [0] }
												) &&
												!exists( $local_users{ (Yaffas::LDAP::search_user_by_attribute("email", $u->{'is'}[0]))[0] }) &&
												$u->{'is'}[0] ne "*"
											) ? ( -checked => 'checked' )
											: ('')
										)
									}
								),
								$main::text{'lbl_address'} . ": "
							),
							$Cgi->td(
								textfield(
									{
										-size => 20,
										-name => "address_" . $i,
										-value => $u->{'is'}[0],
									}
								)
							),
						),
						$Cgi->Tr(
							$Cgi->td(
								$Cgi->input(
									{
										-type     => 'radio',
										-name     => "type_$i",
										-value    => 'multidrop',
										-selected => (
											  ( $u->{'is'}[0] eq "*" )
											? ( -checked => 'checked' )
											: ('')
										)
									}
								),
								$main::text{'lbl_multidrop'}
							),
							$Cgi->td("&nbsp;"),
						),
					),
				),
			),
			$Cgi->Tr(
				$Cgi->td(
					[
						$main::text{'poll_smtpaddress'},
						textfield( "smtpaddress_$i", $u->{'smtpaddress'} )
					]
				)
			),
			$Cgi->Tr(
				$Cgi->td( $main::text{'poll_keep'} ),
				$Cgi->td(scalar radio_group({
					-type  => 'radio',
					-name  => "keep_$i",
					-value => [1, 0],
					-labels => {
						0 => $main::text{no},
						1 => $main::text{yes},
					},
					-default => defined $u->{'keep'} ? $u->{'keep'} : 0
				})),
			),
			$Cgi->Tr(
				$Cgi->td( $main::text{'poll_fetchall'} ),
				$Cgi->td(scalar radio_group({
					-type  => 'radio',
					-name  => "fetchall_$i",
					-value => [1, 0],
					-labels => {
						0 => $main::text{no},
						1 => $main::text{yes},
					},
					-default =>
						defined $u->{'fetchall'} ? $u->{'fetchall'} : 0
				})),
			),
			$Cgi->Tr(
				$Cgi->td( $main::text{'poll_ssl'} ),
				$Cgi->td(
					scalar radio_group({
						-type  => 'radio',
						-name  => "ssl_$i",
						-value => [1, 0],
						-labels => {
							0 => $main::text{'no'},
							1 => $main::text{'yes'},
						},
						-default => defined $u->{'ssl'} ? $u->{'ssl'} : 0
					})
				),
			),
		);
		$i++;
	}
	print end_section();

	if ($new) {
		print section_button( $Cgi->submit( 'submit', $main::text{'create'} ) );
	}
	else {
		print section_button(
			$Cgi->submit( 'submit', $main::text{'save'} ),
			$Cgi->button(
				{
					-id    => 'adduser-' . $main::in{'idx'},
					-label => $main::text{'poll_adduser'}
				}
			)
		);
	}

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
