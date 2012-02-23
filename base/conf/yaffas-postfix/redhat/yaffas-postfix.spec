Name:		yaffas-postfix
Version:	0.7.0
Release:	1%{?dist}
Summary:	Configuration package for postfix
Group:		Application/System
License:	AGPL
URL:		http://www.yaffas.org
Source:		file://%{name}-%{version}.tar.gz
BuildArch:	noarch
BuildRoot:	%(mktemp -ud %{_tmppath}/%{name}-%{version}-%{release}-XXXXXX)
Requires:	postfix, cyrus-sasl

%description
Configuration package for postfix

%build
make %{?_smp_mflags}

%install
rm -rf $RPM_BUILD_ROOT
make install DESTDIR=$RPM_BUILD_ROOT

%clean
rm -rf $RPM_BUILD_ROOT

%post
if [ "$1" = 1 ] ; then
	sed -e '/smtpd_tls_session_cache_database/d' -i /opt/yaffas/share/doc/example/etc/postfix/main.cf
	sed -e '/smtp_tls_session_cache_database/d' -i /opt/yaffas/share/doc/example/etc/postfix/main.cf
	%{__mv} -f /etc/postfix/main.cf /etc/postfix/main.cf.yaffassave
	%{__mv} -f /etc/postfix/master.cf /etc/postfix/master.cf.yaffassave
	%{__mv} -f /etc/postfix/sasl/smtpd.conf /etc/postfix/sasl/smtpd.conf.yaffassave
	%{__cp} -f -a /opt/yaffas/share/doc/example/etc/postfix/main.cf /etc/postfix
	%{__cp} -f -a /opt/yaffas/share/doc/example/etc/postfix/master-redhat.cf /etc/postfix/master.cf
	%{__cp} -f -a /opt/yaffas/share/doc/example/etc/postfix/dynamicmaps.cf /etc/postfix
	%{__cp} -f -a /opt/yaffas/share/doc/example/etc/postfix/sasl/smtpd.conf /etc/postfix/sasl/

	CONF=/etc/postfix
	mkdir -p $CONF

	touch $CONF/ldap-aliases.cf
	touch $CONF/ldap-aliases.cf.db
	touch $CONF/ldap-users.cf
	touch $CONF/ldap-users.cf.db
	touch $CONF/smtp_auth.cf
	postmap $CONF/smtp_auth.cf
	touch $CONF/virtual_users_global
	postmap $CONF/virtual_users_global

	chmod 600 $CONF/smtp_auth.cf
	chmod 600 $CONF/smtp_auth.cf.db

	/usr/bin/newaliases

fi

if ! grep -q 'MECH="rimap"' /etc/sysconfig/saslauthd; then
    sed -e 's/^MECH.*/MECH="rimap"/' -i /etc/sysconfig/saslauthd
    sed -e 's/^OPTIONS.*/OPTIONS="-O 127.0.0.1"/' -i /etc/sysconfig/saslauthd
    chkconfig saslauthd on
fi

# disable sendmail
service sendmail stop
chkconfig sendmail off

# enable postfix
alternatives --set mta /usr/sbin/sendmail.postfix
chkconfig postfix on
service postfix restart
service saslauthd restart

%postun
if [ $1 -eq 0 ]; then
	%{__rm} -f /etc/postfix/dynamicmaps.cf
	%{__mv} -f /etc/postfix/main.cf.yaffassave /etc/postfix/main.cf
	%{__mv} -f /etc/postfix/master.cf.yaffassave /etc/postfix/master.cf
fi

%files
%defattr(-,root,root,-)
%doc debian/{changelog,copyright}
/opt/yaffas/share/doc/example/etc/postfix/dynamicmaps.cf
/opt/yaffas/share/doc/example/etc/postfix/main.cf
/opt/yaffas/share/doc/example/etc/postfix/master.cf
/opt/yaffas/share/doc/example/etc/postfix/master-redhat.cf
/opt/yaffas/share/doc/example/etc/postfix/sasl/smtpd.conf

%changelog
