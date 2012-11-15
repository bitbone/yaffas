Name:		yaffas-software
Version:	1.0
Release:	beta3%{?dist}
Summary:	Includes software into the samba share
Group:		Application/System
License:	AGPL
URL:		http://www.yaffas.org
Source0:	file://%{name}-%{version}.tar.gz
BuildRoot:	%(mktemp -ud %{_tmppath}/%{name}-%{version}-%{release}-XXXXXX)
BuildArch:	noarch
Requires:	yaffas-samba

%description
Includes software into the samba share

%build
make %{?_smp_mflags}

%install
rm -rf $RPM_BUILD_ROOT
make install DESTDIR=$RPM_BUILD_ROOT

%clean
rm -rf $RPM_BUILD_ROOT

%post

%postun
INCLUDES="/etc/samba/includes.smb"
if [ -e $INCLUDES ]; then
	if ( grep -q "smbopts.software" $INCLUDES ); then
		sed '/smbopts.software/d' -i $INCLUDES
	fi
fi

%files
%defattr(-,root,root,-)
%doc debian/{copyright,changelog}
/opt/software/zarafaclient-en.msi
/opt/software/zarafaclient-7.1.1-38327.msi
/opt/software/zarafamigrationtool.exe
/opt/yaffas/share/%{name}/postinst-deb.sh
/opt/yaffas/share/%{name}/postinst-rpm.sh

%changelog
