#!/usr/bin/perl -w
package Yaffas::Module::ChangePW;
use strict;
use warnings;

use Yaffas;
use Yaffas::LDAP;
use Yaffas::File;
use Yaffas::File::Config;
use Yaffas::UGM;
use Yaffas::Auth;
use Yaffas::Product;
use Yaffas::Service qw(LDAP NSCD WEBMIN HYLAFAX RESTART SASLAUTHD ZARAFA_SERVER SSHD SAMBA WINBIND);
use File::Copy;
use File::Basename;
use Yaffas::Exception;
use Yaffas::Conf;
use Yaffas::Conf::Function;
use Yaffas::Constant;
use Yaffas::Module::AuthSrv;
use Error qw(:try);
eval "use DBI";

our @ISA = qw(Yaffas::Module);

=pod

=head1 NAME

Yaffas::Module::ChangePW

=head1 FUNCTIONS

=over

=item change_root_password( PASSWORD )

Changes root password in LDAP and files.

=cut

sub change_root_password($) {
	my $pass = shift;
	(Yaffas::Constant::OS =~ m/RHEL\d/ ) && return;

	throw Yaffas::Exception("err_password") unless (Yaffas::Check::password($pass));

	my $current_password;

	if (-r Yaffas::Constant::FILE->{ldap_secret_local}) {
		my $file = Yaffas::File->new(Yaffas::Constant::FILE->{ldap_secret_local});
		$current_password = $file->get_content();
	} else {
		#$current_password = Yaffas::LDAP::get_passwd();
		my $file = Yaffas::File->new(Yaffas::Constant::FILE->{ldap_secret});
		$current_password = $file->get_content();
	}

	unless (Yaffas::UGM::password("root", $pass)) {
		throw Yaffas::Exception("err_root_password");
	}

	_ldap_password($current_password, $pass);
	
	if(Yaffas::Auth::get_auth_type() eq Yaffas::Auth::Type::LOCAL_LDAP){

		_ldap_password_files($current_password, $pass);

		# replace samba password
		my $err = Yaffas::do_back_quote(Yaffas::Constant::APPLICATION->{smbpasswd}, "-w", $pass);
		throw Yaffas::Exception("err_smbpasswd", $err) if ($? != 0);

		if (Yaffas::Product::check_product("fax")) {
			_hylafax_pass($pass);
		}

		if ( Yaffas::Product::check_product("zarafa")) {
			Yaffas::Module::AuthSrv::set_zarafa_ldap();
		}

		Yaffas::Module::AuthSrv::set_searchldap_settings({'LDAPSECRET'=>$pass});
	} else {
		## remote LDAP or something
		# set ldap password, but don't change it in files

		# save root password in /etc/ldap.secret.local so we can read it and set it on for local auth
		my $file = Yaffas::File->new(Yaffas::Constant::FILE->{ldap_secret_local}, $pass);
		$file->save();

		chmod 0600, Yaffas::Constant::FILE->{ldap_secret_local};

	}

	if (Yaffas::Product::check_product("fax") || Yaffas::Product::check_product("zarafa") || Yaffas::Product::check_product("mailgate")) {
		_mysql_pass($current_password, $pass);
	}

	if ( Yaffas::Product::check_product("zarafa")) {
		_set_zarafa_db_pass($pass);
	}

	_revert_sshd_config();
	# schütze vor dem init script das wir aufrufen werdne
	$SIG{TERM} = 'IGNORE';
	Yaffas::Service::control(WEBMIN, RESTART);
	Yaffas::Service::control(LDAP, RESTART);
	Yaffas::Service::control(NSCD, RESTART) unless Yaffas::Constant::OS =~ m/RHEL\d/ ;
	Yaffas::Service::control(SSHD, RESTART);
	# have to restart samba, becuase smbpasswd does't tell samba to read the new password
	Yaffas::Service::control(SAMBA, RESTART);
	Yaffas::Service::control(WINBIND, RESTART);

	if (Yaffas::Product::check_product("mail")) {
		Yaffas::Service::control(SASLAUTHD, RESTART);
	}
	if (Yaffas::Product::check_product("zarafa")) {
		Yaffas::Service::control(ZARAFA_SERVER, RESTART);
	}

return 1;
}

