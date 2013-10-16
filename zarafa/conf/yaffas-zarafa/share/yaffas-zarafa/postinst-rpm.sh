#!/bin/bash
OS=$(perl -I /opt/yaffas/lib/perl5 -MYaffas::Constant -we 'print Yaffas::Constant::OS')

##### yaffas-zarafa #####
YAFFAS_EXAMPLE=/opt/yaffas/share/doc/example
for CFG in /etc/zarafa/*.cfg; do
    cp -f $CFG ${CFG}.yaffassave
done
cp -f -a ${YAFFAS_EXAMPLE}/etc/zarafa/*.cfg /etc/zarafa

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
/sbin/restorecon -R /var/lib/zarafa-webapp
/sbin/restorecon -R /var/lib/zarafa

# WebApp 1.3 and later default to connecting to http://localhost:236
# instead of using the unix socket /var/run/zarafa (ADM-321)
setsebool httpd_can_network_connect=1

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
