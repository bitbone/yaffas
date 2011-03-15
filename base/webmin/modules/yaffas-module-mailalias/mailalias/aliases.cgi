#!/usr/bin/perl

use strict;
use warnings;

use Yaffas;
use Yaffas::Product qw(check_product);
use Yaffas::Mail::Mailalias qw(list_alias);
use Sort::Naturally;
use Yaffas::Constant;
use Text::Iconv;
use JSON;

Yaffas::json_header();

my %user_alias = list_alias();
my %dir_alias  = list_alias("DIR");

my %tmp = ( %user_alias, %dir_alias );
my @keys = keys %tmp;
my @content;

foreach (@keys) {
	push @content, {
		alias => $_,
		user => defined($user_alias{$_}) ? (join ", ", split( /\s*,\s*/, $user_alias{$_})) : "",
		folder => defined($dir_alias{$_}) ? $dir_alias{$_} : ""
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
