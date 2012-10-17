#!/bin/bash
OS=$(perl -I /opt/yaffas/lib/perl5 -MYaffas::Constant -we 'print Yaffas::Constant::OS')
if [ -n $1 ]; then
	INSTALLLEVEL=$1
else 
	INSTALLLEVEL=1
fi

set -e


if [ "$INSTALLLEVEL" = 1 ] ; then
	# copy files only on new installation
	if [ -e /etc/postfix/main.cf ]; then
		mv -f /etc/postfix/main.cf /etc/postfix/main.cf.yaffassave
	fi
	if [ -e /etc/postfix/master.cf ]; then
		mv -f /etc/postfix/master.cf /etc/postfix/master.cf.yaffassave
	fi
	if [ -e /etc/postfix/sasl/smtpd.conf ]; then
		mv -f /etc/postfix/sasl/smtpd.conf /etc/postfix/sasl/smtpd.conf.yaffassave
	fi
	cp -f -a /opt/yaffas/share/doc/example/etc/postfix/main.cf /etc/postfix
	cp -f -a /opt/yaffas/share/doc/example/etc/postfix/master.cf /etc/postfix
	cp -f -a /opt/yaffas/share/doc/example/etc/postfix/dynamicmaps.cf /etc/postfix
	cp -f -a /opt/yaffas/share/doc/example/etc/postfix/sasl/smtpd.conf /etc/postfix/sasl/
fi

if ! grep -q "START=yes" /etc/default/saslauthd; then
	sed -e 's/^START.*/START=yes/' -i /etc/default/saslauthd
fi

if ! grep -q 'MECHANISMS="rimap"' /etc/default/saslauthd; then
	sed -e 's/^MECHANISMS.*/MECHANISMS="rimap"/' -i /etc/default/saslauthd
	sed -e 's/^MECH_OPTIONS.*/MECH_OPTIONS="127.0.0.1"/' -i /etc/default/saslauthd
	sed -e 's#^OPTIONS.*#OPTIONS="-c -m /var/spool/postfix/var/run/saslauthd"#' -i /etc/default/saslauthd
fi
adduser postfix sasl

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

invoke-rc.d postfix restart
invoke-rc.d saslauthd restart

exit 0


