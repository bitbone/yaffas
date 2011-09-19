#!/usr/bin/perl -w

use strict;
use warnings;

use Error qw(:try);
use Yaffas;
use Yaffas::Product;
use Yaffas::Module::Setup;
use Yaffas::Module::ChangePW;

Yaffas::init_webmin();

ReadParse();

header();

try {
    my $pw1 = $main::in{admin_password1};
    my $pw2 = $main::in{admin_password2};

    throw Yaffas::Exception("err_password") unless ($pw1 eq $pw2 and length($pw1) > 0);

    Yaffas::Module::ChangePW::change_admin_password($pw1);

    if (Yaffas::Product::check_product("zarafa")) {
        eval "use Yaffas::Module::ZarafaConf;";
        Yaffas::Module::ZarafaConf::set_zarafa_database($main::in{mysql_host}, $main::in{mysql_database}, $main::in{mysql_user}, $main::in{mysql_password});
    }

    Yaffas::Module::Setup::hide();

} catch Yaffas::Exception with {
    print Yaffas::UI::all_error_box(shift);
};

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
