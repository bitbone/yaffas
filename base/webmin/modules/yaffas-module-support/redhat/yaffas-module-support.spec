Summary:	Support module for yaffas
Name:		yaffas-module-support
Version:	1.0.0
Release:	1
License:	AGPLv3
Url:		http://www.yaffas.org
Group:		Applications/System
Source: 	file://%{name}-%{version}.tar.gz
BuildArch:	noarch
BuildRoot:	%{_tmppath}/%{name}-%{version}-%{release}-buildroot
Requires:	yaffas-install-lib, yaffas-core, yaffas-module-saveconf, lshw, perl(Yaffas), perl(File::Copy), perl(File::Find), perl(File::Path), perl(File::Temp)
AutoReqProv: no

%description
Support module for yaffas.

%build
make %{?_smp_mflags}

%install
%{__rm} -rf $RPM_BUILD_ROOT
make install DESTDIR=$RPM_BUILD_ROOT

%clean
%{__rm} -rf $RPM_BUILD_ROOT

%post
set -e
source /opt/yaffas/lib/bbinstall-lib.sh
MODULE=support
add_webmin_acl $MODULE

%postun
set -e
source /opt/yaffas/lib/bbinstall-lib.sh
MODULE=support
del_webmin_acl $MODULE

%files
%defattr(-,root,root)
%doc debian/{copyright,changelog}
/opt/yaffas/webmin/support

%changelog
