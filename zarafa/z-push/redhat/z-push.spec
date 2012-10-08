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


%files
%defattr(-,root,root,-)
%doc debian/{changelog,copyright}
/usr/share/z-push
/opt/yaffas/share/%{name}/postinst.sh

%changelog
* Mon Mar 08 2011 Package Builder <packages@yaffas.org> 1.4.5-1
- initial release

