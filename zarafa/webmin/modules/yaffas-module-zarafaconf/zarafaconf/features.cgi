#!/usr/bin/perl

use strict;
use warnings;

use Yaffas;
use Yaffas::Module::ZarafaConf;
use JSON;

Yaffas::init_webmin();
ReadParse();

Yaffas::json_header();

if (defined $main::in{service}) {
	Yaffas::Module::ZarafaConf::change_default_features(lc $main::in{service}, $main::in{value});
}
else {
	my $f = Yaffas::Module::ZarafaConf::get_default_features();

	my @features;

	foreach (keys %{$f}) {
		push @features, {"feature" => uc $_, state => $f->{$_} eq "on" ? 1 : 0};
	}

	print to_json({"Response" => \@features}, {latin1 => 1});
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
