#!/bin/bash

SERVERCFG="/etc/zarafa/server.cfg"
if grep -q index_services_enabled $SERVERCFG; then
    sed -e 's/index_services_enabled/search_enabled/' -i $SERVERCFG
fi

if grep -q index_services_path $SERVERCFG; then
    sed -e '/index_services_path/d' -i $SERVERCFG
    echo "search_socket = file:///var/run/zarafa-search" >> $SERVERCFG
fi

# Work around for ZCP-13222 (apache2ctl graceful crashes apache with
# ZCP-7.1.12's php-mapi);
# can be removed once a newer release than ZCP 7.1.12 gets included
touch /etc/zarafa/php-mapi.cfg
