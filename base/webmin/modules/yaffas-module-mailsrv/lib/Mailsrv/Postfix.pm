#!/usr/bin/perl
package Yaffas::Module::Mailsrv::Postfix;

use warnings;
use strict;

sub BEGIN {
	use Exporter;
	our (@ISA, @EXPORT_OK);
	@ISA = qw(Exporter Yaffas::Module);
	@EXPORT_OK = qw(
					&get_smarthost  &set_smarthost &rm_smarthost &get_smarthost_routing &set_smarthost_routing
					&get_mailserver &set_mailserver
					&get_verify_rcp  &set_verify_rcp
					&get_accept_relay &set_accept_relay &rm_accept_relay
					&get_accept_domains &set_accept_domains &rm_accept_domains
					&get_mailsize &set_mailsize
					&get_archive &set_archive
					&get_zarafa_admin &set_zarafa_admin
				   );
}
use Yaffas qw/do_back_quote/;
use Yaffas::Constant;
use Yaffas::File;
use Yaffas::File::Config;
use Yaffas::Conf;
use Yaffas::Conf::Function;
use Yaffas::Check;
use Yaffas::UGM;
use Yaffas::Service;
use Yaffas::Product;
use Yaffas::Module::Users;
use Switch;

our $TESTDIR = "";

# private function

sub _get_value ($) {
	my $type = shift;

	throw Yaffas::Exception('Postfix.pm: invalid value for type at _get_value') unless $type =~ m#^[A-Za-z0-9_-]+\z#;
	my $out = do_back_quote(Yaffas::Constant::APPLICATION()->{postconf}, $type);
	$out =~ s/[^=]+\s*=\s*//;
	$out =~ s/\n//g;
    return undef if ($out eq "");
	return $out;
}

sub _set_value ($$) {
	my $type = shift;
	my $value = shift;

	throw Yaffas::Exception('Postfix.pm: invalid first parameter at _set_value')  unless $type =~ m#^[A-Za-z0-9_-]+\z#;
	throw Yaffas::Exception('Postfix.pm: invalid second parameter at _set_value') if $value =~ m#[`!;]#mg;

	system(Yaffas::Constant::APPLICATION()->{postconf}, "-e", "$type = $value");
	throw Yaffas::Exception('Postfix.pm: error in postfix -e') if $?;
}
sub start_fetchmail(){
	Yaffas::Service::control(Yaffas::Service::FETCHMAIL(), Yaffas::Service::START());
}
sub fetchmail_started(){
	if (-e  Yaffas::Constant::FILE->{'fetchmail_pid'} ){
		return 1;
	}
	else {
		return 0;
	}
}

sub _set_config ($$;$) {
	my $fid = shift;
	my $function = shift;
	my $value = shift;

	my $bkc = Yaffas::Conf->new();
	my $sec = $bkc->section("mailsrv-$fid");
	my $func = Yaffas::Conf::Function->new($fid, $function);
	$func->add_param({type => "scalar", param => $value} );
	$sec->del_func($fid);
	$sec->add_func($func);
	$bkc->save();

}

######################################################
################ Verify Recipient  ###################
######################################################

sub get_verify_rcp (){
	my $verify_action = "delete";
	my $mailadmin = undef;
	if (defined( _get_value("verifyrecipient"))) {
		$verify_action = "refuse";
	} elsif (_get_value("mailadmin")) {
		$mailadmin = _get_value("mailadmin");
		$verify_action = "mailadmin";
	}
	return ($verify_action,$mailadmin);
}

sub set_verify_rcp ($;$) {
	my ($verify_action,$mailadmin) = @_;
	if ($verify_action eq "delete") {
		_set_value("mailadmin","");
		_set_value("verifyrecipient","");
	} elsif ($verify_action eq "refuse") {
		_set_value("verifyrecipient","1");
		_set_value("mailadmin","");
	} elsif ($verify_action eq "mailadmin") {
		if (defined($mailadmin)) {
			Yaffas::Check::email($mailadmin) or throw Yaffas::Exception('err_mailadmin');
			_set_value("mailadmin", $mailadmin);
			_set_value("verifyrecipient","");
		}
	} else {
		throw Yaffas::Exception('err_verify_value');
	}
}

sub _set_verify_rcp_config($;$) {
	my $action = shift;
	my $mailadmin = shift;

	return 0 unless $action;

	my $bkc = Yaffas::Conf->new();
	my $sec = $bkc->section("mailsrv-verify_rcp");
	my $func = Yaffas::Conf::Function->new("verify_rcp", "Yaffas::Module::Mailsrv::Postfix::set_verify_rcp");
	$func->add_param({type => "scalar", param => $action},
					 {type => "scalar", param => $mailadmin});
	$sec->del_func("verify_rcp");
	$sec->add_func($func);
	$bkc->save();
	return 1;
}

