Name:		yaffas
Version:	0.9
Release:	1%{?dist}
Summary:	Meta package for yaffas
Group:		Applications/System
License:	GPL
URL:		http://www.yaffas.org
Source0:	file://%{name}-%{version}.tar.gz
BuildArch: noarch
BuildRoot:	%(mktemp -ud %{_tmppath}/%{name}-%{version}-%{release}-XXXXXX)
Requires: yaffas-core, yaffas-theme, yaffas-yui, yaffas-lang, yaffas-module-about, yaffas-module-changelang, yaffas-module-systeminfo, yaffas-module-changepw, yaffas-module-logfiles, yaffas-module-snmpconf, yaffas-module-authsrv, yaffas-module-support, yaffas-module-users, yaffas-module-certificate, yaffas-module-fetchmail, yaffas-module-notify, yaffas-module-mailalias, yaffas-module-mailq, yaffas-module-service, yaffas-module-bulkmail, yaffas-module-group, yaffas-module-saveconf, yaffas-module-netconf, yaffas-module-mailsrv, yaffas-module-setup, yaffas-config, yaffas-zarafa, yaffas-module-security, yaffas-certificates, yaffas-software

%description
This package is a meta package for all the yaffas modules. Install it to pull
all required packages into your system.

%build

%install
make install DESTDIR=$RPM_BUILD_ROOT

%clean
rm -rf $RPM_BUILD_ROOT

%post
CONF="/opt/yaffas/etc/installed-products"
KEY="framework"
VALUE='yaffas v1.3.0'

if [ -e /opt/yaffas/share/doc/example/etc/git-revision ]; then
    VALUE=$VALUE-$(cat /opt/yaffas/share/doc/example/etc/git-revision | tr "-" " " | awk '{ print $3 }')
fi

if [ -e $CONF ]; then
	if ! grep -iq ^$KEY $CONF; then
		echo "$KEY=$VALUE" >> $CONF
	else
		sed -e s/^$KEY=.*/"$KEY=$VALUE"/ -i $CONF
	fi
else
	echo "$KEY=$VALUE" >> $CONF
fi

if [ $1 -gt 1 ] ; then
    # process all upgrade scripts
    /opt/yaffas/bin/yaffas-upgrade.sh
fi

%files
%defattr(-,root,root,-)
%doc debian/{copyright,changelog}
/opt/yaffas/share/doc/example/etc/git-revision

%changelog
