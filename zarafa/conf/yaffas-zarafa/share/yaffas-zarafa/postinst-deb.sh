#!/bin/bash
OS=$(perl -I /opt/yaffas/lib/perl5 -MYaffas::Constant -we 'print Yaffas::Constant::OS')
if [ -n $1 ]; then
	INSTALLLEVEL=$1
else 
	INSTALLLEVEL=1
fi

set -e

	if [ "$INSTALLLEVEL" = 1 ] ; then
		YAFFAS_EXAMPLE=/opt/yaffas/share/doc/example
		for CFG in /etc/zarafa/*.cfg; do
			cp -f $CFG ${CFG}.yaffassave
		done
		cp -f -a ${YAFFAS_EXAMPLE}/etc/zarafa/*.cfg /etc/zarafa
		if [ -e /etc/apache2/sites-available/zarafa-webaccess-ssl ]; then
			mv -f /etc/apache2/sites-available/zarafa-webaccess-ssl /etc/apache2/sites-available/zarafa-webaccess-ssl.yaffassave
		fi
		cp -f ${YAFFAS_EXAMPLE}/etc/apache2/sites-available/zarafa-webaccess-ssl /etc/apache2/sites-available
	fi

	PHPINI=/etc/php5/apache2/php.ini
	PHPCLIINI=/etc/php5/cli/php.ini
	LDAPHOSTNAME=`grep "BASEDN=" /etc/ldap.settings | cut -d= -f2-`
	LIC="/etc/zarafa/license/base"
	chmod 600 /etc/zarafa/server.cfg
	chmod 600 /etc/zarafa/ldap.cfg
	chmod 600 /etc/zarafa/ldap.yaffas.cfg
	#necessary if zarafa installed after first installation

    if [ -f "/etc/locale.gen" ]; then
        if ! grep -q "^en_US.UTF-8" /etc/locale.gen; then
            echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
        fi
    fi

    echo "zarafa=Zarafa v7.0.1" > /opt/yaffas/etc/installed-products

	/usr/sbin/locale-gen
	export PERLLIB="/opt/yaffas/lib/perl5"
	perl -MYaffas::Module::ChangeLang -wle '
	my $lang = Yaffas::Module::ChangeLang::get_lang();
	Yaffas::Module::ChangeLang::set_lang($lang);
	'

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
	sed "s/LDAPHOSTNAME/$LDAPHOSTNAME/g" -i /etc/zarafa/ldap.yaffas.cfg
	OURPASSWD=$(cat /etc/ldap.secret)
	sed -e "s#--OURPASSWD--#$OURPASSWD#g" -i /etc/zarafa/ldap.yaffas.cfg

	#if ! grep "Listen.*443" /etc/apache2/ports.conf &>/dev/null; then
	#	echo "Listen 443" >> /etc/apache2/ports.conf
	#fi

    if [ -f /etc/default/zarafa-dagent ]; then
        sed -e 's/DAGENT_ENABLED=no/DAGENT_ENABLED=yes/' -i /etc/default/zarafa-dagent
    fi

    # In Zarafa 7 this option is merged into a global config file
    if [ -f /etc/default/zarafa ]; then
        sed -e 's/DAGENT_ENABLED=no/DAGENT_ENABLED=yes/' -i /etc/default/zarafa
    fi

	# optimize memory

	if [ "$INSTALLLEVEL" = 1 ] ; then
		# only on a fresh installation
		MEM=$(cat /proc/meminfo | awk '/MemTotal:/ { printf "%d", $2*1024 }')

		LOGMEM=$(($MEM/16))

		if [ $LOGMEM -gt $((1024*1024*1024)) ]; then
			LOGMEM="1024M"
		fi

		MEM=$(($MEM/4))

		if [ -d /etc/mysql/conf.d ]; then
			echo -e "[mysqld]\ninnodb_buffer_pool_size = $MEM\ninnodb_log_file_size = $LOGMEM\ninnodb_log_buffer_size = 32M" > /etc/mysql/conf.d/zarafa-innodb.cnf
		else
			echo -e "[mysqld]\ninnodb_buffer_pool_size = $MEM\ninnodb_log_file_size = $LOGMEM\ninnodb_log_buffer_size = 32M" >> /etc/mysql/my.cnf
		fi
		rm -f /data/db/mysql/ib_logfile* /var/lib/mysql/ib_logfile*
		sed -e 's/^cache_cell_size.*/cache_cell_size = '$MEM'/' -i /etc/zarafa/server.cfg

		if [ "$(lsb_release -sr)" != "12.04" ]; then
			if uname -m | grep -q "x86_64"; then
				sed -e 's#^plugin_path\s*=.*#plugin_path=/usr/lib64/zarafa#' -i /etc/zarafa/server.cfg
			else
				sed -e 's#^plugin_path\s*=.*#plugin_path=/usr/lib/zarafa#' -i /etc/zarafa/server.cfg
			fi
		fi

		mkdir -p /data/zarafa/attachments/
	fi

    if [ "$INSTALLLEVEL" = 2 ] ; then
        SERVERCFG="/etc/zarafa/server.cfg"
        if grep -q index_services_enabled $SERVERCFG; then
            sed -e 's/index_services_enabled/search_enabled/' -i $SERVERCFG
        fi

        if grep -q index_services_path $SERVERCFG; then
            sed -e '/index_services_path/d' -i $SERVERCFG
            echo "search_socket = file:///var/run/zarafa-search" >> $SERVERCFG
        fi
    fi

	rm -f /tmp/zarafa.te

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

exit 0


