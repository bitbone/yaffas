Summary:    Module for configuration of mail security options
Name:       yaffas-module-security
Version:    0.9.1
Release:    1
License:    AGPLv3
Url:        http://www.yaffas.org
Group:      Applications/System
Source:     file://%{name}-%{version}.tar.gz
BuildArch:  noarch
BuildRoot:  %{_tmppath}/%{name}-%{version}-%{release}-buildroot
Requires:   yaffas-install-lib, yaffas-core, perl(Net::DNS), amavisd-new, clamav, clamd, spamassassin, policyd-weight
AutoReqProv: no

%description
Module for configuration of mail security options

%build
make %{?_smp_mflags}

%install
rm -rf $RPM_BUILD_ROOT
make install DESTDIR=$RPM_BUILD_ROOT

%clean
%{__rm} -rf $RPM_BUILD_ROOT

%post
set -e
source /opt/yaffas/lib/bbinstall-lib.sh
MODULE="security"
add_webmin_acl $MODULE

%postun
if [ $1 -eq 0 ]; then
	%{__mv} -f /etc/policyd-weight.conf.yaffassave /etc/policyd-weight.conf

	source /opt/yaffas/lib/bbinstall-lib.sh
	MODULE="security"
	del_webmin_acl $MODULE
fi

%files
%defattr(-,root,root)
%doc debian/{copyright,changelog}
/opt/yaffas/webmin/security
/opt/yaffas/lib/perl5/Yaffas/Module/Security.pm
/opt/yaffas/config/channels.cf
/opt/yaffas/config/channels.keys
/opt/yaffas/share/doc/example/etc/amavis/conf.d/60-yaffas
/opt/yaffas/share/doc/example/etc/amavis/conf.d/60-yaffas-debian
/opt/yaffas/share/doc/example/etc/policyd-weight.conf
/opt/yaffas/share/doc/example/etc/amavis-master.cf
/opt/yaffas/share/doc/example/etc/amavisd-redhat.conf
/opt/yaffas/share/%{name}/postinst-deb.sh
/opt/yaffas/share/%{name}/postinst-rpm.sh
/opt/yaffas/share/yaffas-upgrade/yaffas-module-security-1.3.0-update-amavis-60-yaffas.sh
/opt/yaffas/share/yaffas-upgrade/yaffas-module-security-1.3.2-5-update-policyd-rfc-ignorant.sh
/opt/yaffas/share/yaffas-upgrade/yaffas-module-security-1.5.0-5-update-policyd-ahbl.sh
%dir /opt/yaffas/config/postfix

%changelog

