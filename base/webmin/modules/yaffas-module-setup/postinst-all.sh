#!/bin/bash
OS=$(perl -I /opt/yaffas/lib/perl5 -MYaffas::Constant -we 'print Yaffas::Constant::OS')
YAFFAS_SHARE=/opt/yaffas/share
if [ x$OS = xRHEL5 -o x$OS = xRHEL6 ]; then
	DIST=rpm
elif [ x$OS = xDebian -o x$OS = xUbuntu ]; then
	DIST=deb
fi

LOGFILE=$(perl -I /opt/yaffas/lib/perl5 -MYaffas::Constant -we 'print Yaffas::Constant::FILE->{postinst_log}')
mkdir -p $(dirname $LOGFILE)

if [ -e $LOGFILE ]; then
	echo "yaffas post installation scripts were already run. Exiting."
	exit 0
fi

for module in yaffas-ldap yaffas-samba yaffas-postfix yaffas-security yaffas-zarafa yaffas-software yaffas-module-security yaffas-module-mailalias z-push bitkit-ldap-tools; do
	SCRIPT=$YAFFAS_SHARE/${module}/postinst-${DIST}.sh
	[[ -f "$SCRIPT" ]] || continue
	echo "executing $SCRIPT ..." >> $LOGFILE
	echo "" >> $LOGFILE
	bash "$SCRIPT" >> $LOGFILE
	echo "" >> $LOGFILE
	echo "... done" >> $LOGFILE
done

echo "all scripts finished" >> $LOGFILE

exit 0
