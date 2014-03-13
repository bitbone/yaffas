Summary:	Yaffas module for alias configuration
Name:		yaffas-module-mailalias
Version:	1.0.0
Release:	1
License:	AGPLv3
Url:		http://www.yaffas.org
Group:		Applications/System
Source:		file://%{name}-%{version}.tar.gz
BuildArch:	noarch
BuildRoot:	%{_tmppath}/%{name}-%{version}-%{release}-buildroot
Requires:	yaffas-install-lib, yaffas-core
AutoReqProv: no

%description
Yaffas module for mail alias configuration.

%build
make %{?_smp_mflags}

%install
%{__rm} -rf $RPM_BUILD_ROOT
make install DESTDIR=$RPM_BUILD_ROOT

%clean
%{__rm} -rf $RPM_BUILD_ROOT

%post
set -e
source /opt/yaffas/lib/bbinstall-lib.sh
MODULE=mailalias
add_webmin_acl $MODULE

%postun
if [ "$1" = "0" ]; then
	set -e
	source /opt/yaffas/lib/bbinstall-lib.sh
	MODULE=mailalias
	del_webmin_acl $MODULE

	# create and configure transport_maps:
	POSTFIX_TRANSPORT=/opt/yaffas/config/postfix/transport-deliver-to-public
	POSTFIX_MASTER_CF=/etc/postfix/master.cf
	ZARAFA_DELIVER_TO_PUBLIC=/opt/yaffas/libexec/mailalias/zarafa-deliver-to-public
	mkdir -p "$(dirname "$POSTFIX_TRANSPORT")"
	touch "$POSTFIX_TRANSPORT"
	postmap "$POSTFIX_TRANSPORT"
	cur_transport_maps=$(postconf -h transport_maps)
	if ! echo "$cur_transport_maps" | grep -q hash:$POSTFIX_TRANSPORT; then
		if [[ -z "$cur_transport_maps" ]]; then
			# if transport_maps is empty, we add ourselves
			postconf -e transport_maps="hash:$POSTFIX_TRANSPORT"
		else
			# if transport_maps is non-empty, we append ourselves to
			# this list
			postconf -e transport_maps="$cur_transport_maps, hash:$POSTFIX_TRANSPORT"
		fi
	fi

	SERVICE_NAME=zarafa-publicfolder
	# note: we could use postconf -M, but we have to support older
	# postfix versions which do not support this yet.

	# check for an existing service definition in master.cf
	if ! grep -qP '^[^#]*'${SERVICE_NAME}'\s+unix\s+' $POSTFIX_MASTER_CF; then
		# add a master.cf service entry:
		cat >> $POSTFIX_MASTER_CF <<EOT

${SERVICE_NAME} unix -	  n	  n	-	10	  pipe
	flags=DORu user=vmail argv=$ZARAFA_DELIVER_TO_PUBLIC \${nexthop}
EOT
		postconf -e ${SERVICE_NAME}_destination_recipient_limit=1
	fi

fi

%files
%defattr(-,root,root)
%doc debian/{copyright,changelog}
/opt/yaffas/webmin/mailalias
/opt/yaffas/lib/perl5/Yaffas/Module/Mailalias.pm
/opt/yaffas/libexec/mailalias/zarafa-deliver-to-public
/opt/yaffas/libexec/mailalias/zarafa-public-folders

%changelog
