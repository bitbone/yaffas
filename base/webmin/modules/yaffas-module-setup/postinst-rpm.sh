#!/bin/bash
OS=$(perl -I /opt/yaffas/lib/perl5 -MYaffas::Constant -we 'print Yaffas::Constant::OS')
INSTALLLEVEL=1

##### yaffas-ldap #####
DOMAIN=$(hostname -d 2> /dev/null || echo "")

if [ -z "$DOMAIN" ]; then
    DOMAIN="yaffas.local"
fi

if ! echo $DOMAIN | grep -q "\."; then
    DOMAIN="$DOMAIN.local"
fi

echo "Using $DOMAIN for LDAP tree"

function _get_base() {
	ARRAY=(`echo ${DOMAIN} | cut -d. -f1- --output-delimiter=\ `)
	COUNT=${#ARRAY[*]}
	BASE=""

	for i in `seq 1 $COUNT`
	do
		if [ $i -eq $COUNT ]; then
			BASE="${BASE}dc=${ARRAY[$(($i-1))]}"
		elif [ $i -eq $(($COUNT-1)) ]; then
			BASE="${BASE}dc=${ARRAY[$(($i-1))]},"
		else
			BASE="${BASE}dc=${ARRAY[$(($i-1))]},"
		fi
	done

	echo -n "$BASE"
}

# use sample DB_CONFIG if none is configured
if [ ! -f /var/lib/ldap/DB_CONFIG ]; then
	if [ -f /usr/share/openldap-servers/DB_CONFIG.example ]; then
		cp /usr/share/openldap-servers/DB_CONFIG.example /var/lib/ldap/DB_CONFIG
	elif [ -f /etc/openldap/DB_CONFIG.example ]; then
		cp /etc/openldap/DB_CONFIG.example /var/lib/ldap/DB_CONFIG
	fi
fi

# some defines
CONF="/etc/ldap.conf"
NSS="/etc/nsswitch.conf"
SLAPD="/etc/openldap/slapd.conf"
LDAPS="/etc/ldap.secret"
LDIF="/tmp/yaffas_base.ldif"
DOMRENAME_FILE="/tmp/slapcat.ldif"
LDAPCONF="/etc/openldap/ldap.conf"
SMBLDAP_CONF="/etc/smbldap-tools/smbldap.conf"
SMBLDAP_BIND="/etc/smbldap-tools/smbldap_bind.conf"
LDAP_SETTINGS="/etc/ldap.settings"
SID=`net getlocalsid 2>/dev/null | awk '{print $NF}'`
NSLCDCONF=/etc/nslcd.conf

# only on first installation, if no ldap tree is present
if [ "$INSTALLLEVEL" = 1 ] ; then

	# create group which allows users to read from ldap
	groupadd -f -r ldapread

	# save existing config files and
	# copy our config files to default locations
	YAFFAS_EXAMPLE="/opt/yaffas/share/doc/example"
	for SAVEFILE in /etc/ldap.conf /etc/openldap/slapd.conf \
		/etc/openldap/ldap.conf /etc/smbldap-tools/smbldap.conf \
		/etc/smbldap-tools/smbldap_bind.conf /etc/nslcd.conf; do
		if [ -e $SAVEFILE ]; then
			mv -f $SAVEFILE ${SAVEFILE}.yaffassave
		fi
	done
	cp -f ${YAFFAS_EXAMPLE}/etc/ldap.conf /etc
	cp -f ${YAFFAS_EXAMPLE}/etc/nslcd.conf /etc
	cp -f ${YAFFAS_EXAMPLE}/etc/ldap.settings /etc
	cp -f -p ${YAFFAS_EXAMPLE}/etc/openldap/slapd.conf /etc/openldap
	cp -f ${YAFFAS_EXAMPLE}/etc/openldap/ldap.conf /etc/openldap
	cp -f ${YAFFAS_EXAMPLE}/etc/ldap.secret /etc
	cp -f ${YAFFAS_EXAMPLE}/etc/postfix/ldap-users.cf /etc/postfix
	cp -f ${YAFFAS_EXAMPLE}/etc/postfix/ldap-aliases.cf /etc/postfix
	cp -f ${YAFFAS_EXAMPLE}/etc/openldap/schema/samba.schema /etc/openldap/schema
	cp -f ${YAFFAS_EXAMPLE}/etc/openldap/schema/zarafa.schema /etc/openldap/schema
	cp -f ${YAFFAS_EXAMPLE}/etc/smbldap-tools/smbldap.conf /etc/smbldap-tools
	cp -f ${YAFFAS_EXAMPLE}/etc/smbldap-tools/smbldap_bind.conf /etc/smbldap-tools

if [ x$OS = xRHEL5 ]; then
	service ldap stop
fi

if [ x$OS = xRHEL6 ]; then
	service slapd stop
fi
	sleep 1

	# kill ldap if it is still running
	if pgrep slapd; then
		killall -9 slapd
	fi

if [ x$OS = xRHEL6 ]; then
	SYSCONFIG_LDAP="/etc/sysconfig/ldap"
	if [ -e $SYSCONFIG_LDAP ]; then
		cp -f $SYSCONFIG_LDAP ${SYSCONFIG_LDAP}.yaffassave
		if grep -q "SLAPD_OPTIONS=" $SYSCONFIG_LDAP; then
			sed -e 's/.*SLAPD_OPTIONS=.*/SLAPD_OPTIONS="-f \/etc\/openldap\/slapd.conf"/' -i $SYSCONFIG_LDAP
		else
			echo 'SLAPD_OPTIONS="-f /etc/openldap/slapd.conf"' >> $SYSCONFIG_LDAP
		fi
	fi
fi

	BASE=`_get_base`

	sed -e "s#BASE#$BASE#" -i /etc/postfix/ldap-users.cf
	sed -e "s#BASE#$BASE#" -i /etc/postfix/ldap-aliases.cf

	echo "Using base $BASE ..."
	echo "Changing configfiles..."

	sed -e "s/BASE/$BASE/" -i $CONF
	sed -e "s/BASE/$BASE/" -i $NSLCDCONF
	sed -e "s/BASE/$BASE/" -i $SLAPD
	sed -e "s/BASE/$BASE/" -i $LDAPCONF
	sed -e "s/BASE/$BASE/" -i $SMBLDAP_CONF
	sed -e "s/NEWSID/$SID/" -i $SMBLDAP_CONF
	sed -e "s/BASE/$BASE/" -i $SMBLDAP_BIND


	echo "Removing old LDAP Database"
	rm -rf /var/lib/ldap/*

	echo "Executing domrename.pl ... $DOMAIN $LDIF"
	sed -e "s/NEWSID/$SID/" -i $LDIF
	/opt/yaffas/bin/domrename.pl BASE $DOMAIN $LDIF

	# import LDIF
	slapadd -v -l $DOMRENAME_FILE -f $SLAPD
	chown -R ldap:ldap /var/lib/ldap/
	rm -f $DOMRENAME_FILE
	rm $LDIF

	# generate password for LDAP
	OURPASSWD="$(mkpasswd -s 0)"

	for MYFILE in /etc/openldap/ldap.conf /etc/ldap.secret \
		/etc/postfix/ldap-users.cf /etc/postfix/ldap-aliases.cf \
		/etc/ldap.conf /etc/smbldap-tools/smbldap_bind.conf; do
		sed -e "s/--OURPASSWD--/$OURPASSWD/" -i $MYFILE
	done

	MYCRYPTPW=$(slappasswd -h {CRYPT} -s $OURPASSWD)
	sed -e "s#--MYCRYPTPW--#$MYCRYPTPW#" -i /etc/openldap/slapd.conf

	#write ldap.settings
	echo "BASEDN=$BASE" >$LDAP_SETTINGS
	echo "USERSEARCH=uid">>$LDAP_SETTINGS
	echo "BINDDN=cn=ldapadmin,ou=People,$BASE" >> $LDAP_SETTINGS
	echo "USER_SEARCHBASE=ou=People,$BASE" >> $LDAP_SETTINGS
	echo "LDAPSECRET=$OURPASSWD" >> $LDAP_SETTINGS
	echo "LDAPURI=ldap://127.0.0.1" >> $LDAP_SETTINGS
	echo "EMAIL=mail" >> $LDAP_SETTINGS

	# set listening options
	DEFAULT="/etc/sysconfig/ldap"
	sed 's/.*SLAPD_LDAP\s*=.*/SLAPD_LDAP=\"yes\"/' -i $DEFAULT
	sed 's/.*SLAPD_LDAPS\s*=.*/SLAPD_LDAPS=\"yes\"/' -i $DEFAULT
	sed 's/.*SLAPD_LDAPI\s*=.*/SLAPD_LDAPI=\"yes\"/' -i $DEFAULT
	mkdir -p /opt/yaffas/config/
	echo "method=ldap" > /opt/yaffas/config/alias.cfg

else
	# this is an update :)

	if ! grep "^tls_checkpeer" $CONF > /dev/null; then
		echo "tls_checkpeer no" >> $CONF
	fi

	if ! grep zarafa.schema $SLAPD &>/dev/null; then
		sed 's|include[[:space:]]\+/etc/openldap/schema/samba.schema|include\t/etc/openldap/schema/samba.schema\ninclude /etc/openldap/schema/zarafa.schema|' -i $SLAPD
	fi

	if grep -q 'BASEDN.*o=.*c=' /etc/ldap.settings; then
		echo "fixing ldap dn..."
		/opt/yaffas/bin/domrename.pl $DOMAIN $DOMAIN upgrade
		service zarafa-server restart
		service postfix reload
		service smb restart
	fi

fi

if [ x$OS = xRHEL6 ]; then
if [ -e /var/run/nss-pam-ldapd.migrate ]; then
	rm -f /var/run/nss-pam-ldapd.migrate
fi
fi

# fix permissions
chmod 440 $CONF
chmod 640 $LDAPS
chown root:ldapread $CONF
chown root:ldapread $LDAPS

rm -f $LDIF

# enabled ldap service
if [ x$OS = xRHEL5 ]; then
chkconfig ldap on
fi
if [ x$OS = xRHEL6 ]; then
chkconfig slapd on
chkconfig nslcd on
fi

##### end yaffas-ldap #####

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

	# restore selinux contexts
	/sbin/restorecon -R /etc/samba

if [ x$OS = xRHEL5 ]; then
	service ldap restart
fi
if [ x$OS = xRHEL6 ]; then
	service slapd restart
fi
	service smb restart
	service winbind restart

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

		service smb restart
		service winbind restart
	fi

	# enable services
	chkconfig smb on
	chkconfig winbind on

	rm -f /opt/yaffas/share/doc/example/tmp/root.ldif
fi

##### end yaffas-samba #####

##### yaffas-postfix #####
if [ "$INSTALLLEVEL" = 1 ] ; then
	sed -e '/smtpd_tls_session_cache_database/d' -i /opt/yaffas/share/doc/example/etc/postfix/main.cf
	sed -e '/smtp_tls_session_cache_database/d' -i /opt/yaffas/share/doc/example/etc/postfix/main.cf
	mv -f /etc/postfix/main.cf /etc/postfix/main.cf.yaffassave
	mv -f /etc/postfix/master.cf /etc/postfix/master.cf.yaffassave
	mv -f /etc/postfix/sasl/smtpd.conf /etc/postfix/sasl/smtpd.conf.yaffassave
	cp -f -a /opt/yaffas/share/doc/example/etc/postfix/main.cf /etc/postfix
	cp -f -a /opt/yaffas/share/doc/example/etc/postfix/master-redhat.cf /etc/postfix/master.cf
	cp -f -a /opt/yaffas/share/doc/example/etc/postfix/dynamicmaps.cf /etc/postfix
	mkdir -p /etc/postfix/sasl
	cp -f -a /opt/yaffas/share/doc/example/etc/postfix/sasl/smtpd.conf /etc/postfix/sasl/

	CONF=/etc/postfix
	mkdir -p $CONF

	touch $CONF/ldap-aliases.cf
	touch $CONF/ldap-aliases.cf.db
	touch $CONF/ldap-users.cf
	touch $CONF/ldap-users.cf.db
	touch $CONF/smtp_auth.cf
	postmap $CONF/smtp_auth.cf
	touch $CONF/virtual_users_global
	postmap $CONF/virtual_users_global

	chmod 600 $CONF/smtp_auth.cf
	chmod 600 $CONF/smtp_auth.cf.db

	/usr/bin/newaliases

fi

if ! grep -q 'MECH="rimap"' /etc/sysconfig/saslauthd; then
    sed -e 's/^MECH.*/MECH="rimap"/' -i /etc/sysconfig/saslauthd
    sed -e 's/^FLAGS.*/FLAGS="-O 127.0.0.1"/' -i /etc/sysconfig/saslauthd
    chkconfig saslauthd on
    service saslauthd restart
fi

# disable sendmail
service sendmail stop
chkconfig sendmail off

# enable postfix
alternatives --set mta /usr/sbin/sendmail.postfix
chkconfig postfix on
service postfix restart
service saslauthd restart

##### end yaffas-postfix #####

##### yaffas-security #####
if ! id amavis | grep -q "ldapread"; then
    usermod -a -G ldapread amavis
fi

if [ x$OS = xRHEL6 ]; then
	/sbin/service amavisd restart
fi

##### end yaffas-security #####

##### yaffas-zarafa #####
if [ "$INSTALLLEVEL" = 1 ] ; then
    YAFFAS_EXAMPLE=/opt/yaffas/share/doc/example
    for CFG in /etc/zarafa/*.cfg; do
        cp -f $CFG ${CFG}.yaffassave
    done
    cp -f -a ${YAFFAS_EXAMPLE}/etc/zarafa/*.cfg /etc/zarafa
fi

LDAPHOSTNAME=`grep "BASEDN=" /etc/ldap.settings | cut -d= -f2-`

export PERLLIB="/opt/yaffas/lib/perl5"
perl -MYaffas::Module::ChangeLang -wle '
my $lang = Yaffas::Module::ChangeLang::get_lang();
Yaffas::Module::ChangeLang::set_lang($lang);
'
sed "s/LDAPHOSTNAME/$LDAPHOSTNAME/g" -i /etc/zarafa/ldap.yaffas.cfg
OURPASSWD=$(cat /etc/ldap.secret)
sed -e "s#--OURPASSWD--#$OURPASSWD#g" -i /etc/zarafa/ldap.yaffas.cfg

SSL_CONF=/etc/httpd/conf.d/ssl.conf
if [ -e $SSL_CONF ]; then
    sed -e 's#^SSLCertificateFile.*#SSLCertificateFile /opt/yaffas/etc/ssl/certs/zarafa-webaccess.crt#' -i $SSL_CONF
    sed -e 's#^SSLCertificateKeyFile.*#SSLCertificateKeyFile /opt/yaffas/etc/ssl/certs/zarafa-webaccess.key#' -i $SSL_CONF
fi

# optimize memory
if [ "$INSTALLLEVEL" = 1 ]; then
    # only on a fresh installation
    MEM=$(cat /proc/meminfo | awk '/MemTotal:/ { printf "%d", $2*1024 }')

    LOGMEM=$(($MEM/16))

    if [ $LOGMEM -gt $((1024*1024*1024)) ]; then
        LOGMEM="1024M"
    fi

    MEM=$(($MEM/4))

    echo -e "[mysqld]\ninnodb_buffer_pool_size = $MEM\ninnodb_log_file_size = $LOGMEM\ninnodb_log_buffer_size = 32M" >> /etc/my.cnf

    rm -f /data/db/mysql/ib_logfile* /var/lib/mysql/ib_logfile*
    sed -e 's/^cache_cell_size.*/cache_cell_size = '$MEM'/' -i /etc/zarafa/server.cfg

    # fix plugin path
    if [ "x86_64" = $(rpm -q --qf %{ARCH} zarafa-server) ]; then
        sed -e 's#plugin_path\s*=.*#plugin_path=/usr/lib64/zarafa#' -i /etc/zarafa/server.cfg
    fi
 
    mkdir -p /data/zarafa/attachments/
fi

if [ "$INSTALLLEVEL" = 1 ] ; then
    #only do this on install, not on upgrade
    zarafa-admin -s
fi

# install zarafa selinux module
if [ "$INSTALLLEVEL" = 1 ] ; then
    checkmodule -M -m -o /tmp/zarafa.mod /tmp/zarafa.te
    semodule_package -o /tmp/zarafa.pp -m /tmp/zarafa.mod
    semodule -i /tmp/zarafa.pp
fi
rm -f /tmp/zarafa.{pp,mod,te}

echo "1: " $INSTALLLEVEL

if [ "$INSTALLLEVEL" = 2 ]; then
    SERVERCFG="/etc/zarafa/server.cfg"
    if grep -q index_services_enabled $SERVERCFG; then
        sed -e 's/index_services_enabled/search_enabled/' -i $SERVERCFG
    fi

    if grep -q index_services_path $SERVERCFG; then
        sed -e '/index_services_path/d' -i $SERVERCFG
        echo "search_socket = file:///var/run/zarafa-search" >> $SERVERCFG
    fi
fi

/sbin/restorecon -R /etc/zarafa
/sbin/restorecon -R /var/lib/zarafa-webaccess
/sbin/restorecon -R /var/lib/zarafa

chkconfig zarafa-server on
service zarafa-server stop
/usr/bin/zarafa-server --ignore-attachment-storage-conflict
service zarafa-server restart

# enable services
for SERV in mysqld zarafa-gateway zarafa-ical zarafa-search zarafa-licensed zarafa-monitor zarafa-spooler zarafa-dagent; do
    chkconfig $SERV on
    service $SERV start
done

##### end yaffas-zarafa #####

##### yafafs-software #####

INCLUDES="/etc/samba/includes.smb"
if [ -e $INCLUDES ]; then
	if ( ! grep -q "smbopts.software" $INCLUDES ); then
		echo "include = /etc/samba/smbopts.software" >> $INCLUDES
	fi
fi

service smb reload

##### end yaffas-software #####

#### yaffas-module-snmpconf #####

if cat /etc/snmp/snmpd.conf| grep com2sec | grep paranoid >/dev/null; then
	/sbin/chkconfig --del confd
fi

##### end yaffas-module-snmpconf #####

##### yaffas-module-security #####

if [ "$INSTALLLEVEL" = 1 ]; then
	mv -f /etc/policyd-weight.conf /etc/policyd-weight.conf.yaffassave
	cp -f -a /opt/yaffas/share/doc/example/etc/policyd-weight.conf /etc
	mv -f /etc/amavisd.conf /etc/amavisd.conf.yaffassave
	cp -f -a /opt/yaffas/share/doc/example/etc/amavisd-redhat.conf /etc/amavisd.conf
	mkdir -p /etc/amavis/conf.d/
	cp -f -a /opt/yaffas/share/doc/example/etc/amavis/conf.d/60-yaffas /etc/amavis/conf.d/60-yaffas

	USER=$(getent passwd | awk -F: '/^clam/ { print $1 }')

	if id $USER >/dev/null; then
		# if user exists
		if ! id $USER | grep -q "amavis"; then
			usermod -a -G amavis $USER
		fi
	fi
	
	GROUP=$(getent group | awk -F: '/^clam/ { print $1 }')
	
	if [ -n "$GROUP" ]; then
		usermod -a -G $GROUP amavis
	fi

	if ! grep -q "amavis" /etc/postfix/master.cf; then
		cat /opt/yaffas/share/doc/example/etc/amavis-master.cf >> /etc/postfix/master.cf
	fi

	touch /opt/yaffas/config/whitelist-amavis
	touch /opt/yaffas/config/postfix/whitelist-postfix

	chcon -R -u system_u -r object_r -t postfix_etc_t /opt/yaffas/config/postfix/
	postmap /opt/yaffas/config/postfix/whitelist-postfix
fi

##### end yaffas-module-security #####

