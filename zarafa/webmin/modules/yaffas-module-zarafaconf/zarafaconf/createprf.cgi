#!/usr/bin/perl -w

use strict;
use warnings;

use Yaffas;
use Yaffas::UI;
use Yaffas::Module::ZarafaConf;
use Error qw(:try);
use Yaffas::Exception;

Yaffas::init_webmin();

ReadParse();

try {
    my $values = {
        profilename => $main::in{profilename},
        mailboxname => $main::in{mailboxname},
        password => $main::in{password},
        homeserver => $main::in{homeserver},
        overwriteprofile => $main::in{overwriteprofile},
        backupprofile => $main::in{backupprofile},
        connectiontype => $main::in{connectiontype},
    };

    my $content = Yaffas::Module::ZarafaConf::create_prf($values);

    print "Content-type: application/octet-stream\n";
    print "Content-length: ".(length $content)."\n";
    print "Content-Disposition: attachment; filename=\"outlook.prf\"";
    print "\n\n";

    print $content;
}
catch Yaffas::Exception with {
    header();
    print Yaffas::UI::all_error_box(shift);
    footer();
};
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
