WEBMIN_ACL_FILE="/opt/yaffas/etc/webmin/webmin.acl-global"
WEBMIN_MODULE_CACHE="/opt/yaffas/etc/webmin/module.infos.cache"
USERMIN_ACL_FILE="/opt/yaffas/etc/usermin/webmin.acl"
USERMIN_MODULE_CACHE="/opt/yaffas/etc/usermin/module.infos.cache"

export PERLLIB="/opt/yaffas/lib/perl5"

if [ "$PRODUCT" == "" ]; then
	PRODUCT="webmin"
fi

function const_file() {
	perl -MYaffas::Constant -e "print Yaffas::Constant::FILE()->{$1}"
}

function add_usermin_acl() {
	local MODULE=$1
	if [ -f $USERMIN_ACL_FILE ] && [ ! "`grep $MODULE $USERMIN_ACL_FILE`" ]; then
		sed -e "s/\$/ $MODULE/" -i $USERMIN_ACL_FILE
	fi
	rm -f $USERMIN_MODULE_CACHE
}

function del_usermin_acl() {
	local MODULE=$1

	if [ -f $USERMIN_ACL_FILE ]; then
		sed -e "s/$MODULE//" -i $USERMIN_ACL_FILE
		rm -f $USERMIN_MODULE_CHACHE
	fi
}

function add_webmin_acl() {
	local MODULE=$1
	if [ ! "`grep $MODULE $WEBMIN_ACL_FILE`" ]; then
		sed -e "s/\$/ $MODULE/" -i $WEBMIN_ACL_FILE
	fi
	rm -f $WEBMIN_MODULE_CACHE
}

function del_webmin_acl() {
	local MODULE=$1
	if [ -f $WEBMIN_ACL_FILE ]; then
		sed -e "s/$MODULE//" -i $WEBMIN_ACL_FILE
	fi
	rm -f $WEBMIN_MODULE_CHACHE
}

function add_license() {
	local MODULE="/opt/yaffas/$PRODUCT/$1/"
	local LICTYPE=$2
	local LIC=$(const_file license_module_file)

	if [[ ! -f $LIC ]]; then
		touch $LIC
	fi
	
	if [ ! "`grep "$MODULE=$LICTYPE" $LIC`" ]; then
		echo "$MODULE=$LICTYPE" >> $LIC
	fi
}

function del_license() {
	local MODULE="/opt/yaffas/$PRODUCT/$1/"
	local LICTYPE=$2
	if [ "$LICTYPE" == "" ]; then
		LICTYPE=".*"
	fi
	local LIC=$(const_file license_module_file)
	if [ -f $LIC ]; then
		sed -e "s|$MODULE=$LICTYPE\$||" -i $LIC
	fi
}

function add_license_webrootdir() {
	local LICTYPE=$1
	local LIC=$(const_file license_module_file)
	
	if [ ! $(grep "/opt/yaffas/webmin/\=" $LIC) ]; then
		echo "/opt/yaffas/webmin/=$LICTYPE" >> $LIC
	fi
	
}

function del_license_webrootdir() {
	local LICTYPE=$1
	local LIC=$(const_file license_module_file)

	sed -e "s|/opt/yaffas/webmin/\=.*\$||" -i $LIC
}