######################################################
##################### Mailserver #####################
######################################################

sub get_mailserver () {
	return _get_value("myhostname");
}

sub set_mailserver ($) {
	my $mailserver = shift;
	if (defined($mailserver)) {
		unless ($mailserver eq "") {
			Yaffas::Check::domainname($mailserver) or throw Yaffas::Exception('err_mailserver');
		}
	}
	_set_value("myhostname", $mailserver);
}

######################################################
##################### Smarthost  #####################
######################################################

sub get_smarthost (){
	my $sh = _get_value("relayhost");
	$sh =~ s/[\[\]]//g;

	my $bkf = Yaffas::File->new(Yaffas::Constant::FILE->{'postfix_smtp_auth'});
	my $ln = $bkf->search_line($sh);
	my $line = $bkf->get_content($ln);

	my ($username, $password);

	if ($line && $line =~ m#^[^ ]+\s+([^:]+):([^ ]+)#) {
		$username = $1;
		$password = $2;
	}

	$username = "" unless defined $username;
	$password = "" unless defined $password;

	return ($sh, $username, $password);
}

sub set_smarthost($$$) {
	my $sh = shift;
	my $user = shift;
	my $pass = shift;


	if ($sh =~ /^\d+\.\d+\.\d+\.\d+$/) {
		Yaffas::Check::ip($sh) or throw Yaffas::Exception('err_smarthost');
	} else {
		Yaffas::Check::domainname($sh) or throw Yaffas::Exception('err_smarthost');
	}

	unless ($user eq "" || ( (length($user) > 1) && (length($user) < 1024) && 
			$user !~ m/[\s:`]+/ )
	       )
	{
		throw Yaffas::Exception('err_username');
	}
	unless ( ($pass eq "" || Yaffas::Check::password($pass)) && $pass !~ m/[\s+|:+]/) {
		throw Yaffas::Exception('err_password');
	}

	_set_value('relayhost', "[$sh]");
	_set_value('smtp_sasl_auth_enable', 'yes');
	_set_value('smtp_sasl_password_maps', 'hash:/etc/postfix/smtp_auth.cf');
	_set_value('smtp_sasl_security_options', 'noanonymous');

	my $bkf = Yaffas::File->new(Yaffas::Constant::FILE->{'postfix_smtp_auth'}, "");

	my $ln = 0; # überschreiben.
	$bkf->splice_line($ln, 1, $sh ."	" . $user  . ":" . $pass) if ($user && $pass);
	$bkf->write();

	system(Yaffas::Constant::APPLICATION->{postmap}, Yaffas::Constant::FILE->{'postfix_smtp_auth'});
}

sub _set_smarthost_config($$$) {
	my $sh = shift;
	my $user = shift;
	my $pass = shift;

	my $bkc = Yaffas::Conf->new();
	my $sec = $bkc->section("mailsrv-smarthost");
	my $func = Yaffas::Conf::Function->new("smarthost", "Yaffas::Module::Mailsrv::Postfix::set_smarthost");
	$func->add_param({type => "scalar", param => $sh},
					 {type => "scalar", param => $user},
					 {type => "scalar", param => $pass});
	$sec->del_func("smarthost");
	$sec->add_func($func);
	$bkc->save();
	return 1;
}

sub rm_smarthost($) {
	my $sh = shift;

	_set_value('relayhost', undef);
	_set_value('smtp_sasl_auth_enable', 'no');
	_set_value('smtp_sasl_password_maps', undef);
	_set_value('smtp_sasl_security_options', undef);


	my $bkf = Yaffas::File->new(Yaffas::Constant::FILE->{'exim_passwd_client'});
	my $ln = $bkf->search_line($sh);
	$bkf->splice_line($ln, 1 );
	$bkf->write();
}

sub set_smarthost_routing($$) {
	my $type = shift;
	my $rewrite = shift;

	if (defined($type) && $type) {
		throw Yaffas::Exception("err_no_smarthost") unless defined _get_value('relayhost');
		throw Yaffas::Exception("err_no_rewrite") unless (defined($rewrite) and $rewrite and Yaffas::Check::domainname($rewrite));
		_set_value("local_header_rewrite_clients", 'static:all');
		_set_value("remote_header_rewrite_domain", "$rewrite");
	} else {
		_set_value("local_header_rewrite_clients", undef);
		_set_value("remote_header_rewrite_domain", undef);
	}
}

sub _set_smarthost_routing_config($$) {
	my $route_all = shift;
	my $rewrite = shift;

	my $bkc = Yaffas::Conf->new();
	my $sec = $bkc->section("mailsrv-smarthostroute");
	my $func = Yaffas::Conf::Function->new("smarthost_routing", "Yaffas::Module::Mailsrv::Postfix::set_smarthost_routing");
	$func->add_param({type => "scalar", param => $route_all},
					 {type => "scalar", param => $rewrite});
	$sec->del_func("smarthost");
	$sec->add_func($func);
	$bkc->save();
	return 1;
}

sub get_smarthost_routing() {
	return _get_value('remote_header_rewrite_domain') ? (1, _get_value('remote_header_rewrite_domain')) : (0, undef);
}

######################################################
##################### Accept Relay ###################
######################################################

sub get_accept_relay(){
	my $line = _get_value('mynetworks');
	return () unless defined $line;

	my @content = split(m#,\s*#, $line);
	return @content;
}

sub set_accept_relay($){
	my $add_me = shift;
	return undef unless $add_me;

	my @domains = get_accept_relay();
	push @domains, $add_me unless grep { $_ eq $add_me } @domains;

	_set_value('mynetworks', join(', ', @domains));
}

sub rm_accept_relay($){
	my $del_me = shift;
	return undef unless $del_me;

	my @domains = get_accept_relay();
	my %temp = map { $_ => "" } @domains;
	delete $temp{$del_me};
	@domains = keys %temp;

	_set_value('mynetworks', join(', ', @domains));
}

######################################################
##################### Accept Domains #################
######################################################

sub get_accept_domains(){
	my $line = _get_value('virtual_mailbox_domains');
	return () unless defined $line;

	my @content = split(m#,\s*#, $line);
	return @content;
}

sub set_accept_domains($){
	my $add_me = shift;
	return undef unless $add_me;
	return undef unless Yaffas::Check::domainname($add_me);

	my @domains = get_accept_domains();
	push @domains, $add_me unless grep { $_ eq $add_me } @domains;

	_set_value('virtual_mailbox_domains', join(', ', @domains));

	set_fetchmail_conf();
	set_mppmanger_conf($add_me);
}

sub rm_accept_domains($){
	my $del_me = shift;
	return undef unless $del_me;

	my @domains = get_accept_domains();
	my %temp = map { $_ => "" } @domains;
	delete $temp{$del_me};
	@domains = keys %temp;

	_set_value('virtual_mailbox_domains', join(', ', @domains));

	# change aka entry in fetchmailrc
	set_fetchmail_conf();
}


sub set_fetchmail_conf() {
	my @domains = get_accept_domains();
	my $file = Yaffas::File->new(Yaffas::Constant::FILE->{fetchmailrc});
	foreach my $line ($file->search_line(qr/^\s*#*aka .*/)) {
		$file->splice_line($line, 1, "\taka ".join " ",@domains) if (@domains);
		$file->splice_line($line, 1, "\t#aka ") unless (@domains);
	}
	if (scalar @{$file->{CONTENT}} > 0) {
		#only write file if not empty!
		$file->save();
	}
}

sub set_mppmanger_conf($) {
	my $domain = shift;

	return unless (Yaffas::Product::check_product("mailgate"));

	my $file = Yaffas::File->new(Yaffas::Constant::FILE()->{qreview_users});

	$file->add_line("auth:$domain:imap:localhost:143:90:username");
	$file->add_line("authz:$domain:user");
	$file->save();
}

# mail size

sub get_mailsize() {
	my $ms = _get_value("message_size_limit");
	$ms = int($ms / 1024 / 1024) if defined($ms);
	return $ms;
}

sub set_mailsize($) {
	my $size = shift;
	if (defined($size)) {
		unless ($size eq "") {
			throw Yaffas::Exception("err_size") unless ($size =~ /^\d+$/ && $size > 0);
			$size = $size * 1024 * 1024;
		}
		_set_value("message_size_limit", $size);
		return;
	}
	throw Yaffas::Exception("err_size");
}

# archive

sub get_archive() {
	return _get_value("always_bcc");
}

sub set_archive($) {
	my $archive = shift;
	if (defined($archive)) {
	throw Yaffas::Exception("err_archive_name")
		unless (grep {$_ eq $archive} Yaffas::UGM::get_users("yaffasmail") or Yaffas::Check::email($archive));
	}
	_set_value("always_bcc", $archive);
}

sub set_zarafa_admin($$) {
	my $username = shift;
	my $password = shift;

	throw Yaffas::Exception("err_zarafa_not_installed") unless (Yaffas::Product::check_product("zarafa"));

	if (not defined $username or $username eq "") {
		_set_value("zarafa_admin", "");
		Yaffas::File->new(Yaffas::Constant::FILE->{zarafa_admin_cfg}, "")->save();
	}
	else {
		my $old_admin = get_zarafa_admin();
		if (defined $old_admin and $username eq $old_admin and $password eq "") {
			# old username and empty password
			return;
		}
		my $bke = Yaffas::Exception->new();
		$bke->add("err_user_not_exists") unless Yaffas::UGM::user_exists($username);
		$bke->add("err_password_missing") unless defined($password);

		$bke->add("err_user_not_zarafa_admin") unless Yaffas::Module::Users::get_zarafa_admin($username);

		throw $bke if $bke;
		my $file = Yaffas::File->new(Yaffas::Constant::FILE->{zarafa_admin_cfg}, "");
		$file->wipe_content();
		$file->add_line($username);
		$file->add_line($password);
		$file->save() or throw Yaffas::Exception("err_file_write", Yaffas::Constant::FILE->{zarafa_admin_cfg});

		Yaffas::do_back_quote(Yaffas::Constant::APPLICATION->{zarafa_public_folder_script}, $TESTDIR);
		if ($? != 0) {
			$file->wipe_content();
			$file->save() or throw Yaffas::Exception("err_file_write", Yaffas::Constant::FILE->{zarafa_admin_cfg});
			throw Yaffas::Exception("err_user_password");
		}
		_set_value("zarafa_admin", $username);
	}
}

sub get_zarafa_admin() {
	return _get_value("zarafa_admin");
}

sub set_postfix_ldap($$) {
	my $postfix_settings = shift;
	my $file = shift;

	my $filename;

	switch($file) {
		case "users" { $filename = "postfix_ldap_users"; }
		case "aliases" { $filename = "postfix_ldap_aliases"; }
		case "group" { $filename = "postfix_ldap_group"; }
	}

	throw Yaffas::Exception('err_unknown_postfix_file') unless defined $filename;

	my $ls_file = Yaffas::File::Config->new(Yaffas::Constant::FILE->{$filename},
										 {
										 -SplitPolicy => 'custom',
										 -SplitDelimiter => '\s*=\s*',
										 -StoreDelimiter => ' = ',
										 }
										 ) or throw Yaffas::Exception("err_file_write");
	my $ls_ref = $ls_file->get_cfg_values();

	for (keys %{$postfix_settings}) {
		if(!defined $postfix_settings->{$_} || $postfix_settings->{$_} eq '') {
			delete $ls_ref->{$_};
		} else {
			$ls_ref->{$_} = $postfix_settings->{$_};
		}
	}

	$ls_file->write() or throw Yaffas::Exception("err_file_write", Yaffas::Constant::FILE->{$filename});

}

sub toggle_distribution_groups($) {
	my $toggle = shift;
	if("ldap" eq lc $toggle) {
		_set_value("virtual_alias_maps", "regexp:/etc/postfix/virtual_users_global, ldap:/etc/postfix/ldap-aliases.cf, ldap:/etc/postfix/ldap-group.cf");
	} elsif("file" eq lc $toggle) {
		_set_value("virtual_alias_maps", "regexp:/etc/postfix/virtual_users_global, ldap:/etc/postfix/ldap-aliases.cf, hash:/etc/postfix/ldap-group.cf");
	}
}

sub conf_dump() {
	# Verify Recipient
	_set_verify_rcp_config(get_verify_rcp());

	# Mailserver
	my $m = get_mailserver();
	_set_config("mailserver", "Yaffas::Module::Mailsrv::Postfix::set_mailserver", $m) if ($m);

	# Smarthost
	my ($s, $u, $p) = get_smarthost();
	_set_smarthost_config($s, $u, $p) if ($s);

	my ($route_all, $domain) = get_smarthost_routing();
	_set_smarthost_routing_config($route_all, $domain);

	# Accept Relay
	foreach my $r (get_accept_relay()) {
		_set_config("relay-$r", "Yaffas::Module::Mailsrv::Postfix::set_accept_relay", $r);
	}

	my $ms = get_mailsize();
	_set_config("mailsize", "Yaffas::Module::Mailsrv::Postfix::set_mailsize", $ms) if ($ms);

	my $archive = get_archive();
	_set_config("archive", "Yaffas::Module::Mailsrv::Postfix::set_archive", $archive) if (defined($archive));

	# Accept Domain
	foreach my $dom (get_accept_domains()) {
		_set_config("domains-$dom", "Yaffas::Module::Mailsrv::Postfix::set_accept_domains", $dom) if ( $dom !~ m/^\s*$/);
	}
	if(fetchmail_started() == 1){
		_set_config("startfetchmail", "Yaffas::Module::Mailsrv::Postfix::start_fetchmail" );
	}

}


1;
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
