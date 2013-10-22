#!/bin/bash

# return early on non-SELinux systems
which setsebool >/dev/null 2>&1 || exit 0

# pre-check the boolean; if it is already set, we don't have to
# set it again; this is way faster than setsebool -P
getsebool httpd_can_network_connect | grep -q on$ && exit 0

# WebApp 1.3 and later default to connecting to http://localhost:236
# instead of using the unix socket /var/run/zarafa (ADM-321)
setsebool -P httpd_can_network_connect=1
