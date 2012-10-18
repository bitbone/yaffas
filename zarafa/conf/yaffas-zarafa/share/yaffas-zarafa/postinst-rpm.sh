#!/bin/bash
OS=$(perl -I /opt/yaffas/lib/perl5 -MYaffas::Constant -we 'print Yaffas::Constant::OS')

##### yaffas-zarafa #####
YAFFAS_EXAMPLE=/opt/yaffas/share/doc/example
for CFG in /etc/zarafa/*.cfg; do
    cp -f $CFG ${CFG}.yaffassave
done
cp -f -a ${YAFFAS_EXAMPLE}/etc/zarafa/*.cfg /etc/zarafa

LDAPHOSTNAME=`grep "BASEDN=" /etc/ldap.settings | cut -d= -f2-`

if [ x$OS = xDebian -o x$OS = xUbuntu ]; then
	if [ -f "/etc/locale.gen" ]; then
	    if ! grep -q "^en_US.UTF-8" /etc/locale.gen; then
	        echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
	    fi
	fi
	
	if ! grep ldap.so $PHPINI; then
		echo "extension = ldap.so" >> $PHPINI
	fi
	if ! grep mapi.so $PHPINI; then
		echo "extension = mapi.so" >> $PHPINI
	fi
	if ! grep mapi.so $PHPCLIINI; then
		echo "extension = mapi.so" >> $PHPCLIINI
	fi
	sed 's/^magic_quotes_gpc[[:space:]]*=.*/magic_quotes_gpc = Off/' -i $PHPINI
	sed 's/^memory_limit[[:space:]]*=[[:space:]]*16M/memory_limit = 64M/' -i $PHPINI

	a2enmod proxy
	a2enmod ssl
	a2enmod proxy_http
	a2ensite zarafa-webaccess-ssl
fi

export PERLLIB="/opt/yaffas/lib/perl5"
perl -MYaffas::Module::ChangeLang -wle '
my $lang = Yaffas::Module::ChangeLang::get_lang();
Yaffas::Module::ChangeLang::set_lang($lang);
'
sed "s/LDAPHOSTNAME/$LDAPHOSTNAME/g" -i /etc/zarafa/ldap.yaffas.cfg
OURPASSWD=$(cat /etc/ldap.secret)
sed -e "s#--OURPASSWD--#$OURPASSWD#g" -i /etc/zarafa/ldap.yaffas.cfg

if [ x$OS = xRHEL5 -o x$OS = xRHEL6]; then
	SSL_CONF=/etc/httpd/conf.d/ssl.conf
	if [ -e $SSL_CONF ]; then
	    sed -e 's#^SSLCertificateFile.*#SSLCertificateFile /opt/yaffas/etc/ssl/certs/zarafa-webaccess.crt#' -i $SSL_CONF
	    sed -e 's#^SSLCertificateKeyFile.*#SSLCertificateKeyFile /opt/yaffas/etc/ssl/certs/zarafa-webaccess.key#' -i $SSL_CONF
	fi
fi

if [ x$OS = xDebian -o x$OS = xUbuntu ]; then
	if [ -f /etc/default/zarafa-dagent ]; then
        sed -e 's/DAGENT_ENABLED=no/DAGENT_ENABLED=yes/' -i /etc/default/zarafa-dagent
    fi

    # In Zarafa 7 this option is merged into a global config file
    if [ -f /etc/default/zarafa ]; then
        sed -e 's/DAGENT_ENABLED=no/DAGENT_ENABLED=yes/' -i /etc/default/zarafa
    fi
fi

# optimize memory
# only on a fresh installation
MEM=$(cat /proc/meminfo | awk '/MemTotal:/ { printf "%d", $2*1024 }')

LOGMEM=$(($MEM/16))

if [ $LOGMEM -gt $((1024*1024*1024)) ]; then
    LOGMEM="1024M"
fi

MEM=$(($MEM/4))

echo -e "[mysqld]\ninnodb_buffer_pool_size = $MEM\ninnodb_log_file_size = $LOGMEM\ninnodb_log_buffer_size = 32M" >> /etc/my.cnf

rm -f /data/db/mysql/ib_logfile* /var/lib/mysql/ib_logfile*
sed -e 's/^cache_cell_size.*/cache_cell_size = '$MEM'/' -i /etc/zarafa/server.cfg

# fix plugin path
if [ "x86_64" = $(rpm -q --qf %{ARCH} zarafa-server) ]; then
    sed -e 's#plugin_path\s*=.*#plugin_path=/usr/lib64/zarafa#' -i /etc/zarafa/server.cfg
fi
 
mkdir -p /data/zarafa/attachments/

#only do this on install, not on upgrade
zarafa-admin -s

# install zarafa selinux module
checkmodule -M -m -o /tmp/zarafa.mod /tmp/zarafa.te
semodule_package -o /tmp/zarafa.pp -m /tmp/zarafa.mod
semodule -i /tmp/zarafa.pp
rm -f /tmp/zarafa.{pp,mod,te}

/sbin/restorecon -R /etc/zarafa
/sbin/restorecon -R /var/lib/zarafa-webaccess
/sbin/restorecon -R /var/lib/zarafa

if [ x$OS = xDebian -o x$OS = xUbuntu ]; then
	#EVIL!!
	set +e
	/etc/init.d/mysql start
	/etc/init.d/slapd start
    if [ -z "$2" ]; then
        /etc/init.d/zarafa-server stop
        /usr/bin/zarafa-server --ignore-attachment-storage-conflict
        /etc/init.d/zarafa-server stop
        if pgrep zarafa-server > /dev/null; then
            killall zarafa-server
            sleep 20
            killall -9 zarafa-server
        fi
        /etc/init.d/zarafa-server start
        #only do this on install, not on upgrade
        zarafa-admin -s
    else
        /etc/init.d/zarafa-server restart
    fi

	/etc/init.d/zarafa-dagent restart
	/etc/init.d/apache2 restart
fi

##### end yaffas-zarafa #####
