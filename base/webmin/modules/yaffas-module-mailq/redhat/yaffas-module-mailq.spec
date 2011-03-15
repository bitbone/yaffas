Name:		yaffas-module-mailq
Version:	1.0.0
Release:	1%{?dist}
Summary:	Webmin module for mail queue administration
Group:		Applications/System
License:	AGPLv3
URL:		http://www.yaffas.org
Source0:	file://%{name}-%{vesion}.tar.gz
BuildArch:	noarch
BuildRoot:	%(mktemp -ud %{_tmppath}/%{name}-%{version}-%{release}-XXXXXX)
Requires:	yaffas-install-lib, yaffas-core
AutoReqProv: no

%description
Webmin module for mail queue administration

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
MODULE=mailq
add_webmin_acl $MODULE

%files
%defattr(-,root,root,-)
%doc
/opt/yaffas/bin/pfcat.sh
/opt/yaffas/webmin/mailq
/opt/yaffas/lib/perl5/Yaffas/Module/Mailq.pm


%changelog
