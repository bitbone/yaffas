Summary:	Initial setup of yaffas
Name:		yaffas-module-setup
Version:	1.0.0
Release:	1
License:	AGPLv3
Url:		http://www.yaffas.org
Group:		Applications/System
Source:		file://%{name}-%{version}.tar.gz
BuildArch:	noarch
BuildRoot:	%{_tmppath}/%{name}-%{version}-%{release}-buildroot
Requires:	yaffas-install-lib, yaffas-core
AutoReqProv: no

%description
Initial setup of yaffas

%build
make %{?_smp_mflags}

%install
rm -rf $RPM_BUILD_ROOT
make install DESTDIR=$RPM_BUILD_ROOT

%clean
%{__rm} -rf $RPM_BUILD_ROOT

%post

%postun

%files
%defattr(-,root,root)
%doc debian/{copyright,changelog}
/opt/yaffas/webmin/setup
/opt/yaffas/share/doc/example/appliance-setup.pl
/opt/yaffas/lib/perl5/Yaffas/Module/Setup.pm

%changelog
