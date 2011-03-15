#! /usr/bin/perl

package Yaffas::Module::Mailq;
use strict;
use warnings;

our @ISA = ("Yaffas::Module");

use Error qw(:try);
use Yaffas::Exception;
use Yaffas::Constant;


=head1 NAME

Yaffas::Module::Mailq

=head1 FUNCTIONS

=over

=item forward_mail ( ADDRESS MAILAIDS )

Forwards mail to given address.

 ADDRESS: One new eMail address to sent mail to
 MAILAIDS: One or more mailid(s)
 Background: Change of recipient is not possible with exim. Existing addresses will be
 labeled as done. The new address will be attached and a delivery attempt will be forced.

=cut

sub forward_mail($\@)
{
	my $address = shift;
	my $mailids = shift;
	
	my $exim4 = Yaffas::Constant::APPLICATION->{exim4};

	my $the_mailid;
	foreach $the_mailid (@{$mailids})
	{
		# mark existing mail addresses as delivered
		foreach (get_address_of_mailid($the_mailid))
		{
			Yaffas::do_back_quote($exim4, "-Mmd", "$the_mailid", "$_");
			throw Yaffas::Exception("err_exim_mark") if ($?);
		}

		# add new recipient to mailid
		Yaffas::do_back_quote($exim4, "-Mar", "$the_mailid", "$address");
		throw Yaffas::Exception("err_exim_new_recipient") if ($?);

		# force a delivery
		Yaffas::do_back_quote($exim4, "-M", "$the_mailid");
		throw Yaffas::Exception("err_exim_force_delivery") if ($?);
	}
	print $main::text{'err_nothingtodo'} unless scalar @{$mailids};
}

=item get_address_of_mailid ( MAILID )

Returns array of eMail Addresses referenced by mailid.

 MAILID: One mailid (see exim4 -bp)

=cut

sub get_address_of_mailid($)
{
	my $mailid = shift;

	my $exim4 = Yaffas::Constant::APPLICATION->{exim4};
	my @maiqid = Yaffas::do_back_quote($exim4, "-bp", "$mailid");
	my @returnmail;

	# grep only mailaddress out of array
	for (my $i = 1; $i <= $#maiqid; $i ++)
	{
		if ($maiqid[$i] =~ m/([^\s]+\@[^\s]+)/)
		{
			push @returnmail, $1;
		}
	}

	return @returnmail;
}


return 1;

sub conf_dump {
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
