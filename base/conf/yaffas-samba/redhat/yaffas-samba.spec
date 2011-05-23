Summary:	yaffas samba configuration
Name:		yaffas-samba
Version: 0.9.0
Release: 1
License:	AGPLv3
Url:		http://www.yaffas.org
Group:		Applications/System
Source: 	file://%{name}-%{version}.tar.gz
BuildArch:	noarch
BuildRoot:	%{_tmppath}/%{name}-%{version}-%{release}-buildroot
Requires:	samba, yaffas-ldap, yaffas-core

%description
Samba configuration for yaffas.

%build
make %{?_smp_mflags}

%install
%{__rm} -rf $RPM_BUILD_ROOT
make install DESTDIR=$RPM_BUILD_ROOT

%clean
%{__rm} -rf $RPM_BUILD_ROOT

%post
set -e

# preserve config files and copy our config
# to default location
YAFFAS_EXAMPLE="/opt/yaffas/share/doc/example"
%{__mv} -f /etc/samba/smb.conf /etc/samba/smb.conf.yaffassave
%{__cp} -f -a ${YAFFAS_EXAMPLE}/etc/samba/smb.conf /etc/samba
%{__cp} -f -a ${YAFFAS_EXAMPLE}/etc/samba/smbopts.software /etc/samba

mkdir -p /etc/samba/smbprinters/
mkdir -p /etc/samba/printer/{W32ALPHA,W32MIPS,W32PPC,W32X86,WIN40}

touch /etc/printcap

chmod -R 777 /etc/samba/printer/

# correct dn in smb.conf
SMBCBB="/etc/samba/smb.conf"
ARRAY=(`hostname -d | cut -d. -f1- --output-delimiter=\ `)
COUNT=${#ARRAY[*]}
BASE=""
ORG=""
for i in `seq 1 $COUNT`
do
	if [ $i -eq $COUNT ]; then
		BASE="${BASE}c=${ARRAY[$(($i-1))]}"
	elif [ $i -eq $(($COUNT-1)) ]; then
		BASE="${BASE}o=${ARRAY[$(($i-1))]},"
		ORG=${ARRAY[$(($i-1))]}
	else
		BASE="${BASE}ou=${ARRAY[$(($i-1))]},"
	fi
done
sed -e "s/-thedn-/$BASE/" -i $SMBCBB

# generate global conf for samba if no one is here
SMBG="/etc/samba/smbopts.global"
if [ ! -f "$SMBG" ]; then
	echo "[global]" > $SMBG
	echo "workgroup = workgroup" >> $SMBG
	echo "enable privileges = yes" >> $SMBG
	echo "passdb backend = ldapsam:ldap://localhost" >> $SMBG
	echo "security = user" >> $SMBG
else
	# don't change anything if PDC authentication
	if ! grep -q 'security = ADS' $SMBG; then
		if ! grep -q 'passdb backend' $SMBG; then
			echo "    passdb backend = ldapsam:ldap://localhost" >> $SMBG
		fi
		if ! grep -q 'security' $SMBG; then
			echo "    security = user" >> $SMBG
		fi
	fi
	if ! grep -i -q '[global]' $SMBG; then
		# missing section identifier can cause trouble
		# so add one
		TMP="/tmp/smbopts.global.tmp"
		cat $SMBG > $TMP
		echo "[global]" > $SMBG
		cat $TMP >> $SMBG
		rm -f $TMP
	fi
fi
if ! grep -q 'winbind enum users' $SMBG; then
	echo "    winbind enum users = yes" >> $SMBG
fi
if ! grep -q 'winbind enum groups' $SMBG; then
	echo "    winbind enum groups = yes" >> $SMBG
fi

mkdir -p /opt/software

SMBINC="/etc/samba/includes.smb"
if [ ! -f $SMBINC ]; then
	echo "include = $SMBG" >> $SMBINC
else
	if ! grep -q "$SMBG" $SMBINC; then
		echo "include = $SMBG" >> $SMBINC
	fi
fi

service ldap restart
service smb restart
service winbind restart

if [ "$1" = 1 ] ; then
	SECRET=$(cat /etc/ldap.secret)
	smbpasswd -w $SECRET

	# grant SePrintOperatorPrivilege to "Print Operators"
	# first add root to ldap (needed to grant privilege)
	SID=$(net getlocalsid)
	SID=${SID/*S/S}
	sed -e "s/-thedn-/$BASE/g" -i /tmp/root.ldif
	sed -e "s/-thesid-/$SID/g" -i /tmp/root.ldif
	/usr/bin/ldapadd -x -D "cn=ldapadmin,ou=People,$BASE" -w $SECRET -f /tmp/root.ldif
	# set privileges for root

	for i in $(seq 1 60); do
		#no exit if grep fails!
		set +e
		RA=$(netstat -ptuan 2>/dev/null | grep -e ":137" )
		RB=$(netstat -ptuan 2>/dev/null | grep -e ":445" )
		set -e
		if [ -n "$RA" -a -n "$RB" ];then
			break
		fi
		sleep 1
	done
	# set privileges for 'Print Operators'
	/usr/bin/net rpc rights grant "Print Operators" SePrintOperatorPrivilege -U root%bitUPsam1
	# set privileges for 'Domain Admins'
	/usr/bin/net rpc rights grant "Domain Admins" SeAddUsersPrivilege SeDiskOperatorPrivilege SeMachineAccountPrivilege SePrintOperatorPrivilege SeRemoteShutdownPrivilege SeTakeOwnershipPrivilege SeBackupPrivilege SeRestorePrivilege -U root%bitUPsam1
	# remove root from LDAP

	/usr/bin/ldapdelete -x -D "cn=ldapadmin,ou=People,$BASE" -w $SECRET "uid=root,ou=People,$BASE"

	service smb restart
	service winbind restart
fi

# enable services
chkconfig smb on
chkconfig winbind on

rm -f /tmp/root.ldif

%postun
%{__mv} -f /etc/samba/smb.conf.yaffassave /etc/samba/smb.conf
%{__rm} -f /etc/samba/smbopts.software
%{__rm} -f /etc/samba/includes.smb
%{__rm} -f /etc/samba/smbopts.global

%files
%defattr(-,root,root)
%doc debian/{copyright,changelog}
%config /opt/yaffas/share/doc/example/etc/samba/smb.conf
%config /opt/yaffas/share/doc/example/etc/samba/smbopts.software
/tmp/root.ldif

%changelog
* Mon Mar 08 2011 Package Builder <packages@yaffas.org> 0.7.0-1
- initial release

