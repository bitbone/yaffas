#!/usr/bin/perl

use strict;
use warnings;

use Yaffas;
use Yaffas::Module::ZarafaBackup::Store;
use Sort::Naturally;
use JSON;
use Data::Dumper;
use URI::Escape;
use File::Temp qw(tempfile);

Yaffas::init_webmin();
Yaffas::json_header();

my $buf;
my $data = read_fully(*STDIN, \$buf, $ENV{'CONTENT_LENGTH'});

$buf = uri_unescape($buf);
$buf =~ s/^keys=//;

my ($fh, $filename) = tempfile();

print $fh $buf;

my $ids = from_json($buf);

close $fh;

system("./restore.sh $filename &> /dev/null &");

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

