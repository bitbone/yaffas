Summary:	The bbauthsrv webmin module
Name:		yaffas-module-authsrv
Version:	1.0.0
Release:	1
License: 	AGPLv3
Group:		Applications/System
Url:		http://www.yaffas.org
Source:		file://%{name}-%{version}.tar.gz
BuildArch:	noarch
BuildRoot:	%{_tmppath}/%{name}-%{version}-%{release}-buildroot
Requires:	yaffas-install-lib, perl, yaffas-core, samba-common, ntp, openldap-clients, smbldap-tools, authconfig
AutoReqProv: no

%description
This module allows you to manage user authentication.

%build
make %{?_smp_mflags}

%install
%{__rm} -rf $RPM_BUILD_ROOT
make install DESTDIR=$RPM_BUILD_ROOT

%post
set -e
source /opt/yaffas/lib/bbinstall-lib.sh
MODULE="authsrv"
add_webmin_acl $MODULE

%postun
if [ "$1" = "0" ]; then
	set -e
	source /opt/yaffas/lib/bbinstall-lib.sh
	MODULE="authsrv"
	del_webmin_acl $MODULE
fi

%clean
%{__rm} -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root)
%doc debian/{copyright,changelog}
/opt/yaffas/webmin/authsrv
/opt/yaffas/lib/perl5/Yaffas/Module/AuthSrv.pm

%changelog
