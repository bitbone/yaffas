#!/usr/bin/perl -w

use strict;
use warnings;
use Yaffas;
use Yaffas::UI qw($Cgi);
use Yaffas::UI::TablePaging qw(show_page);
use Yaffas::Service qw(/.+/);
use JSON;

Yaffas::init_webmin();

Yaffas::json_header();

my $services = installed_services();
my $bkfc =
  Yaffas::File::Config->new( Yaffas::Constant::FILE->{goggletyke_cfg} );
my $config = $bkfc->get_cfg_values();

my @content;

foreach my $key ( sort keys %{$services} ) {
	push @content, {
		name => $key,
		status => control( $services->{$key}->{'constant'} ) ? 1 : 0,
		monitor => $config->{$key}->{should_run} ? 1 : 0,
		startonboot => Yaffas::Service::is_in_runlevel( $services->{$key}->{constant} ) ? 1 : 0
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
