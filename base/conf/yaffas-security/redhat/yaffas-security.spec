Name:		yaffas-security
Version:	0.9.0
Release:	1%{?dist}
Summary:	Config for yaffas security module
Group:		Application/System
License:	AGPL
URL:		http://www.yaffas.org
Source0:	file://%{name}-%{version}.tar.gz
BuildRoot:	%(mktemp -ud %{_tmppath}/%{name}-%{version}-%{release}-XXXXXX)
BuildArch:	noarch
Requires:	yaffas-ldap, yaffas-module-security

%description
Adds amavis user to ldapread group

%build
make %{?_smp_mflags}

%install
rm -rf $RPM_BUILD_ROOT
make install DESTDIR=$RPM_BUILD_ROOT

%post
set -e

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root,-)
%doc debian/{changelog,copyright}
/opt/yaffas/share/%{name}/postinst.sh

%changelog
