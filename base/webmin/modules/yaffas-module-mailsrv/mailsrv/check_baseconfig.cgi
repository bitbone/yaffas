#! /usr/bin/perl -w
use strict;
use warnings;
use Error qw(:try);
use CGI::Carp qw(fatalsToBrowser warningsToBrowser);

use Yaffas;
use Yaffas::Service qw(POSTFIX STOP START STATUS control RESTART);
use Yaffas::UI;
use Yaffas::Exception;
use Yaffas::Module::Mailsrv::Postfix qw(set_verify_rcp set_mailserver set_mailsize set_zarafa_admin);
use Yaffas::Product qw(check_product);
use Yaffas::Module::Secconfig;

require "./forms.pl";

Yaffas::init_webmin();
header($main::text{'index_header'}, "");
ReadParse();

#my $maildomain = $main::in{maildomain};
my $mailadmin  = $main::in{mailadmin};
my $verify_action  = $main::in{verify_action};
my $mailserver = $main::in{mailservername};
my $mailsize = $main::in{mailsize};
my $username = $main::in{zarafa_admin};
my $password = $main::in{password};
my $client_tls = $main::in{client_tls};
my $server_tls = $main::in{server_tls};

my ($old_verify_action,$old_mailadmin) = get_verify_rcp ();
my $old_mailserver = get_mailserver ();
my $old_mailsize = get_mailsize ();

my $fax = check_product("fax");
my $gate = check_product("gate");
my $pdf = check_product("pdf");

my $bke = Yaffas::Exception->new();

try {
	set_mailserver($mailserver);
} catch Yaffas::Exception with {
	$bke->append(shift);
};

try {
	set_mailsize($mailsize);
} catch Yaffas::Exception with {
	$bke->append(shift);
};

if (check_product("zarafa")) {
	try {
		set_zarafa_admin($username, $password);
	} catch Yaffas::Exception with {
		$bke->append(shift);
	};
}

try {
	throw $bke if $bke;

	control(POSTFIX(), RESTART());
	print Yaffas::UI::ok_box();

} catch Yaffas::Exception with {
	print Yaffas::UI::all_error_box(shift);
	base_settings_form();
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
