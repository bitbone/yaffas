Name:		yaffas
Version:	1.0.1
Release:	1%{?dist}
Summary:	Meta package for yaffas
Group:		Applications/System
License:	GPL
URL:		http://www.yaffas.org
Source0:	file://%{name}-%{version}.tar.gz
BuildArch: noarch
BuildRoot:	%(mktemp -ud %{_tmppath}/%{name}-%{version}-%{release}-XXXXXX)
Requires:	yaffas-core, yaffas-theme, yaffas-yui, yaffas-module-about, yaffas-module-changelang, yaffas-module-systeminfo, yaffas-module-changepw, yaffas-module-logfiles, yaffas-module-snmpconf, yaffas-module-authsrv, yaffas-module-support, yaffas-module-users, yaffas-module-certificate, yaffas-module-fetchmail, yaffas-module-notify, yaffas-module-mailalias, yaffas-module-mailq, yaffas-module-service, yaffas-module-bulkmail, yaffas-module-group, yaffas-module-saveconf, yaffas-module-netconf, yaffas-module-mailsrv

%description
This package is a meta package for all the yaffas modules. Install it to pull
all required packages into your system.

%build

%install
rm -rf $RPM_BUILD_ROOT

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root,-)
%doc debian/{copyright,changelog}

%changelog
