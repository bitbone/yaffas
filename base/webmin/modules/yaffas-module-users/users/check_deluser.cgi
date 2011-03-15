#!/usr/bin/perl
# index.cgi
use strict;
use warnings;
use Yaffas;
use Yaffas::UI;
use Yaffas::UGM;
use Yaffas::Module::Users;
use Yaffas::Module::Mailalias;
use Error qw(:try);
use Yaffas::Exception;
use Yaffas::Auth;
use Yaffas::Auth::Type;
use Yaffas::Module::Mailsrv;

require './forms.pl';

Yaffas::init_webmin();
ReadParse();

my @uid = split /\0/, $main::in{uid};

header();

try {
	Yaffas::Exception->throw('err_no_local_auth') unless ( Yaffas::Auth::auth_type() eq Yaffas::Auth::Type::LOCAL_LDAP or
							       Yaffas::Auth::auth_type() eq Yaffas::Auth::Type::FILES );

	foreach my $uid (@uid) {
		my $login = Yaffas::UGM::get_username_by_uid($uid);
		throw Yaffas::Exception("err_user_is_zarafa_admin", $login) if (Yaffas::Module::Mailsrv::get_zarafa_admin() eq $login);

		Yaffas::UGM::rm_user( $uid );
		Yaffas::UGM::clear_cache();

		my $a = Yaffas::Module::Mailalias->new();
		my @setaliases = $a->get_user_aliases($login);
		foreach my $alias (@setaliases) {
			$a->remove($alias, $login);
		}
		$a->write();
	}
	print Yaffas::UI::ok_box();
} catch Yaffas::Exception with {
	print Yaffas::UI::all_error_box(shift);
} otherwise {
	print Yaffas::UI::error_box(shift);
};

footer();

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
