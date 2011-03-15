#!/usr/bin/perl

use strict;
use warnings;

use Yaffas::Module::Mailsrv qw(get_mailserver set_mailserver);
use Yaffas::Constant;

use Test::More tests => 6;
use Test::Exception;

use Yaffas::Test;

Yaffas::Test::create_file(Yaffas::Constant::FILE()->{bbexim_conf});

is(get_mailserver(), undef, "No mailadmin set");
lives_ok {set_mailserver('mail.server.name')} "Setting mail.server.name as mailservername";
is(get_mailserver(), 'mail.server.name', "Check if set was correct");

dies_ok {set_mailserver('123$')} "Setting 123\$ as mailadmin";
dies_ok {set_mailserver('-name')} "Setting -name as mailadmin";
dies_ok {set_mailserver('name-')} "Setting name- as mailadmin";

