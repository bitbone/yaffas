Summary:	Webmin module for changing the passwords
Name:		yaffas-module-changepw
Version:	1.0.0
Release:	1
License:	AGPLv3
Group:		Applications/System
Source:		file://%{name}-%{version}.tar.gz
BuildArch:	noarch
BuildRoot:	%{_tmppath}/%{name}-%{version}-%{release}-buildroot
Requires:	yaffas-install-lib, yaffas-core, expect, yaffas-lib, perl
AutoReqProv: no

%description
Webmin module for changing the yaffas interface and root passwords.

%build
make %{?_smp_mflags}

%install
%{__rm} -rf $RPM_BUILD_ROOT
make install DESTDIR=$RPM_BUILD_ROOT

%clean
%{__rm} -rf $RPM_BUILD_ROOT

%post
source /opt/yaffas/lib/bbinstall-lib.sh
MODULE="changepw"
add_webmin_acl $MODULE

%postun
if [ "$1" = "0" ]; then
	source /opt/yaffas/lib/bbinstall-lib.sh
	MODULE="changepw"
	del_webmin_acl $MODULE
fi

%files
%defattr(-,root,root)
%doc debian/{copyright,changelog}
/opt/yaffas/webmin/changepw
/opt/yaffas/lib/perl5/Yaffas/Module/ChangePW.pm

%changelog
