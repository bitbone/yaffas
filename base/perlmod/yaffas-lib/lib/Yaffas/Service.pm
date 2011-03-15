#!/usr/bin/perl
package Yaffas::Service;

use warnings;
use strict;

sub BEGIN {
	use Exporter;
	our @ISA = qw(Exporter);
	our @EXPORT_OK = qw(&control &installed_services
						&EXIM &POSTFIX &CYRUS &INETD &WEBMIN &LDAP &NSCD
						&HYLAFAX &XINETD &USERMIN &SASLAUTHD
						&SAMBA &NETWORK &MYSQL &CUPS &KAV &KAS
						&CAPIINIT &CAPI4HYLAFAX &GREYLIST
						&FETCHMAIL &POSTGRESQL &SPAMASSASSIN &WINBIND &SNMPD
						&DIVAS &GOGGLETYKE &SSHD
						&ZARAFA_SERVER &ZARAFA_GATEWAY &ZARAFA_SPOOLER &ZARAFA_MONITOR &ZARAFA_ICAL &ZARAFA_LICENSED
						&APACHE &BBLCD &NFSD
						&MPPD
						&START &STOP &RESTART &STATUS &RELOAD
					   );
}

use Yaffas qw(do_back_quote);
use Yaffas::Constant;
use Yaffas::Product qw(check_product);
use Yaffas::Check;

## prototypes ##
sub _start($$);
sub _stop($$);
sub _restart($$);
sub _reload($$);
sub _status($);
sub control($;$);
sub installed_services(;$);
sub print_started($);
sub print_stopped($);

our $Message = undef;

=head1 NAME

Yaffas::Service - Interface to the Deamons

=head1 SYNOPSIS

use Yaffas::Service

=head1 DESCRIPTION

Yaffas::Service is a Module to controll your Deamons.

=head1 CONSTANTS

=head2 Constants for Services

=over


=item EXIM

=cut

sub EXIM(){ 1; }


=item HYLAFAX

=cut

sub HYLAFAX(){ 2; }

=item NETWORK

=cut

sub NETWORK(){ 3; }


=item CAPI4HYLAFAX

=cut

sub CAPI4HYLAFAX(){ 4; }


=item LADP

=cut

sub LDAP(){ 5; }


=item NSCD

=cut

sub NSCD(){ 6; }


=item SAMBA

=cut

sub SAMBA(){ 7; }


=item CYRUS

=cut

sub CYRUS(){ 8; }

=item SASLAUTHD

=cut

sub SASLAUTHD(){ 9; }

=cut

=item INETD

=cut

sub INETD(){ 10; }

=item WEBMIN

=cut

sub WEBMIN(){ 11; }

=item USERMIN

=cut

sub USERMIN(){ 12; }

=item XINETD

=cut

sub XINETD(){ 13; }

=item CAPIINIT

=cut

sub CAPIINIT(){ 14; }

=item MYSQL

=cut 

sub MYSQL(){ 15; }

=item CUPS

=cut 

sub CUPS(){ 16; }

=item KAV

=cut 

sub KAV(){ 17; }

=item KAS

=cut 

sub KAS(){ 18; }

=item GREYLIST

=cut 

sub GREYLIST(){ 19; }

=item FETCHMAIL

=cut

sub FETCHMAIL(){ 20; }

=item POSTGRESQL

=cut

sub POSTGRESQL(){ 21; }

=item SPAMASSASSIN

=cut

sub SPAMASSASSIN(){ 22; }

=item WINBIND

=cut

sub WINBIND(){ 23; }

=item SNMPD

=cut

sub SNMPD(){ 24; }

=item DIVAS

=cut

sub DIVAS(){ 25; }

=item GOGGLETYKE

=cut

sub GOGGLETYKE(){ 26; }

=item ZARAFA_GATEWAY

=cut

sub ZARAFA_GATEWAY(){ 27; }

=item ZARAFA_MONITOR

=cut

sub ZARAFA_MONITOR(){ 28; }

=item ZARAFA_SERVER

=cut

sub ZARAFA_SERVER(){ 29; }

=item ZARAFA_SPOOLER

=cut

sub ZARAFA_SPOOLER(){ 30; }

=item APACHE

=cut

sub APACHE(){ 31; }

=item ZARAFA_ICAL

=cut

sub ZARAFA_ICAL(){ 32; }

=item SSHD

=cut

sub SSHD(){ 33; }

