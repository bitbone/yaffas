#!/bin/bash
OS=$(perl -I /opt/yaffas/lib/perl5 -MYaffas::Constant -we 'print Yaffas::Constant::OS')
YAFFAS_SHARE=/opt/yaffas/share
if [ x$OS = xRHEL5 -o x$OS = xRHEL6 ]; then
	DIST=rpm
elif [ x$OS = xDebian -o x$OS = xUbuntu ]; then
	DIST=deb
fi

for module in yaffas-ldap yaffas-samba yaffas-postfix yaffas-security yaffas-zarafa yaffas-software yaffas-module-security z-push; do
	sh $YAFFAS_SHARE/${module}/postinst-${DIST}.sh
done
