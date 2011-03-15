#!/usr/bin/perl
# index.cgi
# Written by Pascal Gauthier (belzebuth@destination.ca)
# (c) under GPL License
# Added memory and filesystem graphs
# and prettied everything up.--Joe Cooper <joe@swelltech.com>

use Yaffas::UI;

do '../web-lib.pl';
require './sysinfo-lib.pl';
&init_config();

&header($text{'index_title'}, "", "intro", 1, 1, "", "");

# refresh every $idx_refresh seconds

if ($config{'idx_refresh'} > 0)
{
  print qq~<meta http-equiv="refresh" content="$config{'idx_refresh'}"\n~;
};

####################### 
#    GENERAL INFO     #
#######################
local ($meminfo, $osinfo, $cpu, $load);

$osinfo = &os_info();
$cpu = &cpu_info();
$load = &loadavg_uptime();

$Yaffas::UI::Print_inner_div = 0;
print Yaffas::UI::section($text{'general_information'},
						  Yaffas::UI::table(
											$Cgi->Tr(
													 $Cgi->td(
															  $osinfo{'ostype'},
															  $osinfo{'osrelease'},
															  $text{'os_on_arch'},
															  $cpu{'arch'}
															 ),
													 $Cgi->td($cpu{'smp_level'},
															  "CPU",
															  $cpu{'name_arch'}
															 ),
													),
											$Cgi->Tr(
													 $Cgi->td(
															  $osinfo{'hostname'},
															  "@",
															  $osinfo{'domainname'}
															 ),
													 $Cgi->td(
															  $load{totalhours} >= 1 ?
															  (
															   $load{updays} >= 1 ?
															   sprintf("%s %u %s %02u:%02u %s",
																	   $text{'uptime'},
																	   $load{'updays'},
																	   $text{'uptime_days'},
																	   $load{'uphours'},
																	   $load{'upminutes'},
																	   $text{'uptime_hours'}
																	  )
															   :
															   sprintf("%s %02u:%02u %s",
																	   $text{'uptime'},
																	   $load{'uphours'},
																	   $load{'upminutes'},
																	   $text{'uptime_hours'}
																	  )
															  )

															  :

															  (
															   $load{updays} >= 1 ?
															   sprintf("%s %02u:%02u %s",
																	   $text{'uptime'},
																	   $load{'updays'},
																	   $text{'uptime_days'},
																	   $load{'upminutes'},
																	   $text{'uptime_minutes'}
																	  )
															   :
															   sprintf("%s 00:%02u %s",
																	   $text{'uptime'},
																	   $load{'upminutes'},
																	   $text{'uptime_minutes'}
																	  )
															  )


															 )
													),

											)
											);

#######################
#     LOADAVERAGE     #
#######################

print Yaffas::UI::section($text{'loadavg_title'},
						  Yaffas::UI::table(
											$Cgi->Tr(
													 [
													 $Cgi->th(
															  [
															  $text{'loadavg_title'},
															  $text{'loadavg_graph'},
															  $text{'loadavg_proc'}
															  ]
															 ),
													 $Cgi->td(
															  [
															  $text{'loadavg_1'},
															  bar_graph($load{'bar_1'}),
															  $load{'one'}
															  ]
															 ),

													 $Cgi->td(
															  [
															  $text{'loadavg_5'},
															  bar_graph($load{'bar_5'}),
															  $load{'five'}
															  ]
															  ),
													 $Cgi->td(
															  [
															  $text{'loadavg_15'},
															  bar_graph($load{'bar_15'}),
															  $load{'fifteen'}
															  ]
															  )
													 ]
													)
										   )
						 );

#######################
#    MEMORYUSAGE      #
#######################

my (@memstat, $meminfo);

$meminfo = &meminfo();
$membuffcachepercent = 100 * (($meminfo->{'mem_cached'} + $meminfo->{'mem_buffers'}) / $meminfo->{'mem_total'});
$memfreepercent = 100 * ($meminfo->{'mem_free'} / $meminfo->{'mem_total'});
$memusedpercent = 100 - ($membuffcachepercent + $memfreepercent);

print Yaffas::UI::section($text{'memory_usage'},
						  Yaffas::UI::table(
											$Cgi->Tr(
													 $Cgi->th({-style=>"width: 20%"},
															  $text{'mem_avail'},
															 ),
													 $Cgi->th({-style=>"width: 80%"}, preview_bar("red")." = $text{'memkey_inuse'}",
													 preview_bar("yellow")." = $text{'memkey_buffer'}",
													 preview_bar("green")." = $text{'memkey_free'}")
													),
											$Cgi->Tr(
													 $Cgi->td(
															  [
															  (sprintf "%.2f", ($meminfo->{'mem_total'}/1024))." MB",
															  bar_graph($memusedpercent, $membuffcachepercent, $memfreepercent)
															  ]
															 )
													)
										   )
						 );


sub preview_bar($) {
	my $color = shift;

	my $ret;
	$ret .= $Cgi->span( {-style=>"width: 10px; height: 1em; vertical-align: middle; background-color: $color;"}, "&nbsp;&nbsp;");
	$ret .= $Cgi->span( "&nbsp;" );
	return $ret;

}


#######################
#    DRIVESPACE       #
#######################
my @df_lines = disk_free();


print Yaffas::UI::section($text{'df_title'},
						  Yaffas::UI::table(
											$Cgi->Tr(
													 $Cgi->th(
															  [
															  split /\s+/, shift @df_lines, 6
															  ]
															 ),
													),
											$Cgi->Tr(
													 [
													 map {$Cgi->td([split /\s+/, $_, 6])} @df_lines
													 ]
													)
										   )
						 );


#######################
#      LOAD ICONS     #
#######################

@links = ("network.cgi", "memory.cgi", "fs.cgi", "irq.cgi");
@titles = ($text{'network_load'}, $text{'memory_usage'} ,$text{'fs_stat'}, $text{'irq_usage'});
@icons = ("images/network.gif", "images/mem.gif", "images/fs.gif", "images/irq.gif");
icons_table(\@links, \@titles, \@icons);


footer("/", $text{'index'});

