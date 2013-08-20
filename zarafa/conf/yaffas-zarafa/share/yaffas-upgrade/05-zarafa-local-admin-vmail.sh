#!/bin/bash

# This upgrade script ensures that 'vmail' is listed as a local
# admin user for zarafa (needed for delivery to public folder using
# manual dagent invocations)

CFG=/etc/zarafa/server.cfg

grep -qP '^local_admin_users\s*(=vmail|=.*\svmail)' "$CFG" && exit 0

if grep -P '^local_admin_users\s*='; then
	sed -re 's|^(local_admin_users\s*=.*)|\1 vmail|' -i "$CFG"
else
	echo 'local_admin_users=root vmail' >> "$CFG"
fi
