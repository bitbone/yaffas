#! /usr/bin/perl

package Yaffas::Module::FaxLicense;

use strict;
use warnings;
use Yaffas::Product;
use Yaffas::File;
use Yaffas::Fax;
use Yaffas::LDAP;
use Yaffas::Service qw(HYLAFAX CAPI4HYLAFAX CAPIINIT START STOP);
use autouse 'Yaffas::Module::Faxsrv' => qw(Yaffas::Module::Faxsrv::get_number_fax_cards Yaffas::Module::Faxsrv::deactivate_ctrl);

use File::Copy;
our @ISA = qw(Yaffas::Module);

=pod

=head1 NAME

Yaffas::Module::FaxLicense

=head1 DESCRIPTION

This Modules provides functions for Webmin module FaxLicense 

=head1 FUNCTIONS

=over

=item check_rm_unlicensed_controller ( )

Will be called after inserting a key. Removes CONTROLLERs if an smaller key is installed.

=back

=cut

sub check_rm_unlicensed_controller()
{
	# check if configured controllers are valid
	my $max_ctr = Yaffas::Product::get_license_info('fax', "i_ab");
	$max_ctr = 1 if (! defined($max_ctr) || $max_ctr <= 0);
	my $system_ctr = Yaffas::Module::Faxsrv::get_number_fax_cards();

	if ( $max_ctr < $system_ctr )
	{
		for (my $i = 1; $i <= $system_ctr; $i++)
		{
			if ( Yaffas::Fax::check_existing_conf_entry($i) )
			{
				if ($max_ctr <= 0)
				{
					Yaffas::Module::Faxsrv::deactivate_ctrl($i);
				}
				else
				{
					$max_ctr--;
				}
			}
		}
	}
}

sub conf_dump {
    1;
}

return 1;

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
