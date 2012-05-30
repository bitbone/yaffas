#!/usr/bin/perl

use strict;
use warnings;

use Yaffas;
use Yaffas::Module::ZarafaWebaccess qw(set_config_value get_option_label get_webaccess_values);
use JSON;

Yaffas::init_webmin();
ReadParse();

Yaffas::json_header();

if (defined $main::in{type}) {
	set_config_value($main::in{type}, $main::in{value});
}
else {
	my $f = get_webaccess_values();

	my @options;

	foreach (keys %{$f}) {
		push @options, {"option" => $_, "label" => $main::text{get_option_label($_)}, state => $f->{$_} eq "true" ? 1 : 0};
	}

	print to_json({"Response" => \@options}, {latin1 => 1});
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
