#!/bin/bash
OS=$(perl -I /opt/yaffas/lib/perl5 -MYaffas::Constant -we 'print Yaffas::Constant::OS')
INSTALLLEVEL=1

##### yaffas-zarafa #####
if [ "$INSTALLLEVEL" = 1 ] ; then
    YAFFAS_EXAMPLE=/opt/yaffas/share/doc/example
    for CFG in /etc/zarafa/*.cfg; do
        cp -f $CFG ${CFG}.yaffassave
    done
    cp -f -a ${YAFFAS_EXAMPLE}/etc/zarafa/*.cfg /etc/zarafa
fi

LDAPHOSTNAME=`grep "BASEDN=" /etc/ldap.settings | cut -d= -f2-`

export PERLLIB="/opt/yaffas/lib/perl5"
perl -MYaffas::Module::ChangeLang -wle '
my $lang = Yaffas::Module::ChangeLang::get_lang();
Yaffas::Module::ChangeLang::set_lang($lang);
'
sed "s/LDAPHOSTNAME/$LDAPHOSTNAME/g" -i /etc/zarafa/ldap.yaffas.cfg
OURPASSWD=$(cat /etc/ldap.secret)
sed -e "s#--OURPASSWD--#$OURPASSWD#g" -i /etc/zarafa/ldap.yaffas.cfg

SSL_CONF=/etc/httpd/conf.d/ssl.conf
if [ -e $SSL_CONF ]; then
    sed -e 's#^SSLCertificateFile.*#SSLCertificateFile /opt/yaffas/etc/ssl/certs/zarafa-webaccess.crt#' -i $SSL_CONF
    sed -e 's#^SSLCertificateKeyFile.*#SSLCertificateKeyFile /opt/yaffas/etc/ssl/certs/zarafa-webaccess.key#' -i $SSL_CONF
fi

# optimize memory
if [ "$INSTALLLEVEL" = 1 ]; then
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
fi

if [ "$INSTALLLEVEL" = 1 ] ; then
    #only do this on install, not on upgrade
    zarafa-admin -s
fi

# install zarafa selinux module
if [ "$INSTALLLEVEL" = 1 ] ; then
    checkmodule -M -m -o /tmp/zarafa.mod /tmp/zarafa.te
    semodule_package -o /tmp/zarafa.pp -m /tmp/zarafa.mod
    semodule -i /tmp/zarafa.pp
fi
rm -f /tmp/zarafa.{pp,mod,te}

echo "1: " $INSTALLLEVEL

if [ "$INSTALLLEVEL" = 2 ]; then
    SERVERCFG="/etc/zarafa/server.cfg"
    if grep -q index_services_enabled $SERVERCFG; then
        sed -e 's/index_services_enabled/search_enabled/' -i $SERVERCFG
    fi

    if grep -q index_services_path $SERVERCFG; then
        sed -e '/index_services_path/d' -i $SERVERCFG
        echo "search_socket = file:///var/run/zarafa-search" >> $SERVERCFG
    fi
fi

/sbin/restorecon -R /etc/zarafa
/sbin/restorecon -R /var/lib/zarafa-webaccess
/sbin/restorecon -R /var/lib/zarafa

chkconfig zarafa-server on
service zarafa-server stop
/usr/bin/zarafa-server --ignore-attachment-storage-conflict
service zarafa-server restart

# enable services
for SERV in mysqld zarafa-gateway zarafa-ical zarafa-search zarafa-licensed zarafa-monitor zarafa-spooler zarafa-dagent; do
    chkconfig $SERV on
    service $SERV start
done

##### end yaffas-zarafa #####
