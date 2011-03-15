#!/usr/bin/perl
use strict;
use warnings;

use CGI::Carp qw(fatalsToBrowser warningsToBrowser);

use Yaffas;
use Yaffas::Mail::Mailalias;
use Yaffas::UI qw(error_box ok_box);

Yaffas::init_webmin();
ReadParse();
header();

my @alias = split /\0/ , $main::in{"delete_me"};

my $user_alias = Yaffas::Mail::Mailalias->new();
my $dir_alias;
if (Yaffas::Product::check_product('mail'))
{
	$dir_alias = Yaffas::Mail::Mailalias->new("DIR");
}

my $exception = Yaffas::Exception->new();

for (@alias) {
	$user_alias->remove($_);
	if (Yaffas::Product::check_product('mail'))
	{
		$dir_alias->remove($_);
	}
}

eval {
	$user_alias->write() or die;
	if (Yaffas::Product::check_product('mail'))
	{
		$dir_alias->write() or die;
	}

	print ok_box();
};

if ($@){
	print error_box($main::text{lbl_check_aliasesrm_error});
}

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
