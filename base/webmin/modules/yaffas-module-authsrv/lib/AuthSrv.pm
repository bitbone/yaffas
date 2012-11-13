#!/usr/bin/perl

package Yaffas::Module::AuthSrv;

use Yaffas::File;
use Yaffas::LDAP;
use Yaffas::Check;
use Yaffas::Constant;
use Yaffas::Conf;
use Yaffas::File::Config;
use File::Samba;
use Yaffas::Service
  qw(control START STOP RESTART LDAP NSCD NSLCD HYLAFAX SASLAUTHD SAMBA WINBIND WEBMIN USERMIN ZARAFA_SERVER);
use Yaffas::Product qw(check_product);
use Yaffas::Module::Netconf;
use Yaffas::Exception;
use Yaffas::Auth;
use Yaffas::Auth::Type qw(:standard);
use Yaffas::Module::Users;
use Yaffas::Module::Mailsrv::Postfix;
use Yaffas::Network;
use Yaffas::UGM;
use File::Copy;
use File::Basename;
use Error qw(:try);
use File::Temp qw(tempfile);
use Net::LDAP;
use Net::LDAP::Util;
use strict;
use warnings;

=pod

=head1 NAME

Yaffas::Module::AuthSrv

=head1 DESCRIPTION

This Modules provides functions for Webmin module bbauthsrv

=head1 FUNCTIONS

=over

=item check_pdc_ping( )

do a wbinfo ping to check connection
returns info string

=cut

sub check_pdc_ping() {
	my $rv =
	  Yaffas::do_back_quote( Yaffas::Constant::APPLICATION->{'wbinfo'}, "-p" );
	if ( $? == 0 ) {
		return $rv;
	}
	else {
		return undef;
	}
}

=item check_pdc_trust( )

do a wbinfo trust to check connection
returns info string

=cut

sub check_pdc_trust() {
	my $rv =
	  Yaffas::do_back_quote( Yaffas::Constant::APPLICATION->{'wbinfo'}, "-t" );
	if ( $? == 0 ) {
		return $rv;
	}
	else {
		return undef;
	}
}

=item mod_pam(<methods>)

Only for RHEL5 Systems!

Modify /etc/pam.d/system-auth-ac, so that winbind or ldap authentication is possible.

Will also modify /etc/sysconfig/authconfig.

<methods> can be a list of authentication methods. Currently only 'winbind'
and 'ldap' are supported. B<Specifying more than one method is not fully tested>.

=cut

sub mod_pam {
	Yaffas::Constant::OS =~ m/RHEL\d/ or return;
	my %methods;
	@methods{@_} = ();
	my $authconfig = Yaffas::Constant::APPLICATION->{'authconfig'};

	my $ldap;
	my $winbind;
	if ( exists $methods{winbind} ) {
		$winbind = "enable";
	}
	else {
		$winbind = "disable";
	}
	if ( exists $methods{ldap} ) {
		$ldap = "enable";
	}
	else {
		$ldap = "disable";
	}
	Yaffas::do_back_quote(
		$authconfig,
		"--" . $ldap . "ldapauth",
		"--" . $winbind . "winbindauth", "--update"
	);
}

=item mod_nsswitch()

modify /etc/nsswitch.conf to reflect the present authentication setting

=cut

sub mod_nsswitch(;$) {
	my $method = shift;

# calling get_auth_type before setting the auth type in nsswitch.conf is likely to fail
# so mod_nsswitch should be called with arguments!
	unless ( defined $method && $method ne "" ) {
		if (   ( Yaffas::Auth::get_auth_type() eq ADS )
			|| ( Yaffas::Auth::get_auth_type() eq PDC ) )
		{
			$method = "files winbind";
		}
		elsif (( Yaffas::Auth::get_auth_type() eq LOCAL_LDAP )
			|| ( Yaffas::Auth::get_auth_type() eq REMOTE_LDAP ) )
		{
			$method = "files ldap";
		}
		elsif ( Yaffas::Auth::get_auth_type() eq FILES ) {
			$method = "files";
		}
		else {

			# fallback if something goes wrong
			$method = "files ldap winbind";
		}
	}

	my $file = Yaffas::File::Config->new(
		Yaffas::Constant::FILE->{'nsswitch'},
		{
			-SplitPolicy    => 'custom',
			-SplitDelimiter => '\s*:\s*',
			-StoreDelimiter => ': ',
		}
	  )
	  or throw Yaffas::Exception( "err_file_write",
		Yaffas::Constant::FILE->{'nsswitch'} );

	my $cfg = $file->get_cfg_values();
	$cfg->{passwd} = $method;
	$cfg->{group}  = $method;
	$cfg->{shadow} = $method;

	$file->write();
}

=item show_pdc_users( )

do a wbinfo users to check connection
return user array

=cut

sub show_pdc_users() {
	my @rv = split(
		/\s+/,
		Yaffas::do_back_quote(
			Yaffas::Constant::APPLICATION->{'wbinfo'}, "-u"
		)
	);
	if ( $? == 0 ) {
		return @rv;
	}
	else {
		return undef;
	}
}

=item net_rpc_join( DOMADM PASS [ TYPE ])

trys join to workgroup from smb.conf with given user and pass

=cut

sub net_rpc_join($$;$) {
	my $domadm = shift;
	my $pass   = shift;
	my $type   = shift;
	$type = "win" unless ( defined($type) );

	my @re;
	if ( $type eq "win" ) {
		set_time();

#ATTENTION
#this is needed because the restart of samba in Yaffas::Module::Users::set_admins
#can cause problems otherwise!
#better solution appreciated though
		sleep 5;
		@re = Yaffas::do_back_quote( Yaffas::Constant::APPLICATION->{'net'},
			'ads', 'join', '-U', "$domadm%$pass" );
	}
	else {
		@re = Yaffas::do_back_quote( Yaffas::Constant::APPLICATION->{'net'},
			'join', 'ads', '-U', "$domadm%$pass" );
	}

	if ( $? == 0 ) {
		@re = Yaffas::do_back_quote( Yaffas::Constant::APPLICATION->{'wbinfo'},
			"--set-auth-user", "$domadm%$pass" );
		Yaffas::Service::control( WINBIND, RESTART );
		return 1;
	}
	else {
		throw Yaffas::Exception(
			'err_joining_domain',
			[
				"type = $type",
				"Domain Administrator = $domadm",
				"output: " . ( join( ",", @re ) )
			]
		);
	}
}

=item pam_login_winbind( on | off )

adds / removes entrys for winbind to /etc/pam.d/login

=cut

sub pam_login_winbind($) {
	my $switch = shift;
	throw Yaffas::Exception("err_only_on_off")
	  if ( $switch ne 'on' && $switch ne 'off' );

	my $plogin = Yaffas::File->new( Yaffas::Constant::FILE->{pamd_login} )
	  or throw Yaffas::Exception( "err_file_read",
		Yaffas::Constant::FILE->{pamd_login} );

	my $linenr =
	  $plogin->search_line(qr/^\s*auth\s+sufficient\s+.*pam_winbind.so/);
	if ( defined($linenr) && $switch eq 'off' ) {
		$plogin->splice_line( $linenr, 1 );
	}
	elsif ( !defined($linenr) && $switch eq "on" ) {
		$plogin->add_line("auth\tsufficient\t/lib/security/pam_winbind.so");
	}

	$linenr = $plogin->search_line(
qr/^\s*auth\s+required\s+.*pam_pwdb.so\s+use_first_pass\s+shadow\s+nullok/
	);
	if ( defined($linenr) && $switch eq 'off' ) {
		$plogin->splice_line( $linenr, 1 );
	}
	elsif ( !defined($linenr) && $switch eq "on" ) {
		$plogin->add_line(
"auth\trequired\t/lib/security/pam_pwdb.so use_first_pass shadow nullok"
		);
	}

	$linenr =
	  $plogin->search_line(qr/^\s*account\s+required\s+.*pam_winbind.so/);
	if ( defined($linenr) && $switch eq 'off' ) {
		$plogin->splice_line( $linenr, 1 );
	}
	elsif ( !defined($linenr) && $switch eq "on" ) {
		$plogin->add_line("account\trequired\t/lib/security/pam_winbind.so");
	}

	$plogin->write();
}

=item set_bk_ldap_auth( HOST BASEDN BINDDN BINDPW USERDN GROUPDN USERSEARCH EMAILATTR [ENCRYPTION] [SAMBASID] )

Sets HOST, BASEDN, BINDDN and BINDPW in all necessary files
If given, sets sambaSID in remote ldap

=cut

