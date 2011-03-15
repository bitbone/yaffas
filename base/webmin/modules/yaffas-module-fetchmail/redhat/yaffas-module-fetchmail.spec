Name:		yaffas-module-fetchmail
Version:	1.0.0
Release:	1%{?dist}
Summary:	Webmin fetchmail module
Group:		Applications/System
License:	AGPLv3
URL:		http://www.yaffas.org
Source0:	file://%{name}-%{version}.tar.gz
BuildArch:	noarch
BuildRoot:	%(mktemp -ud %{_tmppath}/%{name}-%{version}-%{release}-XXXXXX)
Requires:	yaffas-install-lib, fetchmail, yaffas-core, yaffas-lib
AutoReqProv: no

%description
Webmin fetchmail module

%build
make %{?_smp_mflags}

%install
rm -rf $RPM_BUILD_ROOT
make install DESTDIR=$RPM_BUILD_ROOT

%clean
rm -rf $RPM_BUILD_ROOT

%post
set -e
source /opt/yaffas/lib/bbinstall-lib.sh
MODULE=fetchmail
add_webmin_acl $MODULE

%files
%defattr(-,root,root,-)
%doc debian/{changelog,copyright}
/opt/yaffas/webmin/fetchmail
/opt/yaffas/etc/fetchmail/config

%changelog
