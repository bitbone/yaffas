#!/usr/bin/perl
# memory.cgi
# Written by Pascal Gauthier (belzebuth@destination.ca)
# (c) under GPL License

require './sysinfo-lib.pl';
&header($text{'memory_usage'}, "", undef, 0, 0, "", "");


####################### 
#    MEMORY USAGE     #
#######################
local (@memstat, $meminfo);

$meminfo = &meminfo();

$Yaffas::UI::Print_inner_div = 0;
print Yaffas::UI::section($text{memory_usage},
						  Yaffas::UI::table(
											$Cgi->Tr(
													 [
													 $Cgi->th(
															  [
															  "",
															  $text{mem_total},
															  $text{mem_used},
															  $text{mem_free},
															  $text{mem_shared},
															  $text{mem_buffers},
															  $text{mem_cache}
															  ]
															 ),
													 $Cgi->td(
															  [
															  $text{main_memory},
															  $meminfo->{mem_total},
															  $meminfo->{mem_used},
															  $meminfo->{mem_free},
															  $meminfo->{mem_shared},
															  $meminfo->{mem_buffers},
															  $meminfo->{mem_cached}
															  ]
															 ),
													 $Cgi->td(
															  [
															  $text{swap_memory},
															  $meminfo->{swap_total},
															  $meminfo->{swap_used},
															  $meminfo->{swap_free},
															  "--",
															  "--",
															  "--"
															  ]
															 )
													 ]
													)
										   )
						 );


=pod
print "<br>\n ";
print "<h3>$text{'memory_usage'}</h3>";
print "<table border width=100%>\n";
print "<tr $tb> <th> <th>$text{'mem_total'} <th>$text{'mem_used'} <th>$text{'mem_free'} <th>$text{'mem_shared'} <th>$text{'mem_buffers'} <th>$text{'mem_cache'}\n";
print "<tr $cb><th $tb>$text{'main_memory'} <td>$meminfo->{'mem_total'} <td>$meminfo->{'mem_used'} <td>$meminfo->{'mem_free'} <td>$meminfo->{'mem_shared'} <td>$meminfo->{'mem_buffers'} <td>$meminfo->{'mem_cached'}\n";
print "<tr $cb><th $tb>$text{'swap_memory'} <td>$meminfo->{'swap_total'} <td>$meminfo->{'swap_used'} <td>$meminfo->{'swap_free'} <td>-- <td>-- <td>--\n";
print "</table>\n";
print $i;
=cut


####################### 
#    LOADED MODULES   #
#######################
my (@modlist, $i, $lsmod);

@modlist = &list_modules();

print Yaffas::UI::section($text{mem_current_modules},
						  Yaffas::UI::table(
											$Cgi->Tr(
													 $Cgi->th(
															  [
															  $text{mem_module},
															  $text{mem_module_size},
															  $text{mem_module_depend}
															  ]
															 )
													),
											$Cgi->Tr(
													 [
													 map { $Cgi->td(
																   [
																   $_->{module_name},
																   $_->{module_size},
																   $_->{module_referring}
																   ]
																  )
													 } @modlist
													 ]
													)
										   ),
						 );


=pod
print "<br><br><br> \n";
print "<h3>$text{'mem_current_modules'}</h3> \n";
print "<table border width=100%> \n";
print "<tr $tb><th>$text{'mem_module'} <th>$text{'mem_module_size'} <th>$text{'mem_module_depend'} \n";
for($i=0; $i<@modlist; $i++) {
    $lsmod = $modlist[$i];
    print "<tr $cb><td>$lsmod->{'module_name'} <td>$lsmod->{'module_size'} <td>$lsmod->{'module_referring'} \n";
};
print "</table> \n";
=cut

#########
#--END--#
#########
#print "<br><br><hr>";

footer("/systeminfo", $text{'index'});