sub set_bk_ldap_auth($$$$$$$$;$$) {
	my $i = 1;
	my ($hosts, $basedn, $binddn, $bindpw, $userdn, $groupdn, $usersearch, $email, $encryption, $sambasid) = @_;
	unless ( ref($hosts) eq "ARRAY" ) {
		$hosts = [$hosts];
	}
	my $protocol = "ldap://";
	if ($encryption) {
		$protocol = "ldaps://";
	}
	my @uris = map( $protocol . $_, @{$hosts} );
	my $ldapuri = join " ", @uris;

	my $exception = Yaffas::Exception->new();

	my @rollback = (
		Yaffas::Constant::FILE->{'pam_ldap_conf'},
		Yaffas::Constant::FILE->{'libnss_ldap_conf'},
		Yaffas::Constant::FILE->{'ldap_conf'},
		Yaffas::Constant::FILE->{'samba_conf'},
		Yaffas::Constant::FILE->{'smb_includes_global'},
		Yaffas::Constant::FILE->{'smbldap_conf'},
		Yaffas::Constant::FILE->{'smbldap_bind_conf'},
		Yaffas::Constant::FILE->{'default_domain'},
		Yaffas::Constant::FILE->{'hosts'},
		Yaffas::Constant::FILE->{'zarafa_ldap_cfg'},
	);
	my $id = rollback_prepare(@rollback);

	try {

		# check all input values
		foreach my $host ( @{$hosts} ) {
			$exception->add("err_invalid_host")
			  if (
				!(
					   Yaffas::Check::ip($host)
					|| Yaffas::Check::hostname($host)
					|| Yaffas::Check::domainname($host)
				)
			  );
		}

		$exception->add("err_userdn")
		  if ( $userdn && !Yaffas::Check::dn($userdn) );
		$exception->add("err_groupdn")
		  if ( $groupdn && !Yaffas::Check::dn($groupdn) );
		$exception->add("err_basedn") if ( !Yaffas::Check::dn($basedn) );
		$exception->add("err_binddn") if ( !Yaffas::Check::dn($binddn) );
		$exception->add("err_pass")   if ( !Yaffas::Check::password($bindpw) );
		$exception->add("err_searchattr")
		  unless ( Yaffas::Check::alpha_num($usersearch) );
		$exception->add("err_emailattr")
		  unless ( Yaffas::Check::alpha_num($email) );

		throw $exception if $exception;

		# Disable AuthSrv if we are not authenticating against localhost
		my $deactivate = 1;
		foreach my $host ( @{$hosts} ) {
			if ( Yaffas::Auth::is_auth_srv()
				&& ( $host eq "127.0.0.1" || $host eq "localhost" ) )
			{
				$deactivate = 0;
			}
		}
		if ($deactivate) {
			auth_srv_ldap("deactivate");
		}
		$deactivate = 1;
		foreach my $host ( @{$hosts} ) {
			if ( $host eq "127.0.0.1" || $host eq "localhost" ) {
				$deactivate = 0;
			}
		}
		if ($deactivate) {
			auth_srv_pdc("deactivate");
		}

		# /etc/pam_ldap.conf 					-r--------	root root
		# /etc/libnss-ldap.conf					-r--r-----	root uucp
		my @files = (
			Yaffas::Constant::FILE->{pam_ldap_conf},
			Yaffas::Constant::FILE->{libnss_ldap_conf},
			Yaffas::Constant::FILE->{ldap_conf},
		);

		foreach my $cfile (@files) {
			my $lc = Yaffas::File::Config->new(
				$cfile,
				{
					-SplitPolicy    => 'custom',
					-SplitDelimiter => '\s+',
					-StoreDelimiter => ' ',
				}
			) or throw Yaffas::Exception( "err_file_read", $cfile );

			my $lc_ref = $lc->get_cfg_values();

			# $lc_ref->{host} = $host;
			$lc_ref->{uri} = $ldapuri;

			$lc_ref->{base}   = $basedn;
			$lc_ref->{binddn} = $binddn;
			$lc_ref->{bindpw} = $bindpw;

			if ( length($userdn) > 0 ) {
				$lc_ref->{nss_base_passwd} =
				  $userdn . ( $userdn =~ m/,/ ? "" : ",$basedn" );
				$lc_ref->{nss_base_shadow} =
				  $userdn . ( $userdn =~ m/,/ ? "" : ",$basedn" );
			}
			else {
				delete $lc_ref->{nss_base_passwd};
				delete $lc_ref->{nss_base_shadow};
			}

			if ( length($groupdn) > 0 ) {
				$lc_ref->{nss_base_group} =
				  $groupdn . ( $groupdn =~ m/,/ ? "" : ",$basedn" );
			}
			else {
				delete $lc_ref->{nss_base_group};
			}

			#$lc_ref->{pam_login_attribute} = $usersearch;
			$lc->write();
		}

		# /etc/samba/smb.conf					-rw-r--r--	root root
		my $smb = File::Samba->new( Yaffas::Constant::FILE->{'samba_conf'} )
		  or throw Yaffas::Exception( "err_file_read",
			Yaffas::Constant::FILE->{samba_conf} );
		$smb->version(3);
		$smb->globalParameter( 'ldap admin dn',  $binddn );
		$smb->globalParameter( 'ldap suffix',    $basedn );
		$smb->globalParameter( 'ldap delete dn', 'Yes' );

		if ( ( length $groupdn ) > 0 ) {
			$smb->globalParameter( 'ldap group suffix', $groupdn );
		}
		else {
			$smb->deleteGlobalParameter('ldap group suffix');
		}

		if ( ( length $userdn ) > 0 ) {
			$smb->globalParameter( 'ldap machine suffix', $userdn );
			$smb->globalParameter( 'ldap user suffix',    $userdn );
		}
		else {
			$smb->deleteGlobalParameter('ldap machine suffix');
			$smb->deleteGlobalParameter('ldap user suffix');
		}

		$smb->globalParameter( 'ldap ssl', 'start tls' );
		$smb->save( Yaffas::Constant::FILE->{samba_conf} )
		  or throw Yaffas::Exception( 'err_file_write',
			Yaffas::Constant::FILE->{samba_conf} );

		# /etc/samba/smbopts.global				-rw-r--r--	root root
		$smb =
		  File::Samba->new( Yaffas::Constant::FILE->{'smb_includes_global'} )
		  or throw Yaffas::Exception( "err_file_read",
			Yaffas::Constant::FILE->{smb_includes_global} );
		$smb->version(3);
		$smb->globalParameter( 'passdb backend', 'ldapsam:"' . $ldapuri . '"' );
		$smb->deleteGlobalParameter('password server');
		$smb->deleteGlobalParameter('idmap gid');
		$smb->deleteGlobalParameter('idmap uid');
		$smb->deleteGlobalParameter('template homedir');
		$smb->deleteGlobalParameter('template shell');
		$smb->deleteGlobalParameter('winbind separator');
		$smb->deleteGlobalParameter('winbind use default domain');
		$smb->deleteGlobalParameter('realm');
		$smb->deleteGlobalParameter('client schannel');
		$smb->deleteGlobalParameter('winbind enum users');
		$smb->deleteGlobalParameter('winbind enum groups');
		$smb->globalParameter( 'security', 'user' );
		$smb->save( Yaffas::Constant::FILE->{smb_includes_global} )
		  or throw Yaffas::Exception( 'err_file_write',
			Yaffas::Constant::FILE->{smb_includes_global} );

# NOTE: because $suffix is needed for the other entries - like nextfreeuid - we can't use Yaffas::File::Config

		# /etc/smbldap-tools/smbldap.conf		-rw-r--r--	root root
		my $smbldap_c =
		  Yaffas::File->new( Yaffas::Constant::FILE->{smbldap_conf} )
		  or throw Yaffas::Exception( "err_file_read",
			Yaffas::Constant::FILE->{smbldap_conf} );

		# slaveLDAP="127.0.0.1"
		my $linenr = $smbldap_c->search_line(qr/^\s*slaveLDAP\s*=/);
		if ( defined($linenr) ) {
			$smbldap_c->splice_line( $linenr, 1, "slaveLDAP=\"" . ${$hosts}[0] . "\"" );
		}
		undef($linenr);

		# masterLDAP="127.0.0.1"
		$linenr = $smbldap_c->search_line(qr/^\s*masterLDAP\s*=/);
		if ( defined($linenr) ) {
			$smbldap_c->splice_line( $linenr, 1, "masterLDAP=\"" . ${$hosts}[0] . "\"" );
		}
		undef($linenr);

		# suffix="o=bitbone,c=de"
		$linenr = $smbldap_c->search_line(qr/^\s*suffix\s*=/);
		if ( defined($linenr) ) {
			$smbldap_c->splice_line( $linenr, 1, "suffix=\"$basedn\"" );
		}
		undef($linenr);

		$linenr = $smbldap_c->search_line(qr/^\s*usersdn\s*=/);
		if ( defined($linenr) ) {
			$smbldap_c->splice_line( $linenr, 1,
				"usersdn=\"$userdn,\${suffix}\"" );
		}
		undef($linenr);

		$linenr = $smbldap_c->search_line(qr/^\s*groupsdn\s*=/);
		if ( defined($linenr) ) {
			$smbldap_c->splice_line( $linenr, 1,
				"groupsdn=\"$groupdn,\${suffix}\"" );
		}
		undef($linenr);

		$smbldap_c->write();

		# /etc/smbldap-tools/smbldap_bind.conf	-rw-r-----	root root
		my $smbldap_bind = Yaffas::File::Config->new(
			Yaffas::Constant::FILE->{smbldap_bind_conf},
			{
				-SplitPolicy    => 'custom',
				-SplitDelimiter => '\s*=\s*',
				-StoreDelimiter => '=',
			}
		  )
		  or throw Yaffas::Exception( "err_file_read",
			Yaffas::Constant::FILE->{smbldap_bind_conf} );

		my $slb_ref = $smbldap_bind->get_cfg_values();
		$slb_ref->{'slaveDN'}  = "'" . $binddn . "'";
		$slb_ref->{'slavePw'}  = "'" . $bindpw . "'";
		$slb_ref->{'masterDN'} = "'" . $binddn . "'";
		$slb_ref->{'masterPw'} = "'" . $bindpw . "'";

		$smbldap_bind->write();

		_link_webaccess_plugin("passwd");
		_link_webapp_plugin("passwd");
		update_passwd_plugin_config( "ldap", ${$hosts}[0], $basedn );

		# be sure system domain ist same as in ldap tree if local auth.
		my $is_local_auth = 0;
		foreach my $host ( @{$hosts} ) {
			if ( $host eq "127.0.0.1" || $host eq "localhost" ) {
				$is_local_auth = 1;
			}
		}
		if ($is_local_auth) {
			my $netconf  = Yaffas::Module::Netconf->new();
			my $hostname = $netconf->hostname();
			my $ip       = Yaffas::Network::get_ip("eth0");
			my $olddom   = $netconf->domainname();
			my $newdom   = Yaffas::LDAP::dn_to_name($basedn);

			# /etc/defaultdomain
			my $ddconf =
			  Yaffas::File->new( Yaffas::Constant::FILE->{default_domain},
				$newdom )
			  or throw Yaffas::Exception( "err_file_read",
				Yaffas::Constant::FILE->{default_domain} );
			$ddconf->write()
			  or throw Yaffas::Exception( "err_file_write",
				Yaffas::Constant::FILE->{default_domain} );

			# /etc/hosts
			my $conf = Yaffas::File->new( Yaffas::Constant::FILE->{hosts} )
			  or throw Yaffas::Exception( "err_file_read",
				Yaffas::Constant::FILE->{hosts} );

			my $linenr = $conf->search_line(
				qr/^\d+\.\d+\.\d+\.\d+\s+.*\.$olddom.*\s+$hostname/);
			if ( defined($linenr) ) {
				$conf->splice_line( $linenr, 1,
					"$ip\t$hostname.$newdom\t$hostname" );
			}

			$linenr = $conf->search_line(qr/^127.0.0.1\s+.*localhost/);
			if ( not $linenr ) {
				$conf->add_line("127.0.0.1 localhost.localdomain localhost");
			}

			$conf->write()
			  or throw Yaffas::Exception( "err_file_write",
				Yaffas::Constant::FILE->{hosts} );

			# move ldap_secret_local file to ldap_secret
			move(
				Yaffas::Constant::FILE->{ldap_secret_local},
				Yaffas::Constant::FILE->{ldap_secret}
			);
		}

# /etc/ldap.settings (must be done after samba, otherwise get_auth_type fails...
		my $ls_ref = {};
		$ls_ref->{USERSEARCH} = $usersearch;
		if ( ( length $userdn ) > 0 ) {
			$ls_ref->{USER_SEARCHBASE} = $userdn . "," . $basedn;
		}
		else {
			$ls_ref->{USER_SEARCHBASE} = $basedn;
		}
		$ls_ref->{LDAPURI} = $ldapuri;

		$ls_ref->{BINDDN}     = $binddn;
		$ls_ref->{BASEDN}     = $basedn;
		$ls_ref->{LDAPSECRET} = $bindpw;
		$ls_ref->{EMAIL}      = $email if ( defined $email );

		set_searchldap_settings($ls_ref);

		# /etc/ldap/ldap.conf
		my $ldap_conf = Yaffas::File::Config->new(
			Yaffas::Constant::FILE->{'ldap_ldap_conf'},
			{
				-SplitPolicy    => 'custom',
				-SplitDelimiter => '\s+',
				-StoreDelimiter => ' ',
			}
		);

		my $ldap_conf_ref = $ldap_conf->get_cfg_values();
		$ldap_conf_ref->{'host'} = ${$hosts}[0];
		$ldap_conf_ref->{'URI'}  = $ldapuri;
		$ldap_conf_ref->{'base'} = $basedn;
		$ldap_conf->write();

		mod_nsswitch("files ldap");

		#/etc/zarafa/ldap.cfg
		if ( Yaffas::Product::check_product("zarafa") ) {
			my $zarafa_settings = {
				'ldap_bind_user' => $binddn,

				#'ldap_host' => $host,
				'ldap_uri' => $ldapuri,
			};

			#unless (defined $encryption) {
			#	$zarafa_settings->{'ldap_port'} = '389';
			#	$zarafa_settings->{'ldap_protocol'} = 'ldap';
			#}
			set_zarafa_ldap($zarafa_settings);
			Yaffas::Service::control( ZARAFA_SERVER, RESTART );
			system( Yaffas::Constant::APPLICATION->{zarafa_admin}, "--sync" );
		}

		# set pass for ldap-samba...
		my $smbpasswd = Yaffas::Constant::APPLICATION->{smbpasswd};
		if ( -f $smbpasswd ) {
			my $ret = Yaffas::do_back_quote( $smbpasswd, "-w", $bindpw );
			throw Yaffas::Exception( "err_file_read", $ret ) if ( $? != 0 );
		}

		Yaffas::Service::control( SAMBA,   RESTART );
		Yaffas::Service::control( WINBIND, RESTART );

		if ( check_product("mail") ) {
			Yaffas::Service::control( SASLAUTHD, RESTART );
		}
		if ( check_product("fax") ) {
			Yaffas::Service::control( HYLAFAX, RESTART );
		}
		Yaffas::Service::control( USERMIN, RESTART );

		# set sambaSID on remote LDAP
		if ( defined $sambasid ) {
			my $ldap = Net::LDAP->new( \@uris, verify => 'none' )
			  or throw Yaffas::Exception('err_set_sambasid');
			my $msg = $ldap->bind( $binddn, password => $bindpw );
			$msg->code
			  && throw Yaffas::Exception( 'err_set_sambasid',
				[ $msg->code, $msg->error_desc ] );

			my $netconf         = Yaffas::Module::Netconf->new();
			my $sambadomainname = $netconf->hostname();
			$msg = $ldap->search(
				base => $basedn,
				filter =>
"(&(sambaDomainName=$sambadomainname)(!(sambaSID=$sambasid)))",
				attrs => []
			);
			$msg->code
			  && throw Yaffas::Exception( 'err_set_sambasid',
				[ $msg->code, $msg->error_desc ] );

			my @entries = $msg->entries;
			if ( scalar @entries > 1 ) {
				throw Yaffas::Exception('err_ldap_duplicate_sambadomain');
			}
			elsif ( scalar @entries == 1 ) {
				$msg =
				  $ldap->modify( $entries[0]->dn,
					replace => { 'sambaSID' => $sambasid } );
				$msg->code
				  && throw Yaffas::Exception( 'err_set_sambasid',
					[ $msg->code, $msg->error_desc ] );
			}

			$msg = $ldap->unbind;
			$msg->code
			  && throw Yaffas::Exception( 'err_set_sambasid',
				[ $msg->code, $msg->error_desc ] );
		}

		# for RedHat
		mod_pam("ldap");

		# postfix
		my $user_searchbase;
		if ( ( length $userdn ) > 0 ) {
			$user_searchbase = $userdn . "," . $basedn;
		}
		else {
			$user_searchbase = $basedn;
		}

		my $postfix_settings = {
			'server_host'      => $ldapuri,
			'search_base'      => $user_searchbase,
			'bind_dn'          => undef,
			'bind_pw'          => undef,
			'bind'             => undef,
			'query_filter'     => '(&(mail=%s)(zarafaAccount=1))',
			'result_attribute' => 'mail',
		};
		Yaffas::Module::Mailsrv::Postfix::set_postfix_ldap( $postfix_settings,
			"users" );

		$postfix_settings->{query_filter} = '(zarafaAliases=%s)';
		Yaffas::Module::Mailsrv::Postfix::set_postfix_ldap( $postfix_settings,
			"aliases" );

		Yaffas::UGM::create_group_aliases();

		Yaffas::Module::Mailsrv::Postfix::toggle_distribution_groups("file");

	}
	catch Yaffas::Exception with {
		my $e = shift;
		try {
			rollback_exec($id);
		}
		catch Yaffas::Exception with {
			$e->append(shift);
		};
		$e->throw();
	}
	otherwise {
		my $e = Yaffas::Exception->new();
		try {
			rollback_exec($id);
		}
		catch Yaffas::Exception with {
			$e->append(shift);
		};
		$e->add( "err_syntax", shift );
		$e->throw();
	};
}

