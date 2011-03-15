#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 4;
use Test::Exception;
use Yaffas::Test;
use Yaffas::Constant;

use Yaffas::Module::ZarafaConf;

Yaffas::Test::setup_file_from_system(Yaffas::Constant::FILE->{webaccess_htaccess});

lives_ok { Yaffas::Module::ZarafaConf::attachment_size(20) } "check if can set to 20";
dies_ok { Yaffas::Module::ZarafaConf::attachment_size("asdf") } "check if can set to asdf";
dies_ok { Yaffas::Module::ZarafaConf::attachment_size(0) } "check if can set to 0";
is (Yaffas::Module::ZarafaConf::attachment_size(), 20, "check if it is still set to 20");
