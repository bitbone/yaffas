#!/usr/bin/perl
# who.cgi
# Written by Pascal Gauthier (belzebuth@destination.ca)
# (c) under GPL License

require './sysinfo-lib.pl';
header ($text{'network_who'}, "", undef, 0, 0, "", "");

####################### 
#  ACTIVE CONNECTION  #
#######################
local (@connected_users, $who);

@connected_users = &who();

shift @connected_users;

$Yaffas::UI::Print_inner_div = 0;
print Yaffas::UI::section($text{'network_who'},
						  Yaffas::UI::table(
											$Cgi->Tr(
													 $Cgi->th({-style=>"width: 30%"},
															  [
															  $text{'network_who_user'},
															  $text{'network_who_tty'},
															  $text{'network_who_from'},
															  $text{'network_who_login'},
															  $text{'network_who_idle'},
															  $text{'network_who_jcpu'},
															  $text{'network_who_pcpu'},
															  $text{'network_who_what'}
															  ]
															  ),
													),
											$Cgi->Tr(
													 [
													 map { $Cgi->td(
																	[
																	$_->{users},
																	$_->{tty},
																	$_->{from},
																	$_->{at},
																	$_->{idle},
																	$_->{jcpu},
																	$_->{pcpu},
																	$_->{what}
																	]
																   )
													 } @connected_users
													 ]
													)
										   )
						 );

#########
#--END--#
#########

footer("network.cgi", $text{'index'});