=item get_all_sambasid( HOST, BASEDN, BINDDN, BINDPW [ENCRYPTION] )

Searches for Samba Domains in remote ldap.

Returns a hash reference with sambaSID's as keys and a reference
to a list of sambaDomainNames as value.

=cut

sub get_all_sambasid ($$$$;$) {
	my ( $host, $basedn, $binddn, $bindpw, $ldap_encryption ) = @_;
	my $all_sambasid = {};

	if ( defined $ldap_encryption ) {
		$host = 'ldaps://' . $host;
	}
	else {
		$host = 'ldap://' . $host;
	}

	my $ldap = Net::LDAP->new( $host, verify => 'none' )
	  or throw Yaffas::Exception('err_get_sambasid');
	my $msg = $ldap->bind( $binddn, password => $bindpw );
	$msg->code
	  && throw Yaffas::Exception( 'err_get_sambasid',
		[ $msg->code, $msg->error_desc ] );

	$msg = $ldap->search(
		base   => $basedn,
		filter => '(sambaSID=*)',
		attrs  => ['sambaSID']
	);
	$msg->code
	  && throw Yaffas::Exception( 'err_get_sambasid',
		[ $msg->code, $msg->error_desc ] );
	foreach my $entry ( $msg->entries ) {
		my $sid = $entry->get_value('sambaSID');
		next unless $sid =~ m/^(S-\d+-\d+-\d+-\d+-\d+-\d+)/;
		$all_sambasid->{$1} = [];
	}

	foreach my $sid ( keys %$all_sambasid ) {
		my $msg_dn = $ldap->search(
			base   => $basedn,
			filter => '(sambaSID=' . $sid . ')',
			attrs  => ['sambaDomainName']
		);
		$msg_dn->code
		  && throw Yaffas::Exception( 'err_get_sambasid',
			[ $msg->code, $msg->error_desc ] );
		foreach ( $msg_dn->entries ) {
			push( @{ $all_sambasid->{$sid} },
				$_->get_value('sambaDomainName') );
		}
	}

	$msg = $ldap->unbind;
	$msg->code
	  && throw Yaffas::Exception( 'err_get_sambasid',
		[ $msg->code, $msg->error_desc ] );

	return $all_sambasid;
}

