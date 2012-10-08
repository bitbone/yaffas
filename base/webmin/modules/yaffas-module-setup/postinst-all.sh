#!/bin/bash
YAFFAS_SHARE=/opt/yaffas/share

for module in yaffas-ldap yaffas-samba yaffas-postfix yaffas-security yaffas-zarafa yaffas-software yaffas-module-security; do
	sh $YAFFAS_SHARE/${module}/postinst.sh
done
