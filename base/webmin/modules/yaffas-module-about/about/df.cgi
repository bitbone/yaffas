#!/usr/bin/perl

use strict;
use warnings;

use Yaffas;
use JSON;

require '../systeminfo/sysinfo-lib.pl';

Yaffas::init_webmin();

Yaffas::json_header();

my @content;

my @df_lines = disk_free();

my $i = 1;
foreach my $line (@df_lines) {
	if ( $i == 1 ) {
		$i = 0;
		next;
	}
	my @cols = split /\s+/, $line, 6;

	next if ($cols[0] !~ /\d$/ && $cols[0] !~ /\/dev\/mapper/);

	push @content,
	  {
		filesystem   => $cols[0],
		size         => $cols[1],
		used         => $cols[2],
		available    => $cols[3],
		used_percent => $cols[4],
		mountpoint   => $cols[5],
	  };
}

print to_json( { "Response" => \@content } );
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
