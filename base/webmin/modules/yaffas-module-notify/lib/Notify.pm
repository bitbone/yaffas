#!/usr/bin/perl -w

package Yaffas::Module::Notify;

our @ISA = ("Yaffas::Module");

use strict;
use warnings;

use Error qw(:try);
use Yaffas::Constant;
use Yaffas::Exception;
use Yaffas::Check;
use Yaffas::File;
use Yaffas::Product;
use Yaffas::Module::Mailalias;

=head1 NAME

Yaffas::Module::Notify

=head1 DESCRIPTION

bitkit Module for Notify

=head1 FUNCTIONS

=over

=item store_notify_mail( MAIL )

Store e-mail for system notification in '/data/config/base/notify/config'

=cut

sub store_notify_mail($)
{
	my $mail = shift;
	if ( Yaffas::Check::email($mail) || $mail =~ m/^\s*$/)
	{

		my $bkconfig = Yaffas::Constant::DIR->{bkconfig};
		my $bk_base = $bkconfig . "base/";
		my $bk_notify = $bk_base . "notify/";
		mkdir $bkconfig unless -d $bkconfig;
		mkdir $bk_base if (! -d $bk_base );
		mkdir $bk_notify if (! -d $bk_notify );

		my $config_f = $bk_notify . "config";
		my $config = new Yaffas::File($config_f);

		my $linnr = $config->search_line(qr/^notifymail=.*/);
		if ( defined($linnr) ) {
			throw Yaffas::Exception('err_modify_file') 
			if (! $config->splice_line($linnr, 1, "notifymail=$mail"));
		} else {
			$config->add_line("notifymail=$mail");
		}
		throw Yaffas::Exception('err_write_file')
		if (! $config->write() );
	} else {
		throw Yaffas::Exception('err_mail',  $mail);
	}
}

sub _store_notify_mail_config($) {
	my $mail = shift;
	# save conffile
	my $bkc = Yaffas::Conf->new();
	my $sec = $bkc->section("notify");
	$sec->del_func("email");
	if ( Yaffas::Check::email($mail) )
	{
		my $func = Yaffas::Conf::Function->new("email", "Yaffas::Module::Notify::store_notify_mail");
		$func->add_param({type => "scalar", param => $mail});
		$sec->add_func($func);
	}
	$bkc->save();
}

=item set_notify( MAIL TYPE )

Set mail alias and notify type in hylafax faxrecv script if product is fax. It also sets
the alias for root on this email.

=cut

sub set_notify($;$) {
	my $mail = shift;
	my $type = shift;

	if ( Yaffas::Check::email($mail) || $mail =~ m/^\s*$/)
	{
        my $postfix_alias = Yaffas::File->new("/etc/postfix/virtual_users_global");
		if (Yaffas::Product::check_product("fax")) {
			throw Yaffas::Exception('err_type',  $type) 
			if ( "$type" ne "always" && "$type" ne "errors" && "$type" ne "never");

			my $faxrcvd_f = Yaffas::Constant::FILE->{faxrcvd};
			my $faxrcvd = new Yaffas::File($faxrcvd_f);

			# add notify type to file
			my $linnr = $faxrcvd->search_line(qr/^NOTIFY_FAXMASTER=.*/);
			if ( defined($linnr) )
			{
				throw Yaffas::Exception('err_modify_file') 
				if (! $faxrcvd->splice_line($linnr, 1, "NOTIFY_FAXMASTER=$type"));
			}
			else
			{
				throw Yaffas::Exception('err_found_line');
			}
			throw Yaffas::Exception('err_write_file')
			if (! $faxrcvd->write() );

            my $line = $postfix_alias->search_line(qr#/FaxMaster@#);
            $postfix_alias->splice_line($line, 1, "/FaxMaster@.*/ root") if defined $line;
            $postfix_alias->add_line("/FaxMaster@.*/ root") unless defined $line;
        }

        my $line = $postfix_alias->search_line(qr#/root@#);

        if (defined $line and $line >= 0) {
            if ($mail ne "") {
                $postfix_alias->splice_line($line, 1, "/root@.*/ $mail");
            }
            else {
                $postfix_alias->splice_line($line, 1);
            }
        }
        else {
            if ($mail ne "") {
                $postfix_alias->add_line("/root@.*/ $mail");
            }
        }

        $postfix_alias->save();
        system("/usr/sbin/postmap", "/etc/postfix/virtual_users_global");

		store_notify_mail($mail);

		# save conffile
		_set_notify_config($mail, $type);
	}
	else {
		throw Yaffas::Exception('err_mail',  $mail);
	}
}

sub _set_notify_config($$) {
	my $mail = shift;
	my $type = shift;
	my $bkc = Yaffas::Conf->new();
	my $sec = $bkc->section("notify");
	$sec->del_func("type");
	my $func = Yaffas::Conf::Function->new("type", "Yaffas::Module::Notify::set_notify");
	$func->add_param({type => "scalar", param => $mail});
	$func->add_param({type => "scalar", param => $type});
	$sec->add_func($func);
	$bkc->save();
}

sub _get_notify_mail() {
	my $conf_f = Yaffas::Constant::DIR->{bkconfig} . "/base/notify/config";
	my $conf = Yaffas::File::Config->new($conf_f,
										 {
										 	-SplitPolicy => 'custom',
											-SplitDelimiter => '\s*=\s*',
										 });
	
	return "" if (! defined($conf) );

	my $hash_conf = $conf->get_cfg_values();
	return $hash_conf->{notifymail};
}

sub _get_notify_type() {
	# this is not a real conf file. File::Conf returns damage :-(.
	# so we search for the regex and parse the found line...
	my $type = "";

	my $faxrcvd_f = Yaffas::Constant::FILE->{faxrcvd};
	my $faxrcvd  = Yaffas::File->new($faxrcvd_f);
	return $type if (! defined($faxrcvd) );

	my $linenr = $faxrcvd->search_line(qr/^\s*NOTIFY_FAXMASTER=.*/);
	if (defined ($linenr) )
	{
		my $type_line = ($faxrcvd->get_content())[$linenr];
		$type_line =~ m/^\s*NOTIFY_FAXMASTER=(.*)$/;
		$type = $1;
	}
	
	# if nothing is found, we set default value
	if ( length($type) <= 0 )
	{
		$type = "always";
	}
	
	return $type;
}

sub conf_dump() {
	_set_notify_config(_get_notify_mail(), _get_notify_type());
}

=back

=cut

;1;
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
