Summary:	Webmin module for the yaffas licence key
Name:		yaffas-module-licencekey
Version:	1.0.0
Release:	1
License:	AGPLv3
Url:		http://www.yaffas.org
Group:		Applications/System
Source:		file://%{name}-%{version}.tar.gz
BuildRoot:	%{_tmppath}/%{name}-%{version}-%{release}-buildroot
BuildArch:	noarch
Requires:	yaffas-install-lib, yaffas-core
AutoReqProv: no

%description
Webmin module for the yaffas licence key.

%build
make %{?_smp_mflags}

%install
%{__rm} -rf $RPM_BUILD_ROOT
make install DESTDIR=$RPM_BUILD_ROOT

%clean
%{__rm} -rf $RPM_BUILD_ROOT

%post
set -e
source /opt/yaffas/lib/bbinstall-lib.sh
MODULE="licencekey"
add_webmin_acl $MODULE

%postun

%files
%defattr(-,root,root)
%doc debian/{copyright,changelog}
/opt/yaffas/webmin/licencekey
/opt/yaffas/lib/perl5/Yaffas/Module/FaxLicense.pm
/opt/yaffas/lib/perl5/Yaffas/Module/License.pm

%changelog
