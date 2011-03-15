Summary: Default bitkit certificates
Name: yaffas-certificates
Version: 1.2.1
Release: 2
License: Commercial
Url: http://www.bitkit.com
Group: Applications/System
Source: file://%{name}-%{version}.tar.gz
BuildArch: noarch
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-buildroot
Requires: yaffas-install-lib

%description
Default bitkit certificates

%build
make %{?_smp_mflags}

%install
%{__rm} -rf $RPM_BUILD_ROOT
make install DESTDIR=$RPM_BUILD_ROOT

%clean
%{__rm} -rf $RPM_BUILD_ROOT

%post
set -e
CERTDIR="/opt/yaffas/etc/ssl/certs/"
CERTS="exim webmin cyrus usermin ldap zarafa-webaccess zarafa-server zarafa-gateway zarafa-ical mppserver"
for i in $CERTS; do
	ln -sf $CERTDIR/org/default.key $CERTDIR/$i.key
	ln -sf $CERTDIR/org/default.crt $CERTDIR/$i.crt
	cat $CERTDIR/org/default.crt $CERTDIR/org/default.key > $CERTDIR/$i
done
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
				rm -f $CONF
				mv -f $TMPCONF $CONF
				chmod 600 $CONF
			else
				echo "${BBKC}file=/opt/yaffas/etc/ssl/certs/$PRODUCT.${FILEEXTENSION}" >> $CONF
			fi
		done
	fi
done

%postun
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

%files
%defattr(-,root,root)
%doc debian/{copyright,changelog}
/opt/yaffas/etc/ssl

%changelog
