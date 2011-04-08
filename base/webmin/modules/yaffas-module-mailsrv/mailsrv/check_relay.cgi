#! /usr/bin/perl -w

use warnings;
use strict;
use Yaffas;
use Yaffas::UI;
use Yaffas::Check;
use Yaffas::Exception;
use Yaffas::Module::Mailsrv::Postfix qw(rm_accept_relay set_accept_relay);
use Yaffas::Service qw(POSTFIX RESTART control);


use Error qw(:try);
use CGI::Carp qw(fatalsToBrowser warningsToBrowser);

## prototype ##
sub test($@);

Yaffas::init_webmin();
header($main::text{'hdr_check_add_domain'}, "");
ReadParse();


my $del    = $main::in{del};
my $add    = $main::in{ipaddr};
my $verify = ($main::in{verify} ? $main::in{verify} : 0);
my @del = split /\0/, $del if $del;

eval {

try{
	my $e = Yaffas::Exception->new();

	# test if okee
	test($e, @del, $add);
	# first del then add
	for (@del) {
		rm_accept_relay($_);
	}
	set_accept_relay($add);
	control(POSTFIX() ,RESTART());
	print Yaffas::UI::ok_box();

} catch Yaffas::Exception with {
	print Yaffas::UI::all_error_box(shift);
};

};
print $@;

footer();



sub test($@){
	my $e = shift;
	my($ip, $mask);
	for (@_) {
		next unless( defined $_ and $_ ne "");
		($ip, $mask) = split /\//, $_;
		Yaffas::Check::ip($ip, $mask, ($mask ? "netaddr" : undef) ) or $e->add('err_ip_entry', $_);
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