=item MPPD

=cut

sub MPPD(){ 34; }

=item MPPMANAGER

=cut

sub MPPMANAGER(){ 35; }

=item MPPSERVER - obsolete

=cut

sub MPPSERVER(){ 35; }

=item SEARCHD

=cut

sub SEARCHD(){ 36; }

=item BBLCD

=cut

sub BBLCD(){ 37; }

=item NFSD

=cut

sub NFSD(){ 38; }

=item SENDMAIL

=cut

sub SENDMAIL(){ 39; }

=back

=item POSTFIX

=cut

sub POSTFIX(){ 40; }

=item ZARAFA_LICENSED

=cut

sub ZARAFA_LICENSED(){ 41; }

=back

=head2 Constants for Actions

=over

=item RESTART

=cut

sub RESTART(){ "restart"}

=item STOP

=cut

sub STOP(){"stop"}

=item START

=cut

sub START(){"start"}

=item STATUS

=cut

sub STATUS(){"status"}

=item RELOAD

=cut

sub RELOAD(){"reload"}

=back

=head1 GLOBAL VARIABLES

=over

=item $Message

This variable is will be set on if an error occured during starting, stopping and restarting
a service. It contains the message which was put to stdout.

=back

=head1 FUNCTIONS

=over

=cut

our %SERVICES;

if(Yaffas::Constant::OS eq 'Ubuntu') {
	%SERVICES = (
				 EXIM()    => "/etc/init.d/exim4",
				 HYLAFAX() => "/etc/init.d/hylafax",
				 NETWORK() => "/etc/init.d/networking",
				 CAPI4HYLAFAX()    => "/etc/init.d/capi4hylafax",
				 LDAP()    => "/etc/init.d/slapd",
				 NSCD()    => "/etc/init.d/nscd",
				 SAMBA()   => "/etc/init.d/smbd",
				 CYRUS()   => "/etc/init.d/cyrus2.2",
				 SASLAUTHD() => "/etc/init.d/saslauthd",
				 INETD()   => "/etc/init.d/inetd",
				 WEBMIN()  => "/etc/init.d/yaffas",
				 USERMIN() => "/etc/init.d/usermin",
				 XINETD()  => "/etc/init.d/xinetd",
				 CAPIINIT()  => "/etc/init.d/capiutils",
				 MYSQL()   => "/etc/init.d/mysql",
				 CUPS()    => "/etc/init.d/cupsys",
				 KAV()     => "/etc/init.d/aveserver",
				 KAS()     => "/etc/init.d/ap-process-server",
				 GREYLIST() => "/etc/init.d/greylist",
				 FETCHMAIL() => "/etc/init.d/fetchmail",
				 POSTGRESQL() => "/etc/init.d/postgresql-8.3",
				 SPAMASSASSIN() => "/etc/init.d/spamassassin",
				 WINBIND() => "/etc/init.d/winbind",
				 SNMPD() => "/etc/init.d/snmpd",
				 DIVAS() => "/usr/lib/eicon/divas/Start",
				 GOGGLETYKE() => "/etc/init.d/goggletyke",
				 ZARAFA_GATEWAY() => "/etc/init.d/zarafa-gateway",
				 ZARAFA_MONITOR() => "/etc/init.d/zarafa-monitor",
				 ZARAFA_SERVER() => "/etc/init.d/zarafa-server",
				 ZARAFA_SPOOLER() => "/etc/init.d/zarafa-spooler",
				 ZARAFA_ICAL() => "/etc/init.d/zarafa-ical",
				 ZARAFA_LICENSED() => "/etc/init.d/zarafa-licensed",
				 APACHE() => "/etc/init.d/apache2",
				 SSHD() => "/etc/init.d/ssh",
				 MPPD() => "/etc/init.d/mppd",
				 MPPMANAGER() => "/etc/init.d/mppmanager",
				 SEARCHD() => "/etc/init.d/searchd",
				 BBLCD() => "/etc/init.d/bblcd",
				 NFSD() => "/etc/init.d/nfs-kernel-server",
				 POSTFIX() => "/etc/init.d/postfix",
				);
}
elsif(Yaffas::Constant::OS eq 'RHEL5') {
	%SERVICES = (
				 EXIM()    => "/sbin/service exim",
				 SENDMAIL() => "/sbin/service sendmail",
				 POSTFIX() => "/sbin/service postfix",
				 HYLAFAX() => "/sbin/service hylafax",
				 NETWORK() => "/sbin/service network",
#				 CAPI4HYLAFAX()    => "/etc/init.d/capi4hylafax",
				 LDAP()    => "/sbin/service ldap",
				 NSCD()    => "/sbin/service nscd",
				 SAMBA()   => "/sbin/service smb",
				 CYRUS()   => "/sbin/service cyrus-imapd",
				 SASLAUTHD() => "/sbin/service saslauthd",
#				 INETD()   => "/etc/init.d/inetd",
				 WEBMIN()  => "/sbin/service bbwebmin",
				 USERMIN() => "/sbin/service bbusermin",
				 XINETD()  => "/sbin/service xinetd",
#				 CAPIINIT()  => "/usr/sbin/capiinit",
#				 MYSQL()   => "/etc/init.d/mysql",
#				 CUPS()    => "/etc/init.d/cupsys",
#				 KAV()     => "/etc/init.d/aveserver",
#				 KAS()     => "/etc/init.d/ap-process-server",
#				 GREYLIST() => "/etc/init.d/greylist",
#				 FETCHMAIL() => "/etc/init.d/fetchmail",
				 POSTGRESQL() => "/sbin/service postgresql",
#				 SPAMASSASSIN() => "/etc/init.d/spamassassin",
				 WINBIND() => "/sbin/service winbind",
				 SNMPD() => "/sbin/service snmpd",
				 DIVAS() => "/usr/lib/eicon/divas/Start",
				 GOGGLETYKE() => "/sbin/service goggletyke",
#				 ZARAFA_GATEWAY() => "/etc/init.d/zarafa-gateway",
#				 ZARAFA_MONITOR() => "/etc/init.d/zarafa-monitor",
#				 ZARAFA_SERVER() => "/etc/init.d/zarafa-server",
#				 ZARAFA_SPOOLER() => "/etc/init.d/zarafa-spooler",
#				 ZARAFA_ICAL() => "/etc/init.d/zarafa-ical",
				 APACHE() => "/sbin/service httpd",
				 SSHD() => "/sbin/service sshd",
#				 MPPD() => "/etc/init.d/mppd",
#				 MPPMANAGER() => "/etc/init.d/mppmanager",
#				 SEARCHD() => "/etc/init.d/searchd",
#				 BBLCD() => "/etc/init.d/bblcd",
				);
}
else {
	die "unknown OS\n";
}

