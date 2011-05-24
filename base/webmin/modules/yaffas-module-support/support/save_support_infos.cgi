#!/usr/bin/perl -w
# save_support_infos.cgi
# download support infos to client
use strict;
use warnings;

use Yaffas;
use Yaffas::UI;
use CGI::Carp qw(warningsToBrowser fatalsToBrowser);

Yaffas::init_webmin();

chomp(my $tar = `./create_backup.pl`);

unless(Yaffas::UI::download_to_client($tar, "yaffas_support_files.tar.gz")) {
	header();
	Yaffas::UI::error_box("Cant find your support file");
	footer();
}

unlink $tar;
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
