#!/usr/bin/perl

use strict;
use warnings;

use Yaffas;
use Yaffas::Module::Notify;
use Yaffas::UI;
use Yaffas::Exception;
use Error qw(:try);
use CGI::Carp qw(fatalsToBrowser warningsToBrowser);

require './forms.pl';

Yaffas::init_webmin();
ReadParse();
my $email = $main::in{'email'};
my $send_mail_on = $main::in{'send_mail_on'};

header();

try
{
	Yaffas::Module::Notify::set_notify($email, $send_mail_on);
	
	my $smtp = Net::SMTP->new('localhost');

	$smtp->mail('root@localhost');
	$smtp->to($email);
	$smtp->data();
	$smtp->datasend("From: root\@localhost\n");
	$smtp->datasend("To: $email\n");
	$smtp->datasend("Subject: $main::text{lbl_test_mail_subject}\n");
	$smtp->datasend("Content-Type: text/plain; charset=utf-8\n");
	$smtp->datasend("\n");
	$smtp->datasend($main::text{'lbl_test_mail_body1'}."\n");
	$smtp->datasend($main::text{'lbl_test_mail_body2'}."\n");
	$smtp->datasend($main::text{'lbl_test_mail_body3'}."\n");
	$smtp->datasend($main::text{'lbl_test_mail_body4'}."\n");
	$smtp->datasend($main::text{'lbl_test_mail_body5'}."\n");
	$smtp->datasend($main::text{'lbl_test_mail_body6'}."\n");
	$smtp->datasend($main::text{'lbl_test_mail_body7'}."\n");
	$smtp->dataend();

	$smtp->quit();
	
	
	print Yaffas::UI::ok_box("$main::text{'suc_set_mail'}");
}
catch Yaffas::Exception with
{
	print Yaffas::UI::all_error_box(shift);
	notify_mail($email);
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
