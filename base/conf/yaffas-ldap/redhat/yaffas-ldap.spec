Name:		yaffas-ldap
Version: 1.0.1
Release: 1
Summary:	LDAP configuration for yaffas
Group:		Application/System
License:	AGPL
URL:		http://www.yaffas.orgg
Source0:	file://%{name}-%{version}.tar.gz
BuildRoot:	%(mktemp -ud %{_tmppath}/%{name}-%{version}-%{release}-XXXXXX)
BuildArch:	noarch
%{?el5:Requires: nscd, openldap-servers, openldap-clients, smbldap-tools, perl(Term::ReadKey), postfix, samba-common, expect, yaffas-certificates, nss_ldap}
%{?el6:Requires: nscd, openldap-servers, openldap-clients, smbldap-tools, perl(Term::ReadKey), postfix, samba-common, expect, yaffas-certificates, nss-pam-ldapd}
Conflicts:  perl-XML-SAX-Base = 0:1.04-1.el6.rf

%description
Edits libnss-ldap.conf, pam-ldap.conf, nsswitch.conf

%build
make %{?_smp_mflags}

%install
rm -rf $RPM_BUILD_ROOT
make install DESTDIR=$RPM_BUILD_ROOT

%post

%postun
if [ $1 -eq 0 ]; then
	for SAVEFILE in /etc/ldap.conf.yaffassave /etc/openldap/slapd.conf.yaffassave /etc/openldap/ldap.conf.yaffassave /etc/smbldap-tools/smbldap.conf.yaffassave /etc/smbldap-tools/smbldap_bind.conf.yaffassave /etc/sysconfig/ldap.yaffassave /etc/nslcd.conf.yaffassave; do
		if [ -e $SAVEFILE ]; then
			%{__mv} -f $SAVEFILE ${SAVEFILE/.yaffassave/}
		fi
	done
	%{__rm} -f /etc/ldap.settings
	%{__rm} -f /etc/ldap.secret
	%{__rm} -f /etc/postfix/ldap-users.cf
	%{__rm} -f /etc/postfix/ldap-aliases.cf
fi

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root,-)
%doc debian/{changelog,copyright}
%config /opt/yaffas/share/doc/example/etc/ldap.conf
%config /opt/yaffas/share/doc/example/etc/nslcd.conf
%config /opt/yaffas/share/doc/example/etc/ldap.secret
%config /opt/yaffas/share/doc/example/etc/ldap.settings
%config /opt/yaffas/share/doc/example/etc/openldap/ldap.conf
/opt/yaffas/share/doc/example/etc/openldap/schema/samba.schema
/opt/yaffas/share/doc/example/etc/openldap/schema/zarafa.schema
%config %attr(640,root,ldap) /opt/yaffas/share/doc/example/etc/openldap/slapd.conf
%config /opt/yaffas/share/doc/example/etc/nsswitch.conf
%config /opt/yaffas/share/doc/example/etc/postfix/ldap-aliases.cf
%config /opt/yaffas/share/doc/example/etc/postfix/ldap-users.cf
%config /opt/yaffas/share/doc/example/etc/smbldap-tools/smbldap.conf
%config /opt/yaffas/share/doc/example/etc/smbldap-tools/smbldap_bind.conf
%config /opt/yaffas/share/doc/example/etc/apparmor.d/local/usr.sbin.slapd
%config %attr(750,root,root) /opt/yaffas/bin/domrename.pl
/opt/yaffas/share/%{name}/postinst-deb.sh
/opt/yaffas/share/%{name}/postinst-rpm.sh
/opt/yaffas/share/yaffas-upgrade/01-yaffas-ldap.sh
/tmp/yaffas_base.ldif

%changelog
* Fri Dec 02 2011 Christof Musik <christof@sanjay.bitbone.de> 1.0.1-1
- update to version 1.0.1-1

* Mon Oct 31 2011 Package Builder <packages@yaffas.org> 1.0.0-1
- update to version 1.0.0-1

* Wed Sep 28 2011 Package Builder <packages@yaffas.org> 1.0-beta3
- update to version 1.0-beta3

* Tue Jul 26 2011 Package Builder <packages@yaffas.org> 1.0-beta2
- update to version 1.0-beta2

* Fri Jun 03 2011 Package Builder <packages@yaffas.org> 1.0-beta1
- update to version 1.0-beta1

* Tue May 03 2011 Package Builder <packages@yaffas.org> 0.9.0-1
- update to version 0.9.0
- some fixes
- added mailserver security module

* Fri Apr 08 2011 Package Builder <packages@yaffas.org> 0.8.0-1
- update to version 0.8.0

* Mon Mar 08 2011 Package Builder <packages@yaffas.org> 0.7.0-1
- initial release

