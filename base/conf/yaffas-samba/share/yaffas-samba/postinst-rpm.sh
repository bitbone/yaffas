#!/bin/bash
OS=$(perl -I /opt/yaffas/lib/perl5 -MYaffas::Constant -we 'print Yaffas::Constant::OS')
if [ -n $1 ]; then
	INSTALLLEVEL=$1
else 
	INSTALLLEVEL=1
fi

##### yaffas-samba #####
if [ $INSTALLLEVEL -eq 1 ]; then
	# preserve config files and copy our config
	# to default location
	YAFFAS_EXAMPLE="/opt/yaffas/share/doc/example"
	mv -f /etc/samba/smb.conf /etc/samba/smb.conf.yaffassave
	cp -f -a ${YAFFAS_EXAMPLE}/etc/samba/smb.conf /etc/samba
	cp -f -a ${YAFFAS_EXAMPLE}/etc/samba/smbopts.software /etc/samba

	mkdir -p /etc/samba/smbprinters/
	mkdir -p /etc/samba/printer/{W32ALPHA,W32MIPS,W32PPC,W32X86,WIN40}

	touch /etc/printcap

	chmod -R 777 /etc/samba/printer/

	# correct dn in smb.conf
	SMBCBB="/etc/samba/smb.conf"

	BASE=$(grep "^BASEDN=" /etc/ldap.settings | cut -d= -f2-)

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

	if [ x$OS = xRHEL5 -o x$OS = xRHEL6 ]; then
	# restore selinux contexts
		/sbin/restorecon -R /etc/samba
	fi
	
	if [ x$OS = xRHEL5 -o x$OS = xRHEL6 ]; then
		if [ x$OS = xRHEL5 ]; then
			service ldap restart
		fi
		if [ x$OS = xRHEL6 ]; then
			service slapd restart
		fi
		service smb restart
		service winbind restart
	else
		SAMBA=/etc/init.d/smbd
	
	    if [ ! -f $SAMBA ]; then
	        SAMBA=/etc/init.d/samba
	    fi
	
	    if [ ! -f $SAMBA ]; then
	        echo "No samba initscript found";
	        exit 1
	    fi
	
		$SAMBA restart
		/etc/init.d/winbind restart
		/etc/init.d/slapd restart
	fi

	if [ "$INSTALLLEVEL" = 1 ] ; then
		SECRET=$(cat /etc/ldap.secret)
		smbpasswd -w $SECRET

		# grant SePrintOperatorPrivilege to "Print Operators"
		# first add root to ldap (needed to grant privilege)
		SID=$(net getlocalsid)
		SID=${SID/*S/S}
		sed -e "s/-thedn-/$BASE/g" -i /opt/yaffas/share/doc/example/tmp/root.ldif
		sed -e "s/-thesid-/$SID/g" -i /opt/yaffas/share/doc/example/tmp/root.ldif
		/usr/bin/ldapadd -x -D "cn=ldapadmin,ou=People,$BASE" -w $SECRET -f /opt/yaffas/share/doc/example/tmp/root.ldif
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

		if [ x$OS = xRHEL5 -o x$OS = xRHEL6 ]; then
			service smb restart
			service winbind restart
		else
			$SAMBA restart
			/etc/init.d/winbind restart
		fi
	fi

	if [ x$OS = xRHEL5 -o x$OS = xRHEL6 ]; then
		# enable services
		chkconfig smb on
		chkconfig winbind on
	fi

	rm -f /opt/yaffas/share/doc/example/tmp/root.ldif
fi

##### end yaffas-samba #####
