#!/bin/bash
OS=$(perl -I /opt/yaffas/lib/perl5 -MYaffas::Constant -we 'print Yaffas::Constant::OS')

set -e

DOMAIN=$(hostname -d 2> /dev/null || echo "")

if [ -z "$DOMAIN" ]; then
    DOMAIN="yaffas.local"
fi

if ! echo $DOMAIN | grep -q "\."; then
    DOMAIN="$DOMAIN.local"
fi

echo "Using $DOMAIN for LDAP tree"

function _get_base() {
	ARRAY=(`echo $DOMAIN | cut -d. -f1- --output-delimiter=\ `)
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

function _get_org() {
	echo `echo $1 | sed -e 's/.*o=\(.*\),.*/\1/g'`
}

# some defines
CONF="/etc/ldap.conf"
NSS="/etc/nsswitch.conf"
SLAPD="/etc/ldap/slapd.conf"
LDAPS="/etc/ldap.secret"
LDIF="/tmp/yaffas_base.ldif"
DOMRENAME_FILE="/tmp/slapcat.ldif"
LDAPCONF="/etc/ldap/ldap.conf"
SMBLDAP_CONF="/etc/smbldap-tools/smbldap.conf"
SMBLDAP_BIND="/etc/smbldap-tools/smbldap_bind.conf"
LDAP_SETTINGS="/etc/ldap.settings"
SID=`net getlocalsid 2>/dev/null | awk '{print $NF}'`

# only on first installation, if no ldap tree is present
# create group which allows users to read from ldap
addgroup --system ldapread

# save existing config files and
# copy our config files to default locations
YAFFAS_EXAMPLE="/opt/yaffas/share/doc/example"
if [ -e /etc/ldap.conf ]; then
	mv -f /etc/ldap.conf /etc/ldap.conf.yaffassave
fi
cp -f ${YAFFAS_EXAMPLE}/etc/ldap.conf /etc
cp -f ${YAFFAS_EXAMPLE}/etc/ldap.settings /etc
# leave nsswitch.conf will be change by setting authentication
#mv -f /etc/nsswitch.conf /etc/nsswitch.conf.yaffassave
#cp -f ${YAFFAS_EXAMPLE}/etc/nsswitch.conf /etc
if [ -e /etc/ldap/slapd.conf ]; then
	mv -f /etc/ldap/slapd.conf /etc/ldap/slapd.conf.yaffassave
fi
cp -f -p ${YAFFAS_EXAMPLE}/etc/ldap/slapd.conf /etc/ldap
if [ -e /etc/ldap/ldap.conf ]; then
	mv -f /etc/ldap/ldap.conf /etc/ldap/ldap.conf.yaffassave
fi
cp -f ${YAFFAS_EXAMPLE}/etc/ldap/ldap.conf /etc/ldap
cp -f ${YAFFAS_EXAMPLE}/etc/ldap.secret /etc
cp -f ${YAFFAS_EXAMPLE}/etc/postfix/ldap-users.cf /etc/postfix
cp -f ${YAFFAS_EXAMPLE}/etc/postfix/ldap-aliases.cf /etc/postfix
cp -f ${YAFFAS_EXAMPLE}/etc/ldap/schema/samba.schema /etc/ldap/schema
if [ -e /usr/share/doc/zarafa/zarafa.schema.gz ]; then
	zcat /usr/share/doc/zarafa/zarafa.schema.gz > /etc/ldap/schema/zarafa.schema
else 
	cp -f ${YAFFAS_EXAMPLE}/etc/ldap/schema/zarafa.schema /etc/ldap/schema
fi
if [ -e /etc/smbldap-tools/smbldap.conf ]; then
	mv -f /etc/smbldap-tools/smbldap.conf /etc/smbldap-tools/smbldap.conf.yaffassave
fi
cp -f ${YAFFAS_EXAMPLE}/etc/smbldap-tools/smbldap.conf /etc/smbldap-tools
if [ -e /etc/smbldap-tools/smbldap_bind.conf ]; then
	mv -f /etc/smbldap-tools/smbldap_bind.conf /etc/smbldap-tools/smbldap_bind.conf.yaffassave
fi
cp -f ${YAFFAS_EXAMPLE}/etc/smbldap-tools/smbldap_bind.conf /etc/smbldap-tools

# allow slapd access to our certificates
APPARMOR_SLAPD=/etc/apparmor.d/usr.sbin.slapd
if [ -w $APPARMOR_SLAPD ] && [ -x /etc/init.d/apparmor ]; then
   	if ! grep -q "#include.*<local/usr.sbin.slapd>" $APPARMOR_SLAPD; then
       	sed -e '$s=.*=#include <local/usr.sbin.slapd>\n}=' -i $APPARMOR_SLAPD
   	fi
   	if [ -e /etc/apparmor.d/local/usr.sbin.slapd ]; then
       	mv -f /etc/apparmor.d/local/usr.sbin.slapd /etc/apparmor.d/local/usr.sbin.slapd.yaffassave
   	fi
   	mkdir -p /etc/apparmor.d/local/
   	cp -f ${YAFFAS_EXAMPLE}/etc/apparmor.d/local/* /etc/apparmor.d/local/
	/etc/init.d/apparmor reload
fi

/etc/init.d/slapd stop
sleep 1

# kill ldap if it is still running
if pgrep slapd; then
	killall -9 slapd
fi

BASE=`_get_base`

sed -e 's#SLAPD_CONF.*#SLAPD_CONF=/etc/ldap/slapd.conf#g' -i /etc/default/slapd
sed -e "s#BASE#$BASE#" -i /etc/postfix/ldap-users.cf
sed -e "s#BASE#$BASE#" -i /etc/postfix/ldap-aliases.cf

echo "Using base $BASE ..."
echo "Changing configfiles..."

sed -e "s/BASE/$BASE/" -i $CONF
sed -e "s/BASE/$BASE/" -i $SLAPD
sed -e "s/BASE/$BASE/" -i $LDAPCONF
sed -e "s/BASE/$BASE/" -i $SMBLDAP_CONF
sed -e "s/NEWSID/$SID/" -i $SMBLDAP_CONF
HOST=$(hostname -s)
sed -e "s/DOMAIN/$HOST/" -i $SMBLDAP_CONF
sed -e "s/BASE/$BASE/" -i $SMBLDAP_BIND

echo "Removing old LDAP Database"
rm -rf /var/lib/ldap/*

echo "Executing domrename.pl ... $DOMAIN $LDIF"

cp $YAFFAS_EXAMPLE/share/yaffas_base.ldif $LDIF

sed -e "s/NEWSID/$SID/" -i $LDIF
/opt/yaffas/bin/domrename.pl BASE $DOMAIN $LDIF

if [ ! -f /var/lib/ldap/DB_CONFIG ]; then
	cp /usr/share/slapd/DB_CONFIG /var/lib/ldap/
fi

# Einspielen des LDIF
slapadd -v -l $DOMRENAME_FILE -f /etc/ldap/slapd.conf
chown -R openldap:openldap /var/lib/ldap/
rm -f $DOMRENAME_FILE
rm $LDIF

# generate password for LDAP
OURPASSWD="$(mkpasswd yaffas)"

for MYFILE in /etc/ldap.secret /etc/postfix/ldap-users.cf /etc/postfix/ldap-aliases.cf /etc/ldap/ldap.conf /etc/ldap.conf /etc/smbldap-tools/smbldap_bind.conf; do
	sed -e "s#--OURPASSWD--#$OURPASSWD#" -i $MYFILE
done

MYCRYPTPW=$(slappasswd -h {CRYPT} -s $OURPASSWD)
sed -e "s#--MYCRYPTPW--#$MYCRYPTPW#" -i /etc/ldap/slapd.conf

#write ldap.settings
echo "BASEDN=$BASE" >$LDAP_SETTINGS
echo "USERSEARCH=uid">>$LDAP_SETTINGS
echo "BINDDN=cn=ldapadmin,ou=People,$BASE" >> $LDAP_SETTINGS
echo "USER_SEARCHBASE=ou=People,$BASE" >> $LDAP_SETTINGS
echo "LDAPSECRET=$OURPASSWD" >> $LDAP_SETTINGS
echo "LDAPURI=ldap://127.0.0.1" >> $LDAP_SETTINGS
echo "EMAIL=mail" >> $LDAP_SETTINGS
	
DEFAULT="/etc/default/slapd"
sed 's/.*SLAPD_SERVICES.*/SLAPD_SERVICES=\"ldap:\/\/127.0.0.1\/ \"/' -i $DEFAULT
mkdir -p /opt/yaffas/config/
echo "method=ldap" > /opt/yaffas/config/alias.cfg

if [ ! -f /var/lib/ldap/DB_CONFIG ]; then
	cp /usr/share/slapd/DB_CONFIG /var/lib/ldap/
fi

# fix permissions
chmod 440 $CONF
chmod 640 $LDAPS
chown root:ldapread $CONF
chown root:ldapread $LDAPS
chown root:ldapread /etc/ldap.conf

rm -f $LDIF

exit 0
