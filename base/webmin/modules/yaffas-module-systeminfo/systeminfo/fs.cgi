#!/usr/bin/perl
# fs.cgi
# Written by Pascal Gauthier (belzebuth@destination.ca)
# (c) under GPL License

require './sysinfo-lib.pl';
header($text{'fs_stat'}, "", undef, 0, 0, "", "");


####################### 
#      MOUNTED FS     #
#######################
my (@fsmount, $i, $fs);

@fsmount = fsmount();

$Yaffas::UI::Print_inner_div = 0;
print Yaffas::UI::section($text{fs_stat},
						  Yaffas::UI::table(
											$Cgi->Tr(
													 $Cgi->th(
															  [
															  $text{'fs_mount_device'},
															  $text{'fs_mount_dir'},
															  $text{'fs_mount_type'},
															  $text{'fs_mount_option'}
															  ]
															 )
													),
											$Cgi->Tr(
													 [
													 map { $Cgi->td(
																	[
																	$_->{device},
																	$_->{directory},
																	$_->{fstype},
																	$_->{mode}
																	]
																	)
													 } @fsmount
													 ]
													 )
										   )
						 );

#########
#--END--#
#########
footer("/systeminfo", $text{'index'});
