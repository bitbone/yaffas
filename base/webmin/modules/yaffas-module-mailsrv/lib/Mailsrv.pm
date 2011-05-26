#!/usr/bin/perl
package Yaffas::Module::Mailsrv;

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

our $TESTDIR = "";

my %names = (
			 "mailadmin" => "BBmailadmin",
			 "mailserver" => "BBhostname",
			 "smarthost" => "BBsmarthost",
			 "message_size" => "BBmessage_size",
			 "mail_archive" => "BBmail_archive",
			 "verifyrecipient" => "BBverifyrecipient",
			 "zarafa_admin" => "BBfolderadmin",
			);

# private function

sub _get_value ($) {
	my $type = shift;

	my $bkcf = Yaffas::File::Config->new(Yaffas::Constant::FILE()->{bbexim_conf},
										 {
										  -SplitPolicy => 'custom',
										  -SplitDelimiter => '\s*=\s*',
										  -StoreDelimiter => ' =  ',
										 });
	return $bkcf->get_cfg_values()->{$names{$type}};
}

sub _set_value ($$) {
	my $type = shift;
	my $value = shift;

	my $bkcf = Yaffas::File::Config->new(Yaffas::Constant::FILE()->{bbexim_conf},
										 {
										 -SplitPolicy => 'custom',
										 -SplitDelimiter => '\s*=\s*',
										 -StoreDelimiter => ' =  ',
										 });

	if ($value eq "") {
		delete $bkcf->get_cfg_values()->{$names{$type}};
	} else {
		$bkcf->get_cfg_values()->{$names{$type}} = $value;
	}
	$bkcf->write();

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
	my $func = Yaffas::Conf::Function->new("verify_rcp", "Yaffas::Module::Mailsrv::set_verify_rcp");
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
	return _get_value("mailserver");
}

sub set_mailserver ($) {
	my $mailserver = shift;
	if (defined($mailserver)) {
		unless ($mailserver eq "") {
			Yaffas::Check::domainname($mailserver) or throw Yaffas::Exception('err_mailserver');
		}
	}
	_set_value("mailserver", $mailserver);
}

######################################################
##################### Smarthost  #####################
######################################################

