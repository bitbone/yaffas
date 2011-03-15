#!/usr/bin/perl
# unixsockets.cgi
# Written by Pascal Gauthier (belzebuth@destination.ca)
# (c) under GPL License

require './sysinfo-lib.pl';
&header($text{'network_unixsockets'}, "", undef, 0, 0, "", "");

####################### 
#  ACTIVE CONNECTION  #
#######################
local (@connections, $active, $i);

@connection = &list_connections("unixsockets");

$Yaffas::UI::Print_inner_div = 0;
print Yaffas::UI::section($text{'network_opensockets_active'},
						  Yaffas::UI::table(
											$Cgi->Tr(
													 $Cgi->th({-style=>"width: 30%"},
															  [
															  $text{'network_unixsockets_protocol'},
															  $text{'network_unixsockets_refcnt'},
															  $text{'network_unixsockets_flags'},
															  $text{'network_unixsockets_type'},
															  $text{'network_unixsockets_state'},
															  $text{'network_unixsockets_inode'},
															  $text{'network_unixsockets_path'}
															  ]
															 ),
													),
											$Cgi->Tr(
													 [
													 map { $Cgi->td(
																	[
																	$_->{protocol},
																	$_->{refcnt},
																	$_->{flags},
																	$_->{type},
																	$_->{state},
																	$_->{inode},
																	$_->{path}
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
#print "<br><br><hr>";
footer("network.cgi", $text{'index'});