our %ACTIONS = (
				START()   => \&_start,
				STOP()    => \&_stop,
				RESTART() => \&_restart,
				STATUS()  => \&_status,
				RELOAD()  => \&_reload,
			   );

=item installed_services( [SERVICE] )

If you pass the optional argument B<SERVICE> this routine will return 
true/undef if the given service exists/not exists.
This routine will return an array reference containing all installed 
services, their constants, their permissions and their debian package name.

=cut

sub installed_services(;$)
{
	my $want = shift;
	my $faxtype = Yaffas::Check::faxtype();

	my $services =
	{
		'network' 	=> { 'constant' => NETWORK(), 'allow' => [ 'restart' ] },
		'ldap' 		=> { 'constant' => LDAP(), 'allow' => [ 'start', 'stop', 'restart' ] },
		'nscd' 		=> { 'constant' => NSCD(), 'allow' => [ 'start', 'stop', 'restart' ] },
		'webmin' 	=> { 'constant' => WEBMIN(), 'allow' => [ 'restart' ] }, 
		'samba'		=> { 'constant' => SAMBA(), 'allow' => [ 'start', 'stop', 'restart' ] },
		'winbind'	=> { 'constant' => WINBIND(), 'allow' => [ 'start', 'stop', 'restart' ] },
		'sshd'		=> { 'constant' => SSHD(), 'allow' => [ 'start', 'stop', 'restart' ] },
		'postfix'	=> { 'constant' => POSTFIX(), 'allow' => [ 'start', 'stop', 'restart' ] },
	};

	if(Yaffas::Constant::OS eq 'RHEL5') {
		$services->{'sendmail'}	= { 'constant' => SENDMAIL(), 'allow' => [ 'start', 'stop', 'restart' ] },
	}

	if(check_product('fax'))
	{
		$services->{'hylafax'}		= { 'constant' => HYLAFAX(), 'allow' => ['start', 'stop', 'restart' ] };
		if ($faxtype eq "AVM")
		{
			$services->{'capiinit'}		= { 'constant' => CAPIINIT(), 'allow' => [ 'start', 'stop', 'restart' ] };
			$services->{'capi4hylafax'}	= { 'constant' => CAPI4HYLAFAX(), 'allow' => [ 'start', 'stop', 'restart' ] };
		}
		else
		{
			$services->{'divas'}		= { 'constant' => DIVAS(), 'allow' => [ 'start', 'stop', ] };
		}
		$services->{'mysql'}		= { 'constant' => MYSQL(), 'allow' => [ 'start', 'stop', 'restart' ] };
		$services->{'apache'}		= { 'constant' => APACHE(), 'allow' => [ 'start', 'stop', 'restart' ] };
	}

	if(check_product('fax') or check_product('pdf'))
	{
		$services->{'cups'}			= { 'constant' => CUPS(), 'allow' => [ 'start', 'stop', 'restart' ] };
	}

	if(check_product('mail'))
	{
		$services->{'cyrus'}		= { 'constant' => CYRUS(), 'allow' => [ 'start', 'stop', 'restart' ] };
		$services->{'saslauthd'}	= { 'constant' => SASLAUTHD(), 'allow' => [ 'start', 'stop', 'restart' ] };
		$services->{'kav'}			= { 'constant' => KAV(), 'allow' => [ 'start', 'stop', 'restart' ] } if (check_service_available(KAV()));
		$services->{'kas'}			= { 'constant' => KAS(), 'allow' => [ 'start', 'stop', 'restart' ] } if (check_service_available(KAS()));
		$services->{'greylist'}	    = { 'constant' => GREYLIST(), 'allow' => [ 'start', 'stop', 'restart' ] };
		$services->{fetchmail}      = { constant => FETCHMAIL(), allow => [ 'start', 'stop', 'restart' ] };
		$services->{spamassassin}      = { constant => SPAMASSASSIN(), allow => [ 'start', 'stop', 'restart' ] };
	}

	if(check_product('gate'))
	{
		$services->{'kav'}	= { 'constant' => KAV(), 'allow' => [ 'start', 'stop', 'restart' ] } if (check_service_available(KAV()));
		$services->{'kas'}	= { 'constant' => KAS(), 'allow' => [ 'start', 'stop', 'restart' ] } if (check_service_available(KAS()));
		$services->{'greylist'}	= { 'constant' => GREYLIST(), 'allow' => [ 'start', 'stop', 'restart' ] };
		$services->{fetchmail}      = { constant => FETCHMAIL(), allow => [ 'start', 'stop', 'restart' ] };
	}

	if(check_product('mailgate'))
	{
		$services->{mppmanager}	= { 'constant' => MPPMANAGER(), 'allow' => [ 'start', 'stop', 'restart' ] };
		$services->{mppd} = { constant => MPPD(), allow => [ 'start', 'stop', 'restart' ] };
		$services->{searchd} = { constant => SEARCHD(), allow => [ 'start', 'stop', 'restart' ] };
	}

	if(check_product('zarafa'))
	{
		$services->{'zarafa-gateway'} = { 'constant' => ZARAFA_GATEWAY(), 'allow' => [ 'start', 'stop', 'restart' ] };
		$services->{'zarafa-monitor'} = { 'constant' => ZARAFA_MONITOR(), 'allow' => [ 'start', 'stop', 'restart' ] };
		$services->{'zarafa-server'} = { 'constant' => ZARAFA_SERVER(), 'allow' => [ 'start', 'stop', 'restart' ] };
		$services->{'zarafa-spooler'} = { 'constant' => ZARAFA_SPOOLER(), 'allow' => [ 'start', 'stop', 'restart' ] };
		$services->{'zarafa-ical'} = { 'constant' => ZARAFA_ICAL(), 'allow' => [ 'start', 'stop', 'restart' ] };
		$services->{'zarafa-licensed'} = { 'constant' => ZARAFA_LICENSED(), 'allow' => [ 'start', 'stop', 'restart' ] };
		$services->{'apache'}		= { 'constant' => APACHE(), 'allow' => [ 'start', 'stop', 'restart' ] };
		delete $services->{cyrus};
	}

	if(check_product('pdf'))
	{
		$services->{'apache'}		= { 'constant' => APACHE(), 'allow' => [ 'start', 'stop', 'restart' ] };
	}

	if(check_product('fileserver'))
	{
		$services->{'nfs-kernel-server'}		= { 'constant' => NFSD(), 'allow' => [ 'start', 'stop', 'restart' ] };
	}

	if($want)
	{
		return ($services->{$want} ? $services->{$want} : undef);
	}

	return $services;
}

