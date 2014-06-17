#!/bin/bash
POSTFIX_MAIN_CF=/etc/postfix/main.cf
POSTFIX_CONFIG_CHANGED=0
TABLE="/opt/yaffas/config/postfix/whitelist-postfix"
HASH_TABLE="hash:$TABLE"
CIDR_TABLE="cidr:$TABLE"
CIDR_RESTRICTION="check_client_access $CIDR_TABLE"

cur_restrictions=$(postconf -h smtpd_recipient_restrictions)
if ! echo "$cur_restrictions" | grep -qF "$CIDR_RESTRICTION"; then
		echo "Fixing Postfix IP whitelisting using CIDR (ADM-403)..."
		POSTFIX_CONFIG_CHANGED=1

		new_restrictions=$(
				echo "$cur_restrictions" |
				sed -e "s|$HASH_TABLE, |$HASH_TABLE, $CIDR_RESTRICTION, |")

		postconf -e smtpd_recipient_restrictions="$new_restrictions"
fi
[[ $POSTFIX_CONFIG_CHANGED != 0 ]] && postfix reload

