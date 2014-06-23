Name:		yaffas-postfix
Version:	0.7.0
Release:	1%{?dist}
Summary:	Configuration package for postfix
Group:		Application/System
License:	AGPL
URL:		http://www.yaffas.org
Source:		file://%{name}-%{version}.tar.gz
BuildArch:	noarch
BuildRoot:	%(mktemp -ud %{_tmppath}/%{name}-%{version}-%{release}-XXXXXX)
Requires:	postfix, cyrus-sasl, cyrus-sasl-plain

%description
Configuration package for postfix

%build
make %{?_smp_mflags}

%install
rm -rf $RPM_BUILD_ROOT
make install DESTDIR=$RPM_BUILD_ROOT

%clean
rm -rf $RPM_BUILD_ROOT

%post

%postun
if [ $1 -eq 0 ]; then
	%{__rm} -f /etc/postfix/dynamicmaps.cf
	%{__mv} -f /etc/postfix/main.cf.yaffassave /etc/postfix/main.cf
	%{__mv} -f /etc/postfix/master.cf.yaffassave /etc/postfix/master.cf
fi

%files
%defattr(-,root,root,-)
%doc debian/{changelog,copyright}
/opt/yaffas/share/doc/example/etc/postfix/dynamicmaps.cf
/opt/yaffas/share/doc/example/etc/postfix/main.cf
/opt/yaffas/share/doc/example/etc/postfix/master.cf
/opt/yaffas/share/doc/example/etc/postfix/master-redhat.cf
/opt/yaffas/share/doc/example/etc/postfix/virtual_users_global
/opt/yaffas/share/doc/example/etc/postfix/sasl/smtpd.conf
/opt/yaffas/share/%{name}/postinst-deb.sh
/opt/yaffas/share/%{name}/postinst-rpm.sh
/opt/yaffas/share/yaffas-upgrade/yaffas-postfix-1.4.0-postmaster.sh
/opt/yaffas/share/yaffas-upgrade/yaffas-postfix-1.4.0-deliver-to-public.sh
/opt/yaffas/share/yaffas-upgrade/yaffas-postfix-1.4.0-ldaps-fix.sh
/opt/yaffas/share/yaffas-upgrade/yaffas-postfix-1.4.1-whitelist-cidr.sh

%changelog
