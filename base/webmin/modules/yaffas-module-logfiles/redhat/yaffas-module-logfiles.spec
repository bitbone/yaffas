Summary:	Webmin module for showing logfiles
Name:		yaffas-module-logfiles
Version:	1.0.0
Release:	1
License:	AGPLv3
Url:		http://www.yaffas.org
Group:		Applications/System
Source:		file://%{name}-%{version}.tar.gz
BuildArch:	noarch
BuildRoot:	%{_tmppath}/%{name}-%{version}-%{release}-buildroot
Provides:	perl(Yaffas::Module::Logfiles)
Requires:	yaffas-install-lib, yaffas-core, perl(Yaffas)
AutoReqProv: no

%description
Webmin module for showing logfiles

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
MODULE=logfiles
add_webmin_acl $MODULE

%postun
set -e
source /opt/yaffas/lib/bbinstall-lib.sh
MODULE=logfiles
del_webmin_acl $MODULE

%files
%defattr(-,root,root)
%doc debian/{copyright,changelog}
/opt/yaffas/webmin/logfiles
/opt/yaffas/lib/perl5/Yaffas/Module/Logfiles.pm

%changelog
