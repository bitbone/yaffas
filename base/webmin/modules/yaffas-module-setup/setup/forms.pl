#!/usr/bin/perl -w

use strict;
use warnings;

use Yaffas::UI qw/textfield/;
use Yaffas::Exception;
use Yaffas::Product;
use Error qw(:try);

sub show_setup() {
    print $Cgi->start_form({-action=>"initialsetup.cgi", -method=>"post"});
    print Yaffas::UI::section("Setup", $Cgi->div( {-id=>"setup"},
            $Cgi->h2($main::text{lbl_basic_settings}),
            $Cgi->table(
                $Cgi->Tr(
                    $Cgi->td($main::text{lbl_admin_pw}.":"),
                    $Cgi->td($Cgi->password_field({-name=>"admin_password1"}))
                ),
                $Cgi->Tr(
                    $Cgi->td($main::text{lbl_admin_pw_repeat}.":"),
                    $Cgi->td($Cgi->password_field({-name=>"admin_password2"}))
                ),
            ),
            Yaffas::Product::check_product("zarafa") ? (
                $Cgi->h2($main::text{lbl_zarafa_settings}),
                $Cgi->table(
                    $Cgi->Tr(
                        $Cgi->td($main::text{lbl_mysql_user}.":"),
                        $Cgi->td(textfield({-name=>"mysql_user"}))
                    ),
                    $Cgi->Tr(
                        $Cgi->td($main::text{lbl_mysql_password}.":"),
                        $Cgi->td(textfield({-name=>"mysql_password"}))
                    ),
                    $Cgi->Tr(
                        $Cgi->td($main::text{lbl_mysql_host}.":"),
                        $Cgi->td(textfield({-name=>"mysql_host"}))
                    ),
                    $Cgi->Tr(
                        $Cgi->td($main::text{lbl_mysql_database}.":"),
                        $Cgi->td(textfield({-name=>"mysql_database"}))
                    ),
                )
            ) : ()
        )
    );
    print Yaffas::UI::section_button($Cgi->submit({-value=>$main::text{'lbl_save'}}));
    print $Cgi->end_form();

    print $Cgi->div({id=>"logoutdlg"});
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
