Summary:	yaffas samba configuration
Name:		yaffas-samba
Version: 0.9.0
Release: 1
License:	AGPLv3
Url:		http://www.yaffas.org
Group:		Applications/System
Source: 	file://%{name}-%{version}.tar.gz
BuildArch:	noarch
BuildRoot:	%{_tmppath}/%{name}-%{version}-%{release}-buildroot
%{?el5:Requires: samba, yaffas-ldap, yaffas-core}
%{?el6:Requires: samba, samba-winbind, yaffas-ldap, yaffas-core}

%description
Samba configuration for yaffas.

%build
make %{?_smp_mflags}

%install
%{__rm} -rf $RPM_BUILD_ROOT
make install DESTDIR=$RPM_BUILD_ROOT

%clean
%{__rm} -rf $RPM_BUILD_ROOT

%post

%postun
if [ $1 -eq 0 ]; then
	%{__mv} -f /etc/samba/smb.conf.yaffassave /etc/samba/smb.conf
	%{__rm} -f /etc/samba/smbopts.software
	%{__rm} -f /etc/samba/includes.smb
	%{__rm} -f /etc/samba/smbopts.global
fi

%files
%defattr(-,root,root)
%doc debian/{copyright,changelog}
%config /opt/yaffas/share/doc/example/etc/samba/smb.conf
%config /opt/yaffas/share/doc/example/etc/samba/smbopts.software
/opt/yaffas/share/doc/example/tmp/root.ldif
/opt/yaffas/share/%{name}/postinst-deb.sh
/opt/yaffas/share/%{name}/postinst-rpm.sh

%changelog
* Mon Mar 08 2011 Package Builder <packages@yaffas.org> 0.7.0-1
- initial release

