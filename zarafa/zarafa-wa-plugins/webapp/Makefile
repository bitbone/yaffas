
po: passwd/lang/de_DE.UTF-8/LC_MESSAGES/plugin_passwd.po

mo: passwd/lang/de_DE.UTF-8/LC_MESSAGES/plugin_passwd.mo

passwd/lang/de_DE.UTF-8/LC_MESSAGES/plugin_passwd.po: passwd/js/passwd.js passwd/php/pwdchange.php
	xgettext --keyword=_ --keyword=_W --keyword=_TT -j -L Python --keyword=dgettext:2 --keyword=ngettext:1,2 --keyword=dngettext:2,3 --keyword=pgettext:1c,2 --keyword=dpgettext:2c,3 --keyword=npgettext:1c,2,3 --keyword=dnpgettext:2c,3,4 --add-comments=TRANSLATORS --from-code iso-8859-15 -o passwd/lang/de_DE.UTF-8/LC_MESSAGES/plugin_passwd.po passwd/js/passwd.js passwd/php/pwdchange.php

passwd/lang/de_DE.UTF-8/LC_MESSAGES/plugin_passwd.mo: passwd/lang/de_DE.UTF-8/LC_MESSAGES/plugin_passwd.po
	msgfmt passwd/lang/de_DE.UTF-8/LC_MESSAGES/plugin_passwd.po -o passwd/lang/de_DE.UTF-8/LC_MESSAGES/plugin_passwd.mo
