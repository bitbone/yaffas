#!/usr/bin/perl
# irq.cgi
# Written by Pascal Gauthier (belzebuth@destination.ca)
# (c) under GPL License

use Yaffas::UI;

require './sysinfo-lib.pl';
header($text{'irq_usage'}, "", undef, 0, 0, "", "");

use Data::Dumper;


#######################
#      IRQ USAGE      #
#######################
my (%irqlist, $i, $j, $irq);

%irqlist = list_irq();

$Yaffas::UI::Print_inner_div = 0;
print Yaffas::UI::section($text{irq_usage},
						  Yaffas::UI::table(
											$Cgi->Tr(
													 $Cgi->th(
															  [
															  "IRQ",
															  $text{irq_device}
															  ]
															  )
													 ),
											$Cgi->Tr(
													 [
													 map {
													 defined($irqlist{$_}) ? $Cgi->td([$_, $irqlist{$_}]) : ""
													 } (0..15)
													 ]
													)
										   )
						 );



#######################
#       IO USAGE      #
#######################
my (@iolist, $iolist_left, $iolist_right , $i);

@iolist = list_ioports();

print Yaffas::UI::section($text{irq_ioports},
						  Yaffas::UI::table(
											$Cgi->Tr(
													 $Cgi->th(
															  [
															  "IO Ports",
															  "Device"
															  ]
															  )
													),
											$Cgi->Tr(
													 [
													 map { $Cgi->td(
																	[
																	$_->{ioport},
																	$_->{device}
																	]
																   )
													 } @iolist
													 ]
													)
										   )
						 );


#########
#--END--#
#########
footer("/systeminfo", $text{'index'});
