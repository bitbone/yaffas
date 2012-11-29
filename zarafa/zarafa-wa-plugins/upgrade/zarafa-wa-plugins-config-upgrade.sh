#!/bin/bash

# Upgrade configuration for webaccess plugin, because the config format changed.
# When updating we assume that ldap will be used as it was only availabe with ldap before

CONF="/opt/yaffas/zarafa/webaccess/plugins/passwd/config.inc.php"

if grep -q 'private $use_ldap = TRUE;' $CONF; then
    sed -e 's#private $use_ldap = TRUE;#private $method = "ldap";#g' -i $CONF
    sed -e 's#return $this->use_ldap;#return $this->method;#g' -i $CONF
fi