=item is_in_runlevel ( SERVICE )

returns true, if the service is in the default runlevel.

=cut

sub is_in_runlevel($){
	my $service = shift;
	my $initscript = $SERVICES{$service};
	$initscript =~ s/[^ ]* // if( Yaffas::Constant::OS eq 'RHEL5' );
	my $initprefix = '/etc';
	$initprefix = '/etc/rc.d' if( Yaffas::Constant::OS eq 'RHEL5' );

	if($initscript){
		$initscript =~ s#$initprefix/init.d/##;
		foreach (glob("$initprefix/rc2.d/*")){

			my $symlink = readlink $_;
			$symlink =~ m#/([^/]*)$#;
			$symlink = $1;
			if($symlink eq $initscript){
				return 1;
			}
		}
		
		# if service is configured for upstart
		if( -e "/etc/init/$initscript.conf") {
			return 1;
		}
	}
	return 0;
}

=item add_to_runlevel ( SERVICE )

adds the SERVCE to the default Runlevel

=cut

sub add_to_runlevel($){
	my $service = shift;
	my $initscript = $SERVICES{$service};
	my $initprefix = '/etc/init.d/';
	if( Yaffas::Constant::OS eq 'RHEL5' ) {
		$initscript =~ s/[^ ]* //;
		$initprefix = '/etc/rc.d/init.d/';
		$initscript = $initprefix.$initscript;
	}

	if( $initscript ){
		my $initconf = $initscript;
		$initconf =~ s#$initprefix##;
		$initconf .= ".conf";
		if( -f "/etc/init/$initconf.disabled") {
			# first handle upstart configuration
			rename "/etc/init/$initconf.disabled", "/etc/init/$initconf";
		} elsif( -f "/etc/init/$initconf" ) {
			# nothing to do, already enabled
			;
		} elsif( -f $initscript ){
			# only if service is not configured for upstart
			my $name = $initscript;
			$name =~ s/$initprefix//;
			if( Yaffas::Constant::OS eq 'Ubuntu' ) {
				system("update-rc.d -f $name defaults");
			} elsif( Yaffas::Constant::OS eq 'RHEL5' ) {
				system("chkconfig --add $name");
				system("chkconfig $name on");
			}
		}
	}
}

