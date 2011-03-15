Summary:	The snmpconf webmin module
Name:		yaffas-module-snmpconf
Version:	1.0.0
Release:	1
License:	AGPLv3
Group:		Applications/System
Url:		http://www.yaffas.org
Source:		file://%{name}-%{version}.tar.gz
BuildArch:	noarch
BuildRoot:	%{_tmppath}/%{name}-%{version}-%{release}-buildroot
Requires:	yaffas-install-lib, perl, yaffas-core, net-snmp
AutoReqProv: no

%description
Webmin module for configuring the snmp daemon.

%build
make %{?_smp_mflags}

%install
%{__rm} -rf $RPM_BUILD_ROOT
make install DESTDIR=$RPM_BUILD_ROOT

%post
set -e
source /opt/yaffas/lib/bbinstall-lib.sh
MODULE="snmpconf"
add_webmin_acl $MODULE

if cat /etc/snmp/snmpd.conf| grep com2sec | grep paranoid >/dev/null; then
	/sbin/chkconfig --del confd
fi


%clean
%{__rm} -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root)
%doc debian/{copyright,changelog}
/opt/yaffas/webmin/snmpconf/
/opt/yaffas/lib/perl5/Yaffas/Module/SNMPConf.pm

%changelog
