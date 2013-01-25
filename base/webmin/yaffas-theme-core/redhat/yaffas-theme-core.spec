Summary:	Yaffas theme core
Name:		yaffas-theme-core
Version:	1.0.0
Release:	1
License:	AGPLv3
Url: 		http://www.yaffas.org
Group:		Applications/System
Source: 	file://%{name}-%{version}.tar.gz
BuildArch:	noarch
BuildRoot:	%{_tmppath}/%{name}-%{version}-%{release}-buildroot
Requires:	yaffas-core, yaffas-yui, perl(JSON)
AutoReqProv: no

%description
This the core for all yaffas themes

%build
make %{?_smp_mflags}

%install
%{__rm} -rf $RPM_BUILD_ROOT
make install DESTDIR=$RPM_BUILD_ROOT

%clean
%{__rm} -rf $RPM_BUILD_ROOT

%files
/opt/yaffas/webmin/theme-core
%defattr(-,root,root)
%doc debian/{copyright,changelog}

%changelog
