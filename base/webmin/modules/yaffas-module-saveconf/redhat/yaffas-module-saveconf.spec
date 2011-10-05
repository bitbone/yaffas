Summary:	The saveconf webmin module
Name:		yaffas-module-saveconf
Version:	1.0.0
Release:	1
License:	AGPLv3
Group:		Applications/System
Url:		http://www.yaffas.org
Source:		file://%{name}-%{version}.tar.gz
BuildArch:	noarch
BuildRoot:	%{_tmppath}/%{name}-%{version}-%{release}-buildroot
Requires:	yaffas-install-lib, perl, yaffas-core, yaffas-module-authsrv, yaffas-lib, perl-MIME-Lite
AutoReqProv: no

%description
Backup for conffiles and ldap-database of yaffas

%build
make %{?_smp_mflags}

%install
%{__rm} -rf $RPM_BUILD_ROOT
make install DESTDIR=$RPM_BUILD_ROOT

%post
set -e
source /opt/yaffas/lib/bbinstall-lib.sh
MODULE="saveconf"
add_webmin_acl $MODULE

%postun
if [ "$1" = "0" ]; then
	set -e
	source /opt/yaffas/lib/bbinstall-lib.sh
	MODULE="saveconf"
	del_webmin_acl $MODULE
fi

%clean
%{__rm} -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root)
%doc debian/{copyright,changelog}
/opt/yaffas/webmin/saveconf
/opt/yaffas/lib/perl5/Yaffas/Module/Backup.pm

%changelog
