Summary:	service module for webmin
Name:		yaffas-module-service
Version:	1.0.0
Release:	1
License:	AGPLv3
Url:		http://www.yaffas.org
Group:		Applications/System
Source:		file://%{name}-%{version}.tar.gz
BuildArch:	noarch
BuildRoot:	%{_tmppath}/%{name}-%{version}-%{release}-buildroot
Provides:	perl(Yaffas::Module::Service)
Requires:	yaffas-install-lib, yaffas-core, perl(Yaffas)
AutoReqProv: no

%description
This module allows the admin to control the installed services.

%build
make %{?_smp_mflags}

%install
%{__rm} -rf $RPM_BUILD_ROOT
make install DESTDIR=$RPM_BUILD_ROOT

%clean
%{__rm} -rf $RPM_BUILD_ROOT

%post
source /opt/yaffas/lib/bbinstall-lib.sh
MODULE="service"
add_webmin_acl $MODULE

%postun
if [ "$1" = "0" ]; then
	source /opt/yaffas/lib/bbinstall-lib.sh
	MODULE="service"
	del_webmin_acl $MODULE
fi

%files
%defattr(-,root,root)
%doc debian/{copyright,changelog}
/opt/yaffas/webmin/service
/opt/yaffas/lib/perl5/Yaffas/Module/Service.pm
/opt/yaffas/lib/perl5/Yaffas/Module/Time.pm

%changelog
