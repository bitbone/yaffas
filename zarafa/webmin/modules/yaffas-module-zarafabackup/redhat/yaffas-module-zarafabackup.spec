Name:		yaffas-module-zarafabackup
Version:	1.0.0
Release:	1%{?dist}
Summary:	Module for zarafa-backup
Group:		Applications/System
License:	AGPLv3
URL:		http://www.yaffas.org
Source0:	file://%{name}-%{version}.tar.gz
BuildArch:	noarch
BuildRoot:	%(mktemp -ud %{_tmppath}/%{name}-%{version}-%{release}-XXXXXX)
Requires:	yaffas-core, yaffas-install-lib, mysql-server, zarafa
AutoReqProv: no

%description
Module for zarafa-backup

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
/opt/yaffas/lib/perl5/Yaffas/Module/ZarafaBackup
/opt/yaffas/lib/perl5/Yaffas/Module/ZarafaBackup.pm
/opt/yaffas/webmin/zarafabackup

%post
source /opt/yaffas/lib/bbinstall-lib.sh
MODULE="zarafabackup"
add_webmin_acl $MODULE

%postun
if [ "$1" = "0" ]; then
	source /opt/yaffas/lib/bbinstall-lib.sh
	MODULE="zarafabackup"
	del_webmin_acl $MODULE
fi

%changelog
