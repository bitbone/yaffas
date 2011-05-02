Name:		yaffas-config
Version:	0.7.0
Release:	1%{?dist}
Summary:	Meta-package for yaffas
Group:		Application/System
License:	AGPL
URL:		http://www.yaffas.org
Source0:	file://%{name}-%{version}.tar.gz
BuildRoot:	%(mktemp -ud %{_tmppath}/%{name}-%{version}-%{release}-XXXXXX)
BuildArch:	noarch
Requires:	yaffas-ldap, yaffas-postfix, yaffas-samba, yaffas-security

%description
Meta-package for yaffas

%build

%install
rm -rf $RPM_BUILD_ROOT

%clean
rm -rf $RPM_BUILD_ROOT

%post
mkdir -p /opt/yaffas/etc

CONF="/opt/yaffas/etc/installed-products"
KEY="framework"
VALUE='yaffas|BASE v0.1'

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
