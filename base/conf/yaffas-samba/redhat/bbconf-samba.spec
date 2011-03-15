Summary:	bitkit samba configuration
Name:		yaffas-samba
Version:	1.0.0
Release:	1
License:	AGPLv3
Url:		http://www.yaffas.org
Group:		Applications/System
Source: 	file://%{name}-%{version}.tar.gz
BuildArch:	noarch
BuildRoot:	%{_tmppath}/%{name}-%{version}-%{release}-buildroot
Requires:	samba

%description
Samba configuration for bitkit.

%build
make %{?_smp_mflags}

%install
%{__rm} -rf $RPM_BUILD_ROOT
make install DESTDIR=$RPM_BUILD_ROOT
%{__install} -m 0644 conf/smb.conf.redhat $RPM_BUILD_ROOT/etc/samba/smb.conf.bitkit

%clean
%{__rm} -rf $RPM_BUILD_ROOT

%post
# generate global conf for samba if there is none
#SMBG="/etc/samba/smbopts.global"
#if [ ! -f "$SMBG" ]; then
#	echo "[global]" > $SMBG
#	echo "enable privileges = yes" >> $SMBG
#else
#	if ! grep -i -q '[global]' $SMBG; then
#		# missing section identifier can cause trouble
#		# so add one
#		TMP="/tmp/smbopts.global.tmp"
#		cat $SMBG > $TMP
#		echo "[global]" > $SMBG
#		cat $TMP >> $SMBG
#		rm -f $TMP
#	fi
#fi

# add includes.smb
#SMBINC="/etc/samba/includes.smb"
#if [ ! -f $SMBINC ]; then
#	echo "include = $SMBG" >> $SMBINC
#else
#	if ! grep -q $SMBG $SMBINC; then
#		TMP="/tmp/includes.smb.tmp"
#		cat $SMBINC > $TMP
#		echo "include = $SMBG" > $SMBINC
#		cat $TMP >> $SMBINC
#		rm -f $TMP
#	fi
#fi

touch /etc/printcap

rm -f /tmp/root.ldif

%files
%defattr(-,root,root)
%doc debian/{copyright,changelog}
%config /etc/samba/smb.conf.bitkit
/etc/samba
/tmp/root.ldif

%changelog