sub get_smarthost (){
	my $sh = _get_value("smarthost");

	my $bkf = Yaffas::File->new(Yaffas::Constant::FILE->{'exim_passwd_client'});
	my $ln = $bkf->search_line($sh);
	my $line = $bkf->get_content($ln);

	my ($username, $password);

	if ($line) {
		$username = (split(/:/, $line))[1];
		$password = (split(/:/, $line))[2];
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

	my $bkcf = Yaffas::File::Config->new(Yaffas::Constant::FILE()->{bbexim_conf},
										 {
										  -SplitPolicy => 'custom',
										  -SplitDelimiter => '\s*=\s*',
										  -StoreDelimiter => ' =  ',
										 });
	my $hash = $bkcf->get_cfg_values();
	$hash->{BBsmarthost} = $sh;
	$bkcf->write();

	my $bkf = Yaffas::File->new(Yaffas::Constant::FILE->{'exim_passwd_client'}, "");

	my $ln = 0; # überschreiben.
	$bkf->splice_line($ln, 1, $sh .":" . $user  . ":" . $pass) if ($user && $pass);
	$bkf->write();
}

sub _set_smarthost_config($$$) {
	my $sh = shift;
	my $user = shift;
	my $pass = shift;

	my $bkc = Yaffas::Conf->new();
	my $sec = $bkc->section("mailsrv-smarthost");
	my $func = Yaffas::Conf::Function->new("smarthost", "Yaffas::Module::Mailsrv::set_smarthost");
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
	my $bkcf = Yaffas::File::Config->new(Yaffas::Constant::FILE()->{bbexim_conf},
										 {
										  -SplitPolicy => 'custom',
										  -SplitDelimiter => '\s*=\s*',
										  -StoreDelimiter => ' =  ',
										 });
	my $hash = $bkcf->get_cfg_values();
	delete $hash->{BBsmarthost};
	$bkcf->write();

	my $bkf = Yaffas::File->new(Yaffas::Constant::FILE->{'exim_passwd_client'});
	my $ln = $bkf->search_line($sh);
	$bkf->splice_line($ln, 1 );
	$bkf->write();
}

sub set_smarthost_routing($$) {
	my $type = shift;
	my $rewrite = shift;

	my $bkcf = Yaffas::File::Config->new(Yaffas::Constant::FILE()->{bbexim_conf},
										 {
										  -SplitPolicy => 'custom',
										  -SplitDelimiter => '\s*=\s*',
										  -StoreDelimiter => ' =  ',
										 });
	my $hash = $bkcf->get_cfg_values();


	if (defined($type) && $type) {
		throw Yaffas::Exception("err_no_smarthost") unless defined $hash->{BBsmarthost};
		throw Yaffas::Exception("err_no_rewrite") unless (defined($rewrite) and $rewrite and Yaffas::Check::domainname($rewrite));
		$hash->{BBroute_all} = $type;
		$hash->{BBrewrite_domain} = $rewrite;
	} else {
		delete $hash->{BBroute_all};
		delete $hash->{BBrewrite_domain};
	}
	$bkcf->save();
}

sub _set_smarthost_routing_config($$) {
	my $route_all = shift;
	my $rewrite = shift;

	my $bkc = Yaffas::Conf->new();
	my $sec = $bkc->section("mailsrv-smarthostroute");
	my $func = Yaffas::Conf::Function->new("smarthost_routing", "Yaffas::Module::Mailsrv::set_smarthost_routing");
	$func->add_param({type => "scalar", param => $route_all},
					 {type => "scalar", param => $rewrite});
	$sec->del_func("smarthost");
	$sec->add_func($func);
	$bkc->save();
	return 1;
}

sub get_smarthost_routing() {
	my $bkcf = Yaffas::File::Config->new(Yaffas::Constant::FILE()->{bbexim_conf},
										 {
										  -SplitPolicy => 'custom',
										  -SplitDelimiter => '\s*=\s*',
										  -StoreDelimiter => ' =  ',
										 });
	my $hash = $bkcf->get_cfg_values();
	return exists $hash->{BBroute_all} ? (1, $hash->{BBrewrite_domain}) : (0, undef);
}

######################################################
##################### Accept Relay ###################
######################################################

sub get_accept_relay(){
	my $bkf = Yaffas::File->new( Yaffas::Constant::FILE()->{exim_relay_conf} );
	my @content = $bkf->get_content();
	return @content;
}

sub set_accept_relay($){
	my $add_me = shift;
	return undef unless $add_me;
	my $bkf = Yaffas::File->new( Yaffas::Constant::FILE()->{exim_relay_conf} );
	my $line = $bkf->search_line($add_me);

	if (defined $line) {
		$bkf->splice_line($line, 1, $add_me);
	}else {
		$bkf->add_line($add_me);
	}
	$bkf->save();
}

sub rm_accept_relay($){
	my $del_me = shift;
	return undef unless $del_me;
	my $bkf = Yaffas::File->new( Yaffas::Constant::FILE()->{exim_relay_conf} );
	my $line = $bkf->search_line($del_me);

	if (defined $line) {
		$bkf->splice_line($line,1);
		$bkf->save();
	}
}

######################################################
##################### Accept Domains #################
######################################################

sub get_accept_domains(){
	my $bkf = Yaffas::File->new( Yaffas::Constant::FILE()->{exim_domains_conf} );
	my @content = grep {$_} $bkf->get_content();
	return @content;
}

sub set_accept_domains($){
	my $add_me = shift;

	return undef unless $add_me;
	return undef unless Yaffas::Check::domainname($add_me);

	my $bkf = Yaffas::File->new( Yaffas::Constant::FILE()->{exim_domains_conf} );
	my $line = $bkf->search_line(qr/^$add_me$/);

	if (defined $line) {
		$bkf->splice_line($line, 1, $add_me);
	} else {
		$bkf->add_line($add_me);
	}
	$bkf->save();

	# change aka entry in fetchmailrc
	set_fetchmail_conf();

	set_mppmanger_conf($add_me);
}

sub rm_accept_domains($){
	my $del_me = shift;
	return undef unless $del_me;
	my $bkf = Yaffas::File->new( Yaffas::Constant::FILE()->{exim_domains_conf} );
	my $line = $bkf->search_line($del_me);

	if (defined $line) {
		$bkf->splice_line($line,1);
		$bkf->save();
	}

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
	my $ms = _get_value("message_size");
	$ms =~ s/M$// if defined($ms);
	return $ms;
}

sub set_mailsize($) {
	my $size = shift;
	if (defined($size)) {
		unless ($size eq "") {
			throw Yaffas::Exception("err_size") unless ($size =~ /^\d+$/ && $size > 0);
			$size = uc($size)."M";
		}
		_set_value("message_size", $size);
		return;
	}
	throw Yaffas::Exception("err_size");
}

# archive

sub get_archive() {
	return _get_value("mail_archive");
}

sub set_archive($) {
	my $archive = shift;
	if (defined($archive)) {
	throw Yaffas::Exception("err_archive_name")
		unless (grep {$_ eq $archive} Yaffas::UGM::get_users("yaffasmail") or Yaffas::Check::email($archive));
	}
	_set_value("mail_archive", $archive);
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

sub conf_dump() {
	# disable conf_dump function for now
	return;
	# Verify Recipient
	_set_verify_rcp_config(get_verify_rcp());

	# Mailserver
	my $m = get_mailserver();
	_set_config("mailserver", "Yaffas::Module::Mailsrv::set_mailserver", $m) if ($m);

	# Smarthost
	my ($s, $u, $p) = get_smarthost();
	_set_smarthost_config($s, $u, $p) if ($s);

	my ($route_all, $domain) = get_smarthost_routing();
	_set_smarthost_routing_config($route_all, $domain);

	# Accept Relay
	foreach my $r (get_accept_relay()) {
		_set_config("relay-$r", "Yaffas::Module::Mailsrv::set_accept_relay", $r);
	}

	my $ms = get_mailsize();
	_set_config("mailsize", "Yaffas::Module::Mailsrv::set_mailsize", $ms) if ($ms);

	my $archive = get_archive();
	_set_config("archive", "Yaffas::Module::Mailsrv::set_archive", $archive) if (defined($archive));

	# Accept Domain
	foreach my $dom (get_accept_domains()) {
		_set_config("domains-$dom", "Yaffas::Module::Mailsrv::set_accept_domains", $dom) if ( $dom !~ m/^\s*$/);
	}
	if(fetchmail_started() == 1){
		_set_config("startfetchmail", "Yaffas::Module::Mailsrv::start_fetchmail" );
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
