Summary:	certificate manager
Name:		yaffas-module-certificate
Version:	1.0.0
Release:	1
License:	AGPLv3
Url:		http://www.yaffas.org
Group:		Applications/System
Source:		file://%{name}-%{version}.tar.gz
BuildArch:	noarch
BuildRoot:	%{_tmppath}/%{name}-%{version}-%{release}-buildroot
Provides:	perl(Yaffas::Module::Certificate)
Requires:	yaffas-install-lib, yaffas-core, openssl, perl, perl(Yaffas), perl(CGI::Carp), perl(Error), perl(Exporter), perl(File::Copy), perl(Time::Local)
AutoReqProv: no

%description
Module for managing openssl certificates

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
MODULE=certificate
add_webmin_acl $MODULE

%postun
if [ "$1" = "0" ]; then
	set -e
	source /opt/yaffas/lib/bbinstall-lib.sh
	MODULE=certificate
	del_webmin_acl $MODULE
fi

%files
%defattr(-,root,root)
%doc debian/{copyright,changelog}
/opt/yaffas/webmin/certificate
/opt/yaffas/lib/perl5/Yaffas/Module/Certificate.pm

%changelog
