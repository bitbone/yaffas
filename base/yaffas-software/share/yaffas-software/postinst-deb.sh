#!/bin/bash
OS=$(perl -I /opt/yaffas/lib/perl5 -MYaffas::Constant -we 'print Yaffas::Constant::OS')

set -e

INCLUDES="/etc/samba/includes.smb"
if [ -e $INCLUDES ]; then
	echo "include = /etc/samba/smbopts.software" >> $INCLUDES
fi

SAMBA=/etc/init.d/smbd

if [ ! -f $SAMBA ]; then
	SAMBA=/etc/init.d/samba
fi

if [ ! -f $SAMBA ]; then
	echo "Samba initscript not found"
    exit 0
fi

$SAMBA reload || exit 0

exit 0

