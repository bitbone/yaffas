#!/bin/bash
OS=$(perl -I /opt/yaffas/lib/perl5 -MYaffas::Constant -we 'print Yaffas::Constant::OS')

mkdir -p /var/lib/z-push/
mkdir -p /var/log/z-push/

chown apache:apache /var/lib/z-push/ /var/log/z-push/
chcon -R -t httpd_sys_content_t /var/lib/z-push/ /var/log/z-push/

ln -sf /usr/share/z-push/z-push-admin.php /usr/bin/z-push-admin
ln -sf /usr/share/z-push/z-push-top.php /usr/bin/z-push-top

HTTPD_CONF=/etc/httpd/conf/httpd.conf
if ( ! grep -q "^Alias /Microsoft-Server-ActiveSync" $HTTPD_CONF ); then
	echo -e "\nAlias /Microsoft-Server-ActiveSync /usr/share/z-push/index.php" >> $HTTPD_CONF
fi

if grep -q "/var/www/z-push/index.php" $HTTPD_CONF; then
    sed -e "s#Alias /Microsoft-Server-ActiveSync.*#Alias /Microsoft-Server-ActiveSync /usr/share/z-push/index.php#" -i $HTTPD_CONF
fi

service httpd restart
