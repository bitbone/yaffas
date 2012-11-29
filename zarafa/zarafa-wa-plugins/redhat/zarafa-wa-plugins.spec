Name:		zarafa-wa-plugins
Version: 1.0.0
Release: 1
Summary:	Open-source push technology
Group:		Applications/System
License:	GPL
Source0:	file://%{name}-%{version}.tar.gz
BuildRoot:	%(mktemp -ud %{_tmppath}/%{name}-%{version}-%{release}-XXXXXX)
BuildArch:	noarch
Requires:	zarafa-webaccess, yaffas-ldap

%description
Misc zarafa webaccess/webapp plugins

%build
make %{?_smp_mflags}

%install
rm -rf $RPM_BUILD_ROOT
make install DESTDIR=$RPM_BUILD_ROOT

%clean
rm -rf $RPM_BUILD_ROOT

%post
BASEDN=$(grep BASEDN /etc/ldap.settings | awk -F "BASEDN=" '{print $2}')
sed -e "s/dc=bitbone,dc=de/$BASEDN/" -i /opt/yaffas/zarafa/webaccess/plugins/passwd/config.inc.php
sed -e "s/dc=bitbone,dc=de/$BASEDN/" -i /opt/yaffas/zarafa/webapp/plugins/passwd/config.inc.php

%files
%defattr(-,root,root,-)
%doc debian/{changelog,copyright}
%config /opt/yaffas/zarafa/webaccess/plugins/passwd/config.inc.php
%config /opt/yaffas/zarafa/webapp/plugins/passwd/config.inc.php
/opt/yaffas/zarafa/webaccess/plugins
/opt/yaffas/zarafa/webapp/plugins
/opt/yaffas/share/yaffas-upgrade

%changelog
* Mon Mar 08 2011 Package Builder <packages@yaffas.org> 1.4.5-1
- initial release