sub change_admin_password($) {
	my $pass = shift;
	throw Yaffas::Exception("err_password") unless (Yaffas::Check::password($pass));

	my $user = "admin";

	my $file = new Yaffas::File(Yaffas::Constant::FILE->{miniservusers}) 
		or throw Yaffas::Exception("err_file_read", Yaffas::Constant::FILE->{miniservusers});
	my $line = "$user:".crypt($pass, substr(time(), 0, 2)).":0\n";

	my @lines = $file->search_line(qr/^admin:/);

	if (@lines) {
		map { $file->splice_line($_, 1, $line) } @lines;
	} else {
		$file->add_line($line);
	}

	$file->write();

	sleep 1;
	# schütze vor dem init script das wir aufrufen werdne
	$SIG{TERM} = 'IGNORE';

	Yaffas::Service::control(WEBMIN, RESTART);

	if ( Yaffas::Product::check_product("mailgate")) {
		_qreview_pass($pass);
	}

	return 1;
}

sub _ldap_password($$) {
	my $current_password = shift;
	my $pass = shift;

	unless (defined($pass)) {
		throw Yaffas::Exception("lbl_password_not_specified");
		return undef;
	}
	unless (defined($current_password)) {
		throw Yaffas::Exception("lbl_current_password_not_specified");
		return undef;
	}

	my $ldap_password = Yaffas::do_back_quote(Yaffas::Constant::APPLICATION->{slappasswd}, "-h", "{CRYPT}", "-s", $pass) 
		or throw Yaffas::Exception("err_execute", Yaffas::Constant::APPLICATION->{slappasswd});
	# do a ldapmodify to set up new pass for ldapadmin

	my $ldapdom = Yaffas::LDAP::get_local_domain();
	my @ldapmodcmd = (Yaffas::Constant::APPLICATION->{ldapmodify}, "-x", "-D", "cn=ldapadmin,ou=People,$ldapdom", "-w", $current_password, "-H", "ldap://127.0.0.1");

	open(LDAPPASS, "|-", @ldapmodcmd) || throw Yaffas::Exception("err_ldapmodify");
	print LDAPPASS "dn: cn=ldapadmin,ou=People,$ldapdom", "\n";
	print LDAPPASS "changetype: modify", "\n";
	print LDAPPASS "replace: userPassword", "\n";
	print LDAPPASS "userPassword: $ldap_password";
	print LDAPPASS "-", "\n";
	print LDAPPASS "\n";
	print LDAPPASS "\n";
	close(LDAPPASS) or print "error occured $? $!";

	my $check = 1;
	my $slapd_conf = Yaffas::Constant::FILE->{slapd_conf};
	my $exception = Yaffas::Exception->new();
	unless (-r $slapd_conf && -w $slapd_conf) {
		$exception->add("err_file_write", $slapd_conf);
		$check = 0;
	}

	unless ($check) {
		throw $exception;
		return undef;
	}

# /etc/ldap/slapd.conf -rw-------  1 root root crypt
	my $file = new Yaffas::File($slapd_conf) or print "cant modify $slapd_conf!\n"; 

	foreach my $line ($file->search_line(qr/^rootpw.*/)) {
		$file->splice_line($line, 1, ("rootpw\t$ldap_password"));
	}

	$file->write();

	chmod 0640, $slapd_conf;
}

