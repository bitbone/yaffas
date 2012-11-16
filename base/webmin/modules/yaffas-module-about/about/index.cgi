#!/usr/bin/perl
# index.cgi

use Yaffas;
use CGI::Carp qw(warningsToBrowser fatalsToBrowser);

Yaffas::init_webmin();

require './forms.pl';

use CGI::Carp qw(fatalsToBrowser);
use strict;
use warnings;

header($main::text{lbl_index_header}, "");

show_panels();
#show_about();

footer("/", $main::text{lbl_index_return});




#!/usr/bin/perl
# index.cgi
# Written by Pascal Gauthier (belzebuth@destination.ca)
# (c) under GPL License
# Added memory and filesystem graphs
# and prettied everything up.--Joe Cooper <joe@swelltech.com>

use Yaffas::UI;

do '../web-lib.pl';
require '../systeminfo/sysinfo-lib.pl';
&init_config();

# refresh every $idx_refresh seconds

if ($main::config{'idx_refresh'} > 0)
{
  print qq~<meta http-equiv="refresh" content="$main::config{'idx_refresh'}"\n~;
};

####################### 
#    GENERAL INFO     #
#######################
my %osinfo = &os_info();
my %cpu = &cpu_info();
my %load = &loadavg_uptime();

$Yaffas::UI::Print_inner_div = 0;


#######################
#     LOADAVERAGE     #
#######################


#######################
#    MEMORYUSAGE      #
#######################





#######################
#    DRIVESPACE       #
#######################

#######################
#      LOAD ICONS     #
#######################

my @links = ("network.cgi", "memory.cgi", "fs.cgi", "irq.cgi");
my @titles = ($main::text{'network_load'}, $main::text{'memory_usage'} ,$main::text{'fs_stat'}, $main::text{'irq_usage'});
my @icons = ();
icons_table(\@links, \@titles, \@icons);


footer("/", $main::text{'index'});

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
