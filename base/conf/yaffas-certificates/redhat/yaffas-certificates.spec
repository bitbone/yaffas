Summary: Default yaffas certificates
Name: yaffas-certificates
Version: 1.2.1
Release: 2
License: Commercial
Url: http://www.yaffas.org
Group: Applications/System
Source: file://%{name}-%{version}.tar.gz
BuildArch: noarch
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-buildroot
Requires: yaffas-install-lib, yaffas-module-certificate

%description
Default yaffas certificates

%build
make %{?_smp_mflags}

%install
%{__rm} -rf $RPM_BUILD_ROOT
make install DESTDIR=$RPM_BUILD_ROOT

%clean
%{__rm} -rf $RPM_BUILD_ROOT

%pre
if [ -f /opt/yaffas/etc/ssl/certs/org/default.crt ]; then
    cp /opt/yaffas/etc/ssl/certs/org/default.* /opt/yaffas/var/
fi

%post
YAFFAS_EXAMPLE="/opt/yaffas/share/doc/example"
CERTDIR="/opt/yaffas/etc/ssl/certs/"
PERL5LIB=/opt/yaffas/lib/perl5/

mkdir -p ${CERTDIR}/org/

if [ -f /opt/yaffas/var/default.crt ]; then
    cp /opt/yaffas/var/default.* ${CERTDIR}/org/
fi

if [ $1 -eq 1 ]; then
	# first install => generate a default certificate
	set -e
	perl -MYaffas::Module::Certificate -e '
		Yaffas::Module::Certificate::create_certificate({
			service => "all",
			o => "Default organization",
			ou => "IT",
			cn => "localhost",
			l => "Default",
			c => "DT",
			st => "Default",
			emailAddress => "root@localhost",
			keysize => 2048,
			days => 10*365
		});'
fi

%postun
if [ $1 -eq 0 ]; then
	set -e
	CERTDIR="/opt/yaffas/etc/ssl/certs/"
	CERTS="exim webmin cyrus usermin ldap zarafa-webaccess zarafa-server zarafa-gateway zarafa-ical mppserver"
	for i in $CERTS; do
		rm -f $CERTDIR/$i{,.key,.crt}
	done
	[ `find $CERTDIR -type f` ] || rm -Rf $CERTDIR # FIXME
	PRODUCTS="webmin usermin"
	for PRODUCT in $PRODUCTS; do
		CONF="/opt/yaffas/etc/$PRODUCT/miniserv.conf"
		TMPCONF="/tmp/miniserv.conf"
		if [ -r $CONF ]; then
			echo "Editing $PRODUCT"
			KC="key cert"
			for BBKC in $KC; do
				if [ "$BBKC" = "cert" ]; then
					FILEEXTENSION="crt";
				else
					FILEEXTENSION="key";
				fi
				if grep -q "^${BBKC}file" $CONF; then
					sed -e "s/^${BBKC}file=.*/${BBKC}file=\/opt\/yaffas\/etc\/ssl\/certs\/$PRODUCT.${FILEEXTENSION}/" $CONF > $TMPCONF
					# FIXME ^
					rm -f $CONF
					mv -f $TMPCONF $CONF
					chmod 600 $CONF
				else
					echo "${BBKC}file=/opt/yaffas/etc/ssl/certs/$PRODUCT.${FILEEXTENSION}" >> $CONF
					# FIXME ^ (alte config wiederherstellen)
				fi
			done
		fi
	done
	rmdir --ignore-fail-on-non-empty /opt/yaffas/etc/ssl
fi

%files
%defattr(-,root,root)
%doc debian/{copyright,changelog}

%changelog
