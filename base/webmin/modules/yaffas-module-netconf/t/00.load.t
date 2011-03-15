#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 1;
use Test::Exception;
use Yaffas::Test;
use Yaffas::Constant;

BEGIN {
	use_ok("Yaffas::Module::Netconf");
}
