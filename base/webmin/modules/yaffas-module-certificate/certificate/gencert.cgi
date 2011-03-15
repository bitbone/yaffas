#!/usr/bin/perl
# gencert.cgi
# Generates self-signed certificates
use strict;
use warnings;

use CGI::Carp qw(fatalsToBrowser warningsToBrowser);

use Yaffas;
use Yaffas::UI qw($Cgi section);

require "./forms.pl";

Yaffas::init_webmin();
ReadParse();
header();

show_errors_or_okee_gen_cert();

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
