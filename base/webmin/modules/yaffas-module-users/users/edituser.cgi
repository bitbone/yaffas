#!/usr/bin/perl

use strict;
use warnings;

use Yaffas;
use Yaffas::Auth;
use Yaffas::Module::Users;
use Yaffas::Exception;
use Error qw(:try);
use Yaffas::UI;
use Yaffas::UGM qw(get_username_by_uid);
use Yaffas::Module::Mailsrv;

require './forms.pl';

Yaffas::init_webmin();

header();
ReadParse();

my @uids = split /\0/, $main::in{user};
if (@uids) {
	try {
		show_edit_user(@uids);
	}
	catch Yaffas::Exception with {
		print Yaffas::UI::all_error_box(shift);
	};
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
