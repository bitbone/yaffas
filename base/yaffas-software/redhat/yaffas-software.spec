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
# remove older zarafa clients such as zarafaclient-7.1.9-44333.msi
rm -f $(readlink /opt/software/zarafa/zarafaclient.msi | grep -vF zarafaclient-7.1.9-44333.msi)

# create a new symlink to the latest version
ln -sf /opt/software/zarafa/zarafaclient-7.1.9-44333.msi /opt/software/zarafa/zarafaclient.msi

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
/opt/software/zarafa/zarafaclient-en.msi
/opt/software/zarafa/zarafaclient-7.1.9-44333.msi
/opt/software/zarafa/zarafamigrationtool.exe
/opt/yaffas/share/%{name}/postinst-deb.sh
/opt/yaffas/share/%{name}/postinst-rpm.sh

%changelog
