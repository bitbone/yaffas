#!/bin/bash
OS=$(perl -I /opt/yaffas/lib/perl5 -MYaffas::Constant -we 'print Yaffas::Constant::OS')
OSVER=$(perl -I /opt/yaffas/lib/perl5 -MYaffas::Constant -we 'print Yaffas::Constant::OSVER')

set -e

YAFFAS_EXAMPLE=/opt/yaffas/share/doc/example
for CFG in /etc/zarafa/*.cfg; do
	cp -f $CFG ${CFG}.yaffassave
done
cp -f -a ${YAFFAS_EXAMPLE}/etc/zarafa/*.cfg /etc/zarafa
if [ -e /etc/apache2/sites-available/zarafa-webaccess-ssl ]; then
	mv -f /etc/apache2/sites-available/zarafa-webaccess-ssl /etc/apache2/sites-available/zarafa-webaccess-ssl.yaffassave
fi
cp -f ${YAFFAS_EXAMPLE}/etc/apache2/sites-available/zarafa-webaccess-ssl /etc/apache2/sites-available

if [[ $OS == "Ubuntu" && $OSVER != "10.04" && $OSVER != "12.04" ]]; then
	# Ubuntu >=14.04 only recognizes .conf files
	# zarafa-webaccess (non-ssl) has been fixed by Zarafa as of ZCP-7.1.13
	pushd /etc/apache2/sites-available >/dev/null
	for conf in zarafa-webaccess-ssl; do
		ln -s "${conf}" "${conf}.conf"
	done
	popd >/dev/null
fi

have_default_index() {
	local FILE=/var/www/index
	[[ -e "${FILE}.php" ]] && return 1
	[[ ! -e "${FILE}.html" ]] && return 0
	grep -qF 'The web server software is running but no content has been added, yet.' "${FILE}.html" && return 0
	return 1
}

if have_default_index; then
	[[ -e /var/www/index.html ]] && mv -f /var/www/index.html /var/www/index.html.yaffassave
	cp ${YAFFAS_EXAMPLE}/var/www/index.html /var/www/index.html
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

/usr/sbin/locale-gen
export PERLLIB="/opt/yaffas/lib/perl5"
perl -MYaffas::Module::ChangeLang -wle '
my $lang = Yaffas::Module::ChangeLang::get_lang();
Yaffas::Module::ChangeLang::set_lang($lang);
'

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

if [[ "$(lsb_release -sr)" == "10.04" || "$(lsb_release -sr)" == 6.* ]]; then
	if uname -m | grep -q "x86_64"; then
		sed -e 's#^plugin_path\s*=.*#plugin_path=/usr/lib64/zarafa#' -i /etc/zarafa/server.cfg
	else
		sed -e 's#^plugin_path\s*=.*#plugin_path=/usr/lib/zarafa#' -i /etc/zarafa/server.cfg
	fi
fi

mkdir -p /data/zarafa/attachments/

rm -f /tmp/zarafa.te

#EVIL!!
set +e
/etc/init.d/mysql start
/etc/init.d/slapd start
/etc/init.d/zarafa-server stop
zarafa-server --ignore-attachment-storage-conflict
/etc/init.d/zarafa-server stop
if pgrep zarafa-server > /dev/null; then
    killall zarafa-server
    sleep 20
    killall -9 zarafa-server
fi
/etc/init.d/zarafa-server start
#only do this on install, not on upgrade
zarafa-admin -s

/etc/init.d/zarafa-monitor restart
/etc/init.d/zarafa-dagent restart
/etc/init.d/apache2 restart

# Work around for ZCP-13222 (apache2ctl graceful crashes apache with
# ZCP-7.1.12's php-mapi);
# can be removed once a newer release than ZCP 7.1.12 gets included
touch /etc/zarafa/php-mapi.cfg

MAPI_LOG=/var/log/zarafa/php-mapi.log
chown :www-data "$MAPI_LOG"
chmod 660 "$MAPI_LOG"

exit 0
