#!/bin/bash

SERVERCFG="/etc/zarafa/server.cfg"
if grep -q index_services_enabled $SERVERCFG; then
    sed -e 's/index_services_enabled/search_enabled/' -i $SERVERCFG
fi

if grep -q index_services_path $SERVERCFG; then
    sed -e '/index_services_path/d' -i $SERVERCFG
    echo "search_socket = file:///var/run/zarafa-search" >> $SERVERCFG
fi

