#!/usr/bin/perl
package Yaffas::Constant;

use strict;
use warnings;

use Switch;

##################################################
# determine of we are on a RHEL5 or Ubuntu machine
##################################################

sub get_os {
	my $lsb_release = `lsb_release -si -sr`;
	switch ($lsb_release) {
		case qr/CentOS 6|RedHatEnterpriseServer 6|Scientific 6/ { return "RHEL6"; }
		case qr/CentOS 5|RedHatEnterpriseServer 5|Scientific 5/ { return "RHEL5"; }
		case qr/Ubuntu/ { return "Ubuntu"; }
		else { return "unknown"; }
	}
}

use constant { OS => get_os() };

use constant {
	DIR => {
		"zarafa_log" => "/var/log/zarafa/",
		"webmin_config" => "/opt/yaffas/etc/webmin/",
		"usermin_config" => "/opt/yaffas/etc/usermin/",
		"yaffas_module" => "/opt/yaffas/lib/perl5/Yaffas/Module/",
		"paging_framework" => "/var/spool/bbpaging",
		"bkconfig" => "/opt/yaffas/config/",
		"watermark" => "/data/config/fax/bbwatermark",
		"webmin_prefix" => "/opt/yaffas/",
		"webmin" => "/opt/yaffas/webmin/",
		"usermin" => "/opt/yaffas/usermin/",
		"var_webmin" => "/opt/yaffas/var/webmin/",
		"bkfiles" => "/opt/yaffas/config/",
		"ldap_data" => '/var/lib/ldap/',
		"smbdata" => '/data/shares/',
		"sieve" => '/data/mail/sieve/',
		"hylafax" => '/etc/hylafax/',
		"doneq" => '/data/fax/hylafax/doneq/',
		"recvq" => '/data/fax/hylafax/recvq/',
		"sendq" => '/data/fax/hylafax/sendq/',
		"docq" => '/data/fax/hylafax/docq/',
		"hylafax_spool" => '/data/fax/hylafax/',
		"hylafax_log" => "/data/fax/hylafax/log",
		"smbprinters" => '/etc/samba/smbprinters/',
		"bbcypheus" => '/data/config/fax/bbcypheus/',
		"module_lang" => '/opt/yaffas/lang/',
		"kav_licence" => '/var/db/kav/5.5/kav4mailservers/licenses/',
		"kav_bases" => '/var/db/kav/5.5/kav4mailservers/bases/',
		"pdf_printers" => '/etc/samba/smbpdfprinters/',
		"pdfsave" => '/data/config/pdf/',
		"pdfdir" => '/data/pdf/',
		"pdf_user_dir" => '/data/pdf/users/',
		"quarantine_dir" => "/data/mail/quarantine/",
		"feature_packages" => '/var/cache/bbfeatures/',
		"bbfaxconf" => '/data/config/fax/bbfaxconf',
		"divasdir" => '/usr/lib/eicon/divas',
		"wwwdir" => '/var/www',
		"logdir" => '/var/log',
		"rundir" => '/var/run',
		"libdir" => '/var/lib',
		"ssl_certs" => "/opt/yaffas/etc/ssl/certs/",
		"ssl_certs_org" => "/opt/yaffas/etc/ssl/certs/org/",
		"updatepath" => "/opt/yaffas/webmin/update/",
		"sievec" => "/usr/lib/cyrus/bin/sievec/",
		"cyrdeliver" => "/usr/sbin/cyrdeliver/",
		"faxprint" => "/etc/samba/smbprinters/faxprint/",
		"jpeg_dir" => "/etc/samba/smbprinters/faxprint/jpeg/",
		"eps_dir" => "/etc/samba/smbprinters/faxprint/eps/",
		"ldap_schema" => (OS eq 'Ubuntu' ? "/etc/ldap/schema/" : "/etc/openldap/schema/"),
		"zarafa_licence" => "/etc/zarafa/license/",
		"selections" => "/selections",
		"rhel5_devices" => "/etc/sysconfig/networking/devices/",
		"rhel5_scripts" => "/etc/sysconfig/network-scripts/",
		"mppserver_conf" => "/etc/mppserver/",
	}
};