=item rm_from_runlevel ( SERVICE )

removes the SERVCE from the default Runlevel

=cut

sub rm_from_runlevel($){
	my $service = shift;
	my $initscript = $SERVICES{$service};
	my $initprefix = '/etc/init.d/';
	if( Yaffas::Constant::OS eq 'RHEL5' ) {
		$initscript =~ s/[^ ]* //;
		$initprefix = '/etc/rc.d/init.d/';
		$initscript = $initprefix.$initscript;
	}

	if( $initscript ){
		my $initconf = $initscript;
		$initconf =~ s#$initprefix##;
		$initconf .= ".conf";
		if( -f "/etc/init/$initconf") {
			# first handle upstart configuration
			rename "/etc/init/$initconf", "/etc/init/$initconf.disabled";
		} elsif( -f "/etc/init/$initconf.disabled" ) {
			# nothing to do, already disabled
			;
		} elsif( -f $initscript ){
			# only if service is not configured for upstart
			my $name = $initscript;
			$name =~ s/$initprefix//;
			if( Yaffas::Constant::OS eq 'Ubuntu' ) {
				system("update-rc.d -f $name remove");
			} elsif( Yaffas::Constant::OS eq 'RHEL5' ) {
				system("chkconfig --del $name");
			}
		}
	}
}

=item control ( SERVICE, [ACTION] )

It does ACTION with the SERVICE. Please B<use> the constants of Yaffas::Service for both!!!
It returns 1 on success else 0.

If ACTION is ommited it uses Yaffas::Service::STATUS as ACTION, returns 1 for running and 0
for not running.

=cut

