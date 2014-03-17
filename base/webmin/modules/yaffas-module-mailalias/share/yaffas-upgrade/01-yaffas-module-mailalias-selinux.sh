#!/bin/bash
set -e

# Important: when modifying this script, keep in mind that it is also
# called from yaffas-module-mailalias/postinst*!

# no SELinux? exit!
selinuxenabled 2>/dev/null || exit 0

# context already set? exit!
ls -lZ /opt/yaffas/libexec/mailalias/zarafa-deliver-to-public | \
		grep -q zarafa_deliver_to_public_exec_t && exit 0

install_selinux_policy() {
	local path=$1; shift
	MOD=$(mktemp)
	PP=$(mktemp)
	checkmodule -M -m "$path" -o "$MOD"
	semodule_package -m "$MOD" -o "$PP"
	semodule -i "$PP"
	rm "$MOD" "$PP"
}

install_selinux_policy /opt/yaffas/share/yaffas-module-mailalias/zarafa-deliver-to-public.te
semanage fcontext -a -t zarafa_deliver_to_public_exec_t /opt/yaffas/libexec/mailalias/zarafa-deliver-to-public
restorecon /opt/yaffas/libexec/mailalias/zarafa-deliver-to-public