use constant {
	FILE => {
		"auth_wizard_lock" => "/var/lock/auth-wizard-lock",
		"sshd_config" => "/etc/ssh/sshd_config",
		"nsswitch" => "/etc/nsswitch.conf",
		"tmpslap" => "/tmp/slapcat.ldif",
		"goggletyke_cfg" => "/etc/goggletyke.cfg",
		"apt_conf" => "/etc/apt/apt.conf",
		"yum_conf" => "/etc/yum.conf",
		"wget_conf" => "/etc/wgetrc",
		"kav_conf" => "/etc/kav/kav_updater.conf",
		"passwd" => "/etc/passwd",
		"group" => "/etc/group",
		"crontab" => "/etc/crontab",
		"smbldap_bind_conf" => "/etc/smbldap-tools/smbldap_bind.conf",
		"ldap_secret" => "/etc/ldap.secret",
		"ldap_secret_local" => "/etc/ldap.secret.local",
		"slapd_conf" => ( OS eq 'Ubuntu' ? "/etc/ldap/slapd.conf" : "/etc/openldap/slapd.conf" ),
		"slapd_default_conf" => "/etc/default/slapd",
		"libnss_ldap_conf" => ( OS eq 'Ubuntu' ? "/etc/libnss-ldap.conf" : "/etc/ldap.conf" ),
		"pam_ldap_conf" => "/etc/pam_ldap.conf",
		"ldap_conf" => "/etc/ldap.conf",
		"ldap_ldap_conf" => ( OS eq 'Ubuntu' ? "/etc/ldap/ldap.conf" : "/etc/openldap/ldap.conf" ),
		"webmin_config" => DIR->{webmin_config}."config",
		"webmin_acl" => DIR->{webmin_config}."webmin.acl",
		"usermin_config" => DIR->{usermin_config}."config",
		"network_interfaces" => "/etc/network/interfaces",
		"resolv_conf" => "/etc/resolv.conf",
		"exim_passwd_client" => ( OS eq 'Ubuntu' ? "/etc/exim4/passwd.client" : "/etc/exim/passwd.client" ),
		"hosts" => "/etc/hosts",
		"hostname" => "/etc/hostname",
		"samba_conf" => "/etc/samba/smb.conf",
		"yaffas_config" => "/opt/yaffas/config/yaffas.xml",
		"default_domain" => "/etc/defaultdomain",
		"smbconf_shares" => '/etc/samba/smbopts.shares',
		"smbconf_fax" => '/etc/samba/smbopts.fax',
		"capi_conf" => "/etc/isdn/capi.conf",
		"hfaxd_conf" => '/etc/hylafax/hfaxd.conf',
		"hosts_hfaxd" => '/etc/hylafax/hosts.hfaxd',
		"fax_notify" => '/etc/hylafax/FaxNotify',
#		"smb_includes_global" => ( OS eq 'Ubuntu' ? "/etc/samba/smbopts.global" : "/etc/samba/smb.conf" ),
		"smb_includes_global" => "/etc/samba/smbopts.global",
		"smb_includes" => '/etc/samba/includes.smb',
		"c2faxsend_bb" => '/etc/c2faxsend_bb.conf',
		"config_faxcapi" => '/etc/hylafax/config.faxCAPI',
		"faxlog" => '/data/fax/hylafax/log/xferfaxlog',
		"faxnotify" => '/etc/hylafax/FaxNotify',
		"fifo" => '/data/fax/hylafax/FIFO.faxCAPI',
		"capi_conf" => '/etc/isdn/capi.conf',
		"activate_capi" => '/etc/default/capi4hylafax',
		"quota_full_file" => "/var/spool/cyrus/quota/mailfull.message",
		"quota_warn_file" => "/var/spool/cyrus/quota/mailwarn.message",
		"imap_conf" => "/etc/imapd.conf",
		"print_nr_dispatch" => "/etc/hylafax/fax2print_nr",
		"print_msn_dispatch" => "/etc/hylafax/fax2print_controller",
		"faxrcvd_opts" => "/data/fax/hylafax/etc/faxrcvd_opts",
		"faxrcvd" => "/data/fax/hylafax/bin/faxrcvd",
		"mysql_cnf" => ( OS eq 'Ubuntu' ? "/etc/mysql/my.cnf" : "/etc/my.cnf" ),
		"zarafa_mysql_cnf" => ( OS eq 'Ubuntu' ? "/etc/mysql/conf.d/zarafa-innodb.cnf" : "/etc/my.cnf" ),
		"exim_relay_conf" => ( OS eq 'Ubuntu' ? "/etc/exim4/exim.acceptrelay" : "/etc/exim/exim.acceptrelay" ),
		"exim_domains_conf" => ( OS eq 'Ubuntu' ? "/etc/exim4/exim.acceptdomains" : "/etc/exim/exim.acceptdomains" ),
		"bbexim_conf" => ( OS eq 'Ubuntu' ? "/etc/exim4/bbexim.conf" : "/etc/exim/bbexim.conf" ),
		"exim_smtproute_conf" => ( OS eq 'Ubuntu' ? "/etc/exim4/exim.smtproutes" : "/etc/exim/exim.smtproutes" ),
		"cypheus_updates" => '/data/config/fax/bbcypheus/installed.txt',
		"bkwizard" => '/etc/bkwizard.conf',
		"license_module_file" => '/etc/bkmodulelicense',
		"fetchmailrc" => "/etc/fetchmailrc",
		"fetchmail_pid" => "/var/run/fetchmail/.fetchmail.pid",
		"global_headers" => '/data/config/mail/mailfilter/headers',
		"bash_history" => '/root/.bash_history',
		"pdf_includes" => '/etc/samba/pdfprinters.smb',
		"pdf_log" => '/var/log/yaffaspdf.log',
		"exception_log" => '/var/log/exception.log',
		"dir_aliases" => '/etc/aliases.dir',
		"feature_package_list" => '/var/cache/bbfeatures/feature-list',
		"feature_config" => '/etc/bbfeatures/config',
		"myyaffas_conf" => '/etc/bbportal/myyaffas.conf',
		"fax2ps" => '/usr/bin/fax2ps',
		"bk_pass" => '/etc/postgresql-common/bk.pass',
		"exim_blacklist" => ( OS eq 'Ubuntu' ? '/etc/exim4/exim.blacklist-hosts' : '/etc/exim/exim.blacklist-hosts'),
		"exim_whitelist" => ( OS eq 'Ubuntu' ? '/etc/exim4/exim.whitelist-hosts' : '/etc/exim/exim.whitelist-hosts'),
		"capiinit" => '/usr/sbin/capiinit',
		"mkfifo" => '/usr/bin/mkfifo',
		"bbcapi_opts" => '/data/config/fax/bbfaxconf/bbcapi.opts',
		"sa_learn_conf" => '/etc/spamassassin/sa-learn-cyrus.conf',
		"smbldap_conf" => '/etc/smbldap-tools/smbldap.conf',
		"smb_allpdfs" => '/etc/samba/smbopts.allpdfs',
		"pamd_login" => '/etc/pam.d/login',
		"snmpd_conf" => '/etc/snmp/snmpd.conf',
		"hylafax_day" => '/etc/hylafax/hylafax_cron_day',
		"hylafax_week" => '/etc/hylafax/hylafax_cron_week',
		"hylafax_month" => '/etc/hylafax/hylafax_cron_month',
		"hylafax_cron_day" => '/etc/cron.daily/hylafax_cron_day',
		"hylafax_cron_week" => '/etc/cron.weekly/hylafax_cron_week',
		"hylafax_cron_month" => '/etc/cron.monthly/hylafax_cron_month',
		"divas_change" => '/data/config/fax/divas_config_changed',
		"config_eiconfax" => '/etc/hylafax/config.ttyds',
		"adapter_config_eiconfax" => '/data/config/fax/bbfaxconf/config.adapter',
		"mtpx_config" => '/data/config/fax/bbfaxconf/mtpx.conf',
		"divas_cfg" => DIR->{divasdir}."/divas_cfg.rc",
		"divas_cid" => "/etc/hylafax/cid",
		"config_ttyds_template" => DIR->{webmin}."bbfaxconf/templates/config.ttyds",
		"exim_mail2fax_conf" => ( OS eq 'Ubuntu' ? "/etc/exim4/exim.mail2fax_hosts" : "/etc/exim/exim.mail2fax_hosts" ),
		"mail2fax_config" => "/data/config/fax/mail2fax/config",
		"sendfax_custom" => "/data/config/fax/mail2fax/sendfax.custom",
		"doneq_clean_cron" => "/etc/cron.daily/doneq_clean",
		"rcvq_clean_cron" => "/etc/cron.daily/rcvq_clean",
		"doneq_clean" => "/etc/hylafax/doneq_clean",
		"rcvq_clean" => "/etc/hylafax/rcvq_clean",
		"pdf_drivers" => ( Yaffas::Constant::OS eq 'Ubuntu' ? "/opt/software/driver/gs_driver.zip" : "/data/pdf/documents/driver/gs_driver.zip" ),
		"bkversion" => "/opt/yaffas/etc/installed-products",
		"krb5" => "/etc/krb5.conf",
		"yaffas_debug" => "/tmp/yaffas.debug",
		"all_log" => "/var/log/bbupdate/all.log",
		"updatelog" => "/var/log/bbupdates",
		"errorlog" => "/var/log/bbupdate.errors",
		"sourceslist" => "/etc/apt/sources.list",
		"time_config" => DIR->{webmin_config}."time/config",
		"miniservusers" => DIR->{webmin_config}."miniserv.users",
		"skyaptnotify" => "/etc/opengroupware.org/ogo/Defaults/skyaptnotify.plist",
		"modps_conf" => DIR->{faxprint}."modps.conf",
		"debiansysmaint" => "/etc/mysql/debian.cnf",
		"ldap_settings" => "/etc/ldap.settings",
		"zarafa_server_cfg" => "/etc/zarafa/server.cfg",
		"zarafa_ldap_cfg" => "/etc/zarafa/ldap.yaffas.cfg",
		"zarafa_spooler_cfg" => "/etc/zarafa/spooler.cfg",
		"need_takeover_flag_file" =>  "/data/config/fax/faxconf_takeover_needed",
		"inittab" => "/etc/inittab",
		"r_ifcfg" => "/etc/sysconfig/network-scripts/ifcfg",
		"iftab" => "/etc/iftab",
		"email_addresses" => ( OS eq 'Ubuntu' ? "/etc/exim4/exim.user-rewrite" : "/etc/exim/exim.user-rewrite" ),
		"proc_dma" => "/proc/dma",
		"proc_swaps" => "/proc/swaps",
		"authconfig" => "/etc/sysconfig/authconfig",
		"system_auth_ac" => "/etc/pam.d/system-auth-ac",
		"qreview_users" => "/etc/mppserver/users.conf",
		"mppd_conf_xml" => "/usr/local/MPP/mppd.conf.xml",
		"zarafa_admin_cfg" => "/etc/zarafa/folderadmin.cfg",
		"exports" => "/etc/exports",
		"sendmail_faxdomain" => "/etc/mail/fax-domains",
		"sendmail_authtype" => "/etc/mail/bbauthtype",
		"sendmail_mail2fax_hosts" => "/etc/mail/mail2fax_hosts",
		"postfix_authtype" => "/etc/postfix/bbauthtype",
		"postfix_mail2fax_hosts" => "/etc/postfix/mail2fax_hosts",
		"postfix_fax_transport" => "/etc/postfix/fax-transport.cf",
		"bootlog" => "/var/log/boot",
		"webaccess_htaccess" => "/usr/share/zarafa-webaccess/.htaccess",
		"zarafa_quota_mail_warn" => "/etc/zarafa/quotamail/userwarning.mail",
		"zarafa_quota_mail_soft" => "/etc/zarafa/quotamail/usersoft.mail",
		"zarafa_quota_mail_hard" => "/etc/zarafa/quotamail/userhard.mail",
		"freshclam_conf" => ( OS eq 'Ubuntu' ? "/etc/clamav/freshclam.conf" : "/etc/freshclam.conf" ),
		"postfix_master" => "/etc/postfix/master.cf",
		"postfix_main" => "/etc/postfix/main.cf",
		"postfix_ldap_users" => "/etc/postfix/ldap-users.cf",
		"postfix_ldap_group" => "/etc/postfix/ldap-group.cf",
		"postfix_ldap_aliases" => "/etc/postfix/ldap-aliases.cf",
		"postfix_smtp_auth" => "/etc/postfix/smtp_auth.cf",
		"fetchmail_default_conf" => "/etc/default/fetchmail",
		"zarafa_backup_conf" => "/opt/yaffas/config/zarafa/backup.conf",
		"rhel_net" => "/etc/init.d/network",
		"freshclam" => "/etc/init.d/clamav-freshclam",
		"policyd_conf" => "/etc/policyd-weight.conf",
		"policy_mod" => "/opt/yaffas/config/policy",
		"clamd_conf" => ( OS eq 'Ubuntu' ? "/etc/clamav/clamd.conf" : "/etc/clamd.conf" ),
		"sa_local_conf" => ( OS eq 'Ubuntu' ? "/etc/spamassassin/local.cf" : "/etc/mail/spamassassin/local.cf" ),
		"amavis_conf" => "/etc/amavis/conf.d/60-yaffas",
		"channels_cf" => "/opt/yaffas/config/channels.cf",
		"channels_keys" => "/opt/yaffas/config/channels.keys",
		"wl_postfix" => "/opt/yaffas/config/postfix/whitelist-postfix",
		"wl_amavis" => "/opt/yaffas/config/whitelist-amavis",
		"rhel5_network" => "/etc/sysconfig/network",
	}
};