sub control($;$){
	## todo ## check parameters
	my $service = shift;
	my $action = shift;
	$Message = undef; # clear message
	$action = STATUS unless defined $action;
	my $init_script = $Yaffas::Service::SERVICES{$service};
	if($init_script =~ m#^/sbin/service#) {
		$init_script =~ s#/sbin/service\s##;
		return undef unless (-x "/etc/rc.d/init.d/$init_script");
	} else {
		return undef unless (-x $Yaffas::Service::SERVICES{$service});
	}
	return &{ $Yaffas::Service::ACTIONS{$action} }($Yaffas::Service::SERVICES{$service}, $service);
}

=back

=cut

sub _start($$) {
	my $tmp;
	if($_[0] eq $Yaffas::Service::SERVICES{ HYLAFAX() } ||
	   $_[0] eq $Yaffas::Service::SERVICES{ ZARAFA_SERVER() } ||
	   $_[0] eq $Yaffas::Service::SERVICES{ ZARAFA_MONITOR() } ||
	   $_[0] eq $Yaffas::Service::SERVICES{ ZARAFA_GATEWAY() } ||
	   $_[0] eq $Yaffas::Service::SERVICES{ ZARAFA_ICAL() } ||
	   $_[0] eq $Yaffas::Service::SERVICES{ ZARAFA_SPOOLER() } ||
	   $_[0] eq $Yaffas::Service::SERVICES{ ZARAFA_LICENSED() } ||
	   $_[0] eq $Yaffas::Service::SERVICES{ WINBIND() }
	   ){
		if($_[0] =~ /\s/) {
			$tmp = system((split /\s/, $_[0]), "start");
		}
		else {
			$tmp = system($_[0], "start");
		}
	}else{
		if($_[0] =~ /\s/) {
			$tmp = do_back_quote((split /\s/, $_[0]), "start");
		}
		else {
			$tmp = do_back_quote($_[0], "start");
		}
	}

	if (control($_[1])) {
		return 1;
	} else {
		$Message = $tmp;
		return 0;
	}
}

sub _reload($$) {
	my $tmp;
	if($_[0] =~ /\s/) {
		$tmp = do_back_quote((split /\s/, $_[0]), "reload");
	}
	else {
		$tmp = do_back_quote($_[0], "reload");
	}

	if (control($_[1])) {
		return 1;
	} else {
		$Message = $tmp;
		return 0;
	}
}

sub _stop($$) {
	my $tmp;
	if($_[0] =~ /\s/) {
		$tmp = do_back_quote((split /\s/, $_[0]), "stop");
	}
	else {
		$tmp = do_back_quote($_[0], "stop");
	}

	if (!control($_[1])) {
		return 1;
	} else {
		$Message = $tmp;
		return 0;
	}
}

sub _restart($$) {
	my $tmp;
	if($_[0] eq $Yaffas::Service::SERVICES{ HYLAFAX() } ||
	   $_[0] eq $Yaffas::Service::SERVICES{ ZARAFA_SERVER() } ||
	   $_[0] eq $Yaffas::Service::SERVICES{ ZARAFA_MONITOR() } ||
	   $_[0] eq $Yaffas::Service::SERVICES{ ZARAFA_GATEWAY() } ||
	   $_[0] eq $Yaffas::Service::SERVICES{ ZARAFA_ICAL() } ||
	   $_[0] eq $Yaffas::Service::SERVICES{ ZARAFA_SPOOLER() } ||
	   $_[0] eq $Yaffas::Service::SERVICES{ ZARAFA_LICENSED() } ||
	   $_[0] eq $Yaffas::Service::SERVICES{ BBLCD() } ||
	   $_[0] eq $Yaffas::Service::SERVICES{ WINBIND() }
	   ){
		if($_[0] =~ /\s/) {
			$tmp = system((split /\s/, $_[0]), "restart");
		}
		else {
			$tmp = system($_[0], "restart");
		}
	}else{
		if($_[0] =~ /\s/) {
			$tmp = do_back_quote((split /\s/, $_[0]), "restart");
		}
		else {
			$tmp = do_back_quote($_[0], "restart");
		}
	}

	if (control($_[1])) {
		return 1;
	} else {
		$Message = $tmp;
		return 0;
	}
}

sub _status($){
	my $service = shift;

	if ($service eq $Yaffas::Service::SERVICES{ EXIM() } ) {
		if(Yaffas::Constant::OS eq 'RHEL5') {
			return __check_process('/usr/sbin/exim');
		} else {
			return __check_process('/usr/sbin/exim4');
		}
	} elsif ($service eq $Yaffas::Service::SERVICES{ SENDMAIL() }) {
		return __check_process('/usr/sbin/sendmail');
	} elsif ($service eq $Yaffas::Service::SERVICES{ POSTFIX() }) {
		if(Yaffas::Constant::OS eq 'RHEL5') {
            return __check_process('/usr/libexec/postfix/master');
		} else {
            return __check_process('/usr/lib/postfix/master');
		}
	} elsif ($service eq $Yaffas::Service::SERVICES{ HYLAFAX() } ) {
		return  __check_process('faxq') && __check_process('hfaxd');
	} elsif ($service eq $Yaffas::Service::SERVICES{ CYRUS() }) {
		return __check_process('/usr/sbin/cyrmaster');
	} elsif ($service eq $Yaffas::Service::SERVICES{ NETWORK() }) {
		return __check_network();
	} elsif ($service eq $Yaffas::Service::SERVICES{ LDAP() }) {
		return __check_process('/usr/sbin/slapd');
	} elsif ($service eq $Yaffas::Service::SERVICES{ NSCD() }) {
		return __check_process('/usr/sbin/nscd');
	} elsif ($service eq $Yaffas::Service::SERVICES{ SAMBA() }) {
		return __check_process('smbd');
	} elsif ($service eq $Yaffas::Service::SERVICES{ SASLAUTHD() }) {
		return __check_process('/usr/sbin/saslauthd');
	} elsif ($service eq $Yaffas::Service::SERVICES{ XINETD() }) {
		return __check_process('/usr/sbin/xinet');
	} elsif ($service eq $Yaffas::Service::SERVICES{ MYSQL() }) {
		return __check_process('/usr/sbin/mysqld');
	} elsif ($service eq $Yaffas::Service::SERVICES{ KAV() }) {
		return __check_process('aveserver');
	} elsif ($service eq $Yaffas::Service::SERVICES{ GREYLIST() }) {
		return __check_process('greylistd');
	} elsif ($service eq $Yaffas::Service::SERVICES{ KAS() }) {
		return __check_process('/usr/local/ap-mailfilter/bin/ap-process-server')
			&& __check_process('/usr/local/ap-mailfilter/bin/kas-license');
	} elsif ($service eq $Yaffas::Service::SERVICES{ WEBMIN() }) {
		if(Yaffas::Constant::OS eq 'RHEL5') {
			return __check_process('/usr/bin/perl /opt/yaffas/webmin/miniserv.pl');
		}
		else {
			return __check_process('/usr/bin/perl /opt/yaffas/webmin/miniserv.pl');
		}
	} elsif ($service eq $Yaffas::Service::SERVICES{ USERMIN() }) {
		if(Yaffas::Constant::OS eq 'RHEL5') {
			return __check_process('/usr/bin/perl /opt/Yaffas/usermin/miniserv.pl');
		}
		else {
			return __check_process('/usr/bin/perl /usr/local/usermin/miniserv.pl');
		}
	} elsif ($service eq $Yaffas::Service::SERVICES{ CUPS() }) {
		return __check_process('/usr/sbin/cupsd');
	} elsif ($service eq $Yaffas::Service::SERVICES{ CAPIINIT() }) {
		return __check_output('/usr/sbin/capiinit status');
	} elsif ($service eq $Yaffas::Service::SERVICES{ CAPI4HYLAFAX() }) {
		return __check_process('/usr/bin/c2faxrecv');
	} elsif ($service eq $Yaffas::Service::SERVICES{ FETCHMAIL() }) {
		return __check_process('/usr/bin/fetchmail');
	} elsif ($service eq $Yaffas::Service::SERVICES{ SPAMASSASSIN() }) {
		return __check_process('spamd');
	} elsif ($service eq $Yaffas::Service::SERVICES{ POSTGRESQL() }) {
		if(Yaffas::Constant::OS eq 'RHEL5') {
			return __check_process('/usr/bin/postmaster');
		}
		else {
			return __check_process('/usr/lib/postgresql/8.3/bin/postgres');
		}
	} elsif ($service eq $Yaffas::Service::SERVICES{ WINBIND() }) {
		if(Yaffas::Constant::OS eq 'RHEL5') {
			return __check_process('winbindd');
		}
		else {
			return __check_process('/usr/sbin/winbindd');
		}
	} elsif ($service eq $Yaffas::Service::SERVICES{ SNMPD() }) {
		return __check_process('/usr/sbin/snmpd');
	} elsif ($service eq $Yaffas::Service::SERVICES{ GOGGLETYKE() }) {
		return __check_process('/usr/sbin/goggletyke');
	} elsif ($service eq $Yaffas::Service::SERVICES{ DIVAS() }) {
		my @ret_lsmod = `/sbin/lsmod`;
		return (grep { $_ =~ m/divas/} @ret_lsmod);
	} elsif ($service eq $Yaffas::Service::SERVICES{ ZARAFA_GATEWAY() }) {
		return __check_process('/usr/bin/zarafa-gateway');
	} elsif ($service eq $Yaffas::Service::SERVICES{ ZARAFA_MONITOR() }) {
		return __check_process('/usr/bin/zarafa-monitor');
	} elsif ($service eq $Yaffas::Service::SERVICES{ ZARAFA_SERVER() }) {
		return __check_process('/usr/bin/zarafa-server');
	} elsif ($service eq $Yaffas::Service::SERVICES{ ZARAFA_SPOOLER() }) {
		return __check_process('/usr/bin/zarafa-spooler');
	} elsif ($service eq $Yaffas::Service::SERVICES{ ZARAFA_ICAL() }) {
		return __check_process('/usr/bin/zarafa-ical');
	} elsif ($service eq $Yaffas::Service::SERVICES{ ZARAFA_LICENSED() }) {
		return __check_process('/usr/bin/zarafa-licensed');
	} elsif ($service eq $Yaffas::Service::SERVICES{ SSHD() }) {
		return __check_process('/usr/sbin/sshd');
	} elsif ($service eq $Yaffas::Service::SERVICES{ MPPD() }) {
		return __check_process('/usr/local/MPP/mppd');
	} elsif ($service eq $Yaffas::Service::SERVICES{ MPPMANAGER() }) {
		return __check_process('/usr/bin/perl -w /usr/local/mppserver/bin/mppserver.pl');
	} elsif ($service eq $Yaffas::Service::SERVICES{ SEARCHD() }) {
		return __check_process('/usr/bin/searchd');
	} elsif ($service eq $Yaffas::Service::SERVICES{ NFSD() }) {
		return __check_process('[nfsd]');
	} elsif ($service eq $Yaffas::Service::SERVICES{ APACHE() }) {
		if(Yaffas::Constant::OS eq 'RHEL5') {
			return __check_process('/usr/sbin/httpd');
		}
		else {
			return __check_process('/usr/sbin/apache2');
		}
	} elsif ($service eq $Yaffas::Service::SERVICES{ BBLCD() }) {
		return ((__check_process('/usr/bin/bblcdclient.pl'))&&(__check_process('/usr/bin/lcdproc')));
	}
	return undef;
}

