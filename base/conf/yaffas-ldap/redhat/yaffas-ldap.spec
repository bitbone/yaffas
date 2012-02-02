Name:		yaffas-ldap
Version:	0.9.0
Release:	1%{?dist}
Summary:	LDAP configuration for yaffas
Group:		Application/System
License:	AGPL
URL:		http://www.yaffas.orgg
Source0:	file://%{name}-%{version}.tar.gz
BuildRoot:	%(mktemp -ud %{_tmppath}/%{name}-%{version}-%{release}-XXXXXX)
BuildArch:	noarch
%{?el5:Requires: nscd, openldap-servers, openldap-clients, smbldap-tools, perl(Term::ReadKey), postfix, samba-common, expect, yaffas-certificates, nss_ldap}
%{?el6:Requires: nscd, openldap-servers, openldap-clients, smbldap-tools, perl(Term::ReadKey), postfix, samba-common, expect, yaffas-certificates, nss-pam-ldapd}

%description
Edits libnss-ldap.conf, pam-ldap.conf, nsswitch.conf

%build
make %{?_smp_mflags}

%install
rm -rf $RPM_BUILD_ROOT
make install DESTDIR=$RPM_BUILD_ROOT

%post
set -e

DOMAIN=$(hostname -d 2> /dev/null || echo "")

if [ -z "$DOMAIN" ]; then
    DOMAIN="yaffas.local"
fi

if ! echo $DOMAIN | grep -q "\."; then
    DOMAIN="$DOMAIN.local"
fi

echo "Using $DOMAIN for LDAP tree"