sub _ldap_password_files ($$) {
	my $current_password = shift;
	my $pass = shift;

	unless (defined($pass)) {
		throw Yaffas::Exception("lbl_password_not_specified");
		return undef;
	}
	unless (defined($current_password)) {
		throw Yaffas::Exception("lbl_current_password_not_specified");
		return undef;
	}
	my $check = 1;

	my $smbldap_bind_conf = Yaffas::Constant::FILE->{smbldap_bind_conf};
	my $ldap_secret = Yaffas::Constant::FILE->{ldap_secret};
	my $libnss_ldap_conf = Yaffas::Constant::FILE->{libnss_ldap_conf};
	my $pam_ldap_conf = Yaffas::Constant::FILE->{pam_ldap_conf};
	my $ldap_conf = Yaffas::Constant::FILE->{ldap_conf};
	my $skyaptnotify = Yaffas::Constant::FILE->{skyaptnotify};

	my $exception = Yaffas::Exception->new();
	unless (-r $smbldap_bind_conf && -w $smbldap_bind_conf) {
		$exception->add("err_file_write", $smbldap_bind_conf);
		$check = 0;
	}
	unless (-r $ldap_secret && -w $ldap_secret) {
		$exception->add("err_file_write", $ldap_secret);
		$check = 0;
	}
	unless (-r $libnss_ldap_conf && -w $libnss_ldap_conf) {
		$exception->add("err_file_write", $libnss_ldap_conf);
		$check = 0;
	}
	unless (-r $pam_ldap_conf && -w $pam_ldap_conf) {
		$exception->add("err_file_write", $pam_ldap_conf);
		$check = 0;
	}
	unless (-r $ldap_conf && -w $ldap_conf) {
		$exception->add("err_file_write", $ldap_conf);
		$check = 0;
	}
	unless ($check) {
		throw $exception;
		return undef;
	}

	my $file;

	my $root_uid = Yaffas::UGM::get_uid_by_username("root");
	my $root_gid = Yaffas::UGM::get_gid_by_groupname("root");
	my $ldapread_gid = Yaffas::UGM::get_gid_by_groupname("ldapread");

# /etc/ldap.secret -rw-r-----  1 root uucp clear
	unlink $ldap_secret || throw Yaffas::Exception("err_delete_file", $ldap_secret);
	$file = new Yaffas::File($ldap_secret, $pass);
	$file->set_newline_char("");
	$file->write();
	chown $root_uid, $ldapread_gid, $ldap_secret;
	chmod 0640, $ldap_secret;

# /etc/smbldap-tools/smbldap_bind.conf -rw-r----- 1 root root clear
	$file = new Yaffas::File($smbldap_bind_conf) or print "cant modify $smbldap_bind_conf!\n"; 

	foreach my $line ($file->search_line(qr/^slavePw.*/)) {
		$file->splice_line($line, 1, ("slavePw=\"$pass\""));
	}

	foreach my $line ($file->search_line(qr/^masterPw.*/)) {
		$file->splice_line($line, 1, ("masterPw=\"$pass\""));
	}

	$file->write();

	chown $root_uid, $root_gid, $smbldap_bind_conf;

	chmod 0640, $smbldap_bind_conf;


# /etc/libnss-ldap.conf -r--------  1 root root clear
	$file = new Yaffas::File($libnss_ldap_conf) or print "cant modify $libnss_ldap_conf!\n"; 

	foreach my $line ($file->search_line(qr/^bindpw.*/)) {
		$file->splice_line($line, 1, ("bindpw $pass"));
	}

	$file->write();

	chown $root_uid, $ldapread_gid, $libnss_ldap_conf;

	chmod 0440, $libnss_ldap_conf;

# /etc/pam_ldap.conf -r--------  1 root root clear
	$file = new Yaffas::File($pam_ldap_conf) or print "cant modify $pam_ldap_conf!\n"; 

	foreach my $line ($file->search_line(qr/^bindpw.*/)) {
		$file->splice_line($line, 1, ("bindpw $pass"));
	}

	$file->write();

	chmod 0440, $pam_ldap_conf;

# /etc/ldap.conf -r--------  1 root root clear
	$file = new Yaffas::File($ldap_conf) or print "cant modify $ldap_conf!\n"; 

	foreach my $line ($file->search_line(qr/^bindpw.*/)) {
		$file->splice_line($line, 1, ("bindpw $pass"));
	}

	$file->write();

	chmod 0440, $ldap_conf;

# /etc/opengroupware.org/ogo/Defaults/skyaptnotify.plist -r--------  1 ogo ogo clear
	if (-f $skyaptnotify) {
		$file = new Yaffas::File($skyaptnotify) or print "cant modify $skyaptnotify!\n"; 

		foreach my $line ($file->search_line(qr/^\s*AptNotifySkyrixPassword\s*=.*/)) {
			$file->splice_line($line, 1, ("AptNotifySkyrixPassword = \"$pass\";\n"));
		}

		$file->write();

		chmod 0400, $skyaptnotify;
	}

	if (Yaffas::Product::check_product("zarafa")) {
		$file = new Yaffas::File::Config(Yaffas::Constant::FILE->{zarafa_server_cfg},
										 {
										  -SplitPolicy => 'custom',
										  -SplitDelimiter => '\s*=\s*',
										  -StoreDelimiter => "=",
										 });
		$file->get_cfg_values()->{mysql_password} = $pass;
		$file->write();

		$file = new Yaffas::File::Config(Yaffas::Constant::FILE->{zarafa_ldap_cfg},
										 {
										  -SplitPolicy => 'custom',
										  -SplitDelimiter => '\s*=\s*',
										  -StoreDelimiter => "=",
										 });
		$file->get_cfg_values()->{ldap_bind_passwd} = $pass;
		$file->write();
	}
}

