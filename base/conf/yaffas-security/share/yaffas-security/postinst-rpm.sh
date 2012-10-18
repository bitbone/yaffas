#!/bin/bash
OS=$(perl -I /opt/yaffas/lib/perl5 -MYaffas::Constant -we 'print Yaffas::Constant::OS')

##### yaffas-security #####
if ! id amavis | grep -q "ldapread"; then
    usermod -a -G ldapread amavis
fi

if [ x$OS = xRHEL6 ]; then
	/sbin/service amavisd restart
fi

##### end yaffas-security #####