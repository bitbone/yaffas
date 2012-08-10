Name:		z-push
Version: 2.0.1
Release: 1
Summary:	Open-source push technology
Group:		Applications/System
License:	GPL
Source0:	file://%{name}-%{version}.tar.gz
BuildRoot:	%(mktemp -ud %{_tmppath}/%{name}-%{version}-%{release}-XXXXXX)
BuildArch:	noarch
%{?el5:Requires: php}
%{?el6:Requires: php, php-process}

%description
Z-Push is an implementation of the ActiveSync protocol which is used
'over-the-air' for multi platform ActiveSync devices, including Windows Mobile,
iPhone, Android, Sony Ericsson and Nokia mobile devices. With Z-Push any
groupware can be connected and synced with these devices.

%build
make %{?_smp_mflags}

%install
rm -rf $RPM_BUILD_ROOT
make install DESTDIR=$RPM_BUILD_ROOT

%clean
rm -rf $RPM_BUILD_ROOT

%post
mkdir -p /var/lib/z-push/
mkdir -p /var/log/z-push/

chown apache:apache /var/lib/z-push/ /var/log/z-push/
chcon -R -t httpd_sys_content_t /var/lib/z-push/ /var/log/z-push/

ln -sf /usr/share/z-push/z-push-admin.php /usr/bin/z-push-admin
ln -sf /usr/share/z-push/z-push-top.php /usr/bin/z-push-top

HTTPD_CONF=/etc/httpd/conf/httpd.conf
if ( ! grep -q "^Alias /Microsoft-Server-ActiveSync" $HTTPD_CONF ); then
	echo -e "\nAlias /Microsoft-Server-ActiveSync /usr/share/z-push/index.php" >> $HTTPD_CONF
fi

if grep -q "/var/www/z-push/index.php" $HTTPD_CONF; then
    sed -e "s#Alias /Microsoft-Server-ActiveSync.*#Alias /Microsoft-Server-ActiveSync /usr/share/z-push/index.php#" -i $HTTPD_CONF
fi

service httpd restart

%files
%defattr(-,root,root,-)
%doc debian/{changelog,copyright}
/usr/share/z-push

%changelog
* Mon Mar 08 2011 Package Builder <packages@yaffas.org> 1.4.5-1
- initial release

