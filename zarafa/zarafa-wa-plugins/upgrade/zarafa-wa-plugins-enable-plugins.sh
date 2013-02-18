#!/usr/bin/env perl -I /opt/yaffas/lib/perl5
use Yaffas;
use Yaffas::AuthSrv;

# ADM-304
# the password change plugin had only be enabled when re-setting
# the authentication server, but it should be enabled on all installs
# by default now
# the actual config was/will be written by the AuthSrv module
Yaffas::AuthSrv::_link_webaccess_plugin("passwd");
Yaffas::AuthSrv::_link_webapp_plugin("passwd");
