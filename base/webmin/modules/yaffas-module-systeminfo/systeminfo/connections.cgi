#!/usr/bin/perl
# connections.cgi
# Written by Pascal Gauthier (belzebuth@destination.ca)
# (c) under GPL License

require './sysinfo-lib.pl';
&header($text{'network_connection'}, "", undef, 0, 0, "", "");

####################### 
#  ACTIVE CONNECTION  #
#######################
local (@connections, $active);

@connection = &list_connections("connections");


$Yaffas::UI::Print_inner_div = 0;
print Yaffas::UI::section($text{'network_connection'},
						  Yaffas::UI::table(
											$Cgi->Tr(
													 $Cgi->th({-style=>"width: 30%"},
															  [
															  $text{'network_connection_protocol'},
															  $text{'network_connection_recvq'},
															  $text{'network_connection_sendq'},
															  $text{'network_connection_localaddr'},
															  $text{'network_connection_foreignaddr'},
															  $text{'network_connection_state'}
															  ]
															 ),
													),
											$Cgi->Tr(
													 [
													 map { $Cgi->td(
																	[
																	$_->{protocol},
																	$_->{recv},
																	$_->{send},
																	$_->{local},
																	$_->{foreign},
																	$_->{state}
																	]
																   )
													 } @connection
													 ]
													)
										   )
						 );


#########
#--END--#
#########
footer("network.cgi", $text{'index'});