=item set_local_auth

This method simply uses Yaffas::Module::AuthSrv::set_bk_ldap_auth() but
sets the parameters appropriate for local authentication. The LDAP bind 
password is taken out of /etc/ldap.secret

=cut

sub set_local_auth() {

	# Don't work if there is nothing to do
	unless ( Yaffas::Auth::get_auth_type() eq LOCAL_LDAP ) {
		my $host   = "127.0.0.1";
		my $basedn = Yaffas::LDAP::get_local_domain();
		my $binddn = "cn=ldapadmin,ou=People," . $basedn;
		my $pass;
		my $local   = Yaffas::Constant::FILE->{ldap_secret_local};
		my $remote  = Yaffas::Constant::FILE->{ldap_secret};
		my $userdn  = "ou=People";
		my $groupdn = "ou=Group";

		my $file;
		if ( -r $local ) {
			$file = Yaffas::File->new($local);
			$pass = $file->get_content();
			$file =
			  Yaffas::File->new( Yaffas::Constant::FILE->{ldap_secret}, $pass );
			$file->save()
			  or throw Yaffas::Exception( "err_write_file",
				Yaffas::Constant::FILE->{ldap_secret} );

			#update ldap.secret in hylafax, if existing
			my $hfdir = Yaffas::Constant::DIR->{hylafax};
			if ( -d $hfdir ) {
				my $frompass = Yaffas::Constant::FILE->{ldap_secret};
				my $topass   = "${hfdir}" . basename($frompass);
				copy( $frompass, $topass )
				  or throw Yaffas::Exception( "err_copy_file", $frompass,
					"Can't copy to $topass:$!" );
				my $passfile = new Yaffas::File($topass);
				$passfile->set_permissions( "root", "uucp", 0640 );
				$passfile->save()
				  or throw Yaffas::Exception( "err_write_file", $topass );
			}
			unlink $local;
		}
		elsif ( -r $remote ) {
			$file = Yaffas::File->new($remote);
			$pass = $file->get_content()
			  or throw Yaffas::Exception( "err_file_read", $remote );
		}
		else {
			throw Yaffas::Exception("err_no_ldap_secret");
		}

		set_bk_ldap_auth(
			$host, $basedn, $binddn, $pass, $userdn, $groupdn,
			"uid", "mail",  undef
		);
	}
}

=item auth_srv_pdc ( [ AUTH ] )

AUTH can be 'activate' or 'deactivate'.
Returns 1 if pdc is enabled, otherwise 0.

=cut

