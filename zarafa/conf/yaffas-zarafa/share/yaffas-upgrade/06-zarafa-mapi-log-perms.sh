#!/bin/bash
MAPI_LOG=/var/log/zarafa/php-mapi.log
chown :www-data "$MAPI_LOG"
chmod 660 "$MAPI_LOG"
