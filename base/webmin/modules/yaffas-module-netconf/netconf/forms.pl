use strict;
use warnings;

use Yaffas;
use Yaffas::UI qw(value_add_del_form $Cgi small_form textfield);
use Yaffas::Module::Netconf;
use Sort::Naturally;
use Data::Dumper;
use Yaffas::Auth;
use Yaffas::Auth::Type;
use Error qw(:try);
use Yaffas::Exception;
use Yaffas::Module::Proxy;

sub net_conf_form () {
	try {
		my $conf = Yaffas::Module::Netconf->new();

		print $Cgi->start_form( { -action => "check_settings.cgi" } );

		$Yaffas::UI::Print_inner_div = 0;

		print Yaffas::UI::section(
			$main::text{lbl_base_settings},
			$Cgi->table(
				$Cgi->Tr(
					[
						_input_td( "hostname", $conf->hostname(),   1 ),
						_input_td( "domain",   $conf->domainname(), 1 ),
						(
							Yaffas::Auth::auth_type() ne Yaffas::Auth::Type::ADS
						  )
						? _input_td( "workgroup", $conf->workgroup(), 1 )
						: undef,
					]
				)
			)
		);
		

		print Yaffas::UI::section_button(
			$Cgi->submit( { -value => $main::text{lbl_save} } ) );
		print $Cgi->end_form();
		
		proxy_form();

		print map {
			my $dev = $conf->device($_);

			$Cgi->start_form( { -action => "check_settings.cgi" } )
			  . Yaffas::UI::section(
				$main::text{lbl_interface} . " $_",
				$Cgi->table(
					$Cgi->Tr(
						[

							$_ =~ /^eth\d+$/
							? (
								$Cgi->td("MAC Adresse:")
								  . $Cgi->td( { -colspan => 3 }, $dev->{MAC} ),
								$Cgi->td("Hersteller:")
								  . $Cgi->td( { -colspan => 3 },
									$dev->{VENDOR} ),
								$Cgi->td("Produkt:")
								  . $Cgi->td(
									{ -colspan => 3 }, $dev->{PRODUCT}
								  )
							  )
							: "",
							_input_status( "$_-enabled", $dev->enabled() ),
							_input_td(
								"$_-ipaddr", $dev->get_ip(),
								$dev->enabled()
							),
							_input_td(
								"$_-netmask", $dev->get_netmask(),
								$dev->enabled()
							),
							_input_td(
								"$_-gateway", $dev->get_gateway(),
								$dev->enabled()
							),
							$_ !~ /^eth\d+:\d+$/ ? (
								_input_td(
									"$_-dns", $dev->get_dns(), $dev->enabled()
								),
								_input_td(
									"$_-search", $dev->get_search(),
									$dev->enabled()
								),
							) : "",
							$Cgi->td(
								  $_ =~ /^eth\d+$/
								? $dev->enabled()
									  ? $Cgi->button(
										  {
										  		-id=>"newip-$_",
										  		-label => $main::text{lbl_new_ip}
										  },
									  )
									  : ""
								: $Cgi->button(
									{
										-id=>"delete-$_",
										-label => $main::text{lbl_delete_device}
									},
								)
							)
						]
					)
				),
			  )
			  . Yaffas::UI::section_button(
				$Cgi->submit( { -value => $main::text{lbl_save} } ) )
			  . $Cgi->end_form()

		} grep { $_ ne "lo" } sort $conf->get_all_names();

		#						 );

	}
	catch Yaffas::Exception with {
		print Yaffas::UI::all_error_box(shift);
	};
}

sub virtual_card_form ($) {
	my $device = shift;

	$device = $main::in{device} if ( defined( $main::in{device} ) );

	print $Cgi->start_form( { -action => "check_settings.cgi" } );

	$Yaffas::UI::Print_inner_div = 0;
	print $Cgi->hidden( { -name => "device", -value => $device } );
	print $Cgi->hidden( { -name => "mode",   -value => "new" } );
	print Yaffas::UI::section(
		$main::text{lbl_new_interface} . " $device",
		$Cgi->table(
			$Cgi->Tr(
				[
					_input_td( "new-ipaddr",  "", 1 ),
					_input_td( "new-netmask", "", 1 ),
					_input_td( "new-gateway", "", 1 ),
				]
			)
		)
	);
	print Yaffas::UI::section_button(
		$Cgi->submit( { -value => $main::text{lbl_create} } ) );
	print $Cgi->end_form();
}

