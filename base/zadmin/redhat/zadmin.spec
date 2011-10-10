Name:		zadmin
Version:	1.0.1
Release:	1%{?dist}
Summary:	Meta package for Z-Admin
Group:		Applications/System
License:	GPL
URL:		http://www.yaffas.org
Source0:	file://%{name}-%{version}.tar.gz
BuildArch: noarch
BuildRoot:	%(mktemp -ud %{_tmppath}/%{name}-%{version}-%{release}-XXXXXX)
Requires:	yaffas-core, zadmin-theme, yaffas-yui, yaffas-module-about, yaffas-module-changelang, yaffas-module-systeminfo, yaffas-module-changepw, yaffas-module-logfiles, yaffas-module-snmpconf, yaffas-module-authsrv, yaffas-module-support, yaffas-module-users, yaffas-module-certificate, yaffas-module-fetchmail, yaffas-module-notify, yaffas-module-mailalias, yaffas-module-mailq, yaffas-module-service, yaffas-module-bulkmail, yaffas-module-group, yaffas-module-saveconf, yaffas-module-netconf, yaffas-module-mailsrv, yaffas-module-security, yaffas-module-setup, yaffas-config, yaffas-zarafa, yaffas-certificates, yaffas-lang, yaffas-software

%description
This package is a meta package for all the zadmin modules. Install it to pull
all required packages into your system.

%build

%install
rm -rf $RPM_BUILD_ROOT

%clean
rm -rf $RPM_BUILD_ROOT

%post
CONF="/opt/yaffas/etc/installed-products"
KEY="framework"
VALUE='Z-Admin v1.0'

if [ -e $CONF ]; then
	if ! grep -iq ^$KEY $CONF; then
		echo "$KEY=$VALUE" >> $CONF
	else
		sed -e s/^$KEY=.*/"$KEY=$VALUE"/ -i $CONF
	fi
else
	echo "$KEY=$VALUE" >> $CONF
fi

%files
%defattr(-,root,root,-)
%doc debian/{copyright,changelog}

%changelog
