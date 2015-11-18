#!/bin/bash
MAPI_LOG=/var/log/zarafa/php-mapi.log
touch "$MAPI_LOG"

OWNER=www-data
getent group apache >/dev/null 2>&1 && OWNER=apache
chown :"$OWNER" "$MAPI_LOG"
chmod 660 "$MAPI_LOG"
