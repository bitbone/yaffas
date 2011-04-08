Name:		z-push
Version: 1.4.5
Release: 1
Summary:	Open-source push technology
Group:		Applications/System
License:	GPL
Source0:	file://%{name}-%{version}.tar.gz
BuildRoot:	%(mktemp -ud %{_tmppath}/%{name}-%{version}-%{release}-XXXXXX)
BuildArch:	noarch
Requires:	php, php-pear

%description
Z-push is an implementation of the ActiveSync protocol, which is used 'over-the-air' for
multi platform ActiveSync devices, including Windows Mobile, Ericsson and Nokia phones.
With Z-push any groupware can be connected and synced with these devices.

%build
make %{?_smp_mflags}

%install
rm -rf $RPM_BUILD_ROOT
make install DESTDIR=$RPM_BUILD_ROOT

%clean
rm -rf $RPM_BUILD_ROOT

%post
mkdir -p /var/www/z-push/state
chown apache:apache /var/www/z-push/state

HTTPD_CONF=/etc/httpd/conf/httpd.conf
if ( ! grep -q "^Alias /Microsoft-Server-ActiveSync" $HTTPD_CONF ); then
	echo -e "\nAlias /Microsoft-Server-ActiveSync /var/www/z-push/index.php" >> $HTTPD_CONF
fi

%files
%defattr(-,root,root,-)
%doc debian/{changelog,copyright}
/var/www/z-push

%changelog
* Mon Mar 08 2011 Package Builder <packages@yaffas.org> 1.4.5-1
- initial release