sub auth_srv_pdc (;$) {
	my $auth    = shift;
	my $smbconf = Yaffas::File->new( Yaffas::Constant::FILE->{smb_includes} );

	my $linenr = $smbconf->search_line(
		qr#^\s*include\s*=\s*/etc/samba/smbopts\.pdc-global\s*#);

	if ( defined $auth ) {
		my @content = grep { !/global$/ } $smbconf->get_content();

		$smbconf->wipe_content();
		$smbconf->add_line("include = /etc/samba/smbopts.global");

		if ( $auth eq 'activate' ) {
			$smbconf->add_line("include = /etc/samba/smbopts.pdc-global");
			$smbconf->add_line("include = /etc/samba/smbopts.pdc-shares")
			  unless ( grep /pdc-shares$/, @content );
		}

		if ( $auth eq 'deactivate' ) {
			@content = grep { !/smbopts\.pdc-shares/ } @content;
		}

		$smbconf->add_line(@content);

		$smbconf->write()
		  or throw Yaffas::Exception( "err_file_write", "smb_includes_global" );
	}

	return ( defined $linenr ? 1 : 0 );
}

=item auth_srv_ldap( AUTH )

AUTH can be 'activate' or 'deactivate'.
Adds and removes 'product' auth to bkversion.

=cut

sub auth_srv_ldap($) {
	my $auth = shift;
	my $prod = "auth";

	# check all input values
	my $exception = Yaffas::Exception->new();

#$exception->add("err_prod_inst") if (Yaffas::Product::check_product($prod) && $auth eq 'activate');
	$exception->add("err_auth")
	  unless ( $auth eq 'activate' || $auth eq 'deactivate' );

	throw $exception if $exception;

	my $conf = Yaffas::File::Config->new(
		Yaffas::Constant::FILE->{'bkversion'},
		{
			-SplitPolicy    => 'custom',
			-SplitDelimiter => '\s*=\s*',
			-StoreDelimiter => '=',
		}
	  )
	  or throw Yaffas::Exception( "err_file_read",
		Yaffas::Constant::FILE->{'bkversion'} );

	my $chash = $conf->get_cfg_values();
	if ( $auth eq 'activate' ) {
		$chash->{$prod} = "yaffas|AUTH v1.00";
	}
	else {
		delete $chash->{$prod};
	}

	$conf->write()
	  or throw Yaffas::Exception( "err_file_write",
		Yaffas::Constant::FILE->{'bkversion'} );

	# (un)set option to bind on specified device
	my $slapc =
	  Yaffas::File->new( Yaffas::Constant::FILE->{'slapd_default_conf'} )
	  or throw Yaffas::Exception( "err_file_read",
		Yaffas::Constant::FILE->{'slapd_default_conf'} );

	my $linenr = $slapc->search_line(qr/^\s*SLAPD_SERVICES=/);
	if ( defined($linenr) ) {
		if ( $auth eq 'activate' ) {
			$slapc->splice_line( $linenr, 1,
				"SLAPD_SERVICES=\" ldap:/// ldaps:/// \"" );
		}
		else {
			$slapc->splice_line( $linenr, 1,
				"SLAPD_SERVICES=\" ldap://127.0.0.1 \"" );
		}
	}
	$slapc->write() or throw Yaffas::Exception( "err_file_write", "slapd" );

	Yaffas::Service::control( LDAP, STOP );
	Yaffas::Service::control( LDAP, START );
	if ( Yaffas::Constant::get_os() eq "RHEL6" ) {
		Yaffas::Service::control( NSLCD, RESTART );
	}
}

=item set_pdc( [DC, DOMAIN, ADMIN, PASSWD, TYPE, BINDUSER, BINDPW, ENCRYPTION] )

configures Domain Controller settings

 PDC - domain controller
 DOMAIN - AD domain name
 ADMIN - domain admin username
 PASSWD - domain admin passord
 TYPE - win (for AD) or samba (for PDC)
 BINDUSER - bind user for AD access (fax, zarafa)
 BINDPW - bind user password(fax, zarafa)
 ENCRYPTION - 1 for ldaps, undef fo ldap

=cut

sub set_pdc( ;$$$$$$$$) {
	my( $pdcs, $domain, $admin, $passwd, $type, $binduser, $bindpw, $encryption ) = @_;
	unless ( ref($pdcs) eq "ARRAY" ) {
		$pdcs = [$pdcs];
	}
	my $ldapuri;
	my $ldap_proto = "ldap://";
    if ($encryption) {
        $ldap_proto = "ldaps://";
    }
	
	my @uris = map( $ldap_proto . $_, @{$pdcs} );
	$ldapuri = join " ", @uris;

	my $exception = Yaffas::Exception->new();

	my @rollback = (
		Yaffas::Constant::FILE->{'krb5'},
		Yaffas::Constant::FILE->{'smb_includes_global'},
		Yaffas::Constant::FILE->{'samba_conf'},
		Yaffas::Constant::FILE->{'ldap_settings'},
		Yaffas::Constant::FILE->{'zarafa_ldap_cfg'},
		Yaffas::Constant::FILE->{'postfix_ldap_users'},
		Yaffas::Constant::FILE->{'postfix_ldap_group'},
		Yaffas::Constant::FILE->{'postfix_ldap_aliases'},
	);
	my $id = rollback_prepare(@rollback);

	try {
		if ( scalar @{$pdcs} < 1 ) {
			$exception->add('err_pdc_missing');
		}
		else {
			foreach my $pdc ( @{$pdcs} ) {
				if (   ( !Yaffas::Check::ip($pdc) )
					&& ( !Yaffas::Check::hostname($pdc) )
					&& ( !Yaffas::Check::domainname($pdc) ) )
				{
					$exception->add('err_invalid_host');
				}
			}
		}
		if ( length $domain < 1 ) {
			$exception->add('err_miss_domain');
		}
		elsif ( !Yaffas::Check::domainname($domain) ) {
			$exception->add( 'err_invalid_domain', $domain );
		}
		if ( length $admin < 1 ) {
			$exception->add('err_miss_admin');
		}
		elsif ( !Yaffas::Check::pathetic_username($admin) ) {
			$exception->add( 'err_invalid_username', $admin );
		}
		if ( length $passwd < 1 ) {
			$exception->add('err_miss_pass');
		}
		elsif ( !Yaffas::Check::password($passwd) ) {
			$exception->add('err_pass');
		}
		if ( $type eq "win" ) {
			if ( length $binduser < 1 ) {
				$exception->add('err_miss_user');
			}
			if ( length $bindpw < 1 ) {
				$exception->add('err_miss_pass');
			}
			elsif ( !Yaffas::Check::password($bindpw) ) {
				$exception->add('err_pass');
			}
		}
		$type = "win" unless ( defined($type) );

		# Kerberos realms must be uppercase, so convert it
		my $realm = uc $domain;

# Active Directory requires the workgroup to be the short form of the domain, so extract it
		my $workgroup = ( split( /\./, $domain ) )[0];
		$exception->add('err_invalid_domain2')
		  unless ( defined($workgroup) or $workgroup eq "" );

		throw $exception if $exception;

# Allowing remote auth if we do a remote auth ourself is pointless. So disable it.
		if ( Yaffas::Auth::is_auth_srv() ) {
			auth_srv_ldap('deactivate');
		}
		auth_srv_pdc('deactivate');

		set_pdc_smb( $realm, $pdcs, $workgroup, $type, $encryption );
		set_pdc_krb( $realm, $domain, $pdcs );

		my $userdn;
		if ( $type eq "win" ) {
			if ( $binduser !~ m/cn=/i ) {    #if binduser is not already the DN
				$userdn =
				  Yaffas::Auth::get_ads_userdn( $ldapuri, $admin, $passwd,
					$binduser );
				$exception->add( 'err_get_userdn', $binduser )
				  unless defined $userdn;
			}
			else {
				$userdn = $binduser;
			}
			throw $exception if $exception;
			$exception->add( 'err_user_bind', $binduser )
			  unless check_userbind( $ldapuri, $userdn, $bindpw, $ldap_proto );
			throw $exception if $exception;

			# /etc/ldap.settings
			my $ls_ref = {};
			$ls_ref->{USERSEARCH}      = 'sAMAccountName';
			$ls_ref->{USER_SEARCHBASE} = "";
			$ls_ref->{LDAPURI}         = $ldapuri;
			$ls_ref->{BASEDN}          = Yaffas::Auth::get_ads_basedn($ldapuri);
			$ls_ref->{BINDDN}          = $userdn;
			$ls_ref->{LDAPSECRET}      = $bindpw;
			set_searchldap_settings($ls_ref);
		}

		net_rpc_join( $admin, $passwd, $type );

		Yaffas::Service::control( SAMBA,   RESTART );
		Yaffas::Service::control( WINBIND, RESTART );
		Yaffas::Service::control( USERMIN, RESTART );

		# for RedHat
		mod_pam("winbind");

		mod_nsswitch("files winbind");

		if ( Yaffas::Product::check_product("zarafa") && ( $type eq "win" ) ) {
			my $zarafa_settings = {
				'ldap_bind_user' => $userdn,
				'ldap_bind_passwd' => $bindpw,

				#'ldap_host' => $host,
				'ldap_uri' => $ldapuri,
			};

			#unless (defined $encryption) {
			#   $zarafa_settings->{'ldap_port'} = '389';
			#   $zarafa_settings->{'ldap_protocol'} = 'ldap';
			#}
			set_zarafa_ldap($zarafa_settings);
			Yaffas::Service::control( ZARAFA_SERVER, RESTART );
			system( Yaffas::Constant::APPLICATION->{zarafa_admin}, "--sync" );
		}

		_create_builtin_admins( $domain, $admin );

		_link_webaccess_plugin("passwd");
		_link_webapp_plugin("passwd");
		update_passwd_plugin_config( "ad", ${$pdcs}[0],
			Yaffas::Auth::get_ads_basedn($ldapuri) );

		# postfix
		my $postfix_settings = {
			'server_host'      => $ldapuri,
			'search_base'      => Yaffas::Auth::get_ads_basedn($ldapuri),
			'bind_dn'          => $userdn,
			'bind_pw'          => $bindpw,
			'bind'             => 'yes',
			'query_filter'     => '(&(objectClass=person)(mail=%s))',
			'result_attribute' => 'mail',
			'version'          => '3',
		};
		Yaffas::Module::Mailsrv::Postfix::set_postfix_ldap( $postfix_settings,
			"users" );

		$postfix_settings->{query_filter} =
		  '(&(objectClass=person)(otherMailbox=%s))';
		Yaffas::Module::Mailsrv::Postfix::set_postfix_ldap( $postfix_settings,
			"aliases" );

		$postfix_settings->{query_filter} = '(&(objectClass=group)(mail=%s))';
		$postfix_settings->{leaf_result_attribute}    = 'mail';
		$postfix_settings->{special_result_attribute} = 'member';
		Yaffas::Module::Mailsrv::Postfix::set_postfix_ldap( $postfix_settings,
			"group" );

		Yaffas::Module::Mailsrv::Postfix::toggle_distribution_groups("ldap");

	}
	catch Yaffas::Exception with {
		my $e = shift;
		try {
			rollback_exec($id);
		}
		catch Yaffas::Exception with {
			$e->append(shift);
		};
		$e->throw();
	}
	otherwise {
		my $e = new Yaffas::Exception();
		try {
			rollback_exec($id);
		}
		catch Yaffas::Exception with {
			$e->append(shift);
		};
		$e->add( "err_syntax", shift );
		$e->throw();
	};
}

=item B<set_pdc_krb( REALM, DOMAIN, PDC )>

Writes a /etc/krb5.conf for use with Microsoft ActiveDirectory
REALM: Kerberos realm (normaly complete domainname in uppercase)
DOMAIN: Complete domainname
PDC: IP or hostname of Kerberos/Domain Server

throws: Yaffas::Exception( 'err_writing_krb' )

=cut

sub set_pdc_krb( $$$ ) {
	my ( $realm, $domain, $pdcs ) = @_;
	my $krb = Yaffas::Constant::FILE->{'krb5'};

	my @kdcs = ();
	foreach my $pdc (@{$pdcs}) {
		push @kdcs, "   kdc = $pdc\n";
	}

	my $file = Yaffas::File->new($krb, [
		"[libdefaults]\n",
		"default_realm = $realm\n",
		"clockskew = 300\n",
		"[realms]\n",
		"$realm = {\n",
		@kdcs,
		"}\n",
		"[domain_realm]\n",
		"$domain  = $realm\n",
		".$domain = $realm\n"
		]
	);
	$file->save() or throw Yaffas::Exception( "err_file_write", $krb );

	return 1;
}

=item B<set_pdc_smb( REALM, PDC, WORKGROUP )>

Sets the apropriate Parameters in Yaffas::Constant::FILE->{'smb_includes_global'}
for use with Microsoft ActiveDirectory.

REALM: Fully qualified name (FQN) of the windows domain 
PDC: Name or IP address of Windows Domaincontroller
WORKGROUP: workgroup

throws: Yaffas::Exception( 'err_writing_smb' )

=cut

sub set_pdc_smb($$$$;$) {
	my ( $realm, $pdcs, $workgroup, $type, $encryption ) = @_;
	my $smb =
	  File::Samba->new( Yaffas::Constant::FILE->{'smb_includes_global'} )
	  or throw Yaffas::Exception( 'err_file_read',
		Yaffas::Constant::FILE->{'smb_includes_global'} );
	$smb->version(3);

	# delete some parameters
	$smb->deleteGlobalParameter('passdb backend');
	$smb->deleteGlobalParameter('idmap backend');
	$smb->deleteGlobalParameter('ldap delete dn');
	$smb->deleteGlobalParameter('ldap group suffix');
	$smb->deleteGlobalParameter('ldap machine suffix');
	$smb->deleteGlobalParameter('ldap ssl');
	$smb->deleteGlobalParameter('ldap user suffix');

	# add some parameters
	if ( $type eq "win" ) {
		$smb->globalParameter( 'security',  'ADS' );
		$smb->globalParameter( 'workgroup', $workgroup );
	}
	else {
		$smb->globalParameter( 'security',  'DOMAIN' );
		$smb->globalParameter( 'workgroup', $realm );
	}
	$smb->globalParameter( 'password server', ( join ", ", @{$pdcs} ) . ", *" );
	$smb->globalParameter( 'winbind separator',          '/' );
	$smb->globalParameter( 'idmap uid',                  '10000-30000' );
	$smb->globalParameter( 'idmap gid',                  '10000-30000' );
	$smb->globalParameter( 'template homedir',           '/tmp/' );
	$smb->globalParameter( 'template shell',             '/bin/false' );
	$smb->globalParameter( 'winbind use default domain', 'yes' );
	$smb->globalParameter( 'realm',                      $realm );
	$smb->globalParameter( 'client use spnego',          'yes' );
	$smb->globalParameter( 'winbind enum users',         'yes' );
	$smb->globalParameter( 'winbind enum groups',        'yes' );

	if ( defined $encryption ) {
		$smb->globalParameter( 'ldap ssl', 'start tls' );
	}
	else {
		$smb->globalParameter( 'ldap ssl', 'off' );
	}

	$smb->save( Yaffas::Constant::FILE->{'smb_includes_global'} )
	  or throw Yaffas::Exception( 'err_file_write',
		Yaffas::Constant::FILE->{'smb_includes_global'} );

	return 1;
}

=item rollback_prepare( @FILES )

Creates backup of all files for a later rollback.
@FILES hat to be a array of filenames with complete path.

On success, a File::Temp object is returned which can be used
to identify the rollback later for revert operations.
The archive is automaticaly removed due to the implementation
of File::Temp.

The rollback is stored in a .tar file under /tmp.

=cut

sub rollback_prepare(@) {
	my @files = @_;
	my @checked_files;

	throw Yaffas::Exception('err_no_files') unless ( scalar @files > 0 );

	foreach (@files) {
		throw Yaffas::Exception( 'err_filename', $_ )
		  unless Yaffas::Check::filename($_);
		push @checked_files, $_ if -f $_;
	}

	# create an tempfile for the rollback
	my $tmp = new File::Temp( DIR => '/tmp/', SUFFIX => '.tar' );

	system( Yaffas::Constant::APPLICATION->{'tar'},
		'--create', '--absolute-names', '--file', $tmp->filename,
		@checked_files );
	throw Yaffas::Exception('err_creating_rollback') if ( $? != 0 );

	return $tmp;
}

=item rollback_exec( TMP )

Reverts the files backuped in the rollback with the given ID.

=cut

sub rollback_exec( $ ) {
	my $tmp = shift;

	throw Yaffas::Exception('err_invalid_id')
	  unless defined( $tmp->filename );

	system( Yaffas::Constant::APPLICATION->{'tar'},
		'--extract', '--file', $tmp->filename, '--same-permissions',
		'--absolute-names', '--unlink-first' );
	throw Yaffas::Exception('err_executing_rollback') if ( $? != 0 );

	return 1;
}

sub set_time(;$) {
	my $ntpserver = shift;
	my $val       = 0;

	unless ( defined($ntpserver) ) {
		$ntpserver = Yaffas::Auth::get_pdc_info()->{host};
	}

	system( Yaffas::Constant::APPLICATION->{'ntpdate'}, "-u", $ntpserver );

	if ($?) {
		$val = 0;
		system( Yaffas::Constant::APPLICATION->{'logger'},
			"-pwarn", "could not connect to ntp-server $ntpserver" );
	}
	else {
		system( Yaffas::Constant::APPLICATION->{'logger'},
			"-pinfo", "synchronized time with $ntpserver" );
		$val = 1;
	}

	return $val;
}

=item set_zarafa_ldap([CONFIG_HASH])

Writes Zarafa LDAP configuration for (local/remote LDAP or ADS)

This function must be called after the new settings are written to files on auth type change.

CONFIG_HASH = hashref to config file parameters
 Contains Key/value pairs suitable for zarafa ldap.cfg (e.g. ldap_user_unique_attribute).
 Should be empty for local LDAP.
 I<Must> contain necessary values for remote (ldap_bind_user, ldap_host).
 I<Must> contain ldap_bind_passwd for ADS.
 If the hashref does not contain searchbases, etc. for remote LDAP, same values as for yaffas LDAP are used.

=cut

sub set_zarafa_ldap(;$) {
	my $type              = Yaffas::Auth::get_auth_type();
	my $additional_config = shift;
	my $basedn            = undef;
	my $rootbasedn        = undef;
	my $file              = Yaffas::File::Config->new(
		Yaffas::Constant::FILE->{'zarafa_ldap_cfg'},
		{
			-SplitPolicy    => 'custom',
			-SplitDelimiter => '\s*=\s*',
			-StoreDelimiter => ' = ',
		}
	  )
	  or throw Yaffas::Exception( "err_file_read",
		Yaffas::Constant::FILE->{'zarafa_ldap_cfg'} );
	my $exception = Yaffas::Exception->new();

	#set defaults
	my $cfg_values = $file->get_cfg_values();
	$cfg_values->{'ldap_quota_multiplier'}        = '1048576';
	$cfg_values->{'ldap_softquota_attribute'}     = 'zarafaQuotaSoft';
	$cfg_values->{'ldap_hardquota_attribute'}     = 'zarafaQuotaHard';
	$cfg_values->{'ldap_quotaoverride_attribute'} = 'zarafaQuotaOverride';
	$cfg_values->{'ldap_warnquota_attribute'}     = 'zarafaQuotaWarn';
	$cfg_values->{'ldap_nonactive_attribute'}     = 'zarafaSharedStoreOnly';
	$cfg_values->{'ldap_isadmin_attribute'}       = 'zarafaAdmin';

	#defaults that are unlikely to be changed
	$cfg_values->{'ldap_authentication_method'} = 'bind';
	$cfg_values->{'ldap_fullname_attribute'}    = 'displayName';
	$cfg_values->{'ldap_user_scope'}            = 'sub';
	$cfg_values->{'ldap_group_scope'}           = 'sub';
	$cfg_values->{'ldap_server_charset'}        = 'utf-8';

	#defaults that are likely to be changed...
	$cfg_values->{'ldap_user_unique_attribute_type'}  = 'text';
	$cfg_values->{'ldap_group_unique_attribute_type'} = 'text';
	$cfg_values->{'ldap_protocol'}                    = 'ldaps';
	$cfg_values->{'ldap_port'}                        = '636';
	$cfg_values->{'ldap_user_search_filter'} =
	  '(&(objectClass=posixAccount)(objectClass=zarafa-user))';
	$cfg_values->{'ldap_group_search_filter'} =
'(&(objectClass=posixGroup)(!(|(cn=yaffasmail)(cn=bkusers)(cn=Domain Admins)(cn=Print Operators)(cn=Domain Users)(cn=Domain Computers)(cn=Domain Guests)(cn=Administrators)(cn=Account Operators)(cn=Backup Operators)(cn=Replicators)(cn=nogroup))))';
	$cfg_values->{'ldap_user_unique_attribute'}       = 'uid';
	$cfg_values->{'ldap_group_unique_attribute'}      = 'cn';
	$cfg_values->{'ldap_emailaddress_attribute'}      = 'mail';
	$cfg_values->{'ldap_emailaliases_attribute'}      = 'zarafaAliases';
	$cfg_values->{'ldap_groupmembers_attribute'}      = 'memberUid';
	$cfg_values->{'ldap_groupmembers_attribute_type'} = 'name';
	$cfg_values->{'ldap_loginname_attribute'}         = 'uid';
	$cfg_values->{'ldap_bind_passwd'}           = Yaffas::LDAP::get_passwd();
	$cfg_values->{'ldap_sendas_attribute_type'} = "dn";
	$cfg_values->{'ldap_sendas_relation_attribute'} = "distinguishedName";

	if ( $type eq LOCAL_LDAP ) {
		$basedn = Yaffas::LDAP::get_local_domain();
		my $binddn = "cn=ldapadmin,ou=People," . $basedn;
		$cfg_values->{'ldap_bind_user'}                  = $binddn;
		#$cfg_values->{'ldap_protocol'}                   = 'ldap';
		#$cfg_values->{'ldap_port'}                       = '389';
		#$cfg_values->{'ldap_host'}                       = 'localhost';
		$cfg_values->{'ldap_uri'}                        = 'ldap://localhost';
		$cfg_values->{'ldap_search_base'}                = $basedn;
		$cfg_values->{'ldap_user_type_attribute_value'}  = "posixAccount";
		$cfg_values->{'ldap_group_type_attribute_value'} = "posixGroup";

	}
	elsif ( $type eq REMOTE_LDAP ) {
		my $ldap_file = Yaffas::File::Config->new(
			Yaffas::Constant::FILE->{'pam_ldap_conf'},
			{
				-SplitPolicy    => 'custom',
				-SplitDelimiter => '\s+',
				-StoreDelimiter => ' = ',
			}
		  )
		  or throw Yaffas::Exception( "err_file_read",
			Yaffas::Constant::FILE->{'pam_ldap_conf'} );
		$basedn = $ldap_file->get_cfg_values()->{'base'};
		$cfg_values->{'ldap_search_base'}                = $basedn;
		$cfg_values->{'ldap_user_type_attribute_value'}  = "posixAccount";
		$cfg_values->{'ldap_group_type_attribute_value'} = "posixGroup";

	}
	elsif ( $type eq ADS ) {
		$basedn =
		  Yaffas::Auth::get_ads_basedn( $additional_config->{'ldap_uri'} );
		$rootbasedn =
		  Yaffas::Auth::get_ads_basedn( $additional_config->{'ldap_uri'},
			"rootDomainNamingContext" );
		unless ( defined $additional_config->{'ldap_bind_passwd'} ) {
			$exception->add("err_miss_pass");
		}
		$cfg_values->{'ldap_user_unique_attribute_type'}  = 'binary';
		$cfg_values->{'ldap_group_unique_attribute_type'} = 'binary';
		$cfg_values->{'ldap_user_search_filter'} =
"(&(objectClass=person)(objectCategory=CN=Person,CN=Schema,CN=Configuration,$rootbasedn))";
		$cfg_values->{'ldap_group_search_filter'}      = '(objectClass=group)',
		  $cfg_values->{'ldap_groupname_attribute'}    = 'cn',
		  $cfg_values->{'ldap_group_unique_attribute'} = 'objectGuid',
		  $cfg_values->{'ldap_user_unique_attribute'}  = 'objectGuid',
		  $cfg_values->{'ldap_emailaddress_attribute'} = 'mail',
		  $cfg_values->{'ldap_emailaliases_attribute'} = 'otherMailbox';
		$cfg_values->{'ldap_groupmembers_attribute'}        = 'member',
		  $cfg_values->{'ldap_groupmembers_attribute_type'} = 'dn',
		  $cfg_values->{'ldap_loginname_attribute'}         = 'sAMAccountName',
		  $cfg_values->{'ldap_search_base'}                 = $basedn;
		$cfg_values->{'ldap_user_type_attribute_value'}  = "user";
		$cfg_values->{'ldap_group_type_attribute_value'} = "group";

	}
	else {
		$exception->add( "err_invalid_authtype", "$type" );
	}

	foreach my $key ( keys %{$additional_config} ) {
		$cfg_values->{$key} = $additional_config->{$key};
	}

	unless ( defined $basedn ) {
		$exception->add("err_get_basedn");
	}
	unless ( defined $cfg_values->{'ldap_host'} ) {
		$exception->add("err_miss_host");
	}
	unless ( defined $cfg_values->{'ldap_bind_user'} ) {
		$exception->add("err_miss_user");
	}

	$file->set_permissions( "root", "root", 00600 );
	throw $exception if $exception;
	$file->write()
	  or throw Yaffas::Exception( "err_file_write",
		Yaffas::Constant::FILE->{'zarafa_ldap_cfg'} );

	return 1;
}

=item test_ldaps( LDAPSERVER )

Tests if LDAP server (or ADS) support ldaps
  LDAPSERVER hostname or IP address

=cut

sub test_ldaps($) {
	my $dcname = shift;
	if (   Yaffas::Check::ip($dcname)
		|| Yaffas::Check::hostname($dcname)
		|| Yaffas::Check::domainname($dcname) )
	{
		system( Yaffas::Constant::APPLICATION->{ldapsearch},
			"-x", "-b", '', "-s", "base", "-H", "ldap://$dcname" );
		throw Yaffas::Exception( "err_contact_host", $dcname ) if ( $? != 0 );
		system( Yaffas::Constant::APPLICATION->{ldapsearch},
			"-x", "-b", '', "-s", "base", "-H", "ldaps://$dcname" );
		return undef if ( $? != 0 );
	}
	return 1;
}

=item set_searchldap_settings( [CONFIGHASH] )

Writes /etc/ldap.settings file for ldapsearch script

CONFIG_HASH = hashref to config file parameters
 Contains Key/value pairs in shell syntax
 fields: BASEDN, LDAPURI, BINDDN, LDAPSECRET, USERSEARCH, USER_SEARCHBASE, EMAIL
 mandatory for remote LDAP: BASEDN, LDAPURI, BINDDN
 mandatory for AD: BASEDN, LDAPURI, BINDDN, LDAPSECRET

=cut

sub set_searchldap_settings(;$) {
	my $cfg_vals  = shift;
	my $exception = Yaffas::Exception->new();
	my $type      = Yaffas::Auth::get_auth_type();

	my $ls_file = Yaffas::File::Config->new(
		Yaffas::Constant::FILE->{'ldap_settings'},
		{
			-SplitPolicy    => 'custom',
			-SplitDelimiter => '\s*=\s*',
			-StoreDelimiter => '=',
		}
	) or throw Yaffas::Exception("err_file_write");
	my $ls_ref = $ls_file->get_cfg_values();

	#set defaults
	$ls_ref->{USERSEARCH}      = "uid";
	$ls_ref->{EMAIL}           = "mail";
	$ls_ref->{USER_SEARCHBASE} = "";

	if ( $type eq LOCAL_LDAP ) {
		my $basedn = Yaffas::LDAP::get_local_domain();
		$ls_ref->{BASEDN}           = $basedn;
		$ls_ref->{BINDDN}           = "cn=ldapadmin,ou=People,$basedn";
		$ls_ref->{LDAPSECRET}       = Yaffas::LDAP::get_passwd();
		$ls_ref->{LDAPURI}          = "ldap://127.0.0.1";
		$ls_ref->{USER_SEARCHBASE}  = "ou=People,$basedn";
		$ls_ref->{GROUP_SEARCHBASE} = "ou=Group,$basedn";
	}
	elsif ( $type eq REMOTE_LDAP ) {
		$ls_ref->{LDAPSECRET} = Yaffas::LDAP::get_passwd();
	}
	elsif ( $type eq ADS ) {
		$ls_ref->{USERSEARCH} = 'sAMAccountName';
	}
	foreach my $key ( keys %{$cfg_vals} ) {
		$ls_ref->{$key} = $cfg_vals->{$key};
	}
	$exception->add( "err_basedn", $ls_file->{'FILE'} )
	  if ( length( $ls_ref->{BASEDN} ) < 3 );

	#the shortest string possible is "ldap:///" -> 10 chars
	$exception->add( "err_ldapuri", $ls_file->{'FILE'} )
	  if ( length( $ls_ref->{LDAPURI} ) < 10 );
	$exception->add( "err_miss_user", $ls_file->{'FILE'} )
	  if ( length( $ls_ref->{BINDDN} ) < 3 );
	$exception->add( "err_miss_pass", $ls_file->{'FILE'} )
	  if ( length( $ls_ref->{LDAPSECRET} ) < 1 );
	$ls_file->set_permissions( "root", "ldapread", 0640 );
	throw $exception if $exception;
	$ls_file->write()
	  or throw Yaffas::Exception( "err_file_write",
		Yaffas::Constant::FILE->{'ldap_settings'} );
}

=item get_ldap_settings()

returns a hashref containing all settings

=cut

sub get_ldap_settings() {
	my $fname   = Yaffas::Constant::FILE->{'ldap_settings'};
	my $ls_file = Yaffas::File::Config->new(
		$fname,
		{
			-SplitPolicy    => 'custom',
			-SplitDelimiter => '\s*=\s*',
			-StoreDelimiter => '=',
		}
	) or throw Yaffas::Exception( "err_file_read", $fname );
	return $ls_file->get_cfg_values();
}

=item check_userbind( DCNAME, USERDN, USERPASS )

returns 1 if bind was successful, undef else; exception on failure in DN or password
  DCNAME - Name or IP address of LDAP Server
  USERDN - complete DN of user
  USERPASS - password
  LDAPPROTO - either ldap or ldaps

=cut

sub check_userbind($$$;$) {
	my ( $ldapuri, $userdn, $pass, $ldap_proto ) = @_;

	if ( ( !defined $ldap_proto ) || ( $ldap_proto !~ m/^ldaps?$/ ) ) {
		$ldap_proto = "ldap";
	}
	my $rv        = undef;
	my $exception = Yaffas::Exception->new();
	$exception->add( "err_pass_wrong", $pass )
	  unless Yaffas::Check::password($pass);
	throw $exception if ($exception);
	my @re = Yaffas::do_back_quote_2(
		Yaffas::Constant::APPLICATION->{ldapsearch},
		"-D", $userdn, "-x", "-H", $ldapuri,
		"-w", $pass, "-b", $userdn
	);

	#	if ($? != 0) {
	if ( scalar @re > 0 ) {
		my $errorcode = "";
		foreach (@re) {
			if (m/AcceptSecurityContext/) {
				m/data\s*([a-f0-9]+)/;
				$errorcode = $1;
				last;
			}
		}

		#back to DOS ;-)
		if ( $errorcode eq "52e" ) {
			$exception->add( "err_ads_pass", [ $userdn, join( "\n", @re ) ] );
		}
		elsif ( $errorcode eq "525" ) {
			$exception->add( "err_ads_dn", [ $userdn, join( "\n", @re ) ] );
		}
		else {
			$exception->add( join( "\n", @re ) );
		}
	}
	else {
		$rv = 1;
	}
	throw $exception if $exception;
	return $rv;
}

=item clean_ug_data( OLDUSERS, OLDGROUPS, [ TYPE ] )

synchronises old with new user data or deletes I<ALL> user data (depending on type)

 OLDUSERS Hash ref containing old system users and old database users
 OLDGROUPS the same for groups
 TYPE if type eq all then all old users will be deleted

=cut

sub clean_ug_data($$;$) {
	my $oldusers  = shift;
	my $oldgroups = shift;
	my $type      = shift;
	try {
		my $e = Yaffas::Exception->new();
		my %newusers;

	#this produces a hash with all array values as keys and undef as hash values
		Yaffas::UGM::clear_cache();
		Yaffas::UGM::get_users();
		Yaffas::UGM::clear_cache();
		@newusers{ Yaffas::UGM::get_users() } = ();
		my %newgroups;
		@newgroups{ Yaffas::UGM::get_groups() } = ();

		$e->add('err_miss_oldusers')  unless defined $oldusers;
		$e->add('err_miss_oldgroups') unless defined $oldgroups;
		throw $e if $e;

		if ( $type eq "all" ) {
			foreach my $user ( keys %{$oldusers} ) {
				Yaffas::UGM::clean_user_data($user);
			}
			foreach my $group ( keys %{$oldgroups} ) {
				Yaffas::UGM::clean_group_data($group);
			}
		}
		else {
			foreach my $user ( keys %{$oldusers} ) {
				if ( !( exists $newusers{$user} ) ) {
					Yaffas::UGM::clean_user_data($user);
				}
				else {
					_correct_picture_owner($user);
					_correct_pdf_user_dir($user);
				}
			}
			foreach my $group ( keys %{$oldgroups} ) {
				if ( !exists $newgroups{$group} ) {
					Yaffas::UGM::clean_group_data($group);
				}
			}
		}
	}
	catch Yaffas::Exception with {
		shift()->throw();
	};
}

=item get_sys_and_db_users( )

returns a hashref containing users (system and DB)

use this function to be able to detect inconsitencies between system and db

inconsitencies can occur if someone deletes or modifies users or groups via command line or in due to bug #977

=cut

sub get_sys_and_db_users() {

	#this produces a hash with all array values as keys and undef as hash values
	my %ret;
	@ret{ Yaffas::UGM::get_users() } = ();
	try {
		my $dbh = eval { Yaffas::Postgres::connect_db("bbfaxconf") };
		unless ($@) {
			@ret{ Yaffas::Postgres::search_ug_table("u") } = ();
		}
	}
	catch Yaffas::Exception with {
		shift()->throw();
	};

	return \%ret;
}

=item get_sys_and_db_groups( )

returns a hashref containing groups (system and DB)

see also get_sys_and_db_users( )

=cut

sub get_sys_and_db_groups() {
	my %ret;
	@ret{ Yaffas::UGM::get_groups() } = ();
	try {
		my $dbh = eval { Yaffas::Postgres::connect_db("bbfaxconf") };
		unless ($@) {
			@ret{ Yaffas::Postgres::search_ug_table("g") } = ();
		}
	}
	catch Yaffas::Exception with {
		shift()->throw();
	};

	return \%ret;
}

sub _correct_picture_owner($) {
	my $name          = shift;
	my $jpeg_filename = Yaffas::Constant::DIR->{'jpeg_dir'} . $name . ".jpg";
	my $eps_filename  = Yaffas::Constant::DIR->{'eps_dir'} . $name . ".eps";
	if ( -f $jpeg_filename ) {
		my $jpeg_file = new Yaffas::File($jpeg_filename);
		$jpeg_file->set_permissions($name);
		$jpeg_file->write();
	}
	if ( -f $eps_filename ) {
		my $eps_file = new Yaffas::File($eps_filename);
		$eps_file->set_permissions($name);
		$eps_file->write();
	}
	return 1;
}

sub _correct_pdf_user_dir($) {
	my $name = shift;
	my $path = Yaffas::Constant::DIR->{'pdf_user_dir'} . "$name";
	if ( -d $path ) {
		system( Yaffas::Constant::APPLICATION->{'chown'}, '-R', "$name",
			$path );
		if ( $? != 0 ) {
			throw Yaffas::Exception( "err_chown", $path );
		}
	}
}

=item set_files_auth()

Configures authentication to use local files (/etc/passwd, /etc/shadow,
/etc/group, /etc/samba/smbpasswd)

=cut

sub set_files_auth() {
	my $i = 1;

	my $exception = Yaffas::Exception->new();

	my @rollback = ( Yaffas::Constant::FILE->{'smb_includes_global'}, );
	my $id       = rollback_prepare(@rollback);

	try {

		# /etc/samba/smbopts.global
		my $smb =
		  File::Samba->new( Yaffas::Constant::FILE->{'smb_includes_global'} )
		  or throw Yaffas::Exception( "err_file_read",
			Yaffas::Constant::FILE->{smb_includes_global} );
		$smb->version(3);
		$smb->globalParameter( 'passdb backend', 'smbpasswd' );
		$smb->deleteGlobalParameter('password server');
		$smb->deleteGlobalParameter('idmap gid');
		$smb->deleteGlobalParameter('idmap uid');
		$smb->deleteGlobalParameter('template homedir');
		$smb->deleteGlobalParameter('template shell');
		$smb->deleteGlobalParameter('winbind separator');
		$smb->deleteGlobalParameter('winbind use default domain');
		$smb->deleteGlobalParameter('realm');
		$smb->deleteGlobalParameter('client schannel');
		$smb->deleteGlobalParameter('winbind enum users');
		$smb->deleteGlobalParameter('winbind enum groups');
		$smb->globalParameter( 'security', 'user' );
		$smb->save( Yaffas::Constant::FILE->{smb_includes_global} )
		  or throw Yaffas::Exception( 'err_file_write',
			Yaffas::Constant::FILE->{smb_includes_global} );

		Yaffas::Service::control( SAMBA,   RESTART );
		Yaffas::Service::control( WINBIND, RESTART );

		if ( check_product("mail") ) {
			Yaffas::Service::control( SASLAUTHD, RESTART );
		}
		if ( check_product("fax") ) {
			Yaffas::Service::control( HYLAFAX, RESTART );
		}
		Yaffas::Service::control( USERMIN, RESTART );

		mod_nsswitch();

		# for RedHat
		mod_pam();
	}
	catch Yaffas::Exception with {
		my $e = shift;
		try {
			rollback_exec($id);
		}
		catch Yaffas::Exception with {
			$e->append(shift);
		};
		$e->throw();
	}
	otherwise {
		my $e = Yaffas::Exception->new();
		try {
			rollback_exec($id);
		}
		catch Yaffas::Exception with {
			$e->append(shift);
		};
		$e->add( "err_syntax", shift );
		$e->throw();
	};
}

sub _create_builtin_admins($$) {
	my $dom   = shift;
	my $admin = shift;

	system( "net", "sam", "createbuiltingroup", "administrators" );
	system( "net", "sam", "addmem", "administrators", "$dom\\$admin" );
}

sub update_passwd_plugin_config {
	my $method = shift;
	my $host   = shift;
	my $dn     = shift;

	foreach my $fn (
		qw(/opt/yaffas/zarafa/webaccess/plugins/passwd/config.inc.php /opt/yaffas/zarafa/webapp/plugins/passwd/config.inc.php)
	  )
	{
		my $file = Yaffas::File->new($fn)
		  or throw Yaffas::Exception( "err_file_read", $fn );

		my $line = $file->search_line(qr/private \$method/);
		if ($line) {
			$file->splice_line( $line, 1,
				'private $method = "' . $method . '";' );
		}

		$line = $file->search_line(qr/private \$uri/);
		if ($line) {
			$file->splice_line( $line, 1, 'private $uri = "' . $host . '";' );
		}

		$line = $file->search_line(qr/private \$basedn/);
		if ($line) {
			$file->splice_line( $line, 1, 'private $basedn = "' . $dn . '";' );
		}

		$file->save();
	}
}

sub _link_webaccess_plugin {
	my $plugin = shift;
	if ( Yaffas::Product::check_product("zarafa") ) {
		unless ( -d "/var/lib/zarafa-webaccess/plugins/$plugin" ) {
			symlink "/opt/yaffas/zarafa/webaccess/plugins/$plugin/",
			  "/var/lib/zarafa-webaccess/plugins/$plugin";
		}
	}
}

sub _remove_webaccess_plugin {
	my $plugin = shift;
	if ( Yaffas::Product::check_product("zarafa") ) {
		if ( -l "/var/lib/zarafa-webaccess/plugins/$plugin" ) {
			unlink "/var/lib/zarafa-webaccess/plugins/$plugin";
		}
	}
}

sub _link_webapp_plugin {
	my $plugin = shift;
	if ( Yaffas::Product::check_product("zarafa") ) {
		unless ( -d "/usr/share/zarafa-webapp/plugins/$plugin" ) {
			symlink "/opt/yaffas/zarafa/webapp/plugins/$plugin/",
			  "/usr/share/zarafa-webapp/plugins/$plugin";
		}
	}
}

sub _remove_webapp_plugin {
	my $plugin = shift;
	if ( Yaffas::Product::check_product("zarafa") ) {
		if ( -l "/usr/share/zarafa-webapp/plugins/$plugin" ) {
			unlink "/usr/share/zarafa-webapp/plugins/$plugin";
		}
	}
}

1;

=back

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
