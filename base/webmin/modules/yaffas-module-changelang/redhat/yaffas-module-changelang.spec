Summary:	Webmin module for changing the language
Name:		yaffas-module-changelang
Version:	1.0.0
Release:	1
License:	BSD
Group:		Applications/System
Source:		file://%{name}-%{version}.tar.gz
BuildArch:	noarch
BuildRoot:	%{_tmppath}/%{name}-%{version}-%{release}-buildroot
Requires:	yaffas-install-lib, yaffas, yaffas-lib
AutoReqProv: no

%description
Webmin module for changing the language of the yaffas interface.

%build
make %{?_smp_mflags}

%install
%{__rm} -rf $RPM_BUILD_ROOT
make install DESTDIR=$RPM_BUILD_ROOT

%clean
%{__rm} -rf $RPM_BUILD_ROOT

%post
source /opt/yaffas/lib/bbinstall-lib.sh
MODULE="changelang"
add_webmin_acl $MODULE

if ! grep -q $MODULE /opt/yaffas/etc/webmin/hidden_modules; then
    echo $MODULE >> /opt/yaffas/etc/webmin/hidden_modules
fi


%files
%defattr(-,root,root)
%doc debian/{copyright,changelog}
/opt/yaffas/webmin/changelang
/opt/yaffas/lib/perl5/Yaffas/Module/ChangeLang.pm

%changelog
