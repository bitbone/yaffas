Summary:	The users webmin module
Name:		yaffas-module-users
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
Module for manageing users of bitkit.

%build
make %{?_smp_mflags}

%install
%{__rm} -rf $RPM_BUILD_ROOT
make install DESTDIR=$RPM_BUILD_ROOT

%post
set -e
source /opt/yaffas/lib/bbinstall-lib.sh
MODULE="users"
add_webmin_acl $MODULE

%clean
%{__rm} -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root)
%doc debian/{copyright,changelog}
/opt/yaffas/webmin/users
/opt/yaffas/lib/perl5/Yaffas/Module/Users.pm

%changelog
