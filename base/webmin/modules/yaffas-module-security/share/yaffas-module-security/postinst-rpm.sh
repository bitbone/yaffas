#!/bin/bash
OS=$(perl -I /opt/yaffas/lib/perl5 -MYaffas::Constant -we 'print Yaffas::Constant::OS')

##### yaffas-module-security #####

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

##### end yaffas-module-security #####