sub _hylafax_pass () {
	my $hfdir = Yaffas::Constant::DIR->{hylafax};
	if ( -d $hfdir ) {
		my $frompass = Yaffas::Constant::FILE->{ldap_secret};
		my $topass = "${hfdir}". basename($frompass) ;
		copy($frompass,$topass) or throw Yaffas::Exception("err_copy_file", $frompass, "Can't copy to $topass:$!");
		my $passfile = new Yaffas::File($topass);
		$passfile->set_permissions("root","uucp",0640);
		$passfile->save() or throw Yaffas::Exception("err_write_file", $topass);

		Yaffas::Service::control(HYLAFAX, RESTART);
	}
	return 1;
}

sub _mysql_pass ($$) {
	my $oldpass = shift;
	my $pass = shift;

	my $dbh = DBI->connect('dbi:mysql:mysql', 'root', $oldpass) || throw Yaffas::Exception('err_mysql_password');
	my $sth = $dbh->prepare("SET PASSWORD = PASSWORD(?)");
	$sth->execute($pass) || throw Yaffas::Exception('err_mysql_password');
	
	return 1;
}

sub _qreview_pass($) {
	my $pass = shift;

	eval qq#
	use lib "/usr/local/mppserver/lib";
	use Crypt;
	#;

	unless ($@) {
		my $p = Crypt::crypt($pass);

		my $file = Yaffas::File->new(Yaffas::Constant::FILE->{qreview_users});

		my $line = $file->search_line(qr/^auth:admin:passwd:/);
		if ($line) {
			$file->splice_line($line, 1, "auth:admin:passwd:$p");
		}
		else {
			$file->add_line("auth:admin:passwd:$p");
		}
		$file->save();
	}
	else {
		throw Yaffas::Exception("err_loading_crypt_failed");
	}
}

sub check_passwords($$) {
	my $pass1 = shift;
	my $pass2 = shift;

	throw Yaffas::Exception("err_password_equal") if ($pass1 ne $pass2);
}

sub _set_zarafa_db_pass($) {
	my $pass = shift;
	my $server_file = Yaffas::File::Config->new(Yaffas::Constant::FILE->{'zarafa_server_cfg'},
										{
										-SplitPolicy => 'custom',
										-SplitDelimiter => '\s*=\s*',
										-StoreDelimiter => ' = ',
										}
									);
	my $cfg_values = $server_file->get_cfg_values();
	$cfg_values->{'mysql_password'} = "$pass";
	$server_file->set_permissions("root","root",00600);
	$server_file->write();
}

sub _revert_sshd_config() {
    my $f = Yaffas::File::Config->new(  Yaffas::Constant::FILE->{sshd_config} );
    if($f->get_cfg_values()->{PermitRootLogin} eq "no"){
	$f->get_cfg_values()->{PermitRootLogin} = "yes";
	$f->save();
    }
}

sub conf_dump() {
    1;
}

=back

=cut

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
