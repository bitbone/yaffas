Name:		yaffas-module-zarafaresources
Version:	1.0.0
Release:	1%{?dist}
Summary:	Module for managing zarafa resources
Group:		Applications/System
License:	AGPLv3
URL:		http://www.yaffas.org
Source0:	file://%{name}-%{version}.tar.gz
BuildArch:	noarch
BuildRoot:	%(mktemp -ud %{_tmppath}/%{name}-%{version}-%{release}-XXXXXX)
Requires:	yaffas-core, yaffas-module-users, yaffas-module-mailsrv, yaffas-install-lib
AutoReqProv: no

%description
Module for managing zarafa resources

%build
make %{?_smp_mflags}

%install
rm -rf $RPM_BUILD_ROOT
make install DESTDIR=$RPM_BUILD_ROOT

%clean
rm -rf $RPM_BUILD_ROOT

%post
source /opt/yaffas/lib/bbinstall-lib.sh
MODULE="zarafaresources"
add_webmin_acl $MODULE

%postun
if [ "$1" = "0" ]; then
	source /opt/yaffas/lib/bbinstall-lib.sh
	MODULE="zarafaresources"
	del_webmin_acl $MODULE
fi

%files
%defattr(-,root,root,-)
%doc debian/{changelog,copyright}
/opt/yaffas/webmin/zarafaresources
/opt/yaffas/lib/perl5/Yaffas/Module/ZarafaResources.pm

%changelog
