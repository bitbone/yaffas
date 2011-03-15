#!/usr/bin/perl

use warnings;
use strict;

use Yaffas::Exception;
use Yaffas::UI;
use Yaffas;
use Yaffas::Auth;
use CGI::Carp qw(fatalsToBrowser warningsToBrowser);
use Error qw(:try);

require './forms.pl';

Yaffas::init_webmin();
ReadParse();

header($main::text{'lbl_index_header'}, "");

my $groups = $main::in{"groups"};
my $mode = $main::in{"mode"};

#my %ldap_auth = Yaffas::Auth::get_bk_ldap_auth();

if (defined($main::in{submit})) {

    my @tmp = split /\0/, $groups;

    try {
	if ($mode eq "edit") {
	    Yaffas::Exception->throw("err_no_group_selected") unless @tmp;
	    show_edit_groups( \@tmp );
	} elsif ($mode eq "delete") {
	    Yaffas::Exception->throw("err_no_group_selected") unless @tmp;
	    $Yaffas::UI::Convert_nl = 0;
	    print Yaffas::UI::yn_confirm(
					 {
					  -action => "rm_groups.cgi",
					  -yes => $main::text{yes},
					  -no => $main::text{no},
					  -title => $main::text{delete},
					  -hidden => [ map { ('groups', $_) } @tmp ],
					 }, $main::text{lbl_ask_delete} ."\n" .  $Cgi->ul($Cgi->li([@tmp])));
	} elsif ($mode eq "create") {
	    add_group_form();
# 	} elsif ($mode eq "filetype") {
# 	    Yaffas::Exception->throw("err_no_group_selected") unless @tmp;
# 	    show_filetype(@tmp);
	} else {
	    throw Yaffas::Exception("err_mode");
	}

    } catch Yaffas::Exception with {
	my $e = shift;
	print Yaffas::UI::all_error_box($e);
    };
} else {
    list_group_form();
    add_group_form();
}

footer();
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
