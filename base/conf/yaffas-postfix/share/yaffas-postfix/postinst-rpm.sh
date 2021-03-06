#!/bin/bash
OS=$(perl -I /opt/yaffas/lib/perl5 -MYaffas::Constant -we 'print Yaffas::Constant::OS')

##### yaffas-postfix #####
sed -e '/smtpd_tls_session_cache_database/d' -i /opt/yaffas/share/doc/example/etc/postfix/main.cf
sed -e '/smtp_tls_session_cache_database/d' -i /opt/yaffas/share/doc/example/etc/postfix/main.cf
mv -f /etc/postfix/main.cf /etc/postfix/main.cf.yaffassave
mv -f /etc/postfix/master.cf /etc/postfix/master.cf.yaffassave
if [ -e /etc/postfix/sasl/smtpd.conf ]; then
	mv -f /etc/postfix/sasl/smtpd.conf /etc/postfix/sasl/smtpd.conf.yaffassave
fi
cp -f -a /opt/yaffas/share/doc/example/etc/postfix/main.cf /etc/postfix
cp -f -a /opt/yaffas/share/doc/example/etc/postfix/master-redhat.cf /etc/postfix/master.cf
cp -f -a /opt/yaffas/share/doc/example/etc/postfix/dynamicmaps.cf /etc/postfix
mkdir -p /etc/postfix/sasl
cp -f -a /opt/yaffas/share/doc/example/etc/postfix/sasl/smtpd.conf /etc/postfix/sasl/

CONF=/etc/postfix
YAFFAS_CONF=/opt/yaffas/config/postfix
mkdir -p $CONF $YAFFAS_CONF

touch $CONF/ldap-aliases.cf
touch $CONF/ldap-aliases.cf.db
touch $CONF/ldap-users.cf
touch $CONF/ldap-users.cf.db
touch $CONF/smtp_auth.cf
postmap $CONF/smtp_auth.cf
touch $CONF/virtual_users_global
postmap $CONF/virtual_users_global
touch $CONF/sender_canonical
postmap $CONF/sender_canonical

chmod 600 $CONF/smtp_auth.cf
chmod 600 $CONF/smtp_auth.cf.db

/usr/bin/newaliases

if ! grep -q 'MECH="rimap"' /etc/sysconfig/saslauthd; then
    sed -e 's/^MECH.*/MECH="rimap"/' -i /etc/sysconfig/saslauthd
    sed -e 's/^FLAGS.*/FLAGS="-O 127.0.0.1"/' -i /etc/sysconfig/saslauthd
    chkconfig saslauthd on
    service saslauthd restart
fi

	
bash /opt/yaffas/share/yaffas-upgrade/yaffas-postfix-1.4.0-deliver-to-public.sh

# disable sendmail
service sendmail stop
chkconfig sendmail off
	
# enable postfix
alternatives --set mta /usr/sbin/sendmail.postfix
chkconfig postfix on
service postfix restart
service saslauthd restart

##### end yaffas-postfix #####
