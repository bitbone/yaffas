#!/bin/bash
# It would be better to have perl as the interpreter, but the framework
# enforces bash...

# ADM-304
# the password change plugin had only be enabled when re-setting
# the authentication server, but it should be enabled on all installs
# by default now
# the actual config was/will be written by the AuthSrv module
perl -I /opt/yaffas/lib/perl5 \
		-MYaffas -MYaffas::Module::AuthSrv \
		-e 'Yaffas::Module::AuthSrv::_link_webaccess_plugin("passwd");Yaffas::Module::AuthSrv::_link_webapp_plugin("passwd");'
