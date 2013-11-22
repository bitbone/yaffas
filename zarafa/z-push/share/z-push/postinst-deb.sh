#!/bin/bash
OS=$(perl -I /opt/yaffas/lib/perl5 -MYaffas::Constant -we 'print Yaffas::Constant::OS')

set -e

mkdir -p /var/lib/z-push/
mkdir -p /var/log/z-push/
chown www-data:www-data /var/lib/z-push/ /var/log/z-push/

ln -sf /usr/share/z-push/z-push-admin.php /usr/bin/z-push-admin
ln -sf /usr/share/z-push/z-push-top.php /usr/bin/z-push-top

if grep -q "/var/www/z-push/index.php" /etc/apache2/sites-available/zarafa-webaccess-ssl; then
    sed -e 's#Alias /Microsoft-Server-ActiveSync.*#Alias /Microsoft-Server-ActiveSync /usr/share/z-push/index.php#' -i /etc/apache2/sites-available/zarafa-webaccess-ssl
    service apache2 reload
fi

if [ ! -f /var/lib/z-push/settings ]; then
    service apache2 restart

    pushd /usr/share/z-push/tools
    /usr/bin/php ./migrate-2.0.x-2.1.0.php
    popd
fi

exit 0


