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
