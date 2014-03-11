#!/bin/bash

if [ ! -f /var/lib/z-push/settings ]; then
	OS=$(perl -I /opt/yaffas/lib/perl5 -MYaffas::Constant -we 'print Yaffas::Constant::OS')

	if [[ $OS == RHEL* ]]; then
		service httpd restart
	else
		service apache2 restart
	fi
	cd /usr/share/z-push/tools
	/usr/bin/php ./migrate-2.0.x-2.1.0.php
fi
