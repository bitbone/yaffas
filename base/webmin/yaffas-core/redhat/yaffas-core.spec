Summary:	The yaffas core
Name:		yaffas-core
Version: 	1.0.0
Release:	3
License:	BSD
Group:		Applications/System
Source: 	file://%{name}-%{version}.tar.gz
Patch0:		multipart.patch
Patch1:		session.patch
Patch2:		bitkit.patch
Patch3:		login.patch
BuildArch:	noarch
BuildRoot: 	%{_tmppath}/%{name}-%{version}-%{release}-buildroot
Requires:	perl, perl-Net-SSLeay
AutoReqProv: no

%description
The core package for yaffas webmin.

%build
# fix perl path
%{__patch} -p1 < redhat/$(basename %PATCH0)
%{__patch} -p1 < redhat/$(basename %PATCH1)
%{__patch} -p1 < redhat/$(basename %PATCH2)
%{__patch} -p1 < redhat/$(basename %PATCH3)

%install

make install DESTDIR=$RPM_BUILD_ROOT

cd $RPM_BUILD_ROOT
for file in `find opt/yaffas/webmin`; do
	if grep -q "/usr/local/bin/perl" $file; then
		%{__sed} -e 's#/usr/local/bin/perl#/usr/bin/perl#g' -i $file
	fi
done

%clean
%{__rm} -rf $RPM_BUILD_ROOT

%{__patch} -R -p1 < redhat/$(basename %PATCH3)
%{__patch} -R -p1 < redhat/$(basename %PATCH2)
%{__patch} -R -p1 < redhat/$(basename %PATCH1)
%{__patch} -R -p1 < redhat/$(basename %PATCH0)

%post
# generate password file for admin login if none exists
if [ ! -f /opt/yaffas/etc/webmin/miniserv.users ]; then
	echo "admin:129TZgbE1H546:0" > /opt/yaffas/etc/webmin/miniserv.users
fi

# generate acl file for webmin if no one exists
if [ ! -f /opt/yaffas/etc/webmin/webmin.acl ]; then
	echo "admin: " > /opt/yaffas/etc/webmin/webmin.acl
fi

# correct permissions
%{__chmod} 600 /opt/yaffas/etc/webmin/miniserv.*

# set selinux context
#/usr/bin/chcon -u system_u -r object_r -t initrc_exec_t %{_initrddir}/yaffas

if [ ! -e /etc/init.d/yaffas ]; then
	ln -s /opt/yaffas/etc/init.d/yaffas /etc/init.d/yaffas
fi

/sbin/chkconfig --add yaffas
chkconfig --level 35 yaffas on
/sbin/service yaffas start &>/dev/null || :

%preun
if [ $1 -eq 0 ]; then
	/sbin/service yaffas stop &>/dev/null || :
	/sbin/chkconfig --del yaffas
fi
%{__rm} -f /opt/yaffas/etc/webmin/miniserv.users
%{__rm} -f /opt/yaffas/etc/webmin/webmin.acl

%postun
#/sbin/service yaffas condrestart &>/dev/null || :


%files -f redhat/rpm.filelist
%defattr(-,root,root)
%doc debian/{copyright,changelog}

#%{_localstatedir}/yaffas
/opt/yaffas/etc/webmin
/opt/yaffas/webmin/Webmin
/opt/yaffas/webmin/proc
/opt/yaffas/webmin/acl
%config(noreplace) /opt/yaffas/webmin/lang/*
/opt/yaffas/webmin/images
%config /opt/yaffas/etc/init.d/yaffas

%changelog
