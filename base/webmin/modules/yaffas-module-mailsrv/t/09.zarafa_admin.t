#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 7;
use Test::Exception;
use Yaffas::Test;
use Yaffas::Constant;
use Yaffas::Product qw(check_product);

use Yaffas::Module::Mailsrv qw(get_zarafa_admin set_zarafa_admin);

$Yaffas::Module::Mailsrv::TESTDIR = Yaffas::Test::testdir();

Yaffas::Test::create_file(Yaffas::Constant::FILE->{zarafa_admin_cfg});
Yaffas::Test::create_file(Yaffas::Constant::FILE->{bbexim_conf});

Yaffas::Test::setup_file("installed-products", "/opt/yaffas/etc/installed-products");
Yaffas::Test::setup_file_from_system("/etc/ldap.secret");
Yaffas::Test::setup_file_from_system(Yaffas::Constant::FILE->{libnss_ldap_conf});
Yaffas::Test::setup_file_from_system(Yaffas::Constant::FILE->{smbldap_conf});

dies_ok {set_zarafa_admin("user1", undef)} "empty password";
dies_ok {set_zarafa_admin("user1testblablub", "password")} "user doesn't exists";

SKIP: {
		  skip "user1 doesn't exists or is not an admin", 5 unless Yaffas::UGM::user_exists("user1") and Yaffas::Module::Users::get_zarafa_admin("user1");
		  dies_ok {set_zarafa_admin("user1", "password")} "correct username, but incorrect password";
		  lives_ok {set_zarafa_admin("user1", "a")} "correct username and username";
		  is(get_zarafa_admin(), "user1", "check if admin is set correctly");

		  lives_ok {set_zarafa_admin("", "")} "remove setting";
		  is(get_zarafa_admin(), undef, "check if admin is set correctly");
	  }
