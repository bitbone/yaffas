Name:		yaffas-module-zarafalicence
Version:	1.0.0
Release:	1%{?dist}
Summary:	Module for installing a zarafa licence key
Group:		Applications/System
License:	AGPLv3
URL:		http://www.yaffas.org
Source0:	file://%{name}-%{version}.tar.gz
BuildArch:	noarch
BuildRoot:	%(mktemp -ud %{_tmppath}/%{name}-%{version}-%{release}-XXXXXX)
Requires:	yaffas-core, yaffas-install-lib
AutoReqProv: no

%description
Module for installing a zarafa licence key

%build
make %{?_smp_mflags}

%install
rm -rf $RPM_BUILD_ROOT
make install DESTDIR=$RPM_BUILD_ROOT

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root,-)
%doc debian/{changelog,copyright}
/opt/yaffas/webmin/zarafalicence
/opt/yaffas/lib/perl5/Yaffas/Module/ZarafaLicence.pm

%changelog
