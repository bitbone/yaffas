#!/usr/bin/perl -w

use strict;
use warnings;

use Yaffas::Module::About;
use Yaffas::UI;
use Yaffas::Module::ZarafaLicence;

sub show_baselicense_form() {
	print $Cgi->start_form({-action=>"index.cgi"});
	print Yaffas::UI::section($main::text{lbl_install_basekey},
							  $Cgi->p($Cgi->textfield('baselicense'))
							 );
	print Yaffas::UI::section_button($Cgi->submit({-value=>$main::text{'lbl_insert'}}));
	print $Cgi->end_form();
}

sub show_callicense_form() {
	print $Cgi->start_form({-action=>"index.cgi"});
	print Yaffas::UI::section($main::text{lbl_install_calkey},
							  $Cgi->p($Cgi->textfield('callicense'))
							 );
	print Yaffas::UI::section_button($Cgi->submit({-value=>$main::text{'lbl_insert'}}));
	print $Cgi->end_form();
}

sub show_archiverlicense_form() {
	print $Cgi->start_form({-action=>"index.cgi"});
	print Yaffas::UI::section($main::text{lbl_install_archiverkey},
							  $Cgi->p($Cgi->textfield('archiverlicense'))
							 );
	print Yaffas::UI::section_button($Cgi->submit({-value=>$main::text{'lbl_insert'}}));
	print $Cgi->end_form();
}

sub show_acallicense_form() {
	print $Cgi->start_form({-action=>"index.cgi"});
	print Yaffas::UI::section($main::text{lbl_install_acalkey},
							  $Cgi->p($Cgi->textfield('acallicense'))
							 );
	print Yaffas::UI::section_button($Cgi->submit({-value=>$main::text{'lbl_insert'}}));
	print $Cgi->end_form();
}

sub show_installed_licences() {
	$Yaffas::UI::Print_inner_div = 0;
	my $base_serial = Yaffas::Module::ZarafaLicence::get_basekey();
	my $archiver_serial = Yaffas::Module::ZarafaLicence::get_archiverkey();
	print Yaffas::UI::start_section($main::text{lbl_installed_licences});
	print $Cgi->h2($main::text{"lbl_base_key"});
	print Yaffas::UI::table($Cgi->Tr(
									 $Cgi->td({style=>"width: 30%"},
														$main::text{lbl_serial}.":&nbsp;"),
									 $Cgi->td({style=>"width: 70%"},
														$base_serial),
									 )
							);
	print $Cgi->h2($main::text{"lbl_archiver_key"});
	print Yaffas::UI::table($Cgi->Tr(
									 $Cgi->td({style=>"width: 30%"},
														$main::text{lbl_archiver_serial}.":&nbsp;"),
									 $Cgi->td({style=>"width: 70%"},
														$archiver_serial),
									 )
							);
	#print $Cgi->h2($main::text{lbl_usercount});
	#my @usercount = Yaffas::do_back_quote(Yaffas::Constant::APPLICATION->{zarafa_admin}, "--user-count");
	#shift @usercount;
	#print $Cgi->pre(@usercount);
	print Yaffas::UI::end_section();
}

sub show_log() {
	my @log = Yaffas::Module::ZarafaLicence::get_log();

	if (scalar @log) {
		print Yaffas::UI::section($main::text{lbl_log},
								  $Cgi->pre(join "\n", @log)
								 );
	}
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
