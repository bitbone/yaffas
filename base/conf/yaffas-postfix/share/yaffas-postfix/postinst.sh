#!/bin/bash
OS=$(perl -I /opt/yaffas/lib/perl5 -MYaffas::Constant -we 'print Yaffas::Constant::OS')
INSTALLLEVEL=1

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

if [ x$OS = xRHEL5 -o x$OS = xRHEL6 ]; then

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
else
	if ! grep -q "START=yes" /etc/default/saslauthd; then
	    sed -e 's/^START.*/START=yes/' -i /etc/default/saslauthd
	fi

	if ! grep -q 'MECHANISMS="rimap"' /etc/default/saslauthd; then
		sed -e 's/^MECHANISMS.*/MECHANISMS="rimap"/' -i /etc/default/saslauthd
		sed -e 's/^MECH_OPTIONS.*/MECH_OPTIONS="127.0.0.1"/' -i /etc/default/saslauthd
		sed -e 's#^OPTIONS.*#OPTIONS="-c -m /var/spool/postfix/var/run/saslauthd"#' -i /etc/default/saslauthd
	fi
	adduser postfix sasl
	invoke-rc.d postfix restart
	invoke-rc.d saslauthd restart
fi

##### end yaffas-postfix #####
