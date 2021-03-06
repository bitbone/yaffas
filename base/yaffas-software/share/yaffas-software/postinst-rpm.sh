#!/bin/bash
OS=$(perl -I /opt/yaffas/lib/perl5 -MYaffas::Constant -we 'print Yaffas::Constant::OS')

##### yafafs-software #####

INCLUDES="/etc/samba/includes.smb"
if [ -e $INCLUDES ]; then
	if ( ! grep -q "smbopts.software" $INCLUDES ); then
		echo "include = /etc/samba/smbopts.software" >> $INCLUDES
	fi
fi

service smb reload

##### end yaffas-software #####
