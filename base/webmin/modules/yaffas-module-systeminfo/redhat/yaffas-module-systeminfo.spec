Summary:	Yaffas webmin module for systeminfo
Name:		yaffas-module-systeminfo
Version:	1.0.0
Release:	1
License:	AGPLv3
Group:		Applications/System
Url:		http://www.yaffas.org
Source:		file://%{name}-%{version}.tar.gz
BuildArch:	noarch
BuildRoot:	%{_tmppath}/%{name}-%{version}-%{release}-buildroot
Requires:	yaffas-install-lib, perl, yaffas-core
AutoReqProv: no

%description
Module for yaffas webmin.
Shows memory, cpu, filesystem, irqs, io ports, ...

%build
make %{?_smp_mflags}

%install
%{__rm} -rf $RPM_BUILD_ROOT
make install DESTDIR=$RPM_BUILD_ROOT

%post
set -e
source /opt/yaffas/lib/bbinstall-lib.sh
MODULE="systeminfo"
add_webmin_acl $MODULE

if ! grep -q $MODULE /opt/yaffas/etc/webmin/hidden_modules; then
    echo $MODULE >> /opt/yaffas/etc/webmin/hidden_modules
fi


%clean
%{__rm} -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root)
%doc debian/{copyright,changelog}
/opt/yaffas/webmin/systeminfo

%changelog
