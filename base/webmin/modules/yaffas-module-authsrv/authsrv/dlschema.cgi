#!/usr/bin/perl
use strict;
use warnings;

use Yaffas;
use Yaffas::UI qw(yn_confirm);
use Yaffas::Constant;
use CGI::Carp qw(fatalsToBrowser warningsToBrowser);

Yaffas::init_webmin();
ReadParse();

my $error = 1;

if(exists($main::in{file}) && defined($main::in{file})) {
	if ($main::in{file} eq "yaffas") {
		$error = 0 unless Yaffas::UI::download_to_client(Yaffas::Constant::DIR->{ldap_schema}."bitbone.schema", "yaffas.schema");
	}
	if ($main::in{file} eq "samba") {
		$error = 0 unless Yaffas::UI::download_to_client(Yaffas::Constant::DIR->{ldap_schema}."samba.schema", "samba.schema");
	}
}

if ($error == 1) {
	header();
	print Yaffas::UI::error_box($main::text{err_file_not_found});
	footer();
}
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
