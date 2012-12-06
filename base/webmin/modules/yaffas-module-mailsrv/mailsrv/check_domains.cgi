#! /usr/bin/perl -w

use warnings;
use strict;
use Yaffas;
use Yaffas::UI;
use Yaffas::Check;
use Yaffas::Exception;
use Yaffas::Module::Mailsrv::Postfix qw(rm_accept_domains set_accept_domains);
use Yaffas::Service qw(POSTFIX RESTART control);


use Error qw(:try);
use CGI::Carp qw(fatalsToBrowser warningsToBrowser);

## prototype ##
sub test(@);

Yaffas::init_webmin();
header($main::text{'hdr_check_add_domain'}, "");
ReadParse();



my $del    = $main::in{del};
my $add    = $main::in{domain};
my $verify = $main::in{verify} ? 1 : 0;
my @del = split /\0/, $del if $del;
my @add = split /\s*,\s*/, $add if $add;

try {
	# test if oke
	foreach my $add(@add) {
		test(@del, $add);
	}
	# first del then add
	for (@del) {
		rm_accept_domains($_);
	}
	foreach my $add(@add) {
		set_accept_domains($add);
	}
	control(POSTFIX(), RESTART());
	print Yaffas::UI::ok_box();

} catch Yaffas::Exception with {
	print Yaffas::UI::all_error_box(shift);
};

footer();



sub test(@){
	my $e = Yaffas::Exception->new();

	for (@_) {
		next unless( defined $_ and $_ ne "");
		my $r = Yaffas::Check::domainname($_);
		if ($r != 1) {
			$e->add('err_domainname', $_);
		}
	}

	throw $e if $e;
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
