#!/usr/bin/perl

use strict;
use warnings;

use constant TESTS => 10;

use Test::More tests => TESTS;
use Test::Exception;
use Yaffas::Test;
use Yaffas::Constant;
use Yaffas::Product;

use Yaffas::Module::ZarafaConf;
$Yaffas::Module::ZarafaConf::TESTMODE = 1;

SKIP: {
		  Yaffas::Test::setup_file_from_system(Yaffas::Constant::FILE->{bkversion});
		  skip "Zarafa not installed", TESTS unless Yaffas::Product::check_product("zarafa");
		  Yaffas::Test::setup_file_from_system("/proc/meminfo");

		  dies_ok {my @values = Yaffas::Module::ZarafaConf::optimized_memory_for()} "no config available";
		  dies_ok {my @values = Yaffas::Module::ZarafaConf::optimized_memory_for(1)} "no config available";

		  Yaffas::Test::setup_file_from_system(Yaffas::Constant::FILE->{zarafa_server_cfg});
		  Yaffas::Test::setup_file("data/my.cnf.default", Yaffas::Constant::FILE->{mysql_cnf});

		  my @values = Yaffas::Module::ZarafaConf::optimized_memory_for();

		  ok ($values[1] > 0 && $values[1] =~ /^\d+$/, "check if memory is read correctly");
		  is ($values[0], -1, "check if file is empty");

		  Yaffas::Test::setup_file("data/meminfo.512mb", "/proc/meminfo");
		  Yaffas::Test::setup_file_from_system(Yaffas::Constant::FILE->{zarafa_server_cfg});

		  @values = Yaffas::Module::ZarafaConf::optimized_memory_for();
		  is ($values[0], -1, "check if file is has no entry");

		  Yaffas::Module::ZarafaConf::optimized_memory_for(1);

		  Yaffas::Test::setup_file("data/meminfo.1024mb", "/proc/meminfo");
		  @values = Yaffas::Module::ZarafaConf::optimized_memory_for();
		  is ($values[1], 1048692*1024, "check if everything is set correctly");
		  is ($values[0], 514976*1024, "check if everything is set correctly");

		  Yaffas::Module::ZarafaConf::optimized_memory_for(1);

		  @values = Yaffas::Module::ZarafaConf::optimized_memory_for();
		  is ($values[1], 1048692*1024, "check if everything is set correctly");
		  is ($values[0], 1048692*1024, "check if everything is set correctly");

		  Yaffas::Test::setup_file("data/server.cfg", Yaffas::Constant::FILE->{zarafa_server_cfg});
		  @values = Yaffas::Module::ZarafaConf::optimized_memory_for();
		  is ($values[0], -1, "check what happens if values from zarafa and mysql are different");
	  }
