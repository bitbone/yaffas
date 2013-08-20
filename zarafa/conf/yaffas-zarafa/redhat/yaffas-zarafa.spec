Name:		yaffas-zarafa
Version: 0.7.0
Release: 1
Summary:	configure yaffas for zarafa
Group:		Application/System
License:	AGPL
URL:		http://www.yaffas.org
Source0:	file://%{name}-%{version}.tar.gz
BuildRoot:	%(mktemp -ud %{_tmppath}/%{name}-%{version}-%{release}-XXXXXX)
BuildArch:  noarch
Requires:	php, php-cli, php-ldap, mysql-server, zarafa-webaccess, zarafa, yaffas-module-zarafalicence, yaffas-module-zarafaresources, yaffas-module-zarafaconf, yaffas-module-changelang, yaffas-module-zarafaorphanedstores, yaffas-module-zarafawebaccess, yaffas-module-zarafabackup, mod_ssl, yaffas-ldap, zarafa-webapp, zarafa-wa-plugins

%description
Additional yaffas configuration to make zarafa work

%build
make %{?_smp_mflags}

%install
%{__rm} -rf $RPM_BUILD_ROOT
make install DESTDIR=$RPM_BUILD_ROOT

%clean
%{__rm} -rf $RPM_BUILD_ROOT

%post

# register product
CONF="/opt/yaffas/etc/installed-products"
KEY="zarafa"
VALUE='Zarafa'

if ZARAFAVERSION=$(/bin/rpm -q --qf %{VERSION} zarafa); then
	VALUE="Zarafa v$ZARAFAVERSION"
fi
if [ -e $CONF ]; then
	if ! grep -iq ^$KEY $CONF; then
		echo "$KEY=$VALUE" >> $CONF
	else
		sed -e s/^$KEY=.*/"$KEY=$VALUE"/ -i $CONF
	fi
else
	echo "$KEY=$VALUE" >> $CONF
fi

%postun
if [ $1 -eq 0 ]; then
	for CFG in /etc/zarafa/*.cfg.yaffassave; do
		%{__mv} -f $CFG ${CFG/.yaffassave/}
	done
fi

%files
%defattr(-,root,root,-)
%doc debian/{changelog,copyright}
%config /opt/yaffas/share/doc/example/etc/zarafa/dagent.cfg
%config /opt/yaffas/share/doc/example/etc/zarafa/gateway.cfg
%config /opt/yaffas/share/doc/example/etc/zarafa/ical.cfg
%config /opt/yaffas/share/doc/example/etc/zarafa/ldap.yaffas.cfg
%config /opt/yaffas/share/doc/example/etc/zarafa/ldap.cfg
%config /opt/yaffas/share/doc/example/etc/zarafa/monitor.cfg
%config /opt/yaffas/share/doc/example/etc/zarafa/server.cfg
%config /opt/yaffas/share/doc/example/etc/zarafa/spooler.cfg
%config /opt/yaffas/share/doc/example/etc/zarafa/search.cfg
/opt/yaffas/share/%{name}/postinst-deb.sh
/opt/yaffas/share/%{name}/postinst-rpm.sh
/opt/yaffas/share/yaffas-upgrade/02-yaffas-zarafa.sh
/opt/yaffas/share/yaffas-upgrade/03-yaffas-zarafa-notifications.sh
/opt/yaffas/share/yaffas-upgrade/04-zarafa-webapp-selinux.sh
/opt/yaffas/share/yaffas-upgrade/05-zarafa-local-admin-vmail.sh
/tmp/zarafa.te

%changelog
* Mon Mar 08 2011 Package Builder <packages@yaffas.org> 0.7.0-1
- initial release