use constant {
	APPLICATION => {
		"update_issue" => "/etc/init.d/update_issue.pl",
		"passwd" => "/usr/bin/passwd.org",
		"su" => "/bin/su",
		"init_fetchmail" => "/etc/init.d/fetchmail",
		"smbpasswd" => "/usr/bin/smbpasswd",
		"slappasswd" => "/usr/sbin/slappasswd",
		"smbldap_passwd" => "/usr/sbin/smbldap-passwd",
		"ldapmodify" => "/usr/bin/ldapmodify",
		"mysqladmin" => "/usr/bin/mysqladmin",
		"mysqlshow" => "/usr/bin/mysqlshow",
		"dpkg" => "/usr/bin/dpkg",
		"rpm" => "/bin/rpm",
		"wget" => "/usr/bin/wget",
		"sendfax" => "/usr/bin/sendfax",
		"mysqldump" => "/usr/bin/mysqldump",
		"mysqlcheck" => "/usr/bin/mysqlcheck",
		"mysql" => "/usr/bin/mysql",
		"ldapsearch" => "/usr/bin/ldapsearch",
		"slapadd" => "/usr/sbin/slapadd",
		"tar" => "/bin/tar",
		"exim4" => ( OS eq 'Ubuntu' ? "/usr/sbin/exim4" : "/usr/sbin/exim" ),
		"faxinfo" => "/usr/sbin/faxinfo",
		"faxrm" => "/usr/bin/faxrm",
		"hostname" => "/bin/hostname",
		"domrename" => "/opt/yaffas/bin/domrename.pl",
		"dmesg" => "/bin/dmesg",
		"lspci" => ( OS eq 'Ubuntu' ? "/usr/bin/lspci" : "/sbin/lspci" ),
		"lshw" => ( OS eq 'Ubuntu' ? "/usr/bin/lshw" : "/usr/sbin/lshw" ),
		"df" => "/bin/df",
		"rm" => "/bin/rm",
		"free" => "/usr/bin/free",
		"slapcat" => "/usr/sbin/slapcat",
		"usershow" => "/usr/sbin/smbldap-usershow",
		"usermod" => "/usr/sbin/smbldap-usermod",
		"useradd" => "/usr/sbin/smbldap-useradd",
		"userdel" => "/usr/sbin/smbldap-userdel",
		"groupmod" => "/usr/sbin/smbldap-groupmod",
		"groupadd" => "/usr/sbin/smbldap-groupadd",
		"groupdel" => "/usr/sbin/smbldap-groupdel",
		"kav_licence" => '/opt/kav/5.5/kav4mailservers/bin/licensemanager',
		"lilo" => '/sbin/lilo',
		"bbgetopts" => '/usr/bin/bbgetopts.pl',
		"dropolddocs" => '/usr/bin/dropolddocs.sh',
		"mutt" => '/usr/bin/mutt',
		"update-rc.d" => '/usr/sbin/update-rc.d',
		"Config.dlg" => DIR->{divasdir}."/Config.dlg",
		"divactrl" => DIR->{divasdir}."/divactrl",
		"ps" => '/bin/ps',
		"faxqclean" => "/usr/sbin/faxqclean",
		"faxcron" => "/usr/sbin/faxcron",
		"faxstat" => "/usr/bin/faxstat",
		"openssl" => "/usr/bin/openssl",
		"hostname.sh" => "/etc/init.d/hostname",
		"dnsdomainname" => ( Yaffas::Constant::OS eq 'Ubuntu' ? "/bin/dnsdomainname" : "/bin/domainname" ),
		"nscd" => "/usr/sbin/nscd",
		"sievec" => "/usr/lib/cyrus/bin/sievec",
		"cyrdeliver" => "/usr/sbin/cyrdeliver",
		"ntpdate" => "/usr/sbin/ntpdate",
		"sa-learn-cyrus" => "/usr/sbin/sa-learn-cyrus",
		"identify" => "/usr/bin/identify",
		"recvstats" => "/usr/sbin/recvstats",
		"xferfaxstats" => "/usr/sbin/xferfaxstats",
		"logger" => "/usr/bin/logger",
		"keepup2date" => "/opt/kav/5.5/kav4mailservers/bin/keepup2date",
		"lpstat" => "/usr/bin/lpstat",
		"lpadmin" => "/usr/sbin/lpadmin",
		"cupsenable" => "/usr/sbin/cupsenable",
		"cupsdisable" => "/usr/sbin/cupsdisable",
		"wbinfo" => "/usr/bin/wbinfo",
		"net" => "/usr/bin/net",
		"file" => "/usr/bin/file",
		"zarafa_admin" => "/usr/bin/zarafa-admin",
		"gpg" => "/usr/bin/gpg",
		"gs_bin" => ( OS eq 'Ubuntu' ? "/usr/bin/gs" : "/opt/Yaffas/ghostscript/bin/gs-gpl" ),
		"webmin_web_lib" => "/opt/yaffas/webmin/web-lib.pl",
		"usermin_web_lib" => "/opt/yaffas/usermin/web-lib.pl",
		"top" => "/usr/bin/top",
		"getent" => "/usr/bin/getent",
		"route" => "/sbin/route",
		"mailq" => "/usr/bin/mailq",
		"chown" => "/bin/chown",
		"rpm" => "/bin/rpm",
		"ifup" => "/sbin/ifup",
		"ifdown" => "/sbin/ifdown",
		"uname" => "/bin/uname",
		"ifconfig" => "/sbin/ifconfig",
		"uptime" => "/usr/bin/uptime",
		"lsmod" => "/sbin/lsmod",
		"mount" => "/bin/mount",
		"lsof" => "/usr/sbin/lsof",
		"htmldoc" => '/usr/bin/htmldoc',
		"last" => "/usr/bin/last",
		"udevinfo" => "/usr/bin/udevinfo",
		"udevadm" => "/sbin/udevadm",
		"chkconfig" => "/sbin/chkconfig",
		"php5" => "/usr/bin/php5",
		"zarafa_public_folder_script" => "/usr/bin/zarafa-public-folders",
		"exportfs" => "/usr/sbin/exportfs",
		"postmap" => "/usr/sbin/postmap",
		"authconfig" => "/usr/sbin/authconfig",
		"testparm" => "/usr/bin/testparm",
		"postconf" => "/usr/sbin/postconf",
		"postmap" => '/usr/sbin/postmap',
		"postsuper" => '/usr/sbin/postsuper',
		"pfcat" => '/opt/yaffas/bin/pfcat.sh',
		"sa_update" => "/usr/bin/sa-update",
		"policyd_weight" => '/usr/sbin/policyd-weight',
		"brctl" => '/usr/sbin/brctl',
		"dhclient" => '/sbin/dhclient',
		"locale-gen" => '/usr/sbin/locale-gen',
	}
};

use constant {
	MISC => {
		"faxrmpasswd" => 'bbs1crEt',
		"sharedfolder" => "Shared Folder",
		"min_uid" => 1000,
		"min_gid" => 501,
		"never_users" => [ "admin", "anyone", "cyrus" ],
		"signature_key_id" => "1727320D",
		"admin_groups" => ["Domain Admins", "Print Operators"],
	}
};

# sub BEGIN {
# 	use Exporter;
# 	our @ISA= qw(Exporter);
# 	our @EXPORT_OK = qw(DIR FILE APPLICATION MISC);
# }

1;

=pod

=head1 NAME

Yaffas::Constant

=head1 SYNOPSIS

 use Yaffas::Constant;
 my $dpkg_binary = Yaffas::Constant::APPLICATION->{dpkg};
 my $webmin_configuration_dir = Yaffas::Constant::DIR->{webmin_config};
 my $apt_conf_file = Yaffas::Constant::FILE->{apt_conf};

=head1 DESCRIPTION

Constants to a lot of Directorys, Files, Applications and other Stuff.

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
