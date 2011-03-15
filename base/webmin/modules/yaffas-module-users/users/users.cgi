#!/usr/bin/perl

use strict;
use warnings;

use Yaffas;
use Yaffas::UGM
  qw(get_users get_groups gecos name get_uid_by_username get_username_by_uid get_suppl_groupnames get_email);
use Yaffas::UI
  qw($Cgi section section_button table yn_confirm creating_cache_finish creating_cache_start);
use Yaffas::Module::Users;
use Yaffas::Product qw(check_product);
use Carp qw(cluck);
use Sort::Naturally;
use Yaffas::Constant;
use Yaffas::Auth;
use Yaffas::Fax;
use Text::Iconv;
use JSON;

Yaffas::json_header();

my $bkfax =
     check_product("fax")
  || check_product("pdf")
  || Yaffas::Auth::is_auth_srv();
my $bkzarafa = check_product("zarafa");

my @users;
my $userlist;
my @zstores;
my $error = Yaffas::Exception->new();

sub _in_group_lc($\@){
	my $username = shift;
	my $admins = shift;
	my $found = 0;
	for (@$admins) {
		if (lc($username) eq lc($_)) {
			$found++;
			last;
		}
	}
	if ($found) {
		return "X";
	}else {
		return "";
	}
}

$userlist = Yaffas::UGM::get_users_full();
if ($bkzarafa) {
	@zstores = Yaffas::Module::Users::get_zarafa_stores();
}

my $zstore = "";

foreach ( keys %{$userlist} ) {
	my $id = $userlist->{$_}->{uid};
	if ($id) {
		my $gecos = $userlist->{$_}->{gecos};
		my %user  = (
			"id"             => $id,
			"username"       => $_,
			"gecos"          => $gecos,
		);
		
		if ($bkzarafa) {
			$user{zarafa_license} = _in_group_lc( $_, @zstores );
		}

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
