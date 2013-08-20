#!/bin/bash

TABLE=hash:/opt/yaffas/config/postfix/transport-deliver-to-public
ALIAS=hash:/opt/yaffas/config/postfix/public-folder-aliases.cf

if ! postconf transport_maps | grep -qF "$TABLE"; then
	MAPS=$(postconf -h transport_maps)
	if [[ $MAPS ]]; then
		MAPS="$MAPS, $TABLE"
	else
		MAPS="$TABLE"
	fi
	postconf -e transport_maps="$MAPS"
fi

if ! postconf virtual_alias_maps | grep -qF "$ALIAS"; then
	MAPS=$(postconf -h virtual_alias_maps)
	if [[ $MAPS ]]; then
		MAPS="$MAPS, $ALIAS"
	else
		MAPS="$ALIAS"
	fi
	postconf -e virtual_alias_maps="$MAPS"
fi

postconf -e zarafa-publicfolder_destination_recipient_limit=1

touch $YAFFAS_CONF/transport-deliver-to-public
postmap $YAFFAS_CONF/transport-deliver-to-public

touch $YAFFAS_CONF/public-folder-aliases.cf
postmap $YAFFAS_CONF/public-folder-aliases.cf

[[ $(postconf -Mf zarafa-publicfolder.unix) ]] && exit 0

cat >>/etc/postfix/master.cf <<EOT
zarafa-publicfolder unix - n     n       -       10      pipe
    flags=DORu user=vmail
    argv=/opt/yaffas/libexec/mailalias/zarafa-deliver-to-public ${nexthop}
EOT

/etc/init.d/postfix reload
