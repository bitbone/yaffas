#!/usr/bin/perl
# network.cgi
# Written by Pascal Gauthier (belzebuth@destination.ca)
# (c) under GPL License

use Yaffas::UI;
require './sysinfo-lib.pl';
header($text{'network_load'}, "", undef, 0, 0, "", "");


####################### 
#    NETWORK LOAD     #
#######################
local (@netstat, $i, $nic);

@netstat = &net_load();


$Yaffas::UI::Print_inner_div = 0;
print Yaffas::UI::section($text{'network_load'}." - ".$text{'network_receive'},
						  Yaffas::UI::table(
											$Cgi->Tr(
													 [
													 $Cgi->th(
															  [
															  $text{'network_nic'},
															  $text{'network_bytes'},
															  $text{'network_errors'},
															  $text{'network_dropped'},
															  $text{'network_frame'}
															  ]
															 ),
													 ]
													),
											$Cgi->Tr(
													 [
													 map { $Cgi->td(
																	[
																	$_->{interface},
																	$_->{r_bytes},
																	$_->{r_errors},
																	$_->{r_dropped},
																	$_->{r_frame}
																   
																	]
																   ) 
													 } @netstat
													 ]
													)
										   )
						 );

print Yaffas::UI::section($text{'network_load'}." - ".$text{'network_send'},
						  Yaffas::UI::table(
											$Cgi->Tr(
													 $Cgi->th({-style=>"width: 30%"},
															  [
															  $text{'network_nic'},
															  $text{'network_bytes'},
															  $text{'network_errors'},
															  $text{'network_dropped'},
															  $text{'network_carrier'},
															  $text{'network_collisions'}
															  ]
															 ),
													),
											$Cgi->Tr(
													 [
													 map { $Cgi->td(
																	[
																	$_->{interface},
																	$_->{s_bytes},
																	$_->{s_errors},
																	$_->{s_dropped},
																	$_->{s_carrier},
																	$_->{s_collisions}
																	]
																   )
													 } @netstat
													 ]
													)
										   )
						 );


####################### 
#      LOAD ICONS     #
#######################

@links = ("connections.cgi", "unixsockets.cgi", "opensockets.cgi", "who.cgi");
@titles = ($text{'network_connection'}, $text{'network_unixsockets'}, $text{'network_opensockets'}, $text{'network_who'});
@icons = ("images/connections.gif", "images/usockets.gif", "images/sockets.gif", "images/who.gif");

icons_table(\@links, \@titles, \@icons, 4);

#########
#--END--#
#########
footer("/systeminfo", $text{'index'});
