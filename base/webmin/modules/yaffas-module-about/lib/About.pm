#!/usr/bin/perl

package Yaffas::Module::About;

use Yaffas;
use Yaffas::File;
use Yaffas::Constant;
use Yaffas::Product qw(get_version_of get_revision_of get_longname_of);
use strict;
use warnings;
our @ISA = qw(Yaffas::Module);


## prototypes ##
sub get_products();

=pod

=head1 NAME

Yaffas::Module::About

=head1 DESCRIPTION

This Modules provides functions for Webmin module bbabout

=head1 FUNCTIONS

=over

=item get_products()

Returns a hash structure with pointers to hashes of the installed products. Following keys
are uses.

 name 	Name of product
 ver 	Version
 rev 	Revision

=cut

sub get_products() {
	my %return;

	foreach ( Yaffas::Product::get_all_installed_products() ){
		$return{$_} = {
					   name => get_longname_of($_),
					   ver => get_version_of($_),
					  }
	}
	return %return;
}

return 1;

sub conf_dump() {
    1;
}

=back

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
