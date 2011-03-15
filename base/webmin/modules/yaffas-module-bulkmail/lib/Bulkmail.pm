#!/usr/bin/perl
package Yaffas::Module::Bulkmail;
use strict;
use warnings;
use MIME::Lite;
use MIME::Base64;
use Yaffas::UGM;
use Yaffas::Constant;

our @ISA = qw(Yaffas::Module);

sub conf_dump { 1 }

# send a mail to all users in the group mail
sub send_bulk_mail($$$) {
	my ($from, $subject, $message) = @_;
	my @users = Yaffas::UGM::get_users();
	@users = grep {$_ ne "cyrus"} @users;
	#my $date = scalar localtime;
	if (scalar @users) {
		foreach my $u ( @users ) {
			$u = Yaffas::UGM::get_email($u);
		}
		$subject = encode_base64 ($subject);
		chomp $subject;
		my $msg = MIME::Lite->new( From => $from,
					   Bcc => \@users,
					   Subject => '=?UTF-8?B?'.$subject.'?=',
					   Type => 'text/plain; charset=UTF-8',
					   Encoding => '8bit',
					   Data => $message );
		$msg->send;
	}
	else {
		Yaffas::do_back_quote(Yaffas::Constant::APPLICATION->{logger}, "could not send bulkmail - no users available", );
	}
	return 1;
}

1;
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
