#!/usr/bin/perl -w

use strict;
use warnings;

use Yaffas::Module::About;
use Yaffas::UI;
use Yaffas::UI::Webmin;
use Yaffas::Exception;
use Error qw(:try);

require '../systeminfo/sysinfo-lib.pl';


sub show_panels {
	print Yaffas::UI::section(
		$main::text{lbl_index_title},
		$Cgi->table(
			{ -id => "panels", -style => "width: 99%; padding-left:0px" },
			$Cgi->Tr(
				[
					$Cgi->td([
						$Cgi->h2($main::text{"lbl_about_".Yaffas::UI::Webmin::get_theme()}),
						$Cgi->h2($main::text{loadavg_title})
					]),
					$Cgi->td(
						{ -style => "width: 50%; vertical-align: top" },
						[
							$Cgi->div( { -id => "panel1" }, show_about() ),
							$Cgi->div( { -id => "panel2" }, show_load() ),
						]
					),
					$Cgi->td([
						$Cgi->h2($main::text{memory_usage}),
						$Cgi->h2($main::text{fs_stat})
					]),
					$Cgi->td(
						{ -style => "width: 50%; vertical-align: top" },
						[
							$Cgi->div( { -id => "panel3" }, show_mem() ),
							$Cgi->div( { -id => "panel4" }, show_df() ),
						]
					)
				]
			)
		)
	);
}

sub show_about {
	return $Cgi->div( { -id => "table" }, "" );
}

sub show_load() {
	return $Cgi->div( { -id => "table-load" }, "" );
}

sub show_df() {
	return $Cgi->div( { -id => "table-df" }, "" );
}

sub show_mem() {
	return $Cgi->div({-id=>"table-mem"}, "");
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
