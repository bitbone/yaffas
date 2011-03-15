Summary:	Shows informations about installed yaffas versions
Name:		yaffas-module-about
Version:	1.0.0
Release:	1
License:	AGPLv3
Url:		http://www.yaffas.org
Group:		Applications/System
Source:		file://%{name}-%{version}.tar.gz
BuildArch:	noarch
BuildRoot:	%{_tmppath}/%{name}-%{version}-%{release}-buildroot
Requires:	yaffas-install-lib, yaffas-core
AutoReqProv: no

%description
Shows information about installed yaffas versions.

%build
make %{?_smp_mflags}

%install
rm -rf $RPM_BUILD_ROOT
make install DESTDIR=$RPM_BUILD_ROOT

%clean
%{__rm} -rf $RPM_BUILD_ROOT

%post
set -e
source /opt/yaffas/lib/bbinstall-lib.sh
MODULE="about"
add_webmin_acl $MODULE

if ! grep -q $MODULE /opt/yaffas/etc/webmin/hidden_modules; then
    echo $MODULE >> /opt/yaffas/etc/webmin/hidden_modules
fi

%postun

%files
%defattr(-,root,root)
%doc debian/{copyright,changelog}
/opt/yaffas/webmin/about
/opt/yaffas/lib/perl5/Yaffas/Module/About.pm

%changelog
