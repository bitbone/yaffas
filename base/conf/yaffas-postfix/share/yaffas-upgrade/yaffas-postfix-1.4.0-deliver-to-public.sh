#!/bin/bash

TABLE=hash:/opt/yaffas/config/postfix/transport-deliver-to-public

if ! postconf transport_maps | grep -qF "$TABLE"; then
	MAPS=$(postconf -h transport_maps)
	if [[ $MAPS ]]; then
		MAPS="$MAPS, $TABLE"
	else
		MAPS="$TABLE"
	fi
	postconf -e transport_maps="$MAPS"
fi

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