sub delete_virtual_card_form ($) {
	my $device = shift;

	$Yaffas::UI::Convert_nl = 0;
	print Yaffas::UI::yn_confirm(
		{
			-action => "check_settings.cgi",
			-hidden => [ device => $device, mode => "delete" ],
			-title  => $main::text{lbl_delete_device},
			-yes    => $main::text{lbl_yes},
			-no     => $main::text{lbl_no},
		},
		$main::text{lbl_really_delete} . $Cgi->ul( $Cgi->li($device) )
	);
}

sub _input_td($$) {
	my $name      = shift;
	my $value     = shift;
	my $enabled   = shift;
	my $old_value = $value;

	my @disabled = ();
	if ( !$enabled ) {
		@disabled = qw(-style color:grey;);
	}
	else {
		@disabled = qw(-style color:black;);
	}

	if (   defined( $main::in{ $name . "-2" } )
		or defined( $main::in{ $name . "-1" } ) )
	{
		$value = [];
		$value->[0] = $main::in{$name} if ( defined( $main::in{$name} ) );
		$value->[1] = $main::in{ $name . "-1" }
		  if ( defined( $main::in{ $name . "-1" } ) );
		$value->[2] = $main::in{ $name . "-2" }
		  if ( defined( $main::in{ $name . "-2" } ) );
	}
	else {
		$value = $main::in{$name} if ( defined( $main::in{$name} ) );
	}

	my $textname = $name;
	$textname =~ s/.*-([^-]+)/$1/;

	my @values = ();

	if ( ref $value eq "ARRAY" ) {
		push @values, @{$value};
	}
	else {
		push @values, $value;
	}

	return $Cgi->td(
		[
			$main::text{"lbl_$textname"} . ":",
			textfield(
				{ -name => $name, -value => $values[0], @disabled }
			),
			( $textname eq "dns" or $textname eq "search" )
			? (
				textfield(
					{ -name => "$name-1", -value => $values[1], @disabled }
				),
				textfield(
					{ -name => "$name-2", -value => $values[2], @disabled }
				)
			  )
			: "",
		]
	);
}

sub _input_status($$) {
	my $name  = shift;
	my $value = shift;

	$value = $main::in{$name} if ( defined( $main::in{$name} ) );

	my $textname = $name;
	$textname =~ s/([^-]+)-.*/$1/;
	my $dev = $1;

	my $javascript = '
	var fields = Array("' 
	  . $dev
	  . '-ipaddr", "'
	  . $dev
	  . '-netmask", "'
	  . $dev
	  . '-gateway", "'
	  . $dev
	  . '-dns", "'
	  . $dev
	  . '-dns-1", "'
	  . $dev
	  . '-dns-2", "'
	  . $dev
	  . '-search", "'
	  . $dev
	  . '-search-1", "'
	  . $dev
	  . '-search-2");
	for (var i = 0; i < fields.length; ++i) {
		var e = document.getElementsByName(fields[i])[0];
		if (e.style.color == "black") {
			e.style.color="grey";
		} else {
			e.style.color="black";
		}
	}';

	return $Cgi->td(
		[
			$main::text{"lbl_status"} . ":",
			join "",
			$Cgi->scrolling_list(
				-onChange => "javascript:$javascript",
				-name     => $name,
				-values   => [ 0, 1 ],
				-labels   => {
					0 => $main::text{lbl_disabled},
					1 => $main::text{lbl_enabled}
				},
				-default => $value,
				-size    => 1,
			)
		]

	);
}

sub proxy_form() {
	my($user, $pass, $proxy, $port) = Yaffas::Module::Proxy::get_proxy();
	$pass = "";

	if (@_) {
		($user, $pass, $proxy, $port) = @_;
	}

	print $Cgi->start_form("post", "setproxy.cgi");
	$Yaffas::UI::Print_inner_div = 0;
	print Yaffas::UI::section($main::text{lbl_proxy_conf},
				  $Cgi->table(
							  $Cgi->Tr([
										$Cgi->td([
												  $main::text{lbl_proxy_ip} . ":" ,
												  textfield("proxy", $proxy, 20),
												 ]),
										$Cgi->td([
												  $main::text{lbl_proxy_port} . ":" ,
												  textfield("port", $port, 4),
												 ]),
									   ])
							 ),
				  $Cgi->h2($main::text{lbl_authentication}),
				  $Cgi->table(
							  $Cgi->Tr([
										$Cgi->td([
												  $main::text{lbl_user} . ":" ,
												  textfield("user", $user, 10),
												 ]),
										$Cgi->td([
												  $main::text{lbl_pass} . ":" ,
												  $Cgi->password_field("pass", $pass, 10),
												 ]),
									   ]),
									   ),
				 );
	print Yaffas::UI::section_button($Cgi->submit({-value => $main::text{lbl_save}}));
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
