#!/bin/bash
OS=$(perl -I /opt/yaffas/lib/perl5 -MYaffas::Constant -we 'print Yaffas::Constant::OS')
YAFFAS_SHARE=/opt/yaffas/share
if [ x$OS = xRHEL5 -o x$OS = xRHEL6 ]; then
	DIST=rpm
elif [ x$OS = xDebian -o x$OS = xUbuntu ]; then
	DIST=deb
fi

LOGFILE=/root/yaffas-postinst.log

if [ -e /root/yaffas-postinst.log ]; then
	echo "yaffas post installation scripts were already run. Exiting."
	exit 0
fi

for module in yaffas-ldap yaffas-samba yaffas-postfix yaffas-security yaffas-zarafa yaffas-software yaffas-module-security z-push; do
	echo "executing $YAFFAS_SHARE/${module}/postinst-${DIST}.sh ..." >> $LOGFILE
	echo "" >> $LOGFILE
	sh $YAFFAS_SHARE/${module}/postinst-${DIST}.sh >> $LOGFILE
	echo "" >> $LOGFILE
	echo "... done" >> $LOGFILE
done

exit 0