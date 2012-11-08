#!/bin/bash
OS=$(perl -I /opt/yaffas/lib/perl5 -MYaffas::Constant -we 'print Yaffas::Constant::OS')

# this is an update :)

DOMAIN=$(hostname -d 2> /dev/null || echo "")

if [ -z "$DOMAIN" ]; then
    DOMAIN="yaffas.local"
fi

if ! echo $DOMAIN | grep -q "\."; then
    DOMAIN="$DOMAIN.local"
fi

CONF="/etc/ldap.conf"
SLAPD="/etc/openldap/slapd.conf"

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

# make sure the latest zarafa LDAP schema is installed
if [ -e /usr/share/doc/zarafa/zarafa.schema ]; then
	cp /usr/share/doc/zarafa/zarafa.schema /etc/openldap/schema
elif [ -e /usr/share/doc/zarafa/zarafa.schema.gz ]; then
	zcat /usr/share/doc/zarafa/zarafa.schema.gz > /etc/ldap/schema
fi

if [ x$OS = xRHEL5 ]; then
	service ldap restart
elif [ x$OS = xRHEL6 ]; then
	service slapd restart
else
	/etc/init.d/slapd restart
fi 
