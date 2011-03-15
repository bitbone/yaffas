#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 1;
use Test::Exception;
use Yaffas::Test;
use Yaffas::Constant;

use Yaffas::Module::AuthSrv;

dies_ok {Yaffas::Module::AuthSrv::set_bk_ldap_auth("localhost", "ou=bitbone,c=de", "cn=ldapadmin,o=bitbone,c=de", "pwd", "ou=People", "ou=Group", "uid", "asdsdf\nasdf", 0)} "wrong email";