# network should be started all the time ;-)
sub __check_network {
	return 1;
}

### this subroutine returns 1 if the given process
# is found in our process list.
# 
# $_[0] = process name
# 
sub __check_process {
	my $proc = shift;
	
	foreach my $line (`ps ax -o cmd`) {
		chomp $line;
		if(index($line, $proc) != -1) {
			return 1;
		}
	}
	return undef;
}

sub __check_output($) {
	my $cmd = shift;
	if (`$cmd`) {
		return 1;
	}
	return undef;
}

sub check_service_available($) {
	my $service = shift;

	if(Yaffas::Constant::OS eq 'Ubuntu') {
		return 1 if (-x $Yaffas::Service::SERVICES{$service});
	}
	elsif(Yaffas::Constant::OS eq 'RHEL5') {
		my $init_script = $Yaffas::Service::SERVICES{$service};
		$init_script =~ s#/sbin/service\s##;
		return 1 if (-x "/etc/init.d/$init_script");
	}
	return 0;
}

=item check_samba ( [blocking] )

Checks if the samba server on localhost is reachable.

If B<blocking> is an integer number, will wait until the server can be reached
for a maximum of B<blocking> seconds.

=cut

sub check_samba(;$) {
	my $blocking = shift || 0;
	$blocking !~ /^\d+$/ and $blocking = 0;
	my $failed = 1;
	while($failed) {
		my $ret = Yaffas::do_back_quote("/usr/bin/smbclient", "-L", "//localhost", "-N");
		if($ret =~ "failed") {
			not $blocking and return 0;
			$blocking--;
			sleep 1;
		}
		else {
			$failed = 0;
		}
	}
	return ($failed ? 0 : 1);
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
