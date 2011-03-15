Name:		yaffas-module-bulkmail
Version:	1.0.0
Release:	1%{?dist}
Summary:	Module for sending mails to all users.
Group:		Application/System
License:	AGPLv3
URL:		http://www.yaffas.org
Source0:	file://%{name}-%{version}.tar.gz
BuildArch:	noarch
BuildRoot:	%(mktemp -ud %{_tmppath}/%{name}-%{version}-%{release}-XXXXXX)
Requires:	yaffas-install-lib, yaffas-core
AutoReqProv: no

%description
Module for sending mails to all users.

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
MODULE=bulkmail
add_webmin_acl $MODULE

%files
%defattr(-,root,root,-)
%doc debian/{changelog,copyright}
/opt/yaffas/webmin/bulkmail
/opt/yaffas/lib/perl5/Yaffas/Module/Bulkmail.pm

%changelog
