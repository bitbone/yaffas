#!/usr/bin/perl
use warnings;
use strict;

use Yaffas;
use Yaffas::UGM qw(get_users get_groups);
use Yaffas::Fax;
use Yaffas::Product;
use Sort::Naturally;
use Yaffas::Auth;
use Text::Iconv;
use Yaffas::Constant;
use JSON;

Yaffas::json_header();
my $show_filetype = 0;
if ( Yaffas::Product::check_product("fax") ) {
	$show_filetype = 1;
}

my %group;
$group{$_} = [ get_users($_) ] foreach ( get_groups() );

# remove duplicate members
foreach my $key ( keys %group ) {
	my $g    = $group{$key};
	my $newg = [];
	for ( my $i = 0 ; $i < scalar @$g ; $i++ ) {
		my $k;
		for ( $k = 0 ; $k < scalar @$newg ; $k++ ) {
			if ( $$newg[$k] eq $$g[$i] ) {
				$k = -1;
				last;
			}
		}
		( $k >= 0 ) && push( @$newg, $$g[$i] );
	}
	$group{$key} = $newg;
}

my $i;
my @groups = map {
	$i = 0;
	{
		group => $_,
		users => ( @{ $group{$_} } )[0]
		? $Cgi->table({-style => "border: 0;"},
			map {
				my $return = "";
				if ( $i % 5 == 0 )
				{    # wenn 10 einträge dann neue tabellen zeile
					$return .= $Cgi->end_Tr() . $Cgi->start_Tr();
				}
				$i++;

				$return .= $Cgi->td(
					{ -style => "border: 0; padding-left: 5px" },
					$_
				);

				$return;                # return it
			  } nsort @{ $group{$_} },
		  )
		: "",
		(
			filetype => $show_filetype
			? Yaffas::UGM::get_hylafax_filetype( $_, "group" )
			: ""
		)
	}
} nsort( keys %group );

print to_json( { "Response" => \@groups }, {latin1 => 1} );
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
