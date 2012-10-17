#!/bin/bash
OS=$(perl -I /opt/yaffas/lib/perl5 -MYaffas::Constant -we 'print Yaffas::Constant::OS')
if [ -n $1 ]; then
	INSTALLLEVEL=$1
else 
	INSTALLLEVEL=1
fi

set -e

source /opt/yaffas/lib/bbinstall-lib.sh

if [ "$INSTALLLEVEL" = 1 ] ; then

	[[ -e /etc/default/spamassassin ]] && sed -e 's/^ENABLED=0/ENABLED=1/' -i /etc/default/spamassassin

	test -f /etc/policyd-weight.conf && mv -f /etc/policyd-weight.conf /etc/policyd-weight.conf.yaffassave
	cp -f -a /opt/yaffas/share/doc/example/etc/policyd-weight.conf /etc
	cp -f -a /opt/yaffas/share/doc/example/etc/amavis/conf.d/60-yaffas-debian /etc/amavis/conf.d/60-yaffas

	if ! id clamav | grep -q "amavis"; then
			usermod -a -G amavis clamav
	fi

	touch /opt/yaffas/config/whitelist-amavis
	touch /opt/yaffas/config/postfix/whitelist-postfix
	postmap /opt/yaffas/config/postfix/whitelist-postfix

	invoke-rc.d spamassassin restart
	invoke-rc.d amavis restart || exit 0

fi

exit 0


