#!/usr/bin/perl

use strict;
use warnings;

use Yaffas;
use Yaffas::Module::Secconfig;
use Yaffas::Service qw(/.+/);

use JSON;

Yaffas::init_webmin();

Yaffas::json_header();

my @enabled = Yaffas::Module::Secconfig::get_enabled();
my @content;

if (!Yaffas::Product::check_product("mailgate")) {
	push @content, {
		name => "greylist",
		enabled => (grep { $_ eq "greylist" } @enabled) ? 1 : 0,
		started => control( GREYLIST() ) ? 1 : 0
	};
	push @content, {
		name => "spamassassin",
		enabled => (grep { $_ eq "spamassassin" } @enabled) ? 1 : 0,
		started => control( SPAMASSASSIN() ) ? 1 : 0
	};
}
else {
	push @content, {
		name => "policyserver",
		enabled => (grep { $_ eq "policyserver" } @enabled) ? 1 : 0,
		started => (control( MPPD() ) && Yaffas::Module::Secconfig::check_mpp_policyserver()) ? 1 : 0
	}
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
