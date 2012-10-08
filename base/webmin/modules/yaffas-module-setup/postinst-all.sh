#!/bin/bash
YAFFAS_SHARE=/opt/yaffas/share

INSTALLLEVEL=1

for module in yaffas-ldap yaffas-samba yaffas-postfix yaffas-security yaffas-zarafa yaffas-software yaffas-module-security z-push; do
	sh $YAFFAS_SHARE/${module}/postinst.sh $INSTALLLEVEL
done
