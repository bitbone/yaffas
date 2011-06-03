#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 10;
use Test::Exception;
use Yaffas::Test;
use Yaffas::Constant;

use Yaffas::Module::Mailsrv;

Yaffas::Test::create_dir("/etc/");
Yaffas::Test::create_dir("/etc/exim4/");

# empty config
lives_ok {Yaffas::Module::Mailsrv::conf_dump()} "conf_dump runs fine";

is(-f Yaffas::Test::testdir()."/etc/yaffas.xml", 1, "was yaffas.xml created");

# config with values
lives_ok {Yaffas::Module::Mailsrv::set_verify_rcp('mailadmin','erwin@bitbone.de')} "set verify_rcp (mailadmin)";
lives_ok {Yaffas::Module::Mailsrv::set_mailsize(1000)} "set mailsize";
lives_ok {Yaffas::Module::Mailsrv::set_smarthost("192.168.7.21", "erwin", "a")} "set smarthost";
lives_ok {Yaffas::Module::Mailsrv::set_mailserver('mail.bitbone.de')} "set mailserver name";
lives_ok {Yaffas::Module::Mailsrv::set_accept_relay('192.168.7.22')} "set accept relay";
lives_ok {Yaffas::Module::Mailsrv::set_archive('erwin@bitbone.de')} "set archive";
Yaffas::Test::create_file(Yaffas::Constant::FILE->{'fetchmail_pid'}, "1");
Yaffas::Test::setup_file("exim.acceptdomains-conf_dump", Yaffas::Constant::FILE()->{exim_domains_conf});

unlink(Yaffas::Test::testdir()."/etc/yaffas.xml");

lives_ok {Yaffas::Module::Mailsrv::conf_dump()} "conf_dump runs fine";
is(-f Yaffas::Test::testdir()."/etc/yaffas.xml", 1, "was yaffas.xml created");
