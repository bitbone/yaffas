Summary:	Z-Admin theme for yaffas
Name:		zadmin-theme
Version:	1.0.0
Release:	1
License:	AGPLv3
Url: 		http://www.yaffas.org
Group:		Applications/System
Source: 	file://%{name}-%{version}.tar.gz
BuildArch:	noarch
BuildRoot:	%{_tmppath}/%{name}-%{version}-%{release}-buildroot
Requires:	yaffas-core, perl(JSON)
AutoReqProv: no

%description
This is a theme for Webmin.

%build
make %{?_smp_mflags}

%install
%{__rm} -rf $RPM_BUILD_ROOT
make install DESTDIR=$RPM_BUILD_ROOT

%clean
%{__rm} -rf $RPM_BUILD_ROOT

%post
miniserv_file="miniserv.conf"
config_file="config"

config="/opt/yaffas/etc/webmin/$config_file"
miniserv="/opt/yaffas/etc/webmin/$miniserv_file"

if [ -f $config ]; then
	echo "Changing Webmin Config";
	%{__cp} $config $config.dpkg-old

	# Overall theme
	cat $config | grep "theme=" > /dev/null
	if [ $? -eq 0 ]; then
		cat $config | sed -e 's/theme=.*/theme=zadmintheme/g' > /tmp/$config_file
		%{__cp} /tmp/$config_file $config
		rm /tmp/$config_file
	else
		echo "theme=zadmintheme" >> $config
	fi

	# miniserv.conf
	cat $miniserv | grep "preroot=" > /dev/null
	if [ $? -eq 0 ]; then
		cat $miniserv | sed -e 's/preroot=.*/preroot=zadmintheme/g' > /tmp/$miniserv_file
		%{__cp} /tmp/$miniserv_file $miniserv
		rm /tmp/$miniserv_file
	else
		echo "preroot=zadmintheme" >> $miniserv
	fi

	echo "Restarting Webmin ..."
	service yaffas restart

	# Link for usermin
	if [ -d /opt/yaffas/usermin/ ] && [ ! -L /opt/yaffas/usermin/zadmintheme ]; then
		ln -fs /opt/yaffas/webmin/zadmintheme /opt/yaffas/usermin/
	fi

	# Images for usermin
	if [ -d /opt/yaffas/usermin/ ] && [ ! -L /opt/yaffas/usermin/images ]; then
		ln -fs /opt/yaffas/webmin/images /opt/yaffas/usermin/
	fi
else
	echo "Config file does not exists!"
fi

%postun
%{__rm} -f /opt/yaffas/usermin/images
%{__rm} -f /opt/yaffas/usermin/zadmintheme
%{__rm} -f /opt/yaffas/etc/webmin/config.dpkg-old

%files
/opt/yaffas/webmin/zadmintheme
/opt/yaffas/webmin/yui
%defattr(-,root,root)
%doc debian/{copyright,changelog}

%changelog
