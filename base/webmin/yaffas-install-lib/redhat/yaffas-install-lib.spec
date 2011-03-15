Summary:	yaffas module postinstall shell functions
Name:		yaffas-install-lib
Version:	1.0.0
Release:	1
License:	AGPLv3
Group:		Applications/System
Source:		file://%{name}-%{version}.tar.gz
Patch:		webmin_path.patch
BuildArch:	noarch
BuildRoot:	%{_tmppath}/%{name}-%{version}-%{release}-buildroot
Requires:	yaffas-lib, yaffas-core

%description
Some basic often used functions which are used to install webmin modules

%build
make %{?_smp_mflags}

%install
%{__rm} -rf $RPM_BUILD_ROOT
make install DESTDIR=$RPM_BUILD_ROOT

%clean
%{__rm} -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root)
%doc debian/{copyright,changelog}
/opt/yaffas/lib/bbinstall-lib.sh

%changelog
