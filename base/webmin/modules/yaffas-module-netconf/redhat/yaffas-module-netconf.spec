Summary:	Basic network configuration for yaffas
Name:		yaffas-module-netconf
Version:	1.0.0
Release:	1
License:	AGPLv3
Url:		http://www.yaffas.org
Group:		Applications/System
Source:		file://%{name}-%{version}.tar.gz
BuildArch:	noarch
BuildRoot:	%{_tmppath}/%{name}-%{version}-buildroot
Requires:	yaffas-install-lib, yaffas-core, perl-IO-Interface, bridge-utils
AutoReqProv: no

%description
Basic network configuration for yaffas.

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
MODULE="netconf"
add_webmin_acl $MODULE

%postun
if [ "$1" = "0" ]; then
	set -e
	source /opt/yaffas/lib/bbinstall-lib.sh
	MODULE="netconf"
	del_webmin_acl $MODULE
fi

%files
%defattr(-,root,root)
%doc debian/{copyright,changelog}
/opt/yaffas/webmin/netconf
/opt/yaffas/lib/perl5/Yaffas/Module/Netconf.pm
/opt/yaffas/lib/perl5/Yaffas/Module/Proxy.pm

%changelog
