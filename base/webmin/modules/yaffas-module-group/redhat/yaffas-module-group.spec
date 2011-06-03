Summary:	Group administration for Webmin
Name:		yaffas-module-group
Version: 1.1.36
Release: 1
License: Commercial
Group: Applications/System
Url: http://www.yaffas.org
Source: file://%{name}-%{version}.tar.gz
BuildArch: noarch
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-buildroot
Requires: yaffas-install-lib, perl, yaffas-core, yaffas-module-authsrv
AutoReqProv: no

%description
Groupadministration for Webmin.

%build
make %{?_smp_mflags}

%install
rm -rf $RPM_BUILD_ROOT
make install DESTDIR=$RPM_BUILD_ROOT

%post
set -e
source /opt/yaffas/lib/bbinstall-lib.sh
MODULE="group"
add_webmin_acl $MODULE

%clean
%{__rm} -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root)
%doc debian/{copyright,changelog}
/opt/yaffas/webmin/group
/opt/yaffas/lib/perl5/Yaffas/Module/Group.pm

%changelog
