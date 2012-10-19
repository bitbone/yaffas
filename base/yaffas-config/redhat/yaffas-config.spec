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
Conflicts:  perl-XML-SAX-Base

%description
Meta-package for yaffas

%build
make %{?_smp_mflags}

%install
rm -rf $RPM_BUILD_ROOT
make install DESTDIR=$RPM_BUILD_ROOT

%clean
rm -rf $RPM_BUILD_ROOT

%post
mkdir -p /opt/yaffas/etc

# enable services
for SERV in httpd amavisd clamd spamassassin policyd-weight; do
	chkconfig $SERV on
	service $SERV start
done

%files
%defattr(-,root,root,-)
%doc debian/{copyright,changelog}
/opt/yaffas/bin/yaffas-upgrade.sh

%changelog
