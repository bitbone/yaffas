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
Requires:	yaffas-install-lib, yaffas-core, yaffas-module-mailsrv
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

	ZARAFA_ADMIN_USER=vmail
	POSTFIX_MASTER_CF=/etc/postfix/master.cf
	POSTFIX_TRANSPORT=/opt/yaffas/config/postfix/transport-deliver-to-public
	POSTFIX_LOCAL_ALIASES=/opt/yaffas/config/postfix/local-aliases.cf
	POSTFIX_PUBLIC_ALIASES=/opt/yaffas/config/postfix/public-folder-aliases.cf
	ZARAFA_SERVER_CFG=/etc/zarafa/server.cfg
	ZARAFA_DELIVER_TO_PUBLIC=/opt/yaffas/libexec/mailalias/zarafa-deliver-to-public
	POSTFIX_CONFIG_CHANGED=0

	# create our ZARAFA_ADMIN_USER if necessary
	getent passwd "${ZARAFA_ADMIN_USER}" >/dev/null || useradd --system --shell /bin/false "${ZARAFA_ADMIN_USER}"

	# create and configure transport_maps:
	mkdir -p "$(dirname "$POSTFIX_TRANSPORT")"
	touch "$POSTFIX_TRANSPORT"
	postmap "$POSTFIX_TRANSPORT"
	cur_transport_maps=$(postconf -h transport_maps)
	if ! echo "$cur_transport_maps" | grep -q hash:$POSTFIX_TRANSPORT; then
		POSTFIX_CONFIG_CHANGED=1
		if [[ -z "$cur_transport_maps" ]]; then
			# if transport_maps is empty, we add ourselves
			postconf -e transport_maps="hash:$POSTFIX_TRANSPORT"
		else
			# if transport_maps is non-empty, we append ourselves to
			# this list
			postconf -e transport_maps="$cur_transport_maps, hash:$POSTFIX_TRANSPORT"
		fi
	fi

	for alias_file in "$POSTFIX_LOCAL_ALIASES" "$POSTFIX_PUBLIC_ALIASES"; do
		mkdir -p "$(dirname "$alias_file")"
		touch "$alias_file"
		postmap "$alias_file"
		cur_aliases=$(postconf -h virtual_alias_maps)
		if ! echo "$cur_aliases" | grep -q hash:$alias_file; then
			POSTFIX_CONFIG_CHANGED=1
			if [[ -z "$cur_aliases" ]]; then
				# if virtual_alias_maps is empty, we add ourselves
				postconf -e virtual_alias_maps="hash:$alias_file"
			else
				# if transport_maps is non-empty, we append ourselves to
				# this list
				postconf -e virtual_alias_maps="$cur_aliases, hash:$alias_file"
			fi
		fi
	done

	SERVICE_NAME=zarafa-publicfolder
	# note: we could use postconf -M, but we have to support older
	# postfix versions which do not support this yet.

	# check for an existing service definition in master.cf
	if ! grep -qP '^[^#]*'${SERVICE_NAME}'\s+unix\s+' $POSTFIX_MASTER_CF; then
		POSTFIX_CONFIG_CHANGED=1
		# add a master.cf service entry:
		cat >> $POSTFIX_MASTER_CF <<EOT

${SERVICE_NAME} unix -	  n	  n	-	10	  pipe
	flags=DORu user=${ZARAFA_ADMIN_USER} argv=$ZARAFA_DELIVER_TO_PUBLIC \${nexthop}
EOT
		postconf -e ${SERVICE_NAME}_destination_recipient_limit=1
	fi

	# check if the ${ZARAFA_ADMIN_USER} user is allowed to act as zarafa admin:
	if ! grep -qP '^[^\r\n#]*local_admin_users\s*=(.*\s+)?'${ZARAFA_ADMIN_USER}'(\s+.*)$' "${ZARAFA_SERVER_CFG}"; then
		sed -re 's/(^[^\r\n#]*local_admin_users\s*=.*)/\1 '${ZARAFA_ADMIN_USER}'/' \
			-i "${ZARAFA_SERVER_CFG}"

		# if zarafa-server is running already (common when upgrading),
		# restart it:
		service zarafa-server status >/dev/null 2>&1 && \
			service zarafa-server restart
	fi

	[[ $POSTFIX_CONFIG_CHANGED ]] && postfix reload
fi

%files
%defattr(-,root,root)
%doc debian/{copyright,changelog}
/opt/yaffas/webmin/mailalias
/opt/yaffas/lib/perl5/Yaffas/Module/Mailalias.pm
/opt/yaffas/libexec/mailalias/zarafa-deliver-to-public
/opt/yaffas/libexec/mailalias/zarafa-public-folders

%changelog
