Name:		yaffas-module-zarafaconf
Version:	1.0.0
Release:	1%{?dist}
Summary:	Module for basic zarafa configuration
Group:		Applications/System
License:	AGPLv3
URL:		http://www.yaffas.org
Source0:	file://%{name}-%{version}.tar.gz
BuildArch:	noarch
BuildRoot:	%(mktemp -ud %{_tmppath}/%{name}-%{version}-%{release}-XXXXXX)
Requires:	yaffas-core, yaffas-module-authsrv, yaffas-module-users, yaffas-install-lib, mysql-server, zarafa
AutoReqProv: no

%description
Module for basic zarafa configuration

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
/opt/yaffas/lib/perl5/Yaffas/Module/ZarafaConf.pm
/opt/yaffas/webmin/zarafaconf

%post
source /opt/yaffas/lib/bbinstall-lib.sh
MODULE="zarafaconf"
add_webmin_acl $MODULE

%postun
source /opt/yaffas/lib/bbinstall-lib.sh
MODULE="zarafaconf"
del_webmin_acl $MODULE

%changelog