function _get_base() {
	ARRAY=(`echo ${DOMAIN} | cut -d. -f1- --output-delimiter=\ `)
	COUNT=${#ARRAY[*]}
	BASE=""
	ORG=""

	for i in `seq 1 $COUNT`
	do
		if [ $i -eq $COUNT ]; then
			BASE="${BASE}c=${ARRAY[$(($i-1))]}"
		elif [ $i -eq $(($COUNT-1)) ]; then
			BASE="${BASE}o=${ARRAY[$(($i-1))]},"
			ORG=${ARRAY[$(($i-1))]}
		else
			BASE="${BASE}ou=${ARRAY[$(($i-1))]},"
		fi
	done

	echo -n "$BASE"
}

function _get_org() {
	echo `echo $1 | sed -e 's/.*o=\(.*\),.*/\1/g'`
}

# some defines
CONF="/etc/ldap.conf"
NSS="/etc/nsswitch.conf"
SLAPD="/etc/openldap/slapd.conf"
LDAPS="/etc/ldap.secret"
LDIF="/tmp/yaffas_base.ldif"
DOMRENAME_FILE="/tmp/slapcat.ldif"
LDAPCONF="/etc/openldap/ldap.conf"
SMBLDAP_CONF="/etc/smbldap-tools/smbldap.conf"
SMBLDAP_BIND="/etc/smbldap-tools/smbldap_bind.conf"
LDAP_SETTINGS="/etc/ldap.settings"
SID=`net getlocalsid 2>/dev/null | awk '{print $NF}'`

# only on first installation, if no ldap tree is present
if [ "$1" = 1 ] ; then

	# create group which allows users to read from ldap
	groupadd -f -r ldapread

	# save existing config files and
	# copy our config files to default locations
	YAFFAS_EXAMPLE="/opt/yaffas/share/doc/example"
	for SAVEFILE in /etc/ldap.conf /etc/openldap/slapd.conf /etc/openldap/ldap.conf /etc/smbldap-tools/smbldap.conf /etc/smbldap-tools/smbldap_bind.conf; do
		if [ -e $SAVEFILE ]; then
			%{__mv} -f $SAVEFILE ${SAVEFILE}.yaffassave
		fi
	done
	%{__cp} -f ${YAFFAS_EXAMPLE}/etc/ldap.conf /etc
	%{__cp} -f ${YAFFAS_EXAMPLE}/etc/ldap.settings /etc
	%{__cp} -f -p ${YAFFAS_EXAMPLE}/etc/openldap/slapd.conf /etc/openldap
	%{__cp} -f ${YAFFAS_EXAMPLE}/etc/openldap/ldap.conf /etc/openldap
	%{__cp} -f ${YAFFAS_EXAMPLE}/etc/ldap.secret /etc
	%{__cp} -f ${YAFFAS_EXAMPLE}/etc/postfix/ldap-users.cf /etc/postfix
	%{__cp} -f ${YAFFAS_EXAMPLE}/etc/postfix/ldap-aliases.cf /etc/postfix
	%{__cp} -f ${YAFFAS_EXAMPLE}/etc/openldap/schema/samba.schema /etc/openldap/schema
	%{__cp} -f ${YAFFAS_EXAMPLE}/etc/openldap/schema/zarafa.schema /etc/openldap/schema
	%{__cp} -f ${YAFFAS_EXAMPLE}/etc/smbldap-tools/smbldap.conf /etc/smbldap-tools
	%{__cp} -f ${YAFFAS_EXAMPLE}/etc/smbldap-tools/smbldap_bind.conf /etc/smbldap-tools

%if 0%{?rhel} < 6
	service ldap stop
%endif
%if 0%{?rhel} >= 6
	service slapd stop
%endif
	sleep 1

	# kill ldap if it is still running
	if pgrep slapd; then
		killall -9 slapd
	fi

	BASE=`_get_base`
	ORG=`_get_org $BASE`

	sed -e "s#BASE#$BASE#" -i /etc/postfix/ldap-users.cf
	sed -e "s#BASE#$BASE#" -i /etc/postfix/ldap-aliases.cf

	echo "Using base $BASE ..."
	echo "Changing configfiles..."

	sed -e "s/BASE/$BASE/" -i $CONF
	sed -e "s/BASE/$BASE/" -i $SLAPD
	sed -e "s/BASE/$BASE/" -i $LDAPCONF
	sed -e "s/BASE/$BASE/" -i $SMBLDAP_CONF
	sed -e "s/NEWSID/$SID/" -i $SMBLDAP_CONF
	sed -e "s/BASE/$BASE/" -i $SMBLDAP_BIND


	echo "Removing old LDAP Database"
	rm -rf /var/lib/ldap/*

	echo "Executing domrename.pl ... $DOMAIN $LDIF"
	sed -e "s/NEWSID/$SID/" -i $LDIF
	/opt/yaffas/bin/domrename.pl BASE $DOMAIN $LDIF

#	if [ ! -f /var/lib/ldap/DB_CONFIG ]; then
#		cp /usr/share/slapd/DB_CONFIG /var/lib/ldap/
#	fi

	# import LDIF
	slapadd -v -l $DOMRENAME_FILE -f $SLAPD
	chown -R ldap:ldap /var/lib/ldap/
	rm -f $DOMRENAME_FILE
	rm $LDIF

	# generate password for LDAP
	OURPASSWD="$(mkpasswd -s 0)"

for MYFILE in /etc/openldap/ldap.conf /etc/ldap.secret /etc/postfix/ldap-users.cf /etc/postfix/ldap-aliases.cf /etc/ldap.conf /etc/smbldap-tools/smbldap_bind.conf; do
	sed -e "s/--OURPASSWD--/$OURPASSWD/" -i $MYFILE
done

	MYCRYPTPW=$(slappasswd -h {CRYPT} -s $OURPASSWD)
	sed -e "s#--MYCRYPTPW--#$MYCRYPTPW#" -i /etc/openldap/slapd.conf

	#write ldap.settings
	echo "BASEDN=$BASE" >$LDAP_SETTINGS
	echo "USERSEARCH=uid">>$LDAP_SETTINGS
	echo "BINDDN=cn=ldapadmin,ou=People,$BASE" >> $LDAP_SETTINGS
	echo "USER_SEARCHBASE=ou=People,$BASE" >> $LDAP_SETTINGS
	echo "LDAPSECRET=$OURPASSWD" >> $LDAP_SETTINGS
	echo "LDAPURI=ldap://127.0.0.1" >> $LDAP_SETTINGS
	echo "EMAIL=mail" >> $LDAP_SETTINGS

	# set listening options
	DEFAULT="/etc/sysconfig/ldap"
	sed 's/.*SLAPD_LDAP\s*=.*/SLAPD_LDAP=\"yes\"/' -i $DEFAULT
	sed 's/.*SLAPD_LDAPS\s*=.*/SLAPD_LDAPS=\"yes\"/' -i $DEFAULT
	sed 's/.*SLAPD_LDAPI\s*=.*/SLAPD_LDAPI=\"yes\"/' -i $DEFAULT
	mkdir -p /opt/yaffas/config/
	echo "method=ldap" > /opt/yaffas/config/alias.cfg

	if [ ! -f /var/lib/ldap/DB_CONFIG ]; then
		if [ -f /etc/openldap/DB_CONFIG.example ]; then
			cp /etc/openldap/DB_CONFIG.example /var/lib/ldap/DB_CONFIG
			chown ldap:ldap /var/lib/ldap/DB_CONFIG
		fi
	fi

else
	# this is an update :)

	if ! grep "^tls_checkpeer" $CONF > /dev/null; then
		echo "tls_checkpeer no" >> $CONF
	fi

	if ! grep zarafa.schema $SLAPD &>/dev/null; then
		sed 's|include[[:space:]]\+/etc/openldap/schema/samba.schema|include\t/etc/openldap/schema/samba.schema\ninclude /etc/openldap/schema/zarafa.schema|' -i $SLAPD
	fi

fi

# fix permissions
chmod 440 $CONF
chmod 640 $LDAPS
chown root:ldapread $CONF
chown root:ldapread $LDAPS

rm -f $LDIF

# enabled ldap service
%if 0%{?rhel} < 6
chkconfig ldap on
%endif
%if 0%{?rhel} >= 6
chkconfig slapd on
%endif

%postun
if [ $1 -eq 0 ]; then
	for SAVEFILE in /etc/ldap.conf.yaffassave /etc/openldap/slapd.conf.yaffassave /etc/openldap/ldap.conf.yaffassave /etc/smbldap-tools/smbldap.conf.yaffassave /etc/smbldap-tools/smbldap_bind.conf.yaffassave; do
		if [ -e $SAVEFILE ]; then
			%{__mv} -f $SAVEFILE ${SAVEFILE/.yaffassave/}
		fi
	done
	%{__rm} -f /etc/ldap.settings
	%{__rm} -f /etc/ldap.secret
	%{__rm} -f /etc/postfix/ldap-users.cf
	%{__rm} -f /etc/postfix/ldap-aliases.cf
fi

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root,-)
%doc debian/{changelog,copyright}
%config /opt/yaffas/share/doc/example/etc/ldap.conf
%config /opt/yaffas/share/doc/example/etc/ldap.secret
%config /opt/yaffas/share/doc/example/etc/ldap.settings
%config /opt/yaffas/share/doc/example/etc/openldap/ldap.conf
/opt/yaffas/share/doc/example/etc/openldap/schema/samba.schema
/opt/yaffas/share/doc/example/etc/openldap/schema/zarafa.schema
%config %attr(640,root,ldap) /opt/yaffas/share/doc/example/etc/openldap/slapd.conf
%config /opt/yaffas/share/doc/example/etc/nsswitch.conf
%config /opt/yaffas/share/doc/example/etc/postfix/ldap-aliases.cf
%config /opt/yaffas/share/doc/example/etc/postfix/ldap-users.cf
%config /opt/yaffas/share/doc/example/etc/smbldap-tools/smbldap.conf
%config /opt/yaffas/share/doc/example/etc/smbldap-tools/smbldap_bind.conf
%config %attr(750,root,root) /opt/yaffas/bin/domrename.pl
/tmp/yaffas_base.ldif

%changelog
