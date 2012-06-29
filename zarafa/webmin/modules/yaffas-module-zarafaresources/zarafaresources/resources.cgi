#!/usr/bin/perl

use strict;
use warnings;

use Yaffas;
use Yaffas::Module::ZarafaResources;

use JSON;

Yaffas::init_webmin();

Yaffas::json_header();

my @content;

my @resources = Yaffas::Module::ZarafaResources::get_resources();
foreach my $resource (@resources) {
	my %details =
	  Yaffas::Module::ZarafaResources::get_resource_details($resource);
	my $r = {
		name => $resource,
		description => $details{description},
		email => $details{email},
		conflicts => $details{decline_conflict},
		recurring => $details{decline_recurring},
		type => $details{type},
		capacity => $details{capacity},
	};
	push( @content, $r );
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
