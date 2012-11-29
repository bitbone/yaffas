#!/bin/bash

CONFD_CLI=/etc/php5/cli/conf.d
CONFD_APACHE2=/etc/php5/apache2/conf.d
CONFD_GLOBAL=/etc/php5/conf.d
PHPINI_CLI=/etc/php5/cli/php.ini
PHPINI_APACHE2=/etc/php5/apache2/php.ini

has_php_extension() {
	local name=$1;
	local where=$2;
	if grep -qr '^\s*extension\s*=\s*'$name'\.so' "$where"; then
		return 0
	else
		return 1
	fi
}

remove_phpini_extension() {
	local name=$1;
	local where=$2;
	sed -e '/^\s*extension\s*=\s*'$name'\.so/d' -i "$where"
}

# run only on debian/ubuntu

if [ $(lsb_release -si) == "Ubuntu" ] || [ $(lsb_release -si) == "Debian" ]; then
	if has_php_extension mapi $CONFD_CLI || \
		has_php_extension mapi $CONFD_GLOBAL; then
		remove_phpini_extension mapi $PHPINI_CLI
	fi

	if has_php_extension mapi $CONFD_APACHE2 || \
		has_php_extension mapi $CONFD_GLOBAL; then
		remove_phpini_extension mapi $PHPINI_APACHE2
	fi


	if has_php_extension ldap $CONFD_CLI || \
		has_php_extension ldap $CONFD_GLOBAL; then
		remove_phpini_extension ldap $PHPINI_CLI
	fi

	if has_php_extension ldap $CONFD_APACHE2 || \
		has_php_extension ldap $CONFD_GLOBAL; then
		remove_phpini_extension ldap $PHPINI_APACHE2
	fi
fi
