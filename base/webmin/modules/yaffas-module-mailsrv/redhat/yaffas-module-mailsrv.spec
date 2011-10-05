Summary:	Basic mailserver configuration
Name:		yaffas-module-mailsrv
Version:	1.0.0
Release:	1
License:	AGPLv3
Group:		Applications/System
Url:		http://www.yaffas.org
Source:		file://%{name}-%{version}.tar.gz
BuildArch:	noarch
BuildRoot:	%{_tmppath}/%{name}-%{version}-%{release}-buildroot
Requires:	yaffas-install-lib, perl, yaffas-core, postfix
AutoReqProv: no

%description
Basic mailserver configuration.

%build
make %{?_smp_mflags}

%install
%{__rm} -rf $RPM_BUILD_ROOT
make install DESTDIR=$RPM_BUILD_ROOT

%post
set -e
source /opt/yaffas/lib/bbinstall-lib.sh
MODULE="mailsrv"
add_webmin_acl $MODULE

%postun
if [ "$1" = "0" ]; then
	set -e
	source /opt/yaffas/lib/bbinstall-lib.sh
	MODULE="mailsrv"
	del_webmin_acl $MODULE
fi

%clean
%{__rm} -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root)
%doc debian/{copyright,changelog}
/opt/yaffas/lib/perl5/Yaffas/Module/Mailsrv
/opt/yaffas/lib/perl5/Yaffas/Module/Mailsrv.pm
/opt/yaffas/lib/perl5/Yaffas/Module/Secconfig.pm
/opt/yaffas/bin/zarafa-public-folders
/opt/yaffas/webmin/mailsrv

%changelog
