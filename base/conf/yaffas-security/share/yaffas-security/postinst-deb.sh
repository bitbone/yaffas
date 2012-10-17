#!/bin/bash
OS=$(perl -I /opt/yaffas/lib/perl5 -MYaffas::Constant -we 'print Yaffas::Constant::OS')
if [ -n $1 ]; then
	INSTALLLEVEL=$1
else 
	INSTALLLEVEL=1
fi

set -e

if ! id amavis | grep -q "ldapread"; then
   	usermod -a -G ldapread amavis
fi

exit 0


