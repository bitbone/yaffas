#!/usr/bin/perl

use strict;
use warnings;

use Yaffas;
use Yaffas::UGM;
use JSON;

Yaffas::json_header();

my @users;
my $userlist;
my $error = Yaffas::Exception->new();

$userlist = Yaffas::UGM::get_users_full();

foreach ( keys %{$userlist} ) {
	my $id = $userlist->{$_}->{uid};
	if ($id) {
		my $gecos = $userlist->{$_}->{gecos};
		my %user  = (
			"id"             => $id,
			"username"       => $_,
			"gecos"          => $gecos,
		);
		
		push( @users, \%user );
	}
	else {
		$error->add( "err_id_not_found", $_ );
	}
}
print to_json({"Response" => \@users}, {latin1 => 1});
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
