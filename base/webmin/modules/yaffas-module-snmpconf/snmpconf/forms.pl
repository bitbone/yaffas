#!/usr/bin/perl -w

use strict;
use warnings;

use Yaffas::UI;
use Yaffas::Module::SNMPConf;

sub show_snmp_conf() {
    my ($enabled, $community, $network) = Yaffas::Module::SNMPConf::get_snmp_config();

    $enabled = $main::in{enabled} if (exists $main::in{enabled});
    $community = $main::in{community} if (exists $main::in{community});
    $network = $main::in{network} if (exists $main::in{network});

    print $Cgi->start_form();
    print Yaffas::UI::section($main::text{lbl_snmp_config},
			      $Cgi->table(
					  $Cgi->Tr([
						    $Cgi->td([
							      $main::text{lbl_enable}.":",
							      $Cgi->checkbox({-name=>"enabled",
									      $enabled ? (-selected=>"selected") : (),
									      -label => "",
									     })
							     ]),
						    $Cgi->td([
							      $main::text{lbl_community}.":",
							      $Cgi->textfield({-name=>"community", -value=>$community})
							     ]),
						    $Cgi->td([
							      $main::text{lbl_network}.":",
							      $Cgi->textfield({-name=>"network", -value=>$network})
							     ]),
						   ]),
					 ),
			     );
	print $Cgi->hidden({ -name => "save", -value => 1 });
    print Yaffas::UI::section_button($Cgi->submit({-name=>"save", -value=>$main::text{lbl_save}}));
    print $Cgi->end_form();
}

return 1;
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
