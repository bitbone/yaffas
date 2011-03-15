Name:		yaffas-yui
Version:	1.0.0
Release:	1%{?dist}
Summary:	YUI Library for theme
Group:		Application/System
License:	AGPLv3
Source0:	file://%{name}-%{version}.tar.gz
BuildArch:	noarch
BuildRoot:	%(mktemp -ud %{_tmppath}/%{name}-%{version}-%{release}-XXXXXX)
Requires:	yaffas-core

%description
YUI Library for theme

%build
make %{?_smp_mflags}

%install
rm -rf $RPM_BUILD_ROOT
make install DESTDIR=$RPM_BUILD_ROOT

%clean
rm -rf $RPM_BUILD_ROOT

%files
/opt/yaffas/webmin/yui
%defattr(-,root,root,-)
%doc debian/{changelog,copyright}

%changelog
